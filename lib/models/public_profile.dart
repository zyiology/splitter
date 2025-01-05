// lib/models/public_profile.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class PublicProfile {
  final String? id; // Document ID
  final String userId; // Firebase Auth User ID
  final String displayName;
  final String? photoURL; // Optional: User's profile photo URL

  PublicProfile({
    this.id,
    required this.userId,
    required this.displayName,
    this.photoURL,
  });

  // Factory constructor to create a PublicProfile from Firestore document
  factory PublicProfile.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return PublicProfile(
      id: doc.id,
      userId: data['userId'] as String,
      displayName: data['displayName'] as String,
      photoURL: data['photoURL'] as String?,
    );
  }

  // Convert PublicProfile to a map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'displayName': displayName,
      'photoURL': photoURL,
    };
  }
}
