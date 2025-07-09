package service

import (
	"crypto/x509"
	"encoding/json"
	"encoding/pem"
	"errors"
	"fmt"
	"io"
	"net/http"
	"net/url"
	"os"
	"strings"
	"time"
	"todo-backend/internal/config"
	"todo-backend/internal/models"
	"todo-backend/internal/repository"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
	"github.com/rs/zerolog/log"
	"golang.org/x/crypto/bcrypt"
)

type AuthService interface {
	// Apple OAuth methods
	GenerateAppleLoginURL(state string) string
	ValidateAppleToken(code string) (*models.AppleUserInfo, error)
	ProcessAppleLogin(appleUserInfo *models.AppleUserInfo, userDataJSON string) (*models.LoginResponse, error)
	
	// JWT token methods
	GenerateTokenPair(userID uuid.UUID, email, appleID string) (*models.LoginResponse, error)
	ValidateAccessToken(tokenString string) (*models.JWTClaims, error)
	RefreshToken(refreshTokenString string) (*models.LoginResponse, error)
	
	// Traditional auth methods (for future use)
	RegisterUser(req *models.UserCreateRequest) (*models.User, error)
	LoginUser(email, password string) (*models.LoginResponse, error)
}

type authService struct {
	userRepo    repository.UserRepository
	config      *config.Config
	httpClient  *http.Client
}

func NewAuthService(userRepo repository.UserRepository, cfg *config.Config) (AuthService, error) {
	return &authService{
		userRepo:   userRepo,
		config:     cfg,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}, nil
}

// GenerateAppleLoginURL creates the URL for Apple OAuth login
func (s *authService) GenerateAppleLoginURL(state string) string {
	baseURL := "https://appleid.apple.com/auth/authorize"
	params := url.Values{}
	params.Add("client_id", s.config.AppleClientID)
	params.Add("redirect_uri", s.config.AppleRedirectURL)
	params.Add("response_type", "code")
	params.Add("scope", "name email")
	params.Add("response_mode", "form_post")
	params.Add("state", state)

	return fmt.Sprintf("%s?%s", baseURL, params.Encode())
}

// Apple Token Response structure
type AppleTokenResponse struct {
	AccessToken  string `json:"access_token"`
	TokenType    string `json:"token_type"`
	ExpiresIn    int    `json:"expires_in"`
	RefreshToken string `json:"refresh_token"`
	IDToken      string `json:"id_token"`
}

// ValidateAppleToken validates the authorization code with Apple and returns user info
func (s *authService) ValidateAppleToken(code string) (*models.AppleUserInfo, error) {
	// Generate client secret (JWT) for Apple
	clientSecret, err := s.generateAppleClientSecret()
	if err != nil {
		return nil, fmt.Errorf("failed to generate client secret: %w", err)
	}

	// Exchange authorization code for tokens
	tokenResp, err := s.exchangeAppleCode(code, clientSecret)
	if err != nil {
		return nil, fmt.Errorf("failed to exchange Apple code: %w", err)
	}

	// Parse ID token to extract user information
	userInfo, err := s.parseAppleIDToken(tokenResp.IDToken)
	if err != nil {
		return nil, fmt.Errorf("failed to parse Apple ID token: %w", err)
	}

	log.Info().
		Str("apple_id", userInfo.Sub).
		Str("email", userInfo.Email).
		Bool("email_verified", userInfo.EmailVerified).
		Bool("is_private_email", userInfo.IsPrivateEmail).
		Msg("Successfully validated Apple token")

	return userInfo, nil
}

