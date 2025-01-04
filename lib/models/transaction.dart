// lib/models/transaction.dart

class SplitterTransaction {
  final String? id; // Primary key
  final double amount;
  final String payer;
  final List<String> payees;
  final String currencySymbol;

  SplitterTransaction({
    this.id,
    required this.amount,
    required this.payer,
    required this.payees,
    required this.currencySymbol,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'payer': payer,
      'payees': payees.join(','), // Store as comma-separated string
      'currency': currencySymbol,
    };
  }

  factory SplitterTransaction.fromMap(String id, Map<String, dynamic> map) {
    return SplitterTransaction(
      id: id,
      amount: (map['amount'] as num).toDouble(),
      payer: map['payer'],
      // payees: List<String>.from(map['payees']), // Restore from comma-separated string
      payees: (map['payees'] as String).split(','), // Restore from comma-separated string
      currencySymbol: map['currency'],
    );
  }
}
