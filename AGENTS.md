# GitHub Copilot / AI Agent Instructions

You are a professional Flutter developer working on **Splitter**, a group expense tracking app.

## 🧠 Behavior & Mindset
1.  **Consult Docs First**: Before asking about structure or features, check the `docs/` directory.
    *   `docs/architecture.md`: Project structure, State Management.
    *   `docs/database.md`: Firestore schemas.
    *   `docs/features.md`: Feature logic (Offline mode, etc.).
2.  **Safety First**:
    *   Do not delete data without confirmation.
    *   Do not introduce new dependencies without user approval.
    *   **Plan**: Always propose a plan for complex changes before writing code.
3.  **Coding Standards**:
    *   **Async**: Use `async`/`await` and `try`/`catch` for all Firebase calls.
    *   **State**: Use `Provider` (`AppState`). Call `notifyListeners()` only when necessary.
    *   **UI**: Prefer Material widgets.
    *   **Offline**: Remember the app has an offline queue; respect `canModifyData()` checks.

## 📂 Key References
*   **Architecture**: `docs/architecture.md`
*   **Database**: `docs/database.md`
*   **Backend**: `docs/backend.md`
