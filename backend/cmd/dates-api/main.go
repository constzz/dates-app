package main

import (
	"context"
	"fmt"
	"log/slog"
	"os"
	"os/signal"
	"syscall"
	"time"

	"my_project/backend/internal/config"
)

func main() {
	if err := run(); err != nil {
		slog.Error("dates-api failed", "error", err)
		os.Exit(1)
	}
}

func run() error {
	cfg, err := config.FromEnv()
	if err != nil {
		return fmt.Errorf("loading config: %w", err)
	}

	application, err := InitializeApp(cfg)
	if err != nil {
		return fmt.Errorf("initializing app: %w", err)
	}

	serverErr := make(chan error, 1)
	go func() {
		serverErr <- application.Run()
	}()

	signalCtx, stop := signal.NotifyContext(context.Background(), os.Interrupt, syscall.SIGTERM)
	defer stop()

	select {
	case <-signalCtx.Done():
		shutdownCtx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
		defer cancel()
		if err := application.Shutdown(shutdownCtx); err != nil {
			return fmt.Errorf("graceful shutdown: %w", err)
		}
		return nil
	case err := <-serverErr:
		if err != nil {
			return fmt.Errorf("server runtime: %w", err)
		}
		return nil
	}
}
