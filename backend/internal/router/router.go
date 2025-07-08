package router

import (
	"todo-backend/internal/config"
	"todo-backend/internal/handlers"
	"todo-backend/internal/middleware"
	"todo-backend/internal/repository"
	"todo-backend/internal/service"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	"github.com/swaggo/gin-swagger"
	"github.com/swaggo/files"
	"gorm.io/gorm"
)

func SetupRouter(db *gorm.DB, cfg *config.Config) *gin.Engine {
	// Create Gin router
	r := gin.Default()

	// CORS middleware
	r.Use(cors.New(cors.Config{
		AllowOrigins:     []string{"*"}, // Configure for production
		AllowMethods:     []string{"GET", "POST", "PUT", "DELETE", "OPTIONS"},
		AllowHeaders:     []string{"*"},
		ExposeHeaders:    []string{"Content-Length"},
		AllowCredentials: true,
	}))

	// Health check endpoint
	r.GET("/health", func(c *gin.Context) {
		c.JSON(200, gin.H{
			"status":  "ok",
			"message": "Todo API is running",
		})
	})

	// Swagger endpoint
	r.GET("/swagger/*any", ginSwagger.WrapHandler(swaggerFiles.Handler))

	// Initialize repositories
	todoRepo := repository.NewTodoRepository(db)
	// userRepo := repository.NewUserRepository(db) // TODO: Use when implementing auth endpoints

	// Initialize services
	todoService := service.NewTodoService(todoRepo)

	// Initialize handlers
	todoHandler := handlers.NewTodoHandler(todoService)

	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		// Public routes (no authentication required)
		// Add auth routes here when implemented
		
		// Protected routes (authentication required)
		protected := v1.Group("")
		protected.Use(middleware.AuthMiddleware(cfg.JWTSecret))
		{
			// Todo routes
			todos := protected.Group("/todos")
			{
				todos.POST("", todoHandler.CreateTodo)
				todos.GET("", todoHandler.GetTodos)
				todos.GET("/:id", todoHandler.GetTodo)
				todos.PUT("/:id", todoHandler.UpdateTodo)
				todos.DELETE("/:id", todoHandler.DeleteTodo)
			}
		}
	}

	return r
} 