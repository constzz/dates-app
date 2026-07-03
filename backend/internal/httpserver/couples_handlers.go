package httpserver

import (
	"encoding/json"
	"net/http"

	"my_project/backend/internal/couples"
)

type createInvitationResponse struct {
	Code      string `json:"code"`
	ExpiresAt string `json:"expires_at"`
}

type acceptInvitationRequest struct {
	Code string `json:"code"`
}

type coupleResponse struct {
	CoupleID  string `json:"couple_id"`
	User1ID   string `json:"user1_id"`
	User2ID   string `json:"user2_id"`
	IsPaired  bool   `json:"is_paired"`
	CreatedAt string `json:"created_at"`
}

// POST /api/couples/invite - Create invitation code
func (s *Server) handleCreateInvitation(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	if user == nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	invitation, err := s.couples.CreateInvitation(user.ID)
	if err == couples.ErrAlreadyPaired {
		writeError(w, http.StatusConflict, "user already paired")
		return
	}
	if err != nil {
		s.logger.Error("failed to create invitation", "error", err)
		writeError(w, http.StatusInternalServerError, "failed to create invitation")
		return
	}

	writeJSON(w, http.StatusOK, createInvitationResponse{
		Code:      invitation.Code,
		ExpiresAt: invitation.ExpiresAt.Format("2006-01-02T15:04:05Z07:00"),
	})
}

// POST /api/couples/accept - Accept invitation code
func (s *Server) handleAcceptInvitation(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	if user == nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	var req acceptInvitationRequest
	if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
		writeError(w, http.StatusBadRequest, "invalid request body")
		return
	}

	if req.Code == "" {
		writeError(w, http.StatusBadRequest, "code is required")
		return
	}

	couple, err := s.couples.AcceptInvitation(req.Code, user.ID)
	if err == couples.ErrAlreadyPaired {
		writeError(w, http.StatusConflict, "user already paired")
		return
	}
	if err == couples.ErrInvitationNotFound {
		writeError(w, http.StatusNotFound, "invitation not found")
		return
	}
	if err == couples.ErrInvitationExpired {
		writeError(w, http.StatusGone, "invitation expired")
		return
	}
	if err == couples.ErrInvitationUsed {
		writeError(w, http.StatusConflict, "invitation already used")
		return
	}
	if err != nil {
		s.logger.Error("failed to accept invitation", "error", err)
		writeError(w, http.StatusInternalServerError, "failed to accept invitation")
		return
	}

	writeJSON(w, http.StatusOK, coupleResponse{
		CoupleID:  couple.ID,
		User1ID:   couple.User1ID,
		User2ID:   couple.User2ID,
		IsPaired:  couple.User2ID != "",
		CreatedAt: couple.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	})
}

// GET /api/couples/me - Get current user's couple status
func (s *Server) handleGetMyCouple(w http.ResponseWriter, r *http.Request) {
	user := getUserFromContext(r.Context())
	if user == nil {
		writeError(w, http.StatusUnauthorized, "unauthorized")
		return
	}

	couple, err := s.couples.GetCoupleByUser(user.ID)
	if err == couples.ErrCoupleNotFound {
		writeJSON(w, http.StatusOK, map[string]interface{}{
			"paired": false,
		})
		return
	}
	if err != nil {
		s.logger.Error("failed to get couple", "error", err)
		writeError(w, http.StatusInternalServerError, "failed to get couple")
		return
	}

	writeJSON(w, http.StatusOK, coupleResponse{
		CoupleID:  couple.ID,
		User1ID:   couple.User1ID,
		User2ID:   couple.User2ID,
		IsPaired:  couple.User2ID != "",
		CreatedAt: couple.CreatedAt.Format("2006-01-02T15:04:05Z07:00"),
	})
}
