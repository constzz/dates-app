GO ?= go

.PHONY: run test wire tidy migrate-up migrate-down

run:
	$(GO) run ./cmd/dates-api

test:
	$(GO) test ./...

wire:
	$(GO) run github.com/google/wire/cmd/wire ./cmd/dates-api

tidy:
	$(GO) mod tidy

migrate-up:
	psql "$(DATABASE_URL)" -f ./migrations/000001_auth_schema.up.sql

migrate-down:
	psql "$(DATABASE_URL)" -f ./migrations/000001_auth_schema.down.sql
