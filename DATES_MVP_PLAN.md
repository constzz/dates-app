# Dates MVP Plan

## Product Goal
Build a lightweight dates planning app that helps someone choose, organize, and remember date ideas without setup friction.

## Primary Use Case
Start from a blank slate and turn it into a concrete date plan.

The MVP should help a user:
- save a date idea quickly
- compare a few options at a glance
- note time, place, and vibe
- keep a short list of upcoming dates
- reopen a plan later without searching through chat history

## Product Positioning
This is a focused planning tool for dates, not a general calendar or social network.

## MVP Scope
### Must Have
- Add a new date idea
- Store a short list of date plans locally
- Show time, place, and note fields
- Mark a plan as upcoming or completed
- Simple home screen with recent plans
- Search or filter by vibe or status

### Should Have
- Empty state with example date ideas
- Friendly reminders for upcoming plans
- Clear save confirmation state
- Simple edit flow for existing plans

### Exclude for MVP
- Accounts
- Cloud sync
- Social feed
- Chat assistant flows
- Multi-device sync
- Complex scheduling automation

## Key Screens
### Home
Shows the current focus, a few date ideas, and recent plans.

### Date Detail
Displays the full plan with notes, timing, and status.

### New Date
Captures the core fields needed to create a plan quickly.

### Empty State
Explains the app in one sentence and offers a first plan CTA.

## Core User Flow
1. Open the app.
2. See the current date plan or a short list of ideas.
3. Add a new idea with a few details.
4. Save it locally.
5. Return later to review or update it.

## Success Criteria
- User can create a date plan in under 30 seconds.
- The home screen feels useful with no onboarding wall.
- The app stays understandable with only a few core fields.
- The app works fully without backend services.

## Technical Stack
- **Frontend**: Native SwiftUI iOS app
- **Backend**: Go REST API with PostgreSQL
- **Storage**: Local CoreData for offline-first + optional backend sync
- **Build**: Bazel

## Technical Assumptions
- iOS-native implementation (SwiftUI).
- Local CoreData storage for plans and reminders.
- Go backend API for future sync/auth (MVP works offline-first).
- A small, visual home screen with a few reusable cards.

## Risks
- Too many input fields will slow the flow down.
- The app can drift into generic note-taking if the home screen is weak.
- Without a clear visual hierarchy, the MVP will feel like a checklist rather than a planning tool.

## Suggested Build Order
1. Home screen and empty state.
2. Create/edit form for a date plan.
3. Local list of saved plans.
4. Status updates and simple filtering.
5. Detail screen polish and reminders.

## Open Questions
- Should the first version focus on one-on-one dates or all social plans?
- Should reminders be local notifications or just in-app cues?
- Should the app support recurring date templates?