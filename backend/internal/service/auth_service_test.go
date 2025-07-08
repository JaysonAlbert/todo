package service

import (
	"net/http"
	"testing"
	"time"
	"todo-backend/internal/config"
	"todo-backend/internal/models"

	"github.com/google/uuid"
	"github.com/stretchr/testify/assert"
	"github.com/stretchr/testify/mock"
)

// Mock repository for testing
type MockUserRepository struct {
	mock.Mock
}

func (m *MockUserRepository) Create(user *models.User) error {
	args := m.Called(user)
	return args.Error(0)
}

func (m *MockUserRepository) GetByID(id uuid.UUID) (*models.User, error) {
	args := m.Called(id)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) GetByEmail(email string) (*models.User, error) {
	args := m.Called(email)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) GetByAppleID(appleID string) (*models.User, error) {
	args := m.Called(appleID)
	if args.Get(0) == nil {
		return nil, args.Error(1)
	}
	return args.Get(0).(*models.User), args.Error(1)
}

func (m *MockUserRepository) Update(user *models.User) error {
	args := m.Called(user)
	return args.Error(0)
}

func (m *MockUserRepository) Delete(id uuid.UUID) error {
	args := m.Called(id)
	return args.Error(0)
}

func (m *MockUserRepository) List(offset, limit int) ([]models.User, int64, error) {
	args := m.Called(offset, limit)
	return args.Get(0).([]models.User), args.Get(1).(int64), args.Error(2)
}

func setupAuthService() (*authService, *MockUserRepository) {
	mockRepo := new(MockUserRepository)
	cfg := &config.Config{
		JWTSecret:        "test-secret",
		AppleTeamID:      "test-team-id",
		AppleClientID:    "test-client-id",
		AppleKeyID:       "test-key-id",
		AppleRedirectURL: "http://localhost:8080/auth/apple/callback",
	}

	service := &authService{
		userRepo:   mockRepo,
		config:     cfg,
		httpClient: &http.Client{Timeout: 30 * time.Second},
	}

	return service, mockRepo
}

func TestGenerateTokenPair(t *testing.T) {
	service, mockRepo := setupAuthService()

	userID := uuid.New()
	email := "test@example.com"
	appleID := "test-apple-id"

	// Mock user data
	user := &models.User{
		ID:           userID,
		Email:        email,
		Name:         "Test User",
		AppleID:      appleID,
		AuthProvider: "apple",
		IsActive:     true,
	}

	mockRepo.On("GetByID", userID).Return(user, nil)

	// Test token generation
	loginResponse, err := service.GenerateTokenPair(userID, email, appleID)

	assert.NoError(t, err)
	assert.NotNil(t, loginResponse)
	assert.NotEmpty(t, loginResponse.AccessToken)
	assert.NotEmpty(t, loginResponse.RefreshToken)
	assert.Equal(t, "Bearer", loginResponse.TokenType)
	assert.Equal(t, 900, loginResponse.ExpiresIn) // 15 minutes
	assert.Equal(t, userID, loginResponse.User.ID)
	assert.Equal(t, email, loginResponse.User.Email)

	mockRepo.AssertExpectations(t)
}

func TestValidateAccessToken(t *testing.T) {
	service, mockRepo := setupAuthService()

	userID := uuid.New()
	email := "test@example.com"
	appleID := "test-apple-id"

	// Mock user data for GenerateTokenPair
	user := &models.User{
		ID:           userID,
		Email:        email,
		Name:         "Test User",
		AppleID:      appleID,
		AuthProvider: "apple",
		IsActive:     true,
	}

	mockRepo.On("GetByID", userID).Return(user, nil)

	// Generate a token first
	loginResponse, err := service.GenerateTokenPair(userID, email, appleID)
	assert.NoError(t, err)

	// Validate the access token
	claims, err := service.ValidateAccessToken(loginResponse.AccessToken)

	assert.NoError(t, err)
	assert.NotNil(t, claims)
	assert.Equal(t, userID, claims.UserID)
	assert.Equal(t, email, claims.Email)
	assert.Equal(t, appleID, claims.AppleID)
	assert.Equal(t, "access", claims.TokenType)

	mockRepo.AssertExpectations(t)
}

func TestValidateAccessToken_InvalidToken(t *testing.T) {
	service, _ := setupAuthService()

	// Test with invalid token
	claims, err := service.ValidateAccessToken("invalid-token")

	assert.Error(t, err)
	assert.Nil(t, claims)
	assert.Contains(t, err.Error(), "failed to parse token")
}

func TestRefreshToken(t *testing.T) {
	service, mockRepo := setupAuthService()

	userID := uuid.New()
	email := "test@example.com"
	appleID := "test-apple-id"

	// Mock user data
	user := &models.User{
		ID:           userID,
		Email:        email,
		Name:         "Test User",
		AppleID:      appleID,
		AuthProvider: "apple",
		IsActive:     true,
	}

	mockRepo.On("GetByID", userID).Return(user, nil).Times(2) // Called twice: once for original token, once for refresh

	// Generate initial token pair
	loginResponse, err := service.GenerateTokenPair(userID, email, appleID)
	assert.NoError(t, err)

	// Refresh the token
	newLoginResponse, err := service.RefreshToken(loginResponse.RefreshToken)

	assert.NoError(t, err)
	assert.NotNil(t, newLoginResponse)
	assert.NotEmpty(t, newLoginResponse.AccessToken)
	assert.NotEmpty(t, newLoginResponse.RefreshToken)
	assert.NotEqual(t, loginResponse.AccessToken, newLoginResponse.AccessToken) // Should be different
	assert.Equal(t, userID, newLoginResponse.User.ID)

	mockRepo.AssertExpectations(t)
}

