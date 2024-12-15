// lib/providers/app_state.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/currency_rate.dart';
import '../services/settlement_service.dart';

class AppState extends ChangeNotifier {
  List<String> participants = [];
  List<CurrencyRate> currencyRates = [];
  List<Transaction> transactions = [];
  List<Settlement> settlements = [];

  void addParticipant(String name) {
    if (!participants.contains(name.toLowerCase())) {
      participants.add(name.toLowerCase());
      notifyListeners();
    }
  }

  void removeParticipant(String name) {
    participants.remove(name.toLowerCase());
    notifyListeners();
  }

  void setCurrencyRate(String symbol, double rate) {
    var existing = currencyRates.firstWhere(
        (c) => c.symbol == symbol,
        orElse: () => CurrencyRate(symbol: symbol));
    existing.rate = rate;
    notifyListeners();
  }

  void addTransaction(Transaction transaction) {
    transactions.add(transaction);
    notifyListeners();
  }

  void calculateSettlements() {
    Map<String, double> rateMap = {
      for (var c in currencyRates) c.symbol: c.rate
    };
    SettlementService service = SettlementService(
      transactions: transactions,
      participants: participants,
      currencyRates: rateMap,
    );
    settlements = service.calculateSettlements();
    notifyListeners();
  }

  void clearData() {
    transactions.clear();
    settlements.clear();
    notifyListeners();
  }
}
