package handlers

import (
	"crypto/rand"
	"encoding/hex"
	"net/http"
	"time"
	"todo-backend/internal/models"
	"todo-backend/internal/service"
	"todo-backend/pkg/utils"

	"github.com/gin-gonic/gin"
	"github.com/rs/zerolog/log"
)

type AuthHandler struct {
	authService service.AuthService
	states      map[string]time.Time // Simple in-memory state storage (use Redis in production)
}

func NewAuthHandler(authService service.AuthService) *AuthHandler {
	return &AuthHandler{
		authService: authService,
		states:      make(map[string]time.Time),
	}
}

// InitiateAppleLogin godoc
// @Summary Initiate Apple ID login
// @Description Generate Apple ID login URL with state parameter for CSRF protection
// @Tags auth
// @Accept json
// @Produce json
// @Success 200 {object} utils.Response{data=map[string]string}
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/auth/apple/login [get]
func (h *AuthHandler) InitiateAppleLogin(c *gin.Context) {
	// Generate random state for CSRF protection
	state, err := h.generateState()
	if err != nil {
		log.Error().Err(err).Msg("Failed to generate state")
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to generate login state", err.Error())
		return
	}

	// Store state with expiration (5 minutes)
	h.states[state] = time.Now().Add(5 * time.Minute)

	// Generate Apple login URL
	loginURL := h.authService.GenerateAppleLoginURL(state)

	log.Info().Str("state", state).Msg("Generated Apple login URL")

	utils.SuccessResponse(c, http.StatusOK, "Apple login URL generated", map[string]string{
		"login_url": loginURL,
		"state":     state,
	})
}

// HandleAppleCallback godoc
// @Summary Handle Apple ID OAuth callback
// @Description Process Apple ID OAuth callback and authenticate user
// @Tags auth
// @Accept json
// @Produce json
// @Param request body models.AppleCallbackRequest true "Apple callback data"
// @Success 200 {object} utils.Response{data=models.LoginResponse}
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/auth/apple/callback [post]
func (h *AuthHandler) HandleAppleCallback(c *gin.Context) {
	var req models.AppleCallbackRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	// Verify state parameter (CSRF protection)
	if req.State != "" {
		if !h.validateState(req.State) {
			utils.SendErrorResponse(c, http.StatusUnauthorized, "Invalid or expired state parameter", "CSRF protection failed")
			return
		}
		// Clean up used state
		delete(h.states, req.State)
	}

	// Validate Apple authorization code
	appleUserInfo, err := h.authService.ValidateAppleToken(req.Code)
	if err != nil {
		log.Error().Err(err).Msg("Failed to validate Apple token")
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Failed to validate Apple authorization", err.Error())
		return
	}

	// Process Apple login (create user if needed, generate tokens)
	loginResponse, err := h.authService.ProcessAppleLogin(appleUserInfo, req.User)
	if err != nil {
		log.Error().Err(err).Msg("Failed to process Apple login")
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to complete Apple login", err.Error())
		return
	}

	log.Info().
		Str("user_id", loginResponse.User.ID.String()).
		Str("email", loginResponse.User.Email).
		Msg("Apple login successful")

	utils.SuccessResponse(c, http.StatusOK, "Apple login successful", loginResponse)
}

// HandleAppleCallbackURL godoc
// @Summary Handle Apple ID OAuth callback URL (from web redirect)
// @Description Process Apple ID OAuth callback from web redirect and authenticate user
// @Tags auth
// @Accept json
// @Produce json
// @Param code query string true "Authorization code from Apple"
// @Param state query string false "State parameter for CSRF protection"
// @Param user query string false "User data from Apple (base64 encoded JSON)"
// @Success 200 {object} utils.Response{data=models.LoginResponse}
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/auth/apple/callback [get]
func (h *AuthHandler) HandleAppleCallbackURL(c *gin.Context) {
	code := c.Query("code")
	state := c.Query("state")
	user := c.Query("user")

	if code == "" {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Missing authorization code", "code parameter is required")
		return
	}

	// Verify state parameter (CSRF protection)
	if state != "" {
		if !h.validateState(state) {
			utils.SendErrorResponse(c, http.StatusUnauthorized, "Invalid or expired state parameter", "CSRF protection failed")
			return
		}
		// Clean up used state
		delete(h.states, state)
	}

	// Validate Apple authorization code
	appleUserInfo, err := h.authService.ValidateAppleToken(code)
	if err != nil {
		log.Error().Err(err).Msg("Failed to validate Apple token")
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Failed to validate Apple authorization", err.Error())
		return
	}

	// Process Apple login (create user if needed, generate tokens)
	loginResponse, err := h.authService.ProcessAppleLogin(appleUserInfo, user)
	if err != nil {
		log.Error().Err(err).Msg("Failed to process Apple login")
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to complete Apple login", err.Error())
		return
	}

	log.Info().
		Str("user_id", loginResponse.User.ID.String()).
		Str("email", loginResponse.User.Email).
		Msg("Apple login successful via URL callback")

	utils.SuccessResponse(c, http.StatusOK, "Apple login successful", loginResponse)
}