// ProcessAppleLogin handles the complete Apple login flow
func (s *authService) ProcessAppleLogin(appleUserInfo *models.AppleUserInfo, userDataJSON string) (*models.LoginResponse, error) {
	// Try to find existing user by Apple ID
	existingUser, err := s.userRepo.GetByAppleID(appleUserInfo.Sub)
	if err == nil && existingUser != nil {
		// User already exists, generate tokens
		log.Info().Str("user_id", existingUser.ID.String()).Msg("Existing Apple user logged in")
		return s.GenerateTokenPair(existingUser.ID, existingUser.Email, existingUser.AppleID)
	}

	// User doesn't exist, create new user
	var userName string
	if userDataJSON != "" {
		// Parse additional user data from Apple (only available on first login)
		var appleUserData map[string]interface{}
		if err := json.Unmarshal([]byte(userDataJSON), &appleUserData); err == nil {
			if name, ok := appleUserData["name"].(map[string]interface{}); ok {
				firstName, _ := name["firstName"].(string)
				lastName, _ := name["lastName"].(string)
				userName = fmt.Sprintf("%s %s", firstName, lastName)
			}
		}
	}

	// Fallback name generation
	if userName == "" {
		if appleUserInfo.Email != "" {
			// Use email prefix as name
			userName = appleUserInfo.Email[:len(appleUserInfo.Email)-len("@example.com")]
		} else {
			userName = "Apple User"
		}
	}

	// Create new user
	newUser := &models.User{
		Email:          appleUserInfo.Email,
		Name:           userName,
		AppleID:        appleUserInfo.Sub,
		IsPrivateEmail: appleUserInfo.IsPrivateEmail,
		AuthProvider:   "apple",
		IsActive:       true,
	}

	if err := s.userRepo.Create(newUser); err != nil {
		log.Error().Err(err).Msg("Failed to create new Apple user")
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	log.Info().
		Str("user_id", newUser.ID.String()).
		Str("apple_id", newUser.AppleID).
		Msg("Created new Apple user")

	// Generate tokens for new user
	return s.GenerateTokenPair(newUser.ID, newUser.Email, newUser.AppleID)
}

// GenerateTokenPair creates access and refresh tokens
func (s *authService) GenerateTokenPair(userID uuid.UUID, email, appleID string) (*models.LoginResponse, error) {
	now := time.Now()
	
	// Access token (short-lived)
	accessTokenClaims := models.JWTClaims{
		UserID:    userID,
		Email:     email,
		AppleID:   appleID,
		TokenType: "access",
		IssuedAt:  now,
		ExpiresAt: now.Add(15 * time.Minute), // 15 minutes
	}

	accessToken, err := s.generateJWT(accessTokenClaims)
	if err != nil {
		return nil, fmt.Errorf("failed to generate access token: %w", err)
	}

	// Refresh token (long-lived)
	refreshTokenClaims := models.JWTClaims{
		UserID:    userID,
		Email:     email,
		AppleID:   appleID,
		TokenType: "refresh",
		IssuedAt:  now,
		ExpiresAt: now.Add(7 * 24 * time.Hour), // 7 days
	}

	refreshToken, err := s.generateJWT(refreshTokenClaims)
	if err != nil {
		return nil, fmt.Errorf("failed to generate refresh token: %w", err)
	}

	// Get user details
	user, err := s.userRepo.GetByID(userID)
	if err != nil {
		return nil, fmt.Errorf("failed to get user details: %w", err)
	}

	return &models.LoginResponse{
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		TokenType:    "Bearer",
		ExpiresIn:    900, // 15 minutes
		User:         user.ToResponse(),
	}, nil
}

// ValidateAccessToken validates and parses an access token
func (s *authService) ValidateAccessToken(tokenString string) (*models.JWTClaims, error) {
	token, err := jwt.Parse(tokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(s.config.JWTSecret), nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse token: %w", err)
	}

	if !token.Valid {
		return nil, errors.New("invalid token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	// Extract user ID
	userIDStr, ok := claims["user_id"].(string)
	if !ok {
		return nil, errors.New("invalid user_id claim")
	}
	
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil, fmt.Errorf("invalid user_id format: %w", err)
	}

	// Extract other claims
	email, _ := claims["email"].(string)
	appleID, _ := claims["apple_id"].(string)
	tokenType, _ := claims["token_type"].(string)

	if tokenType != "access" {
		return nil, errors.New("not an access token")
	}

	// Extract timestamps
	iatFloat, ok := claims["iat"].(float64)
	if !ok {
		return nil, errors.New("invalid iat claim")
	}
	
	expFloat, ok := claims["exp"].(float64)
	if !ok {
		return nil, errors.New("invalid exp claim")
	}

	issuedAt := time.Unix(int64(iatFloat), 0)
	expiresAt := time.Unix(int64(expFloat), 0)

	if time.Now().After(expiresAt) {
		return nil, errors.New("token expired")
	}

	return &models.JWTClaims{
		UserID:    userID,
		Email:     email,
		AppleID:   appleID,
		TokenType: tokenType,
		IssuedAt:  issuedAt,
		ExpiresAt: expiresAt,
	}, nil
}

// RefreshToken generates a new access token using a refresh token
func (s *authService) RefreshToken(refreshTokenString string) (*models.LoginResponse, error) {
	token, err := jwt.Parse(refreshTokenString, func(token *jwt.Token) (interface{}, error) {
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return []byte(s.config.JWTSecret), nil
	})

	if err != nil {
		return nil, fmt.Errorf("failed to parse refresh token: %w", err)
	}

	if !token.Valid {
		return nil, errors.New("invalid refresh token")
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("invalid token claims")
	}

	// Extract user ID
	userIDStr, ok := claims["user_id"].(string)
	if !ok {
		return nil, errors.New("invalid user_id claim")
	}
	
	userID, err := uuid.Parse(userIDStr)
	if err != nil {
		return nil, fmt.Errorf("invalid user_id format: %w", err)
	}

	// Extract other claims
	email, _ := claims["email"].(string)
	appleID, _ := claims["apple_id"].(string)
	tokenType, _ := claims["token_type"].(string)

	if tokenType != "refresh" {
		return nil, errors.New("not a refresh token")
	}

	// Extract expiration time
	expFloat, ok := claims["exp"].(float64)
	if !ok {
		return nil, errors.New("invalid exp claim")
	}

	expiresAt := time.Unix(int64(expFloat), 0)
	if time.Now().After(expiresAt) {
		return nil, errors.New("refresh token expired")
	}

	// Generate new token pair
	return s.GenerateTokenPair(userID, email, appleID)
}

// Traditional auth methods for future use

// RegisterUser creates a new user with email and password
func (s *authService) RegisterUser(req *models.UserCreateRequest) (*models.User, error) {
	// Check if user already exists
	existingUser, _ := s.userRepo.GetByEmail(req.Email)
	if existingUser != nil {
		return nil, errors.New("user already exists")
	}

	// Hash password
	hashedPassword, err := bcrypt.GenerateFromPassword([]byte(req.Password), bcrypt.DefaultCost)
	if err != nil {
		return nil, fmt.Errorf("failed to hash password: %w", err)
	}

	// Create user
	user := &models.User{
		Email:        req.Email,
		Password:     string(hashedPassword),
		Name:         req.Name,
		AuthProvider: "email",
		IsActive:     true,
	}

	if err := s.userRepo.Create(user); err != nil {
		return nil, fmt.Errorf("failed to create user: %w", err)
	}

	return user, nil
}

// LoginUser authenticates a user with email and password
func (s *authService) LoginUser(email, password string) (*models.LoginResponse, error) {
	// Get user by email
	user, err := s.userRepo.GetByEmail(email)
	if err != nil {
		return nil, errors.New("invalid credentials")
	}

	if !user.IsActive {
		return nil, errors.New("user account is deactivated")
	}

	if user.AuthProvider != "email" {
		return nil, errors.New("please use your Apple ID to login")
	}

	// Verify password
	if err := bcrypt.CompareHashAndPassword([]byte(user.Password), []byte(password)); err != nil {
		return nil, errors.New("invalid credentials")
	}

	// Generate tokens
	return s.GenerateTokenPair(user.ID, user.Email, "")
}

// Helper method to generate JWT tokens
func (s *authService) generateJWT(claims models.JWTClaims) (string, error) {
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, jwt.MapClaims{
		"user_id":    claims.UserID.String(),
		"email":      claims.Email,
		"apple_id":   claims.AppleID,
		"token_type": claims.TokenType,
		"iat":        claims.IssuedAt.Unix(),
		"exp":        claims.ExpiresAt.Unix(),
		"jti":        uuid.New().String(), // JWT ID for uniqueness
	})

	return token.SignedString([]byte(s.config.JWTSecret))
}

// generateAppleClientSecret creates a JWT client secret for Apple OAuth
func (s *authService) generateAppleClientSecret() (string, error) {
	// Check if Apple configuration is properly set up
	if s.config.AppleKeyPath == "" || s.config.AppleTeamID == "" || s.config.AppleClientID == "" || s.config.AppleKeyID == "" {
		return "", errors.New("Apple OAuth is not configured: missing required environment variables (APPLE_KEY_PATH, APPLE_TEAM_ID, APPLE_CLIENT_ID, APPLE_KEY_ID)")
	}

	// Load the private key file
	keyData, err := os.ReadFile(s.config.AppleKeyPath)
	if err != nil {
		return "", fmt.Errorf("failed to read Apple private key: %w", err)
	}

	// Parse the PEM private key
	block, _ := pem.Decode(keyData)
	if block == nil {
		return "", errors.New("failed to decode PEM block from Apple private key")
	}

	// Parse the private key
	privateKey, err := x509.ParsePKCS8PrivateKey(block.Bytes)
	if err != nil {
		return "", fmt.Errorf("failed to parse Apple private key: %w", err)
	}

	// Create JWT claims
	now := time.Now()
	claims := jwt.MapClaims{
		"iss": s.config.AppleTeamID,
		"iat": now.Unix(),
		"exp": now.Add(time.Hour).Unix(), // Token expires in 1 hour
		"aud": "https://appleid.apple.com",
		"sub": s.config.AppleClientID,
	}

	// Create and sign the token
	token := jwt.NewWithClaims(jwt.SigningMethodES256, claims)
	token.Header["kid"] = s.config.AppleKeyID

	tokenString, err := token.SignedString(privateKey)
	if err != nil {
		return "", fmt.Errorf("failed to sign Apple client secret: %w", err)
	}

	return tokenString, nil
}

// exchangeAppleCode exchanges authorization code for tokens
func (s *authService) exchangeAppleCode(code, clientSecret string) (*AppleTokenResponse, error) {
	data := url.Values{}
	data.Set("client_id", s.config.AppleClientID)
	data.Set("client_secret", clientSecret)
	data.Set("code", code)
	data.Set("grant_type", "authorization_code")
	data.Set("redirect_uri", s.config.AppleRedirectURL)

	req, err := http.NewRequest("POST", "https://appleid.apple.com/auth/token", strings.NewReader(data.Encode()))
	if err != nil {
		return nil, fmt.Errorf("failed to create token request: %w", err)
	}

	req.Header.Set("Content-Type", "application/x-www-form-urlencoded")

	resp, err := s.httpClient.Do(req)
	if err != nil {
		return nil, fmt.Errorf("failed to exchange code for token: %w", err)
	}
	defer resp.Body.Close()

	body, err := io.ReadAll(resp.Body)
	if err != nil {
		return nil, fmt.Errorf("failed to read token response: %w", err)
	}

	if resp.StatusCode != http.StatusOK {
		return nil, fmt.Errorf("Apple token exchange failed with status %d: %s", resp.StatusCode, string(body))
	}

	var tokenResp AppleTokenResponse
	if err := json.Unmarshal(body, &tokenResp); err != nil {
		return nil, fmt.Errorf("failed to parse token response: %w", err)
	}

	return &tokenResp, nil
}

// parseAppleIDToken parses the Apple ID token and extracts user information
func (s *authService) parseAppleIDToken(idToken string) (*models.AppleUserInfo, error) {
	// Parse without verification for now (Apple's keys would need to be fetched)
	token, _, err := new(jwt.Parser).ParseUnverified(idToken, jwt.MapClaims{})
	if err != nil {
		return nil, fmt.Errorf("failed to parse ID token: %w", err)
	}

	claims, ok := token.Claims.(jwt.MapClaims)
	if !ok {
		return nil, errors.New("failed to extract claims from ID token")
	}

	userInfo := &models.AppleUserInfo{}

	if sub, ok := claims["sub"].(string); ok {
		userInfo.Sub = sub
	} else {
		return nil, errors.New("missing 'sub' claim in ID token")
	}

	if email, ok := claims["email"].(string); ok {
		userInfo.Email = email
	}

	if emailVerified, ok := claims["email_verified"].(bool); ok {
		userInfo.EmailVerified = emailVerified
	}

	if isPrivateEmail, ok := claims["is_private_email"].(bool); ok {
		userInfo.IsPrivateEmail = isPrivateEmail
	}

	return userInfo, nil
} 