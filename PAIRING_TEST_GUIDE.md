# Couple Pairing Testing Guide

## Backend Status
✅ Backend running on `localhost:8080`
✅ Couple pairing API tested via curl

## App Features Implemented

### 1. Authentication
- Register/Login via AuthView
- JWT token-based auth
- Min 8 character password

### 2. Couple Pairing
- Create invitation code (8 chars, 24h expiry)
- Accept invitation code
- Shared date plans for paired couples

### 3. Auto-Sync
- Polls backend every 10 seconds
- Bidirectional sync (local ↔️ backend)
- Offline-first with CoreData

### 4. UI Indicators
- Person icon (top-left): Shows auth status, tap to login/register
- Heart icon (top-right): Tap for pairing
- Header shows: Paired status + Online/Offline status

## Testing with TWO Simulators

### Setup
```bash
# Terminal 1: Backend (already running)
cd backend && go run ./cmd/dates-api/

# Terminal 2: Build and launch first simulator
./test_app.sh

# Terminal 3: Launch second simulator
xcrun simctl boot "iPhone 15"
open -a Simulator

# Terminal 4: Install app on second simulator
cd bazel-bin/modules/test_valdi
unzip -o DatesApp.ipa -d app_payload
xcrun simctl install "iPhone 15" app_payload/Payload/DatesApp.app
xcrun simctl launch "iPhone 15" com.dates.app
```

### Pairing Flow

**Device 1 (User A):**
1. Tap person icon (top-left)
2. Create account: `user1@test.com` / `password123`
3. Tap heart icon (top-right)
4. Tap "Create Invitation"
5. Copy invitation code (e.g., `AB12XY78`)

**Device 2 (User B):**
1. Tap person icon
2. Create account: `user2@test.com` / `password123`
3. Tap heart icon
4. Tap "Enter Partner's Code"
5. Enter code from Device 1
6. Tap "Join Couple"

**Verification:**
- Both devices should show "Paired" label in header
- Create a date on Device 1
- Within 10 seconds, it appears on Device 2
- Edit/delete on either device syncs to both

## Quick Terminal Test (Already Verified)

```bash
# Register User 1
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user1@test.com","password":"password123"}'
# Response: {"access_token":"TOKEN1",...}

# Create Invitation
curl -X POST http://localhost:8080/api/couples/invite \
  -H "Authorization: Bearer TOKEN1" \
  -H "Content-Type: application/json" -d '{}'
# Response: {"code":"SmrsApIh","expires_at":"..."}

# Register User 2
curl -X POST http://localhost:8080/api/auth/register \
  -H "Content-Type: application/json" \
  -d '{"email":"user2@test.com","password":"password123"}'
# Response: {"access_token":"TOKEN2",...}

# Accept Invitation
curl -X POST http://localhost:8080/api/couples/accept \
  -H "Authorization: Bearer TOKEN2" \
  -H "Content-Type: application/json" \
  -d '{"code":"SmrsApIh"}'
# Response: {"is_paired":true,"couple_id":"..."}

# Create Date (User 1)
curl -X POST http://localhost:8080/api/dates \
  -H "Authorization: Bearer TOKEN1" \
  -H "Content-Type: application/json" \
  -d '{"title":"Dinner","planned_at":"2026-07-10T19:00:00Z","status":"planned","vibe":"romantic"}'

# List Dates (User 2) - Should see User 1's date
curl http://localhost:8080/api/dates \
  -H "Authorization: Bearer TOKEN2"
# Response: [{"id":"...","title":"Dinner",...}]
```

## Known Limitations

1. **Real-time updates**: 10-second polling (consider WebSocket for instant sync)
2. **No unpair feature**: Once paired, cannot unpair (backend doesn't support it yet)
3. **Single couple**: Each user can only be in one couple
4. **Invite expiry**: Codes expire after 24 hours
5. **No notification on partner changes**: No push notifications when partner adds/edits dates

## Next Steps (Optional Enhancements)

- [ ] WebSocket for real-time updates (no polling delay)
- [ ] Push notifications for partner's date changes
- [ ] Unpair functionality
- [ ] Partner profile display
- [ ] Multiple couples support
- [ ] Invite history/management
- [ ] Background sync (even when app closed)
