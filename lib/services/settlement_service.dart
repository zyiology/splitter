// lib/services/settlement_service.dart
import 'dart:collection';
// import 'package:decimal/decimal.dart'; // Add decimal support if needed
import '../models/transaction.dart';
import '../models/currency_rate.dart';

class SettlementService {
  final List<Transaction> transactions;
  final List<String> participants;
  final Map<String, double> currencyRates;

  SettlementService({
    required this.transactions,
    required this.participants,
    required this.currencyRates,
  });

  List<Settlement> calculateSettlements() {
    Map<String, double> balances = { for (var p in participants) p: 0.0 };

    for (var trans in transactions) {
      double rate = currencyRates[trans.currency] ?? 1.0;
      double amountInBase = trans.amount * rate;
      int numPayees = trans.payees.length;
      double splitAmount = numPayees > 0 ? amountInBase / numPayees : 0.0;

      for (var payee in trans.payees) {
        if (payee != trans.payer) {
          balances[payee] = (balances[payee] ?? 0) - splitAmount;
          balances[trans.payer] = (balances[trans.payer] ?? 0) + splitAmount;
        }
      }
    }

    List<Settlement> simplified = [];
    const double tolerance = 0.01;

    while (true) {
      String? maxCreditor;
      double maxCredit = 0.0;
      String? maxDebtor;
      double maxDebit = 0.0;

      balances.forEach((person, balance) {
        if (balance > maxCredit) {
          maxCredit = balance;
          maxCreditor = person;
        }
        if (balance < maxDebit) {
          maxDebit = balance;
          maxDebtor = person;
        }
      });

      if ((maxCredit - 0).abs() < tolerance &&
          (maxDebit - 0).abs() < tolerance) {
        break;
      }

      double amount = maxCredit < (-maxDebit) ? maxCredit : -maxDebit;
      amount = double.parse((amount).toStringAsFixed(2));

      if (maxCreditor != null && maxDebtor != null) {
        // Use non-null assertion operator '!' since we've checked for null
        simplified.add(Settlement(
          debtor: maxDebtor!,
          creditor: maxCreditor!,
          amount: amount,
        ));

        balances[maxCreditor!] = (balances[maxCreditor]! - amount);
        balances[maxDebtor!] = (balances[maxDebtor]! + amount);
      } else {
        break;
      }
    }

    return simplified;
  }
}

class Settlement {
  final String debtor;
  final String creditor;
  final double amount;

  Settlement({
    required this.debtor,
    required this.creditor,
    required this.amount,
  });
}