func TestProcessAppleLogin_NewUser(t *testing.T) {
	service, mockRepo := setupAuthService()

	appleUserInfo := &models.AppleUserInfo{
		Sub:            "test-apple-id",
		Email:          "test@example.com",
		EmailVerified:  true,
		IsPrivateEmail: false,
	}

	// Mock that user doesn't exist yet
	mockRepo.On("GetByAppleID", "test-apple-id").Return(nil, assert.AnError)
	
	// Mock user creation
	mockRepo.On("Create", mock.AnythingOfType("*models.User")).Return(nil).Run(func(args mock.Arguments) {
		user := args.Get(0).(*models.User)
		user.ID = uuid.New() // Simulate DB assigning ID
	})

	// Mock getting user after creation
	newUser := &models.User{
		ID:             uuid.New(),
		Email:          appleUserInfo.Email,
		Name:           "Apple User",
		AppleID:        appleUserInfo.Sub,
		IsPrivateEmail: appleUserInfo.IsPrivateEmail,
		AuthProvider:   "apple",
		IsActive:       true,
	}
	mockRepo.On("GetByID", mock.AnythingOfType("uuid.UUID")).Return(newUser, nil)

	// Test processing Apple login for new user
	loginResponse, err := service.ProcessAppleLogin(appleUserInfo, "")

	assert.NoError(t, err)
	assert.NotNil(t, loginResponse)
	assert.NotEmpty(t, loginResponse.AccessToken)
	assert.Equal(t, appleUserInfo.Email, loginResponse.User.Email)
	assert.Equal(t, "apple", loginResponse.User.AuthProvider)

	mockRepo.AssertExpectations(t)
}

func TestProcessAppleLogin_ExistingUser(t *testing.T) {
	service, mockRepo := setupAuthService()

	appleUserInfo := &models.AppleUserInfo{
		Sub:            "test-apple-id",
		Email:          "test@example.com",
		EmailVerified:  true,
		IsPrivateEmail: false,
	}

	// Mock that user already exists
	existingUser := &models.User{
		ID:             uuid.New(),
		Email:          appleUserInfo.Email,
		Name:           "Existing User",
		AppleID:        appleUserInfo.Sub,
		IsPrivateEmail: appleUserInfo.IsPrivateEmail,
		AuthProvider:   "apple",
		IsActive:       true,
	}

	mockRepo.On("GetByAppleID", "test-apple-id").Return(existingUser, nil)
	mockRepo.On("GetByID", existingUser.ID).Return(existingUser, nil)

	// Test processing Apple login for existing user
	loginResponse, err := service.ProcessAppleLogin(appleUserInfo, "")

	assert.NoError(t, err)
	assert.NotNil(t, loginResponse)
	assert.NotEmpty(t, loginResponse.AccessToken)
	assert.Equal(t, existingUser.ID, loginResponse.User.ID)
	assert.Equal(t, appleUserInfo.Email, loginResponse.User.Email)

	mockRepo.AssertExpectations(t)
}

func TestRegisterUser(t *testing.T) {
	service, mockRepo := setupAuthService()

	req := &models.UserCreateRequest{
		Email:    "test@example.com",
		Password: "password123",
		Name:     "Test User",
	}

	// Mock that user doesn't exist
	mockRepo.On("GetByEmail", req.Email).Return(nil, assert.AnError)
	
	// Mock user creation
	mockRepo.On("Create", mock.AnythingOfType("*models.User")).Return(nil).Run(func(args mock.Arguments) {
		user := args.Get(0).(*models.User)
		user.ID = uuid.New() // Simulate DB assigning ID
	})

	// Test user registration
	user, err := service.RegisterUser(req)

	assert.NoError(t, err)
	assert.NotNil(t, user)
	assert.Equal(t, req.Email, user.Email)
	assert.Equal(t, req.Name, user.Name)
	assert.Equal(t, "email", user.AuthProvider)
	assert.True(t, user.IsActive)
	assert.NotEmpty(t, user.Password) // Should be hashed

	mockRepo.AssertExpectations(t)
}

func TestRegisterUser_UserExists(t *testing.T) {
	service, mockRepo := setupAuthService()

	req := &models.UserCreateRequest{
		Email:    "test@example.com",
		Password: "password123",
		Name:     "Test User",
	}

	// Mock that user already exists
	existingUser := &models.User{
		ID:    uuid.New(),
		Email: req.Email,
		Name:  "Existing User",
	}
	mockRepo.On("GetByEmail", req.Email).Return(existingUser, nil)

	// Test user registration with existing email
	user, err := service.RegisterUser(req)

	assert.Error(t, err)
	assert.Nil(t, user)
	assert.Contains(t, err.Error(), "user already exists")

	mockRepo.AssertExpectations(t)
} 