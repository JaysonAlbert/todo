package handlers

import (
	"errors"
	"net/http"
	"strconv"
	"todo-backend/internal/models"
	"todo-backend/internal/service"
	"todo-backend/pkg/utils"

	"github.com/gin-gonic/gin"
	"github.com/google/uuid"
)

type TodoHandler struct {
	todoService service.TodoService
}

func NewTodoHandler(todoService service.TodoService) *TodoHandler {
	return &TodoHandler{
		todoService: todoService,
	}
}

// CreateTodo godoc
// @Summary Create a new todo
// @Description Create a new todo for the authenticated user
// @Tags todos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param todo body models.TodoCreateRequest true "Todo data"
// @Success 201 {object} utils.Response{data=models.TodoResponse}
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 422 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/todos [post]
func (h *TodoHandler) CreateTodo(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Unauthorized", err.Error())
		return
	}

	var req models.TodoCreateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	todo, err := h.todoService.Create(userID, &req)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to create todo", err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusCreated, "Todo created successfully", todo.ToResponse())
}

// GetTodos godoc
// @Summary Get todos for user
// @Description Get paginated list of todos for the authenticated user
// @Tags todos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param page query int false "Page number" default(1)
// @Param limit query int false "Number of items per page" default(10)
// @Param status query string false "Filter by status" Enums(pending,in_progress,completed)
// @Success 200 {object} utils.PaginatedResponse{data=[]models.TodoResponse}
// @Failure 401 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/todos [get]
func (h *TodoHandler) GetTodos(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Unauthorized", err.Error())
		return
	}

	// Parse pagination parameters
	page, _ := strconv.Atoi(c.DefaultQuery("page", "1"))
	limit, _ := strconv.Atoi(c.DefaultQuery("limit", "10"))
	status := c.Query("status")

	if status != "" {
		// Filter by status
		todos, err := h.todoService.GetByStatus(userID, models.TodoStatus(status))
		if err != nil {
			utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to get todos", err.Error())
			return
		}

		var responses []models.TodoResponse
		for _, todo := range todos {
			responses = append(responses, todo.ToResponse())
		}

		utils.SuccessResponse(c, http.StatusOK, "Todos retrieved successfully", responses)
		return
	}

	// Get paginated todos
	todos, total, err := h.todoService.GetByUserID(userID, page, limit)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to get todos", err.Error())
		return
	}

	var responses []models.TodoResponse
	for _, todo := range todos {
		responses = append(responses, todo.ToResponse())
	}

	pagination := utils.CalculatePagination(page, limit, int(total))
	utils.PaginatedSuccessResponse(c, http.StatusOK, "Todos retrieved successfully", responses, pagination)
}

// GetTodo godoc
// @Summary Get a todo by ID
// @Description Get a specific todo by its ID
// @Tags todos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Todo ID"
// @Success 200 {object} utils.Response{data=models.TodoResponse}
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 404 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/todos/{id} [get]
func (h *TodoHandler) GetTodo(c *gin.Context) {
	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid todo ID", err.Error())
		return
	}

	todo, err := h.todoService.GetByID(id)
	if err != nil {
		if err.Error() == "todo not found" {
			utils.SendErrorResponse(c, http.StatusNotFound, "Todo not found", err.Error())
			return
		}
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to get todo", err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Todo retrieved successfully", todo.ToResponse())
}

// UpdateTodo godoc
// @Summary Update a todo
// @Description Update a todo by its ID
// @Tags todos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Todo ID"
// @Param todo body models.TodoUpdateRequest true "Todo data"
// @Success 200 {object} utils.Response{data=models.TodoResponse}
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 404 {object} utils.ErrorResponse
// @Failure 422 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/todos/{id} [put]
func (h *TodoHandler) UpdateTodo(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Unauthorized", err.Error())
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid todo ID", err.Error())
		return
	}

	var req models.TodoUpdateRequest
	if err := c.ShouldBindJSON(&req); err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid request body", err.Error())
		return
	}

	if err := utils.ValidateStruct(&req); err != nil {
		utils.ValidationErrorResponse(c, err)
		return
	}

	todo, err := h.todoService.Update(id, userID, &req)
	if err != nil {
		if err.Error() == "todo not found" {
			utils.SendErrorResponse(c, http.StatusNotFound, "Todo not found", err.Error())
			return
		}
		if err.Error() == "unauthorized to update this todo" {
			utils.SendErrorResponse(c, http.StatusForbidden, "Forbidden", err.Error())
			return
		}
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to update todo", err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Todo updated successfully", todo.ToResponse())
}

// DeleteTodo godoc
// @Summary Delete a todo
// @Description Delete a todo by its ID
// @Tags todos
// @Accept json
// @Produce json
// @Security BearerAuth
// @Param id path string true "Todo ID"
// @Success 200 {object} utils.Response
// @Failure 400 {object} utils.ErrorResponse
// @Failure 401 {object} utils.ErrorResponse
// @Failure 404 {object} utils.ErrorResponse
// @Failure 500 {object} utils.ErrorResponse
// @Router /api/v1/todos/{id} [delete]
func (h *TodoHandler) DeleteTodo(c *gin.Context) {
	userID, err := getUserIDFromContext(c)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusUnauthorized, "Unauthorized", err.Error())
		return
	}

	idStr := c.Param("id")
	id, err := uuid.Parse(idStr)
	if err != nil {
		utils.SendErrorResponse(c, http.StatusBadRequest, "Invalid todo ID", err.Error())
		return
	}

	err = h.todoService.Delete(id, userID)
	if err != nil {
		if err.Error() == "todo not found" {
			utils.SendErrorResponse(c, http.StatusNotFound, "Todo not found", err.Error())
			return
		}
		if err.Error() == "unauthorized to delete this todo" {
			utils.SendErrorResponse(c, http.StatusForbidden, "Forbidden", err.Error())
			return
		}
		utils.SendErrorResponse(c, http.StatusInternalServerError, "Failed to delete todo", err.Error())
		return
	}

	utils.SuccessResponse(c, http.StatusOK, "Todo deleted successfully", nil)
}

func getUserIDFromContext(c *gin.Context) (uuid.UUID, error) {
	userIDInterface, exists := c.Get("userID")
	if !exists {
		return uuid.Nil, errors.New("user ID not found in context")
	}

	userID, ok := userIDInterface.(uuid.UUID)
	if !ok {
		return uuid.Nil, errors.New("invalid user ID format")
	}

	return userID, nil
} 