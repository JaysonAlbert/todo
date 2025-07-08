package repository

import (
	"todo-backend/internal/models"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TodoRepository interface {
	Create(todo *models.Todo) error
	GetByID(id uuid.UUID) (*models.Todo, error)
	GetByUserID(userID uuid.UUID, offset, limit int) ([]models.Todo, int64, error)
	Update(todo *models.Todo) error
	Delete(id uuid.UUID) error
	GetByStatus(userID uuid.UUID, status models.TodoStatus) ([]models.Todo, error)
}

type todoRepository struct {
	db *gorm.DB
}

func NewTodoRepository(db *gorm.DB) TodoRepository {
	return &todoRepository{db: db}
}

func (r *todoRepository) Create(todo *models.Todo) error {
	return r.db.Create(todo).Error
}

func (r *todoRepository) GetByID(id uuid.UUID) (*models.Todo, error) {
	var todo models.Todo
	err := r.db.Preload("User").First(&todo, "id = ?", id).Error
	if err != nil {
		return nil, err
	}
	return &todo, nil
}

func (r *todoRepository) GetByUserID(userID uuid.UUID, offset, limit int) ([]models.Todo, int64, error) {
	var todos []models.Todo
	var total int64

	// Count total records
	if err := r.db.Model(&models.Todo{}).Where("user_id = ?", userID).Count(&total).Error; err != nil {
		return nil, 0, err
	}

	// Get paginated records
	err := r.db.Where("user_id = ?", userID).
		Order("created_at DESC").
		Offset(offset).
		Limit(limit).
		Find(&todos).Error

	return todos, total, err
}

func (r *todoRepository) Update(todo *models.Todo) error {
	return r.db.Save(todo).Error
}

func (r *todoRepository) Delete(id uuid.UUID) error {
	return r.db.Delete(&models.Todo{}, "id = ?", id).Error
}

func (r *todoRepository) GetByStatus(userID uuid.UUID, status models.TodoStatus) ([]models.Todo, error) {
	var todos []models.Todo
	err := r.db.Where("user_id = ? AND status = ?", userID, status).
		Order("created_at DESC").
		Find(&todos).Error
	return todos, err
} 