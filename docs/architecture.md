# Architecture & Project Structure

## Software Stack

The application is built using the following technologies:

*   **Frontend**: Flutter (using Dart) - Single codebase for cross-platform mobile apps.
*   **Backend**: Firebase
    *   **Firestore**: NoSQL document database.
    *   **Authentication**: Google Sign-In handling.
    *   **Cloud Functions**: Server-side logic (TypeScript).
*   **State Management**: `provider` package (utilizing `ChangeNotifier`).

## Project Structure Overview

The project follows a standard Flutter structure with separated Firebase functions.

### Key Directories
*   **`lib/`**: Main Flutter code.
    *   `models/`: Data classes (`TransactionGroup`, `Transaction`, `Participant`, etc.).
    *   **`providers/`**: State management logic (primarily `AppState`).
    *   `screens/`: UI screens (`HomeScreen`, `TransactionGroupScreen`, etc.).
    *   `services/`: Specialized services (`SettlementService`).
    *   `dialogs/`: UI components for dialogs.
*   **`functions/`**: Firebase Cloud Functions (TypeScript).
*   **`android/`**: Android native project files.
*   **`ios/`**, **`web/`**, **`linux/`**, **`macos/`**, **`windows/`**: Platform-specific folders.
    *   > [!NOTE]
    *   > While these folders exist, the app is primarily developed and tested on **Android**.

## internal Architecture

### State Management (`AppState`)
The `AppState` class (`lib/providers/app_state.dart`) is the central hub for:
*   **Auth State**: Managing the current user.
*   **Data Management**: Fetching, holding, and caching transaction groups and profiles.
*   **Real-time Listeners**: Setting up Firestore subscriptions for active groups.
*   **Business Logic**: Bridging UI actions with Firebase services.

### Deep Linking
Entry point `lib/main.dart` handles deep links (`https://splitter-2e1ae.web.app/join?token=...`) to allow seamless group joining.
