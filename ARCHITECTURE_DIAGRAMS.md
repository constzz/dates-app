# System Architecture Diagram

## Overall Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                        iOS App (SwiftUI)                     │
├─────────────────────────────────────────────────────────────┤
│  Views Layer                                                 │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │ ContentView  │ │  PairingView │ │   AuthView   │        │
│  │  (main list) │ │ (invitations)│ │ (login/reg)  │        │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘        │
│         │                │                │                  │
├─────────┼────────────────┼────────────────┼─────────────────┤
│  Services Layer          │                │                  │
│  ┌──────▼────────────────▼────────────────▼─────────┐       │
│  │        DateStorageService (orchestrator)         │       │
│  │  • Sync every 10s                                │       │
│  │  • Pairing status check                          │       │
│  │  • Online/offline management                     │       │
│  └───────┬──────────────┬──────────────┬────────────┘       │
│          │              │              │                     │
│  ┌───────▼──────┐ ┌────▼─────┐ ┌─────▼──────────┐          │
│  │   APIClient  │ │CoreData  │ │  Notification  │          │
│  │ (HTTP calls) │ │ Manager  │ │    Service     │          │
│  └───────┬──────┘ └──────────┘ └────────────────┘          │
└──────────┼──────────────────────────────────────────────────┘
           │
           │ HTTPS (JWT Bearer Token)
           │
┌──────────▼──────────────────────────────────────────────────┐
│                  Go Backend (:8080)                          │
├─────────────────────────────────────────────────────────────┤
│  HTTP Layer (net/http)                                       │
│  ┌──────────────┐ ┌──────────────┐ ┌──────────────┐        │
│  │Auth Handlers │ │Couple        │ │Date Handlers │        │
│  │              │ │Handlers      │ │              │        │
│  └──────┬───────┘ └──────┬───────┘ └──────┬───────┘        │
│         │                │                │                  │
├─────────┼────────────────┼────────────────┼─────────────────┤
│  Service Layer           │                │                  │
│  ┌──────▼──────┐ ┌──────▼───────┐ ┌──────▼──────┐          │
│  │AuthService  │ │CoupleService │ │DateService  │          │
│  │(JWT + bcrypt)│ │(invitations) │ │(CRUD+filter)│          │
│  └─────────────┘ └──────────────┘ └─────────────┘          │
│                                                              │
│  Storage: In-Memory Maps (sync.RWMutex)                     │
│  ┌─────────────────────────────────────────────────────┐   │
│  │ users, sessions, couples, invitations, dates        │   │
│  └─────────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────────┘
```

## Couple Pairing Flow

```
Device 1 (User A)                Backend                 Device 2 (User B)
    │                               │                           │
    │ 1. POST /auth/register        │                           │
    ├──────────────────────────────>│                           │
    │ {email, password}             │                           │
    │                               │                           │
    │ <─────────────────────────────┤                           │
    │ {user_id: A, access_token: T1}│                           │
    │                               │                           │
    │ 2. POST /couples/invite       │                           │
    ├──────────────────────────────>│                           │
    │ Authorization: Bearer T1      │                           │
    │                               │                           │
    │                           [Backend]                       │
    │                        Creates couple:                    │
    │                        {user1: A, user2: nil}             │
    │                        Creates invitation:                │
    │                        {code: "ABC123", expires: 24h}     │
    │                               │                           │
    │ <─────────────────────────────┤                           │
    │ {code: "ABC123", expires_at}  │                           │
    │                               │                           │
    │ 3. Share code with partner    │                           │
    │ (copy/paste, text, verbally)  │                           │
    │                               │                           │
    │                               │ 4. POST /auth/register    │
    │                               │<──────────────────────────┤
    │                               │ {email, password}         │
    │                               │                           │
    │                               ├──────────────────────────>│
    │                               │ {user_id: B, token: T2}   │
    │                               │                           │
    │                               │ 5. POST /couples/accept   │
    │                               │<──────────────────────────┤
    │                               │ {code: "ABC123"}          │
    │                               │ Authorization: Bearer T2  │
    │                               │                           │
    │                           [Backend]                       │
    │                        Finds invitation                   │
    │                        Updates couple:                    │
    │                        {user1: A, user2: B}               │
    │                        Marks invitation used              │
    │                               │                           │
    │                               ├──────────────────────────>│
    │                               │ {couple_id, is_paired: true}
    │                               │                           │
    │ 6. Poll GET /couples/me       │                           │
    ├──────────────────────────────>│                           │
    │ (every 10s auto-sync)         │                           │
    │ <─────────────────────────────┤                           │
    │ {is_paired: true, couple_id}  │                           │
    │                               │                           │
    │ 7. POST /dates (create)       │                           │
    ├──────────────────────────────>│                           │
    │ {title: "Dinner", ...}        │                           │
    │                               │                           │
    │                           [Backend]                       │
    │                        Saves date with:                   │
    │                        {couple_id: X, user_id: A}         │
    │                               │                           │
    │                               │ 8. GET /dates (sync poll) │
    │                               │<──────────────────────────┤
    │                               │ (every 10s)               │
    │                               │                           │
    │                           [Backend]                       │
    │                        Filters dates by couple_id         │
    │                               │                           │
    │                               ├──────────────────────────>│
    │                               │ [{id, title: "Dinner"}]   │
    │                               │                           │
    │                               │ 9. Shows in UI ✅         │
    │                               │    "Dinner" appears       │
