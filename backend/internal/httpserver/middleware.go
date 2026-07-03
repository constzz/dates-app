package httpserver

import (
	"context"
	"crypto/rand"
	"encoding/hex"
	"fmt"
	"log/slog"
	"net/http"
	"strings"
	"time"

	"my_project/backend/internal/auth"
)

type contextKey string

const (
	requestIDContextKey contextKey = "request_id"
	userContextKey      contextKey = "user"
)

func requestIDMiddleware(next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		requestID := strings.TrimSpace(r.Header.Get("X-Request-ID"))
		if requestID == "" {
			generatedID, err := newRequestID()
			if err != nil {
				http.Error(w, "failed to generate request id", http.StatusInternalServerError)
				return
			}
			requestID = generatedID
		}

		w.Header().Set("X-Request-ID", requestID)
		ctx := context.WithValue(r.Context(), requestIDContextKey, requestID)
		next.ServeHTTP(w, r.WithContext(ctx))
	})
}

func requestLoggingMiddleware(logger *slog.Logger, next http.Handler) http.Handler {
	return http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		startedAt := time.Now()
		recorder := &statusRecorder{ResponseWriter: w, status: http.StatusOK}
		next.ServeHTTP(recorder, r)

		logger.InfoContext(
			r.Context(),
			"http request",
			"method", r.Method,
			"path", r.URL.Path,
			"status", recorder.status,
			"duration_ms", time.Since(startedAt).Milliseconds(),
			"request_id", RequestIDFromContext(r.Context()),
		)
	})
}

func RequestIDFromContext(ctx context.Context) string {
	requestID, _ := ctx.Value(requestIDContextKey).(string)
	return requestID
}

func newRequestID() (string, error) {
	buf := make([]byte, 16)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("reading random bytes: %w", err)
	}
	return hex.EncodeToString(buf), nil
}

type statusRecorder struct {
	http.ResponseWriter
	status int
}

func (r *statusRecorder) WriteHeader(statusCode int) {
	r.status = statusCode
	r.ResponseWriter.WriteHeader(statusCode)
}

func (s *Server) authMiddleware(next http.HandlerFunc) http.HandlerFunc {
	return func(w http.ResponseWriter, r *http.Request) {
		authHeader := r.Header.Get("Authorization")
		if authHeader == "" {
			writeError(w, http.StatusUnauthorized, "missing authorization header")
			return
		}

		parts := strings.Split(authHeader, " ")
		if len(parts) != 2 || strings.ToLower(parts[0]) != "bearer" {
			writeError(w, http.StatusUnauthorized, "invalid authorization header")
			return
		}

		token := parts[1]
		user, err := s.auth.ValidateAccessToken(r.Context(), token)
		if err != nil {
			s.logger.InfoContext(r.Context(), "invalid access token", "error", err)
			writeError(w, http.StatusUnauthorized, "invalid or expired token")
			return
		}

		ctx := context.WithValue(r.Context(), userContextKey, user)
		next(w, r.WithContext(ctx))
	}
}

func getUserFromContext(ctx context.Context) *auth.User {
	user, _ := ctx.Value(userContextKey).(*auth.User)
	return user
}
