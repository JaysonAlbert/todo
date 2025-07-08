package service

import (
	"errors"
	"todo-backend/internal/models"
	"todo-backend/internal/repository"

	"github.com/google/uuid"
	"gorm.io/gorm"
)

type TodoService interface {
	Create(userID uuid.UUID, req *models.TodoCreateRequest) (*models.Todo, error)
	GetByID(id uuid.UUID) (*models.Todo, error)
	GetByUserID(userID uuid.UUID, page, limit int) ([]models.Todo, int64, error)
	Update(id uuid.UUID, userID uuid.UUID, req *models.TodoUpdateRequest) (*models.Todo, error)
	Delete(id uuid.UUID, userID uuid.UUID) error
	GetByStatus(userID uuid.UUID, status models.TodoStatus) ([]models.Todo, error)
}

type todoService struct {
	todoRepo repository.TodoRepository
}

func NewTodoService(todoRepo repository.TodoRepository) TodoService {
	return &todoService{
		todoRepo: todoRepo,
	}
}

func (s *todoService) Create(userID uuid.UUID, req *models.TodoCreateRequest) (*models.Todo, error) {
	todo := &models.Todo{
		Title:       req.Title,
		Description: req.Description,
		Status:      req.Status,
		Priority:    req.Priority,
		DueDate:     req.DueDate,
		UserID:      userID,
	}

	// Set default status if not provided
	if todo.Status == "" {
		todo.Status = models.TodoStatusPending
	}

	if err := s.todoRepo.Create(todo); err != nil {
		return nil, err
	}

	return todo, nil
}

func (s *todoService) GetByID(id uuid.UUID) (*models.Todo, error) {
	todo, err := s.todoRepo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("todo not found")
		}
		return nil, err
	}
	return todo, nil
}

func (s *todoService) GetByUserID(userID uuid.UUID, page, limit int) ([]models.Todo, int64, error) {
	if page < 1 {
		page = 1
	}
	if limit < 1 {
		limit = 10
	}

	offset := (page - 1) * limit
	return s.todoRepo.GetByUserID(userID, offset, limit)
}

func (s *todoService) Update(id uuid.UUID, userID uuid.UUID, req *models.TodoUpdateRequest) (*models.Todo, error) {
	todo, err := s.todoRepo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return nil, errors.New("todo not found")
		}
		return nil, err
	}

	// Check if the todo belongs to the user
	if todo.UserID != userID {
		return nil, errors.New("unauthorized to update this todo")
	}

	// Update fields if provided
	if req.Title != "" {
		todo.Title = req.Title
	}
	if req.Description != "" {
		todo.Description = req.Description
	}
	if req.Status != "" {
		todo.Status = req.Status
	}
	if req.Priority > 0 {
		todo.Priority = req.Priority
	}
	if req.DueDate != nil {
		todo.DueDate = req.DueDate
	}

	if err := s.todoRepo.Update(todo); err != nil {
		return nil, err
	}

	return todo, nil
}

func (s *todoService) Delete(id uuid.UUID, userID uuid.UUID) error {
	todo, err := s.todoRepo.GetByID(id)
	if err != nil {
		if errors.Is(err, gorm.ErrRecordNotFound) {
			return errors.New("todo not found")
		}
		return err
	}

	// Check if the todo belongs to the user
	if todo.UserID != userID {
		return errors.New("unauthorized to delete this todo")
	}

	return s.todoRepo.Delete(id)
}

func (s *todoService) GetByStatus(userID uuid.UUID, status models.TodoStatus) ([]models.Todo, error) {
	return s.todoRepo.GetByStatus(userID, status)
} 