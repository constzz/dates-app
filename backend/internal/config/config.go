package config

import (
	"fmt"
	"log/slog"
	"os"
	"strings"
)

type Config struct {
	Env      string
	HTTPAddr string
	LogLevel slog.Level
}

func FromEnv() (Config, error) {
	// Railway uses PORT env var, fallback to HTTP_ADDR for local dev
	port := getEnv("PORT", "")
	if port == "" {
		port = getEnv("HTTP_ADDR", ":8080")
	}
	if !strings.HasPrefix(port, ":") && port != "" {
		port = ":" + port
	}

	cfg := Config{
		Env:      getEnv("APP_ENV", "dev"),
		HTTPAddr: port,
		LogLevel: parseLogLevel(getEnv("LOG_LEVEL", "info")),
	}

	if strings.TrimSpace(cfg.HTTPAddr) == "" {
		return Config{}, fmt.Errorf("PORT or HTTP_ADDR must not be empty")
	}

	return cfg, nil
}

func getEnv(key, fallback string) string {
	value := strings.TrimSpace(os.Getenv(key))
	if value == "" {
		return fallback
	}
	return value
}

func parseLogLevel(value string) slog.Level {
	switch strings.ToLower(strings.TrimSpace(value)) {
	case "debug":
		return slog.LevelDebug
	case "warn", "warning":
		return slog.LevelWarn
	case "error":
		return slog.LevelError
	default:
		return slog.LevelInfo
	}
}
