// lib/models/transaction_group.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class SplitterTransactionGroup {
  final String? id; // Primary key
  final String owner;
  final String ownerName;
  final List<String> sharedWith;
  final String groupName;
  final DateTime createdAt;
  final String inviteToken;

  SplitterTransactionGroup({
    this.id,
    required this.owner,
    required this.ownerName,
    required this.sharedWith,
    required this.groupName,
    required this.createdAt,
    required this.inviteToken,
  });

  // Factory constructor to create a TransactionGroup from Firestore Document
  factory SplitterTransactionGroup.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;
    return SplitterTransactionGroup(
      id: doc.id,
      owner: data['owner'] as String,
      ownerName: data['ownerName'] as String,
      sharedWith: List<String>.from(data['sharedWith'] ?? []),
      groupName: data['groupName'] as String,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      inviteToken: data['inviteToken'] as String,
    );
  }

  // Method to convert TransactionGroup to a Map for Firestore
  Map<String, dynamic> toFirestore() {
    return {
      'owner': owner,
      'ownerName': ownerName,
      'sharedWith': sharedWith,
      'groupName': groupName,
      'createdAt': Timestamp.fromDate(createdAt),
      'inviteToken': inviteToken,
    };
  }

  SplitterTransactionGroup copyWith({
    String? id,
    String? owner,
    String? ownerName,
    List<String>? sharedWith,
    String? groupName,
    DateTime? createdAt,
    String? inviteToken,
  }) {
    return SplitterTransactionGroup(
      id: id ?? this.id,
      owner: owner ?? this.owner,
      ownerName: ownerName ?? this.ownerName,
      sharedWith: sharedWith ?? this.sharedWith,
      groupName: groupName ?? this.groupName,
      createdAt: createdAt ?? this.createdAt,
      inviteToken: inviteToken ?? this.inviteToken,
    );
  }
}