```

## Data Flow: Shared Dates

```
                    Couple ID: "couple-123"
                           │
                ┌──────────┴──────────┐
                │                     │
            User A                User B
          (Device 1)            (Device 2)
                │                     │
                │                     │
        ┌───────▼─────────┐   ┌───────▼─────────┐
        │ DateStorage     │   │ DateStorage     │
        │ Service         │   │ Service         │
        │ • isPaired ✓    │   │ • isPaired ✓    │
        │ • poll: 10s     │   │ • poll: 10s     │
        └───────┬─────────┘   └───────┬─────────┘
                │                     │
                │    HTTP Requests    │
                │   (Bearer Token)    │
                │                     │
        ┌───────▼─────────────────────▼─────────┐
        │        Backend Dates Service           │
        │  • Filter by couple_id = "couple-123"  │
        │  • Both users get same dates           │
        └───────┬────────────────────────────────┘
                │
        ┌───────▼─────────┐
        │  In-Memory DB   │
        │                 │
        │  dates = [      │
        │   {id: 1,       │
        │    couple_id:   │
        │    "couple-123",│
        │    user_id: A,  │
        │    title:       │
        │    "Dinner"}    │
        │  ]              │
        └─────────────────┘
```

## Sync Flow

```
    iOS App                         Backend
       │                               │
       │ Timer fires (every 10s)       │
       │                               │
       ├─ GET /dates ──────────────────>│
       │  Authorization: Bearer TOKEN  │
       │                               │
       │                           [Backend]
       │                        Gets user from token
       │                        Looks up couple_id
       │                        Filters dates by couple_id
       │                               │
       │<────── [{date1, date2}] ──────┤
       │                               │
   [iOS App]                           │
   Saves to CoreData                   │
   Reloads UI                          │
   Plans updated ✅                    │
       │                               │
       │ User creates new date         │
       ├─ POST /dates ─────────────────>│
       │  {title, place, vibe...}      │
       │  Authorization: Bearer TOKEN  │
       │                               │
       │                           [Backend]
       │                        Saves with couple_id
       │                               │
       │<────── {date created} ─────────┤
       │                               │
   [iOS App]                           │
   Saves to CoreData                   │
   UI updates immediately              │
       │                               │
   [Partner's Device]                  │
       │ Timer fires (10s later)       │
       ├─ GET /dates ──────────────────>│
       │                               │
       │<────── [{date1, date2, NEW}]──┤
       │                               │
   [Partner sees new date] ✅          │
```

## Offline-First Architecture

```
           User Action
               │
               ▼
      ┌────────────────┐
      │ DateStorage    │
      │ Service        │
      └────────┬───────┘
               │
               ├──── Save to CoreData FIRST ──┐
               │     (always succeeds)         │
               │                               ▼
               │                     ┌─────────────────┐
               │                     │  CoreData       │
               │                     │  (Persistent)   │
               │                     │  ✅ Always works │
               │                     └─────────────────┘
               │
               └──── Sync to backend ─────┐
                     (if online)          │
                                          ▼
                                ┌──────────────────┐
                                │  Check online?   │
                                └────┬─────────┬───┘
                                     │         │
                                  Yes│         │No
                                     │         │
                                     ▼         ▼
                          ┌────────────┐  ┌────────────┐
                          │POST/PUT to │  │  Skip sync │
                          │  backend   │  │ (queued)   │
                          └────────────┘  └────────────┘
                                │
                                ▼
                          Success? Update
                          isOnline status
```

## Security Flow

```
    iOS App                         Backend
       │                               │
       │ POST /auth/login              │
       ├──────────────────────────────>│
       │ {email, password}             │
       │                               │
       │                           [Backend]
       │                        1. Find user by email
       │                        2. bcrypt.Compare(hash, pass)
       │                        3. Generate tokens:
       │                           - access: 15min
       │                           - refresh: 30 days
       │                               │
       │<───── {access_token,          │
       │        refresh_token} ─────────┤
       │                               │
   [iOS App]                           │
   Saves tokens to                     │
   UserDefaults                        │
       │                               │
       │ All future requests:          │
       ├──────────────────────────────>│
       │ Authorization:                │
       │   Bearer {access_token}       │
       │                               │
       │                           [Backend]
       │                        authMiddleware:
       │                        1. Extract token from header
       │                        2. Hash and lookup in sessions
       │                        3. Check expiry
       │                        4. Attach user to context
       │                               │
       │<───── {protected data} ────────┤
       │                               │
```
