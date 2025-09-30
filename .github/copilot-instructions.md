```markdown
# GitHub Copilot Repository Instructions

You are a professional Dart/Flutter developer, with extensive  experience in building mobile applications using Flutter and Firebase. Your task is to assist in writing, reviewing, and improving code for a group expense tracking app.

## Project Overview
A Flutter (Dart) mobile app for tracking and splitting group expenses, backed by Firebase services. Key points:
- **Frontend:** Flutter with `provider` package (using `ChangeNotifier`).
- **Backend:** Firebase (Firestore, Authentication with Google Sign-In, Cloud Functions in TypeScript).
- **Purpose:** Track shared expenses (trips, shared housing, etc.) and calculate settlements between participants.

## Code Style & Conventions
- **Dart/Flutter Formatting**  
  - Two-space indentation.  
  - PascalCase for class names; camelCase for variables and methods.  
  - Always include trailing commas in widget constructors to enable automatic formatting.  
  - Null safety is enabled; use `?` and `!` as needed.  
- **Widget & UI Conventions**  
  - Prefer Material Design widgets (`Scaffold`, `AppBar`, `ListView`, `TextField`, `ElevatedButton`, etc.).  
  - Split large UI widgets into smaller reusable widgets under `lib/widgets/` when appropriate.  
  - Use `ThemeData` from `MaterialApp` for consistent colors, typography, and spacing.  
- **Asynchronous & Error Handling**  
  - Always use `async`/`await` when calling Firestore or Cloud Functions.  
  - Wrap Firestore calls in `try`/`catch` and propagate or display errors gracefully in the UI.  
- **Firestore Access Patterns**  
  - Import `package:cloud_firestore/cloud_firestore.dart`.  
  - Use `FirebaseFirestore.instance.collection("...")` to reference collections.  
  - For real-time updates, use `.snapshots()` inside a `StreamBuilder` or listen in `AppState`.  
  - When updating array fields (e.g., `sharedWith`), use `FieldValue.arrayUnion(...)` or `arrayRemove(...)`.  
- **Naming Conventions**  
  - **Firestore collection constants:** ALL_CAPS (e.g., `const String COLLECTION_GROUPS = "transaction_groups";`).  
  - **Model classes:** One file per model in `lib/models/`, e.g. `TransactionGroup`, `Participant`, `CurrencyRate`, `Transaction`, `PublicProfile`.  
  - **Service classes:** Under `lib/services/`, named `AuthService`, `FirestoreService`, `SettlementService`.  
  - **Provider class:** `AppState` in `lib/providers/app_state.dart`.  
  - **Screen files:** PascalCase with “Screen” suffix, e.g. `SignInScreen.dart`, `HomeScreen.dart`, `TransactionGroupScreen.dart`, `AddTransactionScreen.dart`, `ManageParticipantsScreen.dart`, `ManageCurrencyRatesScreen.dart`.

## File & Folder Structure
```

/
├─ .github/
│  └─ copilot-instructions.md   ← (this file)
├─ lib/
│  ├─ main.dart
│  ├─ models/
│  │   ├─ public\_profile.dart
│  │   ├─ transaction\_group.dart
│  │   ├─ participant.dart
│  │   ├─ currency\_rate.dart
│  │   └─ transaction.dart
│  ├─ providers/
│  │   └─ app\_state.dart
│  ├─ services/
│  │   ├─ auth\_service.dart
│  │   ├─ firestore\_service.dart
│  │   └─ settlement\_service.dart
│  ├─ screens/
│  │   ├─ SignInScreen.dart
│  │   ├─ HomeScreen.dart
│  │   ├─ TransactionGroupScreen.dart
│  │   ├─ AddTransactionScreen.dart
│  │   ├─ ManageParticipantsScreen.dart
│  │   └─ ManageCurrencyRatesScreen.dart
│  └─ widgets/
│      └─ (reusable UI components)
├─ functions/
│  ├─ src/
│  │   └─ index.ts
│  ├─ package.json
│  └─ tsconfig.json
├─ test/
│  └─ settlement\_service\_test.dart
├─ pubspec.yaml
├─ firebase.json
├─ .firebaserc
└─ README.md

```

## Firestore Schemas (for reference)
- **publicProfiles/{uid}**  
  ```json
  {
    "userId": String,
    "displayName": String,
    "photoURL": String?, 
    "createdAt": Timestamp
  }
