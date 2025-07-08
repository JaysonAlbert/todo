# Todo Backend API

A modern REST API backend built with **Gin** and **GORM** for managing todo items. This backend supports user authentication, CRUD operations, and provides comprehensive API documentation.

## 🚀 Features

- **Clean Architecture**: Separation of concerns with controllers, services, and repositories
- **Gin Framework**: Fast HTTP web framework written in Go
- **GORM**: Feature-rich ORM for database operations
- **PostgreSQL**: Robust relational database
- **JWT Authentication**: Secure token-based authentication
- **Swagger Documentation**: Auto-generated API documentation
- **Docker Support**: Containerized development and deployment
- **Input Validation**: Request validation with detailed error messages
- **Pagination**: Efficient data pagination for large datasets
- **CORS Support**: Cross-origin resource sharing enabled
- **Structured Logging**: JSON structured logging with Zerolog
- **Graceful Shutdown**: Proper application lifecycle management

## 📁 Project Structure

```
backend/
├── cmd/
│   └── server/             # Application entry point
├── internal/
│   ├── config/            # Configuration management
│   ├── database/          # Database connection and migrations
│   ├── handlers/          # HTTP request handlers
│   ├── middleware/        # HTTP middleware (auth, CORS, etc.)
│   ├── models/           # Data models and DTOs
│   ├── repository/       # Data access layer
│   ├── router/           # Route definitions
│   └── service/          # Business logic layer
├── pkg/
│   ├── logger/           # Logging utilities
│   └── utils/            # Common utilities
├── docs/                 # Swagger documentation
├── Dockerfile           # Docker configuration
├── docker-compose.yml   # Multi-container setup
├── Makefile            # Development commands
└── go.mod              # Go module dependencies
```

## 🛠️ Prerequisites

- **Go 1.21+**
- **PostgreSQL 12+**
- **Docker & Docker Compose** (optional)
- **Make** (optional, for using Makefile commands)

## ⚡ Quick Start

### Option 1: Using Docker Compose (Recommended)

1. **Clone and navigate to the backend directory**:
   ```bash
   cd backend
   ```

2. **Start all services**:
   ```bash
   make docker-run
   # or
   docker-compose up -d
   ```

3. **Verify the API is running**:
   ```bash
   curl http://localhost:8080/health
   ```

4. **Access Swagger documentation**:
   Open http://localhost:8080/swagger/index.html

### Option 2: Local Development

1. **Install dependencies**:
   ```bash
   make deps
   ```

2. **Set up PostgreSQL database**:
   ```bash
   # Start PostgreSQL (using your preferred method)
   # Create database
   createdb todo_db
   ```

3. **Configure environment variables**:
   ```bash
   # Copy the example file and edit it
   cp .env.example .env
   # Edit .env with your database credentials
   ```

4. **Install development tools**:
   ```bash
   make install-tools
   ```

5. **Generate Swagger documentation**:
   ```bash
   make swagger
   ```

6. **Run the application**:
   ```bash
   make run
   # or with hot reload
   make dev-watch
   ```

## 🔧 Configuration

Create a `.env` file in the backend directory:

```env
# Application Configuration
ENVIRONMENT=development
PORT=8080
LOG_LEVEL=info

# Database Configuration
DATABASE_URL=postgres://postgres:password@localhost:5432/todo_db?sslmode=disable

# JWT Configuration
JWT_SECRET=your-secret-key-change-this-in-production
```

## 📚 API Documentation

### Base URL
```
http://localhost:8080/api/v1
```

### Authentication
The API uses JWT (JSON Web Tokens) for authentication. Include the token in the Authorization header:
```
Authorization: Bearer <your-jwt-token>
```

### Endpoints

#### Health Check
```http
GET /health
```

#### Todos
```http
POST   /api/v1/todos      # Create a new todo
GET    /api/v1/todos      # Get todos (with pagination and filtering)
GET    /api/v1/todos/:id  # Get a specific todo
PUT    /api/v1/todos/:id  # Update a todo
DELETE /api/v1/todos/:id  # Delete a todo
```

#### Query Parameters for GET /todos
- `page`: Page number (default: 1)
- `limit`: Items per page (default: 10)
- `status`: Filter by status (pending, in_progress, completed)

### Example Requests

#### Create Todo
```bash
curl -X POST http://localhost:8080/api/v1/todos \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN" \
  -d '{
    "title": "Learn Go",
    "description": "Study Go programming language",
    "status": "pending",
    "priority": 3
  }'
```

#### Get Todos with Pagination
```bash
curl "http://localhost:8080/api/v1/todos?page=1&limit=10&status=pending" \
  -H "Authorization: Bearer YOUR_JWT_TOKEN"
```

## 🧪 Testing

```bash
# Run all tests
make test

# Run tests with coverage
make test-coverage

# View coverage report
open coverage.html
```

## 🚀 Development Commands

```bash
# Show all available commands
make help

# Development workflow
make dev                 # Full development setup
make dev-watch          # Run with hot reload

# Building
make build              # Build for development
make prod-build         # Build for production

# Docker operations
make docker-build       # Build Docker image
make docker-run         # Start with Docker Compose
make docker-stop        # Stop Docker containers
make docker-logs        # View logs

# Code quality
make fmt               # Format code
make lint              # Run linter

# Documentation
make swagger           # Generate Swagger docs
```

## 🐳 Docker Services

When using Docker Compose, the following services are available:

- **API Server**: http://localhost:8080
- **PostgreSQL**: localhost:5432
- **pgAdmin**: http://localhost:5050 (admin@admin.com / admin)
- **Swagger UI**: http://localhost:8080/swagger/index.html

## 🔒 Security Features

- **JWT Authentication**: Secure token-based authentication
- **Password Hashing**: Bcrypt for password security
- **Input Validation**: Comprehensive request validation
- **CORS Protection**: Configurable cross-origin policies
- **SQL Injection Protection**: GORM provides built-in protection

## 📊 Logging

The application uses structured logging with Zerolog:

- **Development**: Pretty-printed console output
- **Production**: JSON formatted logs
- **Log Levels**: Debug, Info, Warn, Error, Fatal

## 🚢 Deployment

### Production Build
```bash
make prod-build
```

### Environment Variables for Production
Ensure these are set in your production environment:
- `ENVIRONMENT=production`
- `DATABASE_URL` (your production database)
- `JWT_SECRET` (strong secret key)
- `PORT` (if different from 8080)

## 🤝 Contributing

1. Follow the existing code structure
2. Add tests for new features
3. Update documentation
4. Ensure all tests pass: `make test`
5. Format code: `make fmt`
6. Run linter: `make lint`

## 📝 License

This project is licensed under the MIT License.

## 📞 Support

For questions or issues, please open an issue in the repository. 