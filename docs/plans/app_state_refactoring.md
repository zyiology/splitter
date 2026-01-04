# AppState Refactoring Migration Plan

This plan outlines a staged refactor from a monolithic `AppState` to feature-scoped controllers and repositories. The goal is to improve maintainability without breaking the UI in a single large change.

## High-level Overview

1. **Organize without behavior change**
   Split `AppState` into focused parts while keeping the public API stable.

2. **Introduce repositories**
   Move Firebase/Firestore/Functions interactions into repositories and inject them into `AppState` (or controllers).

3. **Extract feature controllers**
   Create `ChangeNotifier` controllers per feature and migrate UI screens to consume them directly.

4. **Reduce AppState to an app scope**
   Keep only cross-cutting concerns (auth session, connectivity, pending invite, offline queue status).

5. **Harden and test**
   Add lightweight tests or manual verification steps for each feature as it moves.

## Detailed Steps

### Step 1: Organize `AppState` with `part` files (no behavior change)

**Goal**: Make the file navigable while keeping the same provider API.

- Create `lib/providers/` part files (examples):
  - `app_state_auth.dart`
  - `app_state_connectivity.dart`
  - `app_state_groups.dart`
  - `app_state_participants.dart`
  - `app_state_currency_rates.dart`
  - `app_state_transactions.dart`
  - `app_state_profiles.dart`
  - `app_state_offline_queue.dart`
- Move method groups and related fields into these parts.
- Keep `class AppState` in `lib/providers/app_state.dart` and add `part` declarations.
- Add `dispose()` in `AppState` to cancel subscriptions safely.

**Deliverable**: Same UI behavior, smaller logical files, easier navigation.

### Step 2: Introduce repositories for Firebase/Firestore/Functions

**Goal**: Isolate data access and error handling from state management.

- Add repository classes under `lib/repositories/` (examples):
  - `auth_repository.dart` (sign-in/out, current user)
  - `groups_repository.dart` (transaction groups CRUD)
  - `participants_repository.dart`
  - `currency_rates_repository.dart`
  - `transactions_repository.dart`
  - `profiles_repository.dart`
  - `functions_repository.dart` (join group callable)
- Each repository exposes async methods and handles `try/catch` consistently.
- Update AppState methods to call repositories.

**Deliverable**: AppState becomes thinner; Firebase usage is centralized.

### Step 3: Extract feature controllers

**Goal**: Replace monolithic state with small, focused `ChangeNotifier`s.

- Create controllers under `lib/features/<feature>/` or `lib/controllers/`:
  - `AuthController` (user, sign-in/out, auth changes)
  - `GroupsController` (groups list, select current group)
  - `ParticipantsController` (participants list, add/remove)
  - `CurrencyRatesController` (rates list, add/update/remove)
  - `TransactionsController` (transactions list, add/remove)
  - `SettlementsController` (calculate, store settlements)
  - `ConnectivityController` (online/offline state)
  - `OfflineQueueController` (pending ops, sync status)
- Wire controllers through `MultiProvider` in `lib/main.dart`.
- Start migrating one screen at a time to the new controller(s), leaving the old AppState in place during transition.

**Deliverable**: UI uses feature controllers directly; AppState usage shrinks.

### Step 4: Reduce `AppState` to app-scope concerns

**Goal**: Keep only cross-cutting concerns in a lightweight app scope.

- `AppState` (or rename to `AppScope`) contains:
  - `pendingInviteToken`
  - connectivity state
  - offline queue status
  - maybe a minimal auth session summary
- Remove feature-specific data collections from `AppState`.
- Update remaining UI references.

**Deliverable**: Single-responsibility app-level state.

### Step 5: Hardening and verification

**Goal**: Prevent regressions during migration.

- Add smoke tests or manual checks per feature:
  - Auth flow (sign-in/sign-out)
  - Group list and join
  - Add participants, currency rates, transactions
  - Offline add + sync
  - Settlements calculation
- Optionally add unit tests for repositories and controllers if coverage is desired.

## Suggested Migration Order

1. **Auth + Profiles** (smallest API surface)
2. **Groups list + current group selection**
3. **Participants**
4. **Currency rates**
5. **Transactions**
6. **Settlements**
7. **Offline queue + connectivity**

This order minimizes cross-feature dependencies and keeps the app functional at each step.

## Notes

- Avoid changing UI behavior while reorganizing.
- Keep `Provider` for now; swap later only if needed.
- Avoid introducing new dependencies without approval.
