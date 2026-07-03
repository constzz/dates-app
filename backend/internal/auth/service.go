package auth

import (
	"context"
	"crypto/rand"
	"crypto/sha256"
	"encoding/base64"
	"encoding/hex"
	"fmt"
	"strings"
	"sync"
	"time"

	"golang.org/x/crypto/bcrypt"
)

const (
	accessTokenTTL  = 15 * time.Minute
	refreshTokenTTL = 30 * 24 * time.Hour
)

type Service struct {
	mu            sync.Mutex
	usersByEmail  map[string]user
	usersByID     map[string]user
	sessionsByRef map[string]session
	sessionsByAcc map[string]session
	now           func() time.Time
}

type User struct {
	ID    string `json:"id"`
	Email string `json:"email"`
}

type Session struct {
	User         User   `json:"user"`
	TokenType    string `json:"token_type"`
	AccessToken  string `json:"access_token"`
	RefreshToken string `json:"refresh_token"`
	ExpiresInSec int64  `json:"expires_in"`
}

type user struct {
	ID           string
	Email        string
	PasswordHash []byte
	CreatedAt    time.Time
}

type session struct {
	UserID              string
	AccessTokenHash     string
	AccessTokenExpires  time.Time
	RefreshTokenHash    string
	RefreshTokenExpires time.Time
	Revoked             bool
}

func NewService() *Service {
	return &Service{
		usersByEmail:  make(map[string]user),
		usersByID:     make(map[string]user),
		sessionsByRef: make(map[string]session),
		sessionsByAcc: make(map[string]session),
		now:           time.Now,
	}
}

func (s *Service) Register(_ context.Context, email, password string) (Session, error) {
	return s.createAccount(email, password)
}

func (s *Service) Login(_ context.Context, email, password string) (Session, error) {
	email = normalizeEmail(email)

	s.mu.Lock()
	user, ok := s.usersByEmail[email]
	s.mu.Unlock()
	if !ok {
		return Session{}, ErrInvalidCredentials
	}

	if err := bcrypt.CompareHashAndPassword(user.PasswordHash, []byte(password)); err != nil {
		return Session{}, ErrInvalidCredentials
	}

	return s.issueSession(user)
}

func (s *Service) Refresh(_ context.Context, refreshToken string) (Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	current, ok := s.sessionsByRef[hashToken(refreshToken)]
	if !ok || current.Revoked {
		return Session{}, ErrInvalidToken
	}

	if s.now().After(current.RefreshTokenExpires) {
		return Session{}, ErrInvalidToken
	}

	current.Revoked = true
	s.sessionsByRef[current.RefreshTokenHash] = current
	delete(s.sessionsByAcc, current.AccessTokenHash)

	user, ok := s.usersByID[current.UserID]
	if !ok {
		return Session{}, ErrInvalidToken
	}

	return s.issueSessionLocked(user)
}

func (s *Service) Logout(_ context.Context, refreshToken string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	current, ok := s.sessionsByRef[hashToken(refreshToken)]
	if !ok || current.Revoked {
		return ErrInvalidToken
	}

	current.Revoked = true
	s.sessionsByRef[current.RefreshTokenHash] = current
	delete(s.sessionsByAcc, current.AccessTokenHash)
	return nil
}

func (s *Service) Me(_ context.Context, accessToken string) (User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	current, ok := s.sessionsByAcc[hashToken(accessToken)]
	if !ok || current.Revoked {
		return User{}, ErrUnauthorized
	}

	if s.now().After(current.AccessTokenExpires) {
		return User{}, ErrUnauthorized
	}

	user, ok := s.usersByID[current.UserID]
	if !ok {
		return User{}, ErrUnauthorized
	}

	return User{ID: user.ID, Email: user.Email}, nil
}

func (s *Service) ValidateAccessToken(_ context.Context, accessToken string) (*User, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	current, ok := s.sessionsByAcc[hashToken(accessToken)]
	if !ok || current.Revoked {
		return nil, ErrUnauthorized
	}

	if s.now().After(current.AccessTokenExpires) {
		return nil, ErrUnauthorized
	}

	user, ok := s.usersByID[current.UserID]
	if !ok {
		return nil, ErrUnauthorized
	}

	return &User{ID: user.ID, Email: user.Email}, nil
}

func (s *Service) createAccount(email, password string) (Session, error) {
	email = normalizeEmail(email)
	if email == "" || len(password) < 8 {
		return Session{}, ErrBadInput
	}

	s.mu.Lock()
	defer s.mu.Unlock()

	if _, exists := s.usersByEmail[email]; exists {
		return Session{}, ErrUserExists
	}

	id, err := newToken()
	if err != nil {
		return Session{}, err
	}

	passwordHash, err := bcrypt.GenerateFromPassword([]byte(password), bcrypt.DefaultCost)
	if err != nil {
		return Session{}, fmt.Errorf("hashing password: %w", err)
	}

	u := user{
		ID:           id,
		Email:        email,
		PasswordHash: passwordHash,
		CreatedAt:    s.now(),
	}

	s.usersByEmail[email] = u
	s.usersByID[u.ID] = u

	return s.issueSessionLocked(u)
}

func (s *Service) issueSession(user user) (Session, error) {
	s.mu.Lock()
	defer s.mu.Unlock()
	return s.issueSessionLocked(user)
}

func (s *Service) issueSessionLocked(user user) (Session, error) {
	accessToken, err := newToken()
	if err != nil {
		return Session{}, err
	}
	refreshToken, err := newToken()
	if err != nil {
		return Session{}, err
	}

	session := session{
		UserID:              user.ID,
		AccessTokenHash:     hashToken(accessToken),
		AccessTokenExpires:  s.now().Add(accessTokenTTL),
		RefreshTokenHash:    hashToken(refreshToken),
		RefreshTokenExpires: s.now().Add(refreshTokenTTL),
	}

	s.sessionsByRef[session.RefreshTokenHash] = session
	s.sessionsByAcc[session.AccessTokenHash] = session

	return Session{
		User:         User{ID: user.ID, Email: user.Email},
		TokenType:    "Bearer",
		AccessToken:  accessToken,
		RefreshToken: refreshToken,
		ExpiresInSec: int64(accessTokenTTL / time.Second),
	}, nil
}

func normalizeEmail(email string) string {
	return strings.ToLower(strings.TrimSpace(email))
}

func hashToken(token string) string {
	sum := sha256.Sum256([]byte(token))
	return hex.EncodeToString(sum[:])
}

func newToken() (string, error) {
	buf := make([]byte, 32)
	if _, err := rand.Read(buf); err != nil {
		return "", fmt.Errorf("generating token: %w", err)
	}
	return base64.RawURLEncoding.EncodeToString(buf), nil
}
