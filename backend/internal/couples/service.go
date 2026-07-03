package couples

import (
	"errors"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
)

var (
	ErrCoupleNotFound     = errors.New("couple not found")
	ErrInvitationNotFound = errors.New("invitation not found")
	ErrInvitationExpired  = errors.New("invitation expired")
	ErrInvitationUsed     = errors.New("invitation already used")
	ErrAlreadyPaired      = errors.New("user already paired")
)

type Service struct {
	mu          sync.RWMutex
	couples     map[string]*Couple     // coupleID -> Couple
	invitations map[string]*Invitation // code -> Invitation
	userCouple  map[string]string      // userID -> coupleID
}

func NewService() *Service {
	return &Service{
		couples:     make(map[string]*Couple),
		invitations: make(map[string]*Invitation),
		userCouple:  make(map[string]string),
	}
}

// CreateInvitation creates a new couple and invitation code
func (s *Service) CreateInvitation(userID string) (*Invitation, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Check if user is already paired
	if _, exists := s.userCouple[userID]; exists {
		return nil, ErrAlreadyPaired
	}

	// Create couple (single user for now)
	coupleID := uuid.New().String()
	couple := &Couple{
		ID:        coupleID,
		User1ID:   userID,
		CreatedAt: time.Now().UTC(),
	}
	s.couples[coupleID] = couple
	s.userCouple[userID] = coupleID

	// Generate invitation code
	code, err := GenerateInviteCode()
	if err != nil {
		return nil, fmt.Errorf("generating invite code: %w", err)
	}

	invitation := &Invitation{
		Code:      code,
		CoupleID:  coupleID,
		CreatedBy: userID,
		ExpiresAt: time.Now().UTC().Add(24 * time.Hour), // 24h expiry
		Used:      false,
	}
	s.invitations[code] = invitation

	return invitation, nil
}

// AcceptInvitation pairs a user with an existing couple via invite code
func (s *Service) AcceptInvitation(code, userID string) (*Couple, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	// Check if user is already paired
	if _, exists := s.userCouple[userID]; exists {
		return nil, ErrAlreadyPaired
	}

	// Find invitation
	invitation, exists := s.invitations[code]
	if !exists {
		return nil, ErrInvitationNotFound
	}

	// Validate invitation
	if invitation.Used {
		return nil, ErrInvitationUsed
	}
	if time.Now().UTC().After(invitation.ExpiresAt) {
		return nil, ErrInvitationExpired
	}

	// Get couple
	couple, exists := s.couples[invitation.CoupleID]
	if !exists {
		return nil, ErrCoupleNotFound
	}

	// Pair the user
	couple.User2ID = userID
	invitation.Used = true
	s.userCouple[userID] = couple.ID

	return couple, nil
}

// GetCoupleByUser returns the couple for a given user
func (s *Service) GetCoupleByUser(userID string) (*Couple, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	coupleID, exists := s.userCouple[userID]
	if !exists {
		return nil, ErrCoupleNotFound
	}

	couple, exists := s.couples[coupleID]
	if !exists {
		return nil, ErrCoupleNotFound
	}

	return couple, nil
}

// GetCoupleID returns just the couple ID for a user (helper)
func (s *Service) GetCoupleID(userID string) (string, bool) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	coupleID, exists := s.userCouple[userID]
	return coupleID, exists
}
