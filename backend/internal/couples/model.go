package couples

import (
	"crypto/rand"
	"encoding/base64"
	"time"
)

type Couple struct {
	ID        string    `json:"id"`
	User1ID   string    `json:"user1_id"`
	User2ID   string    `json:"user2_id"`
	CreatedAt time.Time `json:"created_at"`
}

type Invitation struct {
	Code      string    `json:"code"`
	CoupleID  string    `json:"couple_id"`
	CreatedBy string    `json:"created_by"`
	ExpiresAt time.Time `json:"expires_at"`
	Used      bool      `json:"used"`
}

// GenerateInviteCode creates a random 8-character invite code
func GenerateInviteCode() (string, error) {
	b := make([]byte, 6)
	if _, err := rand.Read(b); err != nil {
		return "", err
	}
	return base64.URLEncoding.EncodeToString(b)[:8], nil
}
