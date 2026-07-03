package auth

import (
	"context"
	"testing"
	"time"
)

func TestService_AuthLifecycle(t *testing.T) {
	t.Parallel()

	now := time.Date(2026, 7, 3, 12, 0, 0, 0, time.UTC)
	svc := NewService()
	svc.now = func() time.Time { return now }

	session, err := svc.Register(context.Background(), "User@Example.com", "password123")
	if err != nil {
		t.Fatalf("register: %v", err)
	}
	if session.User.Email != "user@example.com" {
		t.Fatalf("email = %q, want %q", session.User.Email, "user@example.com")
	}

	me, err := svc.Me(context.Background(), session.AccessToken)
	if err != nil {
		t.Fatalf("me: %v", err)
	}
	if me.Email != "user@example.com" {
		t.Fatalf("me email = %q, want %q", me.Email, "user@example.com")
	}

	refreshed, err := svc.Refresh(context.Background(), session.RefreshToken)
	if err != nil {
		t.Fatalf("refresh: %v", err)
	}
	if refreshed.AccessToken == session.AccessToken {
		t.Fatalf("refresh should rotate access token")
	}

	if err := svc.Logout(context.Background(), refreshed.RefreshToken); err != nil {
		t.Fatalf("logout: %v", err)
	}

	if _, err := svc.Me(context.Background(), refreshed.AccessToken); err != ErrUnauthorized {
		t.Fatalf("me after logout error = %v, want %v", err, ErrUnauthorized)
	}
}

func TestService_RegisterAndLoginValidation(t *testing.T) {
	t.Parallel()

	svc := NewService()

	tests := []struct {
		name     string
		setup    func()
		email    string
		password string
		wantErr  error
	}{
		{
			name:     "missing password",
			email:    "a@example.com",
			password: "short",
			wantErr:  ErrBadInput,
		},
		{
			name:     "missing email",
			email:    "",
			password: "password123",
			wantErr:  ErrBadInput,
		},
	}

	for _, tt := range tests {
		t.Run(tt.name, func(t *testing.T) {
			t.Parallel()
			_, err := svc.Register(context.Background(), tt.email, tt.password)
			if err != tt.wantErr {
				t.Fatalf("register error = %v, want %v", err, tt.wantErr)
			}
		})
	}

	if _, err := svc.Register(context.Background(), "dup@example.com", "password123"); err != nil {
		t.Fatalf("initial register: %v", err)
	}
	if _, err := svc.Register(context.Background(), "dup@example.com", "password123"); err != ErrUserExists {
		t.Fatalf("duplicate register error = %v, want %v", err, ErrUserExists)
	}

	if _, err := svc.Login(context.Background(), "dup@example.com", "wrong-password"); err != ErrInvalidCredentials {
		t.Fatalf("invalid login error = %v, want %v", err, ErrInvalidCredentials)
	}
}
