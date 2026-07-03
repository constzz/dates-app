package httpserver

import (
	"encoding/json"
	"errors"
	"net/http"
	"strings"

	"my_project/backend/internal/auth"
)

type authCredentialsRequest struct {
	Email    string `json:"email"`
	Password string `json:"password"`
}

type refreshRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type logoutRequest struct {
	RefreshToken string `json:"refresh_token"`
}

type authResponse struct {
	User         auth.User `json:"user"`
	TokenType    string    `json:"token_type"`
	AccessToken  string    `json:"access_token"`
	RefreshToken string    `json:"refresh_token"`
	ExpiresIn    int64     `json:"expires_in"`
}

func authResponseFromSession(session auth.Session) authResponse {
	return authResponse{
		User:         session.User,
		TokenType:    session.TokenType,
		AccessToken:  session.AccessToken,
		RefreshToken: session.RefreshToken,
		ExpiresIn:    session.ExpiresInSec,
	}
}

func (s *Server) handleRegister(w http.ResponseWriter, r *http.Request) {
	var req authCredentialsRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	session, err := s.auth.Register(r.Context(), req.Email, req.Password)
	if err != nil {
		s.writeAuthError(w, err)
		return
	}

	writeJSONResponse(w, http.StatusCreated, authResponseFromSession(session))
}

func (s *Server) handleLogin(w http.ResponseWriter, r *http.Request) {
	var req authCredentialsRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	session, err := s.auth.Login(r.Context(), req.Email, req.Password)
	if err != nil {
		s.writeAuthError(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, authResponseFromSession(session))
}

func (s *Server) handleRefresh(w http.ResponseWriter, r *http.Request) {
	var req refreshRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	session, err := s.auth.Refresh(r.Context(), req.RefreshToken)
	if err != nil {
		s.writeAuthError(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, authResponseFromSession(session))
}

func (s *Server) handleLogout(w http.ResponseWriter, r *http.Request) {
	var req logoutRequest
	if err := decodeJSON(r, &req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if err := s.auth.Logout(r.Context(), req.RefreshToken); err != nil {
		s.writeAuthError(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, map[string]string{"status": "ok"})
}

func (s *Server) handleMe(w http.ResponseWriter, r *http.Request) {
	token := strings.TrimSpace(strings.TrimPrefix(r.Header.Get("Authorization"), "Bearer "))
	if token == "" {
		writeError(w, http.StatusUnauthorized, "missing bearer token")
		return
	}

	user, err := s.auth.Me(r.Context(), token)
	if err != nil {
		s.writeAuthError(w, err)
		return
	}

	writeJSONResponse(w, http.StatusOK, user)
}

func (s *Server) writeAuthError(w http.ResponseWriter, err error) {
	switch {
	case errors.Is(err, auth.ErrUserExists):
		writeError(w, http.StatusConflict, err.Error())
	case errors.Is(err, auth.ErrInvalidCredentials), errors.Is(err, auth.ErrInvalidToken), errors.Is(err, auth.ErrUnauthorized):
		writeError(w, http.StatusUnauthorized, err.Error())
	case errors.Is(err, auth.ErrBadInput):
		writeError(w, http.StatusBadRequest, err.Error())
	default:
		s.logger.Error("auth request failed", "error", err)
		writeError(w, http.StatusInternalServerError, "internal server error")
	}
}

func decodeJSON(r *http.Request, dst any) error {
	dec := json.NewDecoder(r.Body)
	dec.DisallowUnknownFields()
	return dec.Decode(dst)
}

func writeError(w http.ResponseWriter, status int, message string) {
	_ = writeJSONResponse(w, status, map[string]string{"error": message})
}

func writeJSONResponse(w http.ResponseWriter, status int, payload any) error {
	return writeJSON(w, status, payload)
}
