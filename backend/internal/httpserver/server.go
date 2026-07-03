package httpserver

import (
	"bytes"
	"context"
	"encoding/json"
	"fmt"
	"log/slog"
	"net/http"
	"sync/atomic"
	"time"

	"my_project/backend/internal/auth"
	"my_project/backend/internal/config"
	"my_project/backend/internal/couples"
	"my_project/backend/internal/dates"
)

type Server struct {
	httpServer *http.Server
	logger     *slog.Logger
	auth       *auth.Service
	couples    *couples.Service
	dates      *dates.Service
	ready      atomic.Bool
	startedAt  time.Time
}

func New(logger *slog.Logger, cfg config.Config, authService *auth.Service, couplesService *couples.Service, datesService *dates.Service) *Server {
	srv := &Server{
		logger:    logger.With("component", "http_server"),
		auth:      authService,
		couples:   couplesService,
		dates:     datesService,
		startedAt: time.Now().UTC(),
	}

	mux := http.NewServeMux()
	mux.HandleFunc("GET /healthz", srv.handleHealth)
	mux.HandleFunc("GET /readyz", srv.handleReady)
	mux.HandleFunc("POST /api/auth/register", srv.handleRegister)
	mux.HandleFunc("POST /api/auth/login", srv.handleLogin)
	mux.HandleFunc("POST /api/auth/refresh", srv.handleRefresh)
	mux.HandleFunc("POST /api/auth/logout", srv.handleLogout)
	mux.HandleFunc("GET /api/me", srv.handleMe)

	// Couple endpoints (authenticated)
	mux.HandleFunc("POST /api/couples/invite", srv.authMiddleware(srv.handleCreateInvitation))
	mux.HandleFunc("POST /api/couples/accept", srv.authMiddleware(srv.handleAcceptInvitation))
	mux.HandleFunc("GET /api/couples/me", srv.authMiddleware(srv.handleGetMyCouple))

	// Date endpoints (authenticated)
	mux.HandleFunc("GET /api/dates", srv.authMiddleware(srv.handleListDates))
	mux.HandleFunc("POST /api/dates", srv.authMiddleware(srv.handleCreateDate))
	mux.HandleFunc("GET /api/dates/{id}", srv.authMiddleware(srv.handleGetDate))
	mux.HandleFunc("PUT /api/dates/{id}", srv.authMiddleware(srv.handleUpdateDate))
	mux.HandleFunc("DELETE /api/dates/{id}", srv.authMiddleware(srv.handleDeleteDate))

	// Curated dates endpoints (public)
	mux.HandleFunc("GET /api/curated-dates", srv.handleGetCuratedDates)
	mux.HandleFunc("GET /api/curated-dates/{id}", srv.handleGetCuratedDate)

	srv.httpServer = &http.Server{
		Addr:              cfg.HTTPAddr,
		Handler:           requestLoggingMiddleware(srv.logger, requestIDMiddleware(mux)),
		ReadHeaderTimeout: 5 * time.Second,
	}
	srv.ready.Store(true)

	return srv
}

func (s *Server) Start() error {
	s.logger.Info("starting HTTP server", "addr", s.httpServer.Addr)
	err := s.httpServer.ListenAndServe()
	if err != nil && err != http.ErrServerClosed {
		return fmt.Errorf("starting HTTP server: %w", err)
	}
	return nil
}

func (s *Server) Shutdown(ctx context.Context) error {
	s.ready.Store(false)
	if err := s.httpServer.Shutdown(ctx); err != nil {
		return fmt.Errorf("shutting down HTTP server: %w", err)
	}
	return nil
}

func (s *Server) handleHealth(w http.ResponseWriter, _ *http.Request) {
	if err := writeJSON(w, http.StatusOK, map[string]string{
		"status": "ok",
	}); err != nil {
		s.logger.Error("failed to write health response", "error", err)
	}
}

func (s *Server) handleReady(w http.ResponseWriter, _ *http.Request) {
	status := http.StatusOK
	state := "ready"
	if !s.ready.Load() {
		status = http.StatusServiceUnavailable
		state = "not_ready"
	}

	if err := writeJSON(w, status, map[string]string{
		"status":  state,
		"started": s.startedAt.Format(time.RFC3339),
	}); err != nil {
		s.logger.Error("failed to write readiness response", "error", err)
	}
}

func writeJSON(w http.ResponseWriter, status int, payload any) error {
	buf := &bytes.Buffer{}
	if err := json.NewEncoder(buf).Encode(payload); err != nil {
		return fmt.Errorf("encoding json response: %w", err)
	}

	w.Header().Set("Content-Type", "application/json")
	w.WriteHeader(status)
	if _, err := w.Write(buf.Bytes()); err != nil {
		return fmt.Errorf("writing response body: %w", err)
	}
	return nil
}
