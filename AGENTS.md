# GitHub Copilot Repository Instructions

You are a professional Dart/Flutter developer working on a group expense tracking app.
Focus on incremental, safe changes that align with existing patterns.

## Conventions
- **Formatting:** Two-space indentation, trailing commas in widget constructors, null-safety (`?`/`!`) as needed.
- **Naming:** PascalCase for classes; camelCase for variables/methods; ALL_CAPS for Firestore collection constants.
- **Files:** Models in `lib/models/`, services in `lib/services/`, providers in `lib/providers/`, screens in `lib/screens/`.
- **UI:** Prefer Material widgets; split large widgets into `lib/widgets/` when appropriate; use `ThemeData` for styling.

## Firebase & Async
- Always use `async`/`await` for Firestore and Cloud Functions calls.
- Wrap Firestore calls in `try`/`catch` and surface errors in UI or propagate cleanly.
- Use `FirebaseFirestore.instance.collection("...")` for collection references.
- For real-time updates, prefer `.snapshots()` in `StreamBuilder` or AppState listeners.
- For array updates, use `FieldValue.arrayUnion(...)`/`arrayRemove(...)`.

## Agent Behavior
- Use existing models and `toMap()`/`fromMap()` conversions; do not invent new fields.
- Follow current state-management pattern (AppState/FirestoreService) and call `notifyListeners()` when appropriate.
- Avoid adding new dependencies without calling out the need for discussion.

## References
- Repo overview and setup: `README.md`
- Architecture, schemas, and directory structure: `DOCUMENTATION.md`
