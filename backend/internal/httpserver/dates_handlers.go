package httpserver

import (
	"encoding/json"
	"net/http"
	"strings"

	"my_project/backend/internal/dates"
)

type CreateDateRequest struct {
	Title  string       `json:"title"`
	Place  string       `json:"place"`
	Date   *string      `json:"date,omitempty"`
	Time   string       `json:"time,omitempty"`
	Vibe   dates.Vibe   `json:"vibe"`
	Status dates.Status `json:"status"`
	Notes  string       `json:"notes"`
}

type UpdateDateRequest struct {
	Title  string       `json:"title"`
	Place  string       `json:"place"`
	Date   *string      `json:"date,omitempty"`
	Time   string       `json:"time,omitempty"`
	Vibe   dates.Vibe   `json:"vibe"`
	Status dates.Status `json:"status"`
	Notes  string       `json:"notes"`
}

func (s *Server) handleListDates(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	if user == nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// Get couple ID (or use user ID if not paired)
	coupleID, exists := s.couples.GetCoupleID(user.ID)
	if !exists {
		coupleID = user.ID // Use user ID as couple ID for unpaired users
	}

	plans, err := s.dates.List(r.Context(), coupleID)
	if err != nil {
		s.logger.Error("failed to list dates", "error", err, "user_id", user.ID, "couple_id", coupleID)
		writeError(w, http.StatusInternalServerError, "failed to list dates")
		return
	}

	if err := writeJSON(w, http.StatusOK, plans); err != nil {
		s.logger.Error("failed to write response", "error", err)
	}
}

func (s *Server) handleCreateDate(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	if user == nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// Get couple ID (or use user ID if not paired)
	coupleID, exists := s.couples.GetCoupleID(user.ID)
	if !exists {
		coupleID = user.ID // Use user ID as couple ID for unpaired users
	}

	var req CreateDateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	input := dates.DatePlan{
		Title:  req.Title,
		Place:  req.Place,
		Time:   req.Time,
		Vibe:   req.Vibe,
		Status: req.Status,
		Notes:  req.Notes,
	}

	plan, err := s.dates.Create(r.Context(), coupleID, user.ID, input)
	if err != nil {
		s.logger.Error("failed to create date", "error", err, "user_id", user.ID)
		writeError(w, http.StatusInternalServerError, "failed to create date")
		return
	}

	if err := writeJSON(w, http.StatusCreated, plan); err != nil {
		s.logger.Error("failed to write response", "error", err)
	}
}

func (s *Server) handleGetDate(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	if user == nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// Get couple ID (or use user ID if not paired)
	coupleID, exists := s.couples.GetCoupleID(user.ID)
	if !exists {
		coupleID = user.ID
	}

	planID := strings.TrimPrefix(r.URL.Path, "/dates/")
	if planID == "" {
		writeError(w, http.StatusBadRequest, "missing plan ID")
		return
	}

	plan, err := s.dates.Get(r.Context(), coupleID, planID)
	if err != nil {
		s.logger.Error("failed to get date", "error", err, "user_id", user.ID, "plan_id", planID)
		writeError(w, http.StatusNotFound, "date not found")
		return
	}

	if err := writeJSON(w, http.StatusOK, plan); err != nil {
		s.logger.Error("failed to write response", "error", err)
	}
}

func (s *Server) handleUpdateDate(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	if user == nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// Get couple ID (or use user ID if not paired)
	coupleID, exists := s.couples.GetCoupleID(user.ID)
	if !exists {
		coupleID = user.ID
	}

	planID := strings.TrimPrefix(r.URL.Path, "/dates/")
	if planID == "" {
		writeError(w, http.StatusBadRequest, "missing plan ID")
		return
	}

	var req UpdateDateRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	input := dates.DatePlan{
		Title:  req.Title,
		Place:  req.Place,
		Time:   req.Time,
		Vibe:   req.Vibe,
		Status: req.Status,
		Notes:  req.Notes,
	}

	plan, err := s.dates.Update(r.Context(), coupleID, planID, input)
	if err != nil {
		s.logger.Error("failed to update date", "error", err, "user_id", user.ID, "plan_id", planID)
		writeError(w, http.StatusNotFound, "date not found")
		return
	}

	if err := writeJSON(w, http.StatusOK, plan); err != nil {
		s.logger.Error("failed to write response", "error", err)
	}
}

func (s *Server) handleDeleteDate(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	if user == nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	// Get couple ID (or use user ID if not paired)
	coupleID, exists := s.couples.GetCoupleID(user.ID)
	if !exists {
		coupleID = user.ID
	}

	planID := strings.TrimPrefix(r.URL.Path, "/dates/")
	if planID == "" {
		writeError(w, http.StatusBadRequest, "missing plan ID")
		return
	}

	if err := s.dates.Delete(r.Context(), coupleID, planID); err != nil {
		s.logger.Error("failed to delete date", "error", err, "user_id", user.ID, "plan_id", planID)
		writeError(w, http.StatusNotFound, "date not found")
		return
	}

	w.WriteHeader(http.StatusNoContent)
}

func (s *Server) handleGetCuratedDates(w http.ResponseWriter, r *http.Request) {
	// Optional vibe filter
	var vibeFilter *dates.Vibe
	vibeParam := r.URL.Query().Get("vibe")
	if vibeParam != "" {
		vibe := dates.Vibe(vibeParam)
		vibeFilter = &vibe
	}

	curatedDates := s.dates.GetCuratedDates(r.Context(), vibeFilter)

	if err := writeJSON(w, http.StatusOK, curatedDates); err != nil {
		s.logger.Error("failed to write response", "error", err)
	}
}

func (s *Server) handleGetCuratedDate(w http.ResponseWriter, r *http.Request) {
	dateID := strings.TrimPrefix(r.URL.Path, "/api/curated-dates/")
	if dateID == "" {
		writeError(w, http.StatusBadRequest, "missing date ID")
		return
	}

	curatedDate, err := s.dates.GetCuratedDate(r.Context(), dateID)
	if err != nil {
		writeError(w, http.StatusNotFound, "curated date not found")
		return
	}

	if err := writeJSON(w, http.StatusOK, curatedDate); err != nil {
		s.logger.Error("failed to write response", "error", err)
	}
}

