package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type User struct {
	ID        uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Email     string         `json:"email" gorm:"uniqueIndex;not null" validate:"required,email"`
	Password  string         `json:"-" gorm:"" validate:"omitempty,min=6"` // Make password optional for OAuth users
	Name      string         `json:"name" gorm:"not null" validate:"required"`
	IsActive  bool           `json:"is_active" gorm:"default:true"`
	CreatedAt time.Time      `json:"created_at"`
	UpdatedAt time.Time      `json:"updated_at"`
	DeletedAt gorm.DeletedAt `json:"-" gorm:"index"`

	// Apple OAuth fields
	AppleID        string `json:"apple_id,omitempty" gorm:"uniqueIndex"`
	IsPrivateEmail bool   `json:"is_private_email" gorm:"default:false"`
	AuthProvider   string `json:"auth_provider" gorm:"default:'email'"` // 'email', 'apple'

	// Relationships
	Todos []Todo `json:"todos,omitempty" gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
}

type UserCreateRequest struct {
	Email    string `json:"email" validate:"required,email"`
	Password string `json:"password" validate:"required,min=6"`
	Name     string `json:"name" validate:"required"`
}

type UserUpdateRequest struct {
	Email string `json:"email" validate:"omitempty,email"`
	Name  string `json:"name" validate:"omitempty"`
}

type UserResponse struct {
	ID             uuid.UUID `json:"id"`
	Email          string    `json:"email"`
	Name           string    `json:"name"`
	IsActive       bool      `json:"is_active"`
	IsPrivateEmail bool      `json:"is_private_email"`
	AuthProvider   string    `json:"auth_provider"`
	CreatedAt      time.Time `json:"created_at"`
	UpdatedAt      time.Time `json:"updated_at"`
}

func (u *User) ToResponse() UserResponse {
	return UserResponse{
		ID:             u.ID,
		Email:          u.Email,
		Name:           u.Name,
		IsActive:       u.IsActive,
		IsPrivateEmail: u.IsPrivateEmail,
		AuthProvider:   u.AuthProvider,
		CreatedAt:      u.CreatedAt,
		UpdatedAt:      u.UpdatedAt,
	}
} 