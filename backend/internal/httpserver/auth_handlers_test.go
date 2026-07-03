package httpserver

import (
	"bytes"
	"encoding/json"
	"io"
	"log/slog"
	"net/http"
	"net/http/httptest"
	"testing"

	"my_project/backend/internal/auth"
	"my_project/backend/internal/config"
)

func TestAuthEndpoints(t *testing.T) {
	t.Parallel()

	server := New(testLogger(), config.Config{HTTPAddr: ":0"}, auth.NewService())
	handler := server.httpServer.Handler

	registerBody := postJSON(t, handler, http.MethodPost, "/auth/register", map[string]string{
		"email":    "user@example.com",
		"password": "password123",
	}, "")
	if registerBody.User.Email != "user@example.com" {
		t.Fatalf("register email = %q, want %q", registerBody.User.Email, "user@example.com")
	}

	loginBody := postJSON(t, handler, http.MethodPost, "/auth/login", map[string]string{
		"email":    "user@example.com",
		"password": "password123",
	}, "")
	if loginBody.AccessToken == "" || loginBody.RefreshToken == "" {
		t.Fatalf("login tokens must be set")
	}

	meBody := getJSON(t, handler, "/me", loginBody.AccessToken)
	if meBody["email"] != "user@example.com" {
		t.Fatalf("me email = %q, want %q", meBody["email"], "user@example.com")
	}

	refreshBody := postJSON(t, handler, http.MethodPost, "/auth/refresh", map[string]string{
		"refresh_token": loginBody.RefreshToken,
	}, "")
	if refreshBody.AccessToken == loginBody.AccessToken {
		t.Fatalf("refresh should rotate access token")
	}

	logoutBody := postJSONMap(t, handler, http.MethodPost, "/auth/logout", map[string]string{
		"refresh_token": refreshBody.RefreshToken,
	}, "")
	if logoutBody["status"] != "ok" {
		t.Fatalf("logout status = %q, want %q", logoutBody["status"], "ok")
	}

	meAfterLogout := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, "/me", nil)
	req.Header.Set("Authorization", "Bearer "+refreshBody.AccessToken)
	handler.ServeHTTP(meAfterLogout, req)
	if meAfterLogout.Code != http.StatusUnauthorized {
		t.Fatalf("status after logout = %d, want %d", meAfterLogout.Code, http.StatusUnauthorized)
	}
}

func TestAuthEndpoints_RejectBadInput(t *testing.T) {
	t.Parallel()

	server := New(testLogger(), config.Config{HTTPAddr: ":0"}, auth.NewService())
	recorder := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodPost, "/auth/register", bytes.NewBufferString(`{"email":"x@example.com"}`))
	server.httpServer.Handler.ServeHTTP(recorder, req)

	if recorder.Code != http.StatusBadRequest {
		t.Fatalf("status = %d, want %d", recorder.Code, http.StatusBadRequest)
	}
}

type sessionResponse struct {
	User struct {
		Email string `json:"email"`
	} `json:"user"`
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
}

func postJSON(t *testing.T, handler http.Handler, method, path string, payload any, bearer string) sessionResponse {
	t.Helper()

	body, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal payload: %v", err)
	}

	recorder := httptest.NewRecorder()
	req := httptest.NewRequest(method, path, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	if bearer != "" {
		req.Header.Set("Authorization", "Bearer "+bearer)
	}
	handler.ServeHTTP(recorder, req)

	if recorder.Code >= 400 {
		t.Fatalf("%s %s returned %d: %s", method, path, recorder.Code, recorder.Body.String())
	}

	var res sessionResponse
	if err := json.NewDecoder(recorder.Body).Decode(&res); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	return res
}

func postJSONMap(t *testing.T, handler http.Handler, method, path string, payload any, bearer string) map[string]string {
	t.Helper()

	body, err := json.Marshal(payload)
	if err != nil {
		t.Fatalf("marshal payload: %v", err)
	}

	recorder := httptest.NewRecorder()
	req := httptest.NewRequest(method, path, bytes.NewReader(body))
	req.Header.Set("Content-Type", "application/json")
	if bearer != "" {
		req.Header.Set("Authorization", "Bearer "+bearer)
	}
	handler.ServeHTTP(recorder, req)

	if recorder.Code >= 400 {
		t.Fatalf("%s %s returned %d: %s", method, path, recorder.Code, recorder.Body.String())
	}

	var res map[string]string
	if err := json.NewDecoder(recorder.Body).Decode(&res); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	return res
}

func getJSON(t *testing.T, handler http.Handler, path, bearer string) map[string]string {
	t.Helper()

	recorder := httptest.NewRecorder()
	req := httptest.NewRequest(http.MethodGet, path, nil)
	req.Header.Set("Authorization", "Bearer "+bearer)
	handler.ServeHTTP(recorder, req)

	if recorder.Code != http.StatusOK {
		t.Fatalf("status = %d, want %d; body=%s", recorder.Code, http.StatusOK, recorder.Body.String())
	}

	var res map[string]string
	if err := json.NewDecoder(recorder.Body).Decode(&res); err != nil {
		t.Fatalf("decode response: %v", err)
	}
	return res
}

func testLogger() *slog.Logger {
	return slog.New(slog.NewJSONHandler(io.Discard, nil))
}
