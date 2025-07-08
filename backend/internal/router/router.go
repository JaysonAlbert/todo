package router

import (
	"todo-backend/internal/config"
	"todo-backend/internal/handlers"
	"todo-backend/internal/middleware"
	"todo-backend/internal/repository"
	"todo-backend/internal/service"

	"github.com/gin-contrib/cors"
	"github.com/gin-gonic/gin"
	swaggerFiles "github.com/swaggo/files"
	ginSwagger "github.com/swaggo/gin-swagger"
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
	userRepo := repository.NewUserRepository(db)

	// Initialize services
	todoService := service.NewTodoService(todoRepo)
	authService, err := service.NewAuthService(userRepo, cfg)
	if err != nil {
		panic("Failed to initialize auth service: " + err.Error())
	}

	// Initialize handlers
	todoHandler := handlers.NewTodoHandler(todoService)
	authHandler := handlers.NewAuthHandler(authService)

	// API v1 routes
	v1 := r.Group("/api/v1")
	{
		// Public routes (no authentication required)
		auth := v1.Group("/auth")
		{
			// Apple ID OAuth routes
			auth.GET("/apple/login", authHandler.InitiateAppleLogin)
			auth.POST("/apple/callback", authHandler.HandleAppleCallback)
			auth.GET("/apple/callback", authHandler.HandleAppleCallbackURL)
			
			// Token management
			auth.POST("/token/refresh", authHandler.RefreshToken)
			
			// Traditional auth routes (for future use)
			auth.POST("/register", authHandler.RegisterUser)
			auth.POST("/login", authHandler.LoginUser)
		}
		
		// Protected routes (authentication required)
		protected := v1.Group("")
		protected.Use(middleware.AuthMiddleware(cfg))
		{
			// Auth-related protected routes
			auth := protected.Group("/auth")
			{
				auth.GET("/user/profile", authHandler.GetUserProfile)
			}
			
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