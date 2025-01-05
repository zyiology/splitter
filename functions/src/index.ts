import * as functions from "firebase-functions/v1"; // Explicitly import v1
import * as admin from "firebase-admin";

// Initialize the Firebase Admin SDK
admin.initializeApp();

// Define the data interface for adding a user to a group
interface AddUserToGroupData {
  inviteToken: string;
}

// Callable HTTPS Function: addUserToGroup
export const addUserToGroup = functions.https.onCall(
  async (data: AddUserToGroupData, context) => {
    // 1. Check if the user is authenticated
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to call this function."
      );
    }

    // 2. Extract and validate the inviteToken
    const {inviteToken} = data;
    if (typeof inviteToken !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Must provide a valid inviteToken string."
      );
    }

    const userId = context.auth.uid;

    try {
      // 3. Query the transaction_groups collection for the inviteToken
      const snapshot = await admin
        .firestore()
        .collection("transaction_groups")
        .where("inviteToken", "==", inviteToken)
        .limit(1)
        .get();

      if (snapshot.empty) {
        throw new functions.https.HttpsError(
          "not-found",
          "No transaction group found with the provided invite token."
        );
      }

      // 4. Retrieve the group ID from the first matching document
      const groupDoc = snapshot.docs[0];
      const groupId = groupDoc.id;

      // 5. Add the user to the sharedWith array in the transaction group
      await admin
        .firestore()
        .collection("transaction_groups")
        .doc(groupId)
        .update({
          sharedWith: admin.firestore.FieldValue.arrayUnion(userId),
        });

      return {success: true, groupId};
    } catch (error) {
      console.error("Error adding user to group:", error);
      throw new functions.https.HttpsError(
        "unknown",
        "An unknown error occurred while adding user to group."
      );
    }
  }
);

// Auth Trigger: createPublicProfile
export const createPublicProfile = functions.auth.user().onCreate((user) => {
  // Define the public profile data
  const publicProfile = {
    userId: user.uid,
    displayName: user.displayName || "No Name",
    photoURL: user.photoURL || null,
    // Add more public fields here if necessary
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  };

  // Create a document in the publicProfiles collection with the user's UID
  return admin
    .firestore()
    .collection("publicProfiles")
    .doc(user.uid)
    .set(publicProfile)
    .then(() => {
      console.log(`PublicProfile created for user: ${user.uid}`);
    })
    .catch((error) => {
      console.error(`Error creating PublicProfile
         for user ID ${user.uid}:`, error);
      // It's good practice to let the error propagate to ensure proper handling
      throw new functions.https.HttpsError(
        "internal",
        "Failed to create PublicProfile."
      );
    });
});
