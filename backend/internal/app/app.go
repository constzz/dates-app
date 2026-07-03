package app

import (
	"context"
	"fmt"
	"log/slog"
	"os"

	"my_project/backend/internal/config"
	"my_project/backend/internal/httpserver"
)

type App struct {
	server *httpserver.Server
	logger *slog.Logger
}

func New(server *httpserver.Server, logger *slog.Logger) *App {
	return &App{
		server: server,
		logger: logger,
	}
}

func (a *App) Run() error {
	if err := a.server.Start(); err != nil {
		return fmt.Errorf("running app: %w", err)
	}
	return nil
}

func (a *App) Shutdown(ctx context.Context) error {
	if err := a.server.Shutdown(ctx); err != nil {
		return fmt.Errorf("shutting down app: %w", err)
	}
	return nil
}

func NewLogger(cfg config.Config) *slog.Logger {
	handler := slog.NewJSONHandler(os.Stdout, &slog.HandlerOptions{
		Level: cfg.LogLevel,
	})

	logger := slog.New(handler).With(
		"service", "dates-api",
		"env", cfg.Env,
	)
	slog.SetDefault(logger)
	return logger
}
