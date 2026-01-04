part of 'app_state.dart';

extension AppStateProfiles on AppState {
  Future<List<String>> fetchUserNames(List<String> ids) async {
    print("Fetching user names for ids: $ids");
    if (ids.isEmpty) return [];

    // Fetch all names in parallel
    List<String> names = await Future.wait(ids.map((id) => fetchUserName(id)));

    return names;
  }

  Future<String> fetchUserName(String id) async {
    DocumentSnapshot doc =
        await firestore.collection('publicProfiles').doc(id).get();
    return doc['displayName'] as String;
  }

  Future<PublicProfile?> getPublicProfile(String userId) async {
    if (_publicProfileCache.containsKey(userId)) {
      return _publicProfileCache[userId];
    }

    try {
      final doc = await firestore.collection('publicProfiles').doc(userId).get();

      if (doc.exists) {
        final profile = PublicProfile.fromDocument(doc);
        _publicProfileCache[userId] = profile;
        return profile;
      } else {
        // Handle missing publicProfile, possibly log or notify
        print('PublicProfile not found for user: $userId');
        return null;
      }
    } catch (e) {
      print('Error fetching PublicProfile: $e');
      return null;
    }
  }
}
