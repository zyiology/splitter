// lib/models/transaction.dart

class SplitterTransaction {
  final String? id; // Primary key
  final double amount;
  final String payer;
  final List<String> payees;
  final String currencySymbol;
  final double? tax;
  final double? serviceCharge;
  final bool isPending; // For offline operations

  SplitterTransaction({
    this.id,
    required this.amount,
    required this.payer,
    required this.payees,
    required this.currencySymbol,
    this.tax = 0.0,
    this.serviceCharge = 0.0,
    this.isPending = false,
  });

  Map<String, dynamic> toMap() {
    return {
      'amount': amount,
      'payer': payer,
      'payees': payees.join(','), // Store as comma-separated string
      'currency': currencySymbol,
      'tax': tax ?? 0.0,
      'serviceCharge': serviceCharge ?? 0.0,
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
      tax: (map['tax'] != null) ? (map['tax'] as num).toDouble() : 0.0,
      serviceCharge: (map['serviceCharge'] != null) ? (map['serviceCharge'] as num).toDouble() : 0.0,
      isPending: false, // Firestore data is never pending
    );
  }

  SplitterTransaction copyWith({
    String? id,
    double? amount,
    String? payer,
    List<String>? payees,
    String? currencySymbol,
    double? tax,
    double? serviceCharge,
    bool? isPending,
  }) {
    return SplitterTransaction(
      id: id ?? this.id,
      amount: amount ?? this.amount,
      payer: payer ?? this.payer,
      payees: payees ?? this.payees,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      tax: tax ?? this.tax,
      serviceCharge: serviceCharge ?? this.serviceCharge,
      isPending: isPending ?? this.isPending,
    );
  }
}
