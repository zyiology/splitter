# App Features

## 1. Authentication
*   **Google Sign-In**: Handled via Firebase Auth.
*   **Profile Creation**: A Cloud Function automatically creates a `publicProfiles` document upon new user registration.

## 2. Transaction Management
*   **Groups**: Users create groups and invite others via links.
*   **Expenses**: Record who paid, who benefited, and in what currency.
*   **Currencies**: Groups support multiple currencies with custom exchange rates.

## 3. Settlements
*   **Logic**: The `SettlementService` calculates net balances based on all transactions and simplify debts (e.g., "A owes B $10").
*   **On-demand**: Settlements are calculated client-side and not stored persistently.

## 4. Offline Mode
The app supports a hybrid offline mode.

### Behavior
*   **Read**: Cached data is viewable offline (Firestore persistence).
*   **Write (Restricted)**:
    *   ✅ **Allowed**: Adding transactions, participants, currency rates.
    *   ❌ **Blocked**: Editing or deleting existing data.
*   **Sync**: Offline operations are queued locally and synced automatically when connection is restored.

### Indicators
*   Orange App Bar / "Cloud-off" icon indicates offline state.
*   Pending items show a sync icon.
