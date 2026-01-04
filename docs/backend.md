# Backend & Security

## Firebase Cloud Functions
Located in `functions/src/index.ts`.

*   **`createPublicProfile`**: triggered on `auth.user().onCreate`. Creates the public profile document.
*   **`addUserToGroup`**: HTTPS Callable. Validates an `inviteToken` and adds the calling user to the group's `sharedWith` list.

## Security Rules
> [!IMPORTANT]
> **Firestore Security Rules are NOT currently tracked in this repository.**
> They are managed directly in the Firebase Console.
>
> *Future Todo*: Export rules to `firestore.rules` for version control.
