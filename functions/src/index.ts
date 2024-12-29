import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

// Make sure you initialize your admin app
admin.initializeApp();

interface AddUserToGroupData {
    inviteToken: string;
}

export const addUserToGroup = functions.https.onCall(
  async (request: functions.https.CallableRequest<AddUserToGroupData>) => {
    // 1. Check if the user is authenticated
    if (!request.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be authenticated to call this function."
      );
    }

    // 2. Extract parameters from data
    // const { inviteToken } = request.data ?? {};
    const inviteToken = request.data?.inviteToken;
    if (typeof inviteToken !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Must provide a valid inviteToken string."
      );
    }

    const userId = request.auth.uid;

    try {
      // 3. Find the transaction group by inviteToken
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

      // 4. We only expect one doc if we used limit(1)
      const groupDoc = snapshot.docs[0];
      const groupId = groupDoc.id;

      // 5. Update the transaction group to add the user
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
