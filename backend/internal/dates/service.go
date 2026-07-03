package dates

import (
	"context"
	"fmt"
	"sync"
	"time"

	"github.com/google/uuid"
)

type Service struct {
	mu    sync.RWMutex
	plans map[string]DatePlan // planID -> DatePlan
	now   func() time.Time
}

func NewService() *Service {
	return &Service{
		plans: make(map[string]DatePlan),
		now:   time.Now,
	}
}

func (s *Service) Create(ctx context.Context, coupleID, userID string, input DatePlan) (DatePlan, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	now := s.now().UTC()
	plan := DatePlan{
		ID:        uuid.NewString(),
		CoupleID:  coupleID,
		UserID:    userID,
		Title:     input.Title,
		Place:     input.Place,
		Date:      input.Date,
		Time:      input.Time,
		Vibe:      input.Vibe,
		Status:    input.Status,
		Notes:     input.Notes,
		CreatedAt: now,
		UpdatedAt: now,
	}

	s.plans[plan.ID] = plan
	return plan, nil
}

func (s *Service) Get(ctx context.Context, coupleID, planID string) (DatePlan, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	plan, ok := s.plans[planID]
	if !ok {
		return DatePlan{}, fmt.Errorf("plan not found")
	}
	if plan.CoupleID != coupleID {
		return DatePlan{}, fmt.Errorf("unauthorized")
	}

	return plan, nil
}

func (s *Service) List(ctx context.Context, coupleID string) ([]DatePlan, error) {
	s.mu.RLock()
	defer s.mu.RUnlock()

	var plans []DatePlan
	for _, plan := range s.plans {
		if plan.CoupleID == coupleID {
			plans = append(plans, plan)
		}
	}

	return plans, nil
}

func (s *Service) Update(ctx context.Context, coupleID, planID string, input DatePlan) (DatePlan, error) {
	s.mu.Lock()
	defer s.mu.Unlock()

	plan, ok := s.plans[planID]
	if !ok {
		return DatePlan{}, fmt.Errorf("plan not found")
	}
	if plan.CoupleID != coupleID {
		return DatePlan{}, fmt.Errorf("unauthorized")
	}

	plan.Title = input.Title
	plan.Place = input.Place
	plan.Date = input.Date
	plan.Time = input.Time
	plan.Vibe = input.Vibe
	plan.Status = input.Status
	plan.Notes = input.Notes
	plan.UpdatedAt = s.now().UTC()

	s.plans[planID] = plan
	return plan, nil
}

func (s *Service) Delete(ctx context.Context, coupleID, planID string) error {
	s.mu.Lock()
	defer s.mu.Unlock()

	plan, ok := s.plans[planID]
	if !ok {
		return fmt.Errorf("plan not found")
	}
	if plan.CoupleID != coupleID {
		return fmt.Errorf("unauthorized")
	}

	delete(s.plans, planID)
	return nil
}

// GetCuratedDates returns curated date ideas, optionally filtered by vibe
func (s *Service) GetCuratedDates(ctx context.Context, vibeFilter *Vibe) []CuratedDate {
	if vibeFilter == nil {
		return WroclawCuratedDates
	}

	filtered := make([]CuratedDate, 0)
	for _, date := range WroclawCuratedDates {
		if date.Vibe == *vibeFilter {
			filtered = append(filtered, date)
		}
	}
	return filtered
}

// GetCuratedDate returns a single curated date by ID
func (s *Service) GetCuratedDate(ctx context.Context, id string) (CuratedDate, error) {
	for _, date := range WroclawCuratedDates {
		if date.ID == id {
			return date, nil
		}
	}
	return CuratedDate{}, fmt.Errorf("curated date not found")
}

