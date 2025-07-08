package models

import (
	"time"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TodoStatus string

const (
	TodoStatusPending    TodoStatus = "pending"
	TodoStatusInProgress TodoStatus = "in_progress" 
	TodoStatusCompleted  TodoStatus = "completed"
)

type Todo struct {
	ID          uuid.UUID      `json:"id" gorm:"type:uuid;primary_key;default:gen_random_uuid()"`
	Title       string         `json:"title" gorm:"not null" validate:"required,min=1,max=255"`
	Description string         `json:"description" gorm:"type:text"`
	Status      TodoStatus     `json:"status" gorm:"type:varchar(20);default:'pending'" validate:"required,oneof=pending in_progress completed"`
	Priority    int            `json:"priority" gorm:"default:0" validate:"min=0,max=5"`
	DueDate     *time.Time     `json:"due_date,omitempty"`
	UserID      uuid.UUID      `json:"user_id" gorm:"type:uuid;not null;index"`
	CreatedAt   time.Time      `json:"created_at"`
	UpdatedAt   time.Time      `json:"updated_at"`
	DeletedAt   gorm.DeletedAt `json:"-" gorm:"index"`

	// Relationships
	User User `json:"user,omitempty" gorm:"foreignKey:UserID;constraint:OnDelete:CASCADE"`
}

type TodoCreateRequest struct {
	Title       string     `json:"title" validate:"required,min=1,max=255"`
	Description string     `json:"description" validate:"max=1000"`
	Status      TodoStatus `json:"status" validate:"omitempty,oneof=pending in_progress completed"`
	Priority    int        `json:"priority" validate:"min=0,max=5"`
	DueDate     *time.Time `json:"due_date,omitempty"`
}

type TodoUpdateRequest struct {
	Title       string     `json:"title" validate:"omitempty,min=1,max=255"`
	Description string     `json:"description" validate:"max=1000"`
	Status      TodoStatus `json:"status" validate:"omitempty,oneof=pending in_progress completed"`
	Priority    int        `json:"priority" validate:"min=0,max=5"`
	DueDate     *time.Time `json:"due_date,omitempty"`
}

type TodoResponse struct {
	ID          uuid.UUID  `json:"id"`
	Title       string     `json:"title"`
	Description string     `json:"description"`
	Status      TodoStatus `json:"status"`
	Priority    int        `json:"priority"`
	DueDate     *time.Time `json:"due_date,omitempty"`
	UserID      uuid.UUID  `json:"user_id"`
	CreatedAt   time.Time  `json:"created_at"`
	UpdatedAt   time.Time  `json:"updated_at"`
}

type TodoWithUserResponse struct {
	TodoResponse
	User UserResponse `json:"user"`
}

func (t *Todo) ToResponse() TodoResponse {
	return TodoResponse{
		ID:          t.ID,
		Title:       t.Title,
		Description: t.Description,
		Status:      t.Status,
		Priority:    t.Priority,
		DueDate:     t.DueDate,
		UserID:      t.UserID,
		CreatedAt:   t.CreatedAt,
		UpdatedAt:   t.UpdatedAt,
	}
}

func (t *Todo) ToResponseWithUser() TodoWithUserResponse {
	return TodoWithUserResponse{
		TodoResponse: t.ToResponse(),
		User:         t.User.ToResponse(),
	}
} 