// RefreshToken godoc
// @Summary Refresh access token
// @Description Generate new access token using refresh token
// @Tags auth
// @Accept json
// @Produce json
// @Param request body models.TokenRefreshRequest true "Refresh token request"
// @Success 200 {object} utils.Response{data=models.LoginResponse}
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/auth/token/refresh [post]
func (h *AuthHandler) RefreshToken(c *gin.Context) {
	var req models.TokenRefreshRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	// Refresh token
	loginResponse, err := h.authService.RefreshToken(req.RefreshToken)
	if err != nil {
		log.Error().Err(err).Msg("Failed to refresh token")
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Failed to refresh token", err.Error())
		return
	}

	log.Info().
		Str("user_id", loginResponse.User.ID.String()).
		Msg("Token refreshed successfully")

	utils.SuccessResponse(c, http.StatusOK, "Token refreshed successfully", loginResponse)
}

// GetUserProfile godoc
// @Summary Get current user profile
// @Description Get the authenticated user's profile information
// @Tags auth
// @Accept json
// @Produce json
// @Security BearerAuth
// @Success 200 {object} utils.Response{data=models.UserResponse}
// @Failure 401 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/auth/user/profile [get]
func (h *AuthHandler) GetUserProfile(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Unauthorized", err.Error())
		return
	}

	// Get user details (this would use userRepository, but for now we can get it from context)
	// In a real implementation, you'd fetch fresh user data from the database
	email, exists := c.Get("email")
	if !exists {
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to get user info", "email not found in context")
		return
	}

	// For now, return basic info from token
	// TODO: Fetch complete user data from repository
	response := models.UserResponse{
		ID:    userID,
		Email: email.(string),
		// Add other fields as needed
	}

	utils.SuccessResponse(c, http.StatusOK, "User profile retrieved", response)
}

// Traditional Auth Handlers (for future use)

// RegisterUser godoc
// @Summary Register new user
// @Description Register a new user with email and password
// @Tags auth
// @Accept json
// @Produce json
// @Param request body models.UserCreateRequest true "User registration data"
// @Success 201 {object} utils.Response{data=models.UserResponse}
// @Failure 400 {object} utils.ErrorResponse
// @Failure 409 {object} utils.ErrorResponse
// @Failure 422 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/auth/register [post]
func (h *AuthHandler) RegisterUser(c *gin.Context) {
	var req models.UserCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	// Register user
	user, err := h.authService.RegisterUser(&req)
	if err != nil {
		if err.Error() == "user already exists" {
			utils.SendErrorResponse(c, http.StatusConflict, "User already exists", err.Error())
			return
		}
		log.Error().Err(err).Msg("Failed to register user")
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to register user", err.Error())
		return
	}

	log.Info().
		Str("user_id", user.ID.String()).
		Str("email", user.Email).
		Msg("User registered successfully")

	utils.SuccessResponse(c, http.StatusCreated, "User registered successfully", user.ToResponse())
}

// LoginUser godoc
// @Summary Login with email and password
// @Description Authenticate user with email and password
// @Tags auth
// @Accept json
// @Produce json
// @Param request body map[string]string true "Login credentials"
// @Success 200 {object} utils.Response{data=models.LoginResponse}
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/auth/login [post]
func (h *AuthHandler) LoginUser(c *gin.Context) {
	var req struct {
		Email    string `json:"email" validate:"required,email"`
		Password string `json:"password" validate:"required"`
	}

	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	// Validate request
	if err := utils.ValidateStruct(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	// Login user
	loginResponse, err := h.authService.LoginUser(req.Email, req.Password)
	if err != nil {
		log.Error().Err(err).Str("email", req.Email).Msg("Failed to login user")
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Login failed", err.Error())
		return
	}

	log.Info().
		Str("user_id", loginResponse.User.ID.String()).
		Str("email", loginResponse.User.Email).
		Msg("User login successful")

	utils.SuccessResponse(c, http.StatusOK, "Login successful", loginResponse)
}

// Helper methods

func (h *AuthHandler) generateState() (string, error) {
	bytes := make([]byte, 16)
	if _, err := rand.Read(bytes); err != nil {
		return "", err
	}
	return hex.EncodeToString(bytes), nil
}

func (h *AuthHandler) validateState(state string) bool {
	expiresAt, exists := h.states[state]
	if !exists {
		return false
	}

	// Check if state has expired
	if time.Now().After(expiresAt) {
		delete(h.states, state)
		return false
	}

	return true
}

// Cleanup expired states (should be called periodically)
func (h *AuthHandler) CleanupExpiredStates() {
	now := time.Now()
	for state, expiresAt := range h.states {
		if now.After(expiresAt) {
			delete(h.states, state)
		}
	}
} 