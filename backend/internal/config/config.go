package config

import (
	"fmt"
	"os"

	"github.com/joho/godotenv"
	"github.com/spf13/viper"
)

type Config struct {
	Environment string `mapstructure:"ENVIRONMENT"`
	Port        string `mapstructure:"PORT"`
	DatabaseURL string `mapstructure:"DATABASE_URL"`
	JWTSecret   string `mapstructure:"JWT_SECRET"`
	LogLevel    string `mapstructure:"LOG_LEVEL"`
	
	// Apple OAuth Configuration
	AppleTeamID     string `mapstructure:"APPLE_TEAM_ID"`
	AppleClientID   string `mapstructure:"APPLE_CLIENT_ID"`
	AppleKeyID      string `mapstructure:"APPLE_KEY_ID"`
	AppleKeyPath    string `mapstructure:"APPLE_KEY_PATH"`
	AppleRedirectURL string `mapstructure:"APPLE_REDIRECT_URL"`
}

func Load() (*Config, error) {
	// Load .env file if it exists
	if err := godotenv.Load(); err != nil {
		// Not a fatal error, .env file might not exist in production
	}

	// Set default values
	viper.SetDefault("ENVIRONMENT", "development")
	viper.SetDefault("PORT", "8080")
	viper.SetDefault("LOG_LEVEL", "info")
	viper.SetDefault("JWT_SECRET", "your-secret-key-change-this-in-production")
	
	// Apple OAuth defaults (empty - must be configured in production)
	viper.SetDefault("APPLE_TEAM_ID", "")
	viper.SetDefault("APPLE_CLIENT_ID", "")
	viper.SetDefault("APPLE_KEY_ID", "")
	viper.SetDefault("APPLE_KEY_PATH", "")
	viper.SetDefault("APPLE_REDIRECT_URL", "http://localhost:8080/api/v1/auth/apple/callback")

	// Bind environment variables
	viper.AutomaticEnv()

	var config Config
	if err := viper.Unmarshal(&config); err != nil {
		return nil, err
	}

	// Explicitly check for DATABASE_URL environment variable
	if databaseURL := os.Getenv("DATABASE_URL"); databaseURL != "" {
		config.DatabaseURL = databaseURL
		fmt.Printf("Using DATABASE_URL from environment: %s\n", databaseURL)
	} else if config.DatabaseURL == "" {
		config.DatabaseURL = getDefaultDatabaseURL()
		fmt.Printf("Using default DATABASE_URL: %s\n", config.DatabaseURL)
	}

	fmt.Printf("Config: %+v\n", config)

	return &config, nil
}

func getDefaultDatabaseURL() string {
	// Default database URL for development
	host := getEnvOrDefault("DB_HOST", "localhost")
	port := getEnvOrDefault("DB_PORT", "5432")
	user := getEnvOrDefault("DB_USER", "postgres")
	password := getEnvOrDefault("DB_PASSWORD", "password")
	dbname := getEnvOrDefault("DB_NAME", "todo_db")
	sslmode := getEnvOrDefault("DB_SSLMODE", "disable")

	return "postgres://" + user + ":" + password + "@" + host + ":" + port + "/" + dbname + "?sslmode=" + sslmode
}

func getEnvOrDefault(key, defaultValue string) string {
	if value := os.Getenv(key); value != "" {
		return value
	}
	return defaultValue
} 