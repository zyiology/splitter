// lib/models/transaction.dart
import 'package:flutter/foundation.dart';

class Transaction {
  final double amount;
  final String payer;
  final List<String> payees;
  final String currency;

  Transaction({
    required this.amount,
    required this.payer,
    required this.payees,
    required this.currency,
  });
}
