.PHONY: help build run test clean docker-build docker-run docker-stop deps swagger

# Variables
BINARY_NAME=server
DOCKER_IMAGE=todo-api
MAIN_PATH=./cmd/server

# Help command
help: ## Show this help message
	@echo 'Usage: make [target]'
	@echo ''
	@echo 'Available targets:'
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z_-]+:.*?## / {printf "  %-15s %s\n", $$1, $$2}' $(MAKEFILE_LIST)

# Development commands
deps: ## Download dependencies
	go mod download
	go mod tidy

build: ## Build the application
	go build -o bin/$(BINARY_NAME) $(MAIN_PATH)

run: ## Run the application
	go run $(MAIN_PATH)

test: ## Run tests
	go test -v ./...

test-coverage: ## Run tests with coverage
	go test -v -coverprofile=coverage.out ./...
	go tool cover -html=coverage.out -o coverage.html

clean: ## Clean build artifacts
	rm -rf bin/
	rm -f coverage.out coverage.html

# Swagger commands
swagger: ## Generate Swagger documentation
	swag init -g cmd/server/main.go

swagger-install: ## Install Swagger CLI
	go install github.com/swaggo/swag/cmd/swag@latest

# Docker commands
docker-build: ## Build Docker image
	docker build -t $(DOCKER_IMAGE) .

docker-run: ## Run with Docker Compose
	docker-compose up -d

docker-stop: ## Stop Docker containers
	docker-compose down

docker-logs: ## View Docker logs
	docker-compose logs -f api

docker-clean: ## Clean Docker containers and images
	docker-compose down -v
	docker rmi $(DOCKER_IMAGE) 2>/dev/null || true

# Database commands
db-create: ## Create database (requires PostgreSQL running)
	createdb todo_db 2>/dev/null || true

db-drop: ## Drop database
	dropdb todo_db 2>/dev/null || true

db-reset: db-drop db-create ## Reset database

# Development workflow
dev: deps swagger run ## Full development setup

# Production build
prod-build: ## Build for production
	CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -o bin/$(BINARY_NAME) $(MAIN_PATH)

# Linting and formatting
fmt: ## Format code
	go fmt ./...

lint: ## Run linter
	golangci-lint run

# Hot reload (requires air: go install github.com/cosmtrek/air@latest)
dev-watch: ## Run with hot reload
	air

install-tools: swagger-install ## Install development tools
	go install github.com/cosmtrek/air@latest
	go install github.com/golangci-lint/golangci-lint/cmd/golangci-lint@latest 