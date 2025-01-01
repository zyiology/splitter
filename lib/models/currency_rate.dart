// lib/models/currency_rate.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class CurrencyRate {
  final String? id;
  final String symbol;
  double rate;

  CurrencyRate({
    this.id, 
    required this.symbol, 
    this.rate = 1.0
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'symbol': symbol,
      'rate': rate,
    };
  }

  factory CurrencyRate.fromMap(Map<String, dynamic> map) {
    return CurrencyRate(
      id: map['id'],
      symbol: map['symbol'],
      rate: map['rate'],
    );
  }

  factory CurrencyRate.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return CurrencyRate(
      id: doc.id,
      symbol: data['symbol'],
      rate: data['rate'],
    );
  }
}
