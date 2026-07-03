# Dates App 💕

A couple's date planning app with AI-powered suggestions, pairing features, and calendar integration.

**Repository**: https://github.com/constzz/dates-app  
**Railway**: https://railway.com/project/008623f9-fab9-4dbe-befe-6ba07599e752

## Stack

- **Backend**: Go 1.26, PostgreSQL, JWT auth
- **Frontend**: Valdi (iOS), Swift  
- **Build**: Bazel
- **Deployment**: Railway + GitHub Actions

## Quick Start

All commands requires `valdi` to be available on PATH.

Get auto completion in VSCode
```sh
valdi projectsync
```

Build and install iOS:
```sh
valdi install ios
```

Build and install Android:
```sh
valdi install android
```

Build and install MacOS:
```sh
valdi install macos
```

Start hot reloader:
```sh
valdi hotreload
```

## Dates MVP foundation

This repo now includes a Go backend bootstrap under `backend/` for the Dates MVP plan:

- flat service layout
- `google/wire` dependency wiring
- structured JSON logs via `log/slog`
- request ID middleware (`X-Request-ID`)
- health and readiness endpoints:
  - `GET /healthz`
  - `GET /readyz`

The Valdi module under `modules/test_valdi/` now renders the dates home screen and serves as the front-end shell for the MVP.

### Backend quick start

```sh
cd backend
cp .env.example .env
go run ./cmd/dates-api
```

Then verify:

```sh
curl -i http://localhost:8080/healthz
curl -i http://localhost:8080/readyz
```

### Backend checks

```sh
cd backend
go test ./...
```

### Auth schema migration (Iteration 1)

`backend/migrations/000001_auth_schema.*.sql` defines:
- `users` table (credentials + account lockout fields)
- `auth_refresh_tokens` table (hashed token storage + revocation chain)

Apply migration:

```sh
cd backend
export DATABASE_URL="postgres://dates_user:dates_pass@localhost:5432/dates_mvp?sslmode=disable"
make migrate-up
```
