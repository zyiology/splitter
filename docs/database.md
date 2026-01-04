# Database Schema (Firestore)

The application uses Cloud Firestore. Data is organized into the following collections.

## 1. `publicProfiles`
*   **Purpose**: Stores public user info (display name, photo) for display in the app.
*   **ID**: User's Firebase UID.
*   **Schema**:
    *   `userId` (String)
    *   `displayName` (String)
    *   `photoURL` (String)
    *   `createdAt` (Timestamp)

## 2. `transaction_groups`
*   **Purpose**: Represents a shared expense group (e.g., "Trip to Japan").
*   **Schema**:
    *   `groupName` (String)
    *   `owner` (String): UID of creator.
    *   `defaultCurrencyId` (String): ID from `currency_rates`.
    *   `inviteToken` (String): For sharing.
    *   `sharedWith` (Array<String>): List of member UIDs.
    *   `defaultTax`, `defaultServiceCharge` (Number)

### Subcollections of `transaction_groups`

#### `participants`
*   **Purpose**: Individuals involved in transactions (don't need to be app users).
*   **Schema**:
    *   `name` (String)

#### `currency_rates`
*   **Purpose**: Accepted currencies and rates for the group.
*   **Schema**:
    *   `symbol` (String): e.g., "USD".
    *   `rate` (Number): Exchange rate relative to base.

#### `transactions`
*   **Purpose**: Individual expense records.
*   **Schema**:
    *   `amount` (Number)
    *   `currency` (String)
    *   `payer` (String): Participant ID/Name.
    *   `payees` (String): Comma-separated names.
    *   `tax`, `serviceCharge` (Number)
    *   `description` (String)
