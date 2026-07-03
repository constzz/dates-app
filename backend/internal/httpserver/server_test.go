package httpserver

import (
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"

	"my_project/backend/internal/auth"
	"my_project/backend/internal/config"
)

func TestHealthz(t *testing.T) {
	t.Parallel()

	server := New(newTestLogger(), config.Config{HTTPAddr: ":0"}, auth.NewService())
	req := httptest.NewRequest(http.MethodGet, "/healthz", nil)
	recorder := httptest.NewRecorder()

	server.httpServer.Handler.ServeHTTP(recorder, req)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	var body map[string]string
	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal health response: %v", err)
	}

	if body["status"] != "ok" {
		t.Fatalf("status body = %q, want %q", body["status"], "ok")
	}
}

func TestReadyz(t *testing.T) {
	t.Parallel()

	server := New(newTestLogger(), config.Config{HTTPAddr: ":0"}, auth.NewService())
	req := httptest.NewRequest(http.MethodGet, "/readyz", nil)
	recorder := httptest.NewRecorder()

	server.httpServer.Handler.ServeHTTP(recorder, req)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusOK)
	}

	var body map[string]string
	if err := json.Unmarshal(recorder.Body.Bytes(), &body); err != nil {
		t.Fatalf("unmarshal ready response: %v", err)
	}

	if body["status"] != "ready" {
		t.Fatalf("status body = %q, want %q", body["status"], "ready")
	}
}

func TestRequestIDMiddleware_UsesInboundHeader(t *testing.T) {
	t.Parallel()

	handler := requestIDMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := w.Write([]byte(RequestIDFromContext(r.Context())))
		if err != nil {
			t.Fatalf("writing response: %v", err)
		}
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	req.Header.Set("X-Request-ID", "client-id-123")
	recorder := httptest.NewRecorder()

	handler.ServeHTTP(recorder, req)

	if recorder.Header().Get("X-Request-ID") != "client-id-123" {
		t.Fatalf("response X-Request-ID = %q, want %q", recorder.Header().Get("X-Request-ID"), "client-id-123")
	}
	if strings.TrimSpace(recorder.Body.String()) != "client-id-123" {
		t.Fatalf("context request id = %q, want %q", recorder.Body.String(), "client-id-123")
	}
}

func TestRequestIDMiddleware_GeneratesHeader(t *testing.T) {
	t.Parallel()

	handler := requestIDMiddleware(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		_, err := w.Write([]byte(RequestIDFromContext(r.Context())))
		if err != nil {
			t.Fatalf("writing response: %v", err)
		}
	}))

	req := httptest.NewRequest(http.MethodGet, "/", nil)
	recorder := httptest.NewRecorder()
	handler.ServeHTTP(recorder, req)

	responseID := recorder.Header().Get("X-Request-ID")
	if responseID == "" {
		t.Fatalf("response X-Request-ID must be set")
	}
	if strings.TrimSpace(recorder.Body.String()) != responseID {
		t.Fatalf("context request id = %q, want %q", strings.TrimSpace(recorder.Body.String()), responseID)
	}
}

func newTestLogger() *slog.Logger {
	return slog.New(slog.NewJSONHandler(io.Discard, nil))
}
