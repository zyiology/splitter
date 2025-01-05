// migrate_public_profiles.js
const admin = require('firebase-admin');
const fs = require('fs');

// Initialize Firebase Admin with service account
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const firestore = admin.firestore();
const auth = admin.auth();

async function migratePublicProfiles() {
  try {
    // Fetch all users. This might require pagination if you have many users.
    let users = [];
    let nextPageToken;
    do {
      const listUsersResult = await auth.listUsers(1000, nextPageToken);
      users = users.concat(listUsersResult.users);
      nextPageToken = listUsersResult.pageToken;
    } while (nextPageToken);

    console.log(`Total users fetched: ${users.length}`);

    for (const user of users) {
      const userId = user.uid;

      // Check if publicProfile already exists
      const profileRef = firestore.collection('publicProfiles').doc(userId);
      const doc = await profileRef.get();

      if (!doc.exists) {
        const publicProfile = {
          userId: userId,
          displayName: user.displayName || 'No Name',
          photoURL: user.photoURL || null,
          // Add more fields if necessary
        };

        await profileRef.set(publicProfile);
        console.log(`Created PublicProfile for user: ${userId}`);
      } else {
        console.log(`PublicProfile already exists for user: ${userId}`);
      }
    }

    console.log('Migration completed successfully.');
    process.exit(0);
  } catch (error) {
    console.error('Error during migration:', error);
    process.exit(1);
  }
}

migratePublicProfiles();
