//go:build wireinject

package main

import (
	"my_project/backend/internal/app"
	"my_project/backend/internal/auth"
	"my_project/backend/internal/config"
	"my_project/backend/internal/couples"
	"my_project/backend/internal/dates"
	"my_project/backend/internal/httpserver"

	"github.com/google/wire"
)

func InitializeApp(cfg config.Config) (*app.App, error) {
	wire.Build(
		auth.NewService,
		couples.NewService,
		dates.NewService,
		app.NewLogger,
		httpserver.New,
		app.New,
	)
	return nil, nil
}