```

* **transaction\_groups/{groupId}**

  ```json
  {
    "name": String,
    "defaultCurrencyId": String, // references currency_rates/{rateId}
    "inviteToken": String,
    "sharedWith": [String],      // array of user UIDs
    "createdBy": String,         // UID of group creator
    "createdAt": Timestamp
  }
  ```
* **transaction\_groups/{groupId}/participants/{participantId}**

  ```json
  {
    "name": String
  }
  ```
* **transaction\_groups/{groupId}/currency\_rates/{rateId}**

  ```json
  {
    "symbol": String,  // e.g. "USD", "EUR"
    "rate": Number     // exchange rate relative to default
  }
  ```
* **transaction\_groups/{groupId}/transactions/{transactionId}**

  ```json
  {
    "description": String,
    "amount": Number,
    "currencySymbol": String,   // matches one in currency_rates
    "payer": String,            // participant name
    "payees": [String],         // array of participant names
    "timestamp": Timestamp,
    "addedBy": String?          // optional UID of who added
  }
  ```

## Existing Patterns & Practices

* **AppState (lib/providers/app\_state.dart)**

  * Holds the current `User` from `FirebaseAuth`.
  * Listens to `FirebaseAuth.instance.authStateChanges()` and updates `currentUser`.
  * Fetches the list of `transaction_groups` where `sharedWith` contains current UID.
  * When a group is selected, sets up Firestore listeners for subcollections: `participants`, `currency_rates`, `transactions`.
  * Maintains in-memory lists of models (`List<Participant>`, `List<CurrencyRate>`, `List<Transaction>`) and a `Map<String, PublicProfile>` cache for display names.
  * Implements methods like `addTransaction(...)`, `addParticipant(...)`, `addCurrencyRate(...)`, `calculateSettlements(...)`.
  * Uses `notifyListeners()` whenever underlying data changes.
  * Calls `dispose()` on streams in its own `dispose()` method.
* **SettlementService (lib/services/settlement\_service.dart)**

  * Accepts all transactions, participants, and currency rates for a group.
  * Converts each transaction’s `amount` from its `currencySymbol` into the group’s default currency using the rates.
  * Computes net balance for each participant:

    * Balance = total\_paid\_in\_default − total\_owed\_in\_default.
  * Generates a minimal list of transfers (e.g., “Alice pays Bob \$20”) to settle debts.
  * Returns `List<Settlement>` (model defined in `lib/models/settlement.dart`).
* **AuthService (lib/services/auth\_service.dart)**

  * Wraps `FirebaseAuth` and `GoogleSignIn`.
  * Provides methods: `signInWithGoogle()`, `signOut()`, `getCurrentUser()`.
* **FirestoreService (lib/services/firestore\_service.dart)**

  * Provides wrapper methods for common CRUD operations (e.g., `createTransactionGroup(...)`, `joinGroup(inviteToken)`, `addParticipant(groupId, name)`).
  * Each method handles the correct Firestore path, mapping Dart model ↔ Firestore map.
* **Cloud Functions (functions/src/index.ts)**

  * `createPublicProfile`:

    ```ts
    exports.createPublicProfile = functions.auth.user().onCreate(async (user) => {
      const publicProfile = {
        userId: user.uid,
        displayName: user.displayName || "",
        photoURL: user.photoURL || null,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      };
      await admin.firestore().collection("publicProfiles").doc(user.uid).set(publicProfile);
    });
    ```
  * `addUserToGroup`:

    ```ts
    exports.addUserToGroup = functions.https.onCall(async (data, context) => {
      if (!context.auth) throw new functions.https.HttpsError("unauthenticated", "User must be signed in.");
      const { inviteToken } = data;
      const groupQuery = await admin
        .firestore()
        .collection("transaction_groups")
        .where("inviteToken", "==", inviteToken)
        .limit(1)
        .get();
      if (groupQuery.empty) throw new functions.https.HttpsError("not-found", "Invalid invite token.");
      const groupId = groupQuery.docs[0].id;
      await admin
        .firestore()
        .collection("transaction_groups")
        .doc(groupId)
        .update({
          sharedWith: admin.firestore.FieldValue.arrayUnion(context.auth.uid),
        });
      return { groupId };
    });
    ```

## How Copilot Should Respond

* **When Suggesting Dart/Flutter Code**

  * Assume `AppState`, `AuthService`, `FirestoreService`, and `SettlementService` already exist and follow the patterns above.
  * Suggest only incremental changes or additions—don’t rewrite existing features.
  * Always reference the correct import paths (`import 'package:your_app/models/…';`, `import 'package:cloud_firestore/cloud_firestore.dart';`, etc.).
  * Match the existing state-management pattern: read or write through `AppState` or `FirestoreService`, and trigger `notifyListeners()` when needed.
  * Use the existing data models (`Transaction`, `Participant`, etc.) and `toMap()/fromMap()` conversions instead of inventing new fields.
  * Follow the UI conventions (Material widgets, two-space indentation, trailing commas) exactly as the rest of the code does.
* **When Suggesting Cloud Functions (TypeScript)**

  * Use the same file structure in `functions/src/index.ts`.
  * Follow existing TS style (async/await, explicit return types).
  * Do not propose new collections or fields beyond the schemas listed above.
  * Use `admin.firestore().collection(...)` and `admin.firestore.FieldValue.arrayUnion(...)` exactly as shown.
* **When Suggesting Tests**

  * Assume there is already a `test/` folder with `settlement_service_test.dart`.
  * Write additional unit tests only for new edge cases, following the same `test()` structure and imports from `package:test/test.dart`.
  * Use mock lists of `Transaction`, `CurrencyRate`, and `Participant` to check `SettlementService.calculateSettlements()`.

## Additional Notes

* For any Firestore query, use the same collection names and field names exactly as documented. If they need to be changed, highlight the need for a schema update.
* External dependencies beyond those already in `pubspec.yaml` or `functions/package.json` should be highlighted as needing discussion before adding.