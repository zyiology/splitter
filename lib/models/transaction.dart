// lib/models/transaction.dart
import 'dart:ffi';

import 'package:flutter/foundation.dart';

class SplitterTransaction {
  final String? id; // Primary key
  final double amount;
  final String payer;
  final List<String> payees;
  final String currency;

  SplitterTransaction({
    this.id,
    required this.amount,
    required this.payer,
    required this.payees,
    required this.currency,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'payer': payer,
      'payees': payees.join(','), // Store as comma-separated string
      'currency': currency,
    };
  }

  factory SplitterTransaction.fromMap(String id, Map<String, dynamic> map) {
    return SplitterTransaction(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      payer: map['payer'],
      // payees: List<String>.from(map['payees']), // Restore from comma-separated string
      payees: (map['payees'] as String).split(','), // Restore from comma-separated string
      currency: map['currency'],
    );
  }
}
