package models

import (
	"time"

	"github.com/golang-jwt/jwt/v5"
	"github.com/google/uuid"
)

// Apple OAuth Login Request
type AppleLoginRequest struct {
	Code         string `json:"code" validate:"required"`
	State        string `json:"state,omitempty"`
	RedirectURI  string `json:"redirect_uri,omitempty"`
}

// Apple OAuth Callback Request (from Apple)
type AppleCallbackRequest struct {
	Code  string `json:"code" validate:"required"`
	State string `json:"state,omitempty"`
	User  string `json:"user,omitempty"` // JSON string containing user info (only on first login)
}

// Apple User Info (from Apple's identity token)
type AppleUserInfo struct {
	Sub            string `json:"sub"`             // Apple User ID
	Email          string `json:"email,omitempty"`
	EmailVerified  bool   `json:"email_verified,omitempty"`
	IsPrivateEmail bool   `json:"is_private_email,omitempty"`
	Name           *AppleUserName `json:"name,omitempty"`
}

// Apple User Name structure
type AppleUserName struct {
	FirstName string `json:"firstName,omitempty"`
	LastName  string `json:"lastName,omitempty"`
}

// Login Response (what we return to client)
type LoginResponse struct {
	AccessToken  string      `json:"access_token"`
	RefreshToken string      `json:"refresh_token"`
	TokenType    string      `json:"token_type"`
	ExpiresIn    int         `json:"expires_in"`
	User         UserResponse `json:"user"`
}

// Token Refresh Request
type TokenRefreshRequest struct {
	RefreshToken string `json:"refresh_token" validate:"required"`
}

// JWTClaims represents the JWT token claims
type JWTClaims struct {
	UserID    uuid.UUID `json:"user_id"`
	Email     string    `json:"email"`
	AppleID   string    `json:"apple_id,omitempty"`
	TokenType string    `json:"token_type"` // "access" or "refresh"
	IssuedAt  time.Time `json:"iat"`
	ExpiresAt time.Time `json:"exp"`
}

// GetExpirationTime implements jwt.Claims
func (c JWTClaims) GetExpirationTime() (*jwt.NumericDate, error) {
	return &jwt.NumericDate{Time: c.ExpiresAt}, nil
}

// GetIssuedAt implements jwt.Claims  
func (c JWTClaims) GetIssuedAt() (*jwt.NumericDate, error) {
	return &jwt.NumericDate{Time: c.IssuedAt}, nil
}

// GetNotBefore implements jwt.Claims
func (c JWTClaims) GetNotBefore() (*jwt.NumericDate, error) {
	return nil, nil
}

// GetIssuer implements jwt.Claims
func (c JWTClaims) GetIssuer() (string, error) {
	return "", nil
}

// GetSubject implements jwt.Claims
func (c JWTClaims) GetSubject() (string, error) {
	return c.UserID.String(), nil
}

// GetAudience implements jwt.Claims
func (c JWTClaims) GetAudience() (jwt.ClaimStrings, error) {
	return nil, nil
}

// Apple OAuth Configuration
type AppleOAuthConfig struct {
	TeamID      string
	ClientID    string
	KeyID       string
	KeyPath     string
	RedirectURL string
}

// OAuth State for CSRF protection
type OAuthState struct {
	State     string    `json:"state"`
	CreatedAt time.Time `json:"created_at"`
	ExpiresAt time.Time `json:"expires_at"`
}

// Error response for authentication failures
type AuthErrorResponse struct {
	Error            string `json:"error"`
	ErrorDescription string `json:"error_description,omitempty"`
	ErrorURI         string `json:"error_uri,omitempty"`
}

// Apple OAuth Error Response (from Apple's API)
type AppleOAuthError struct {
	Error string `json:"error"`
}

// User profile update request (after Apple login)
type UserProfileUpdateRequest struct {
	Name string `json:"name" validate:"omitempty,min=1,max=255"`
} 