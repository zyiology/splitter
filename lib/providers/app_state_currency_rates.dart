part of 'app_state.dart';

extension AppStateCurrencyRates on AppState {
  /// Adds a new currency exchange rate to a transaction group's currency rates collection.
  ///
  /// [symbol] The currency symbol/code (e.g. "USD", "EUR")
  /// [rate] The exchange rate relative to the base currency
  /// [groupId] Optional transaction group ID. If not provided, uses current group
  Future<CurrencyRate?> addCurrencyRate(
    String symbol,
    double rate, {
    String? groupId,
  }) async {
    // check if the currency rate already exists
    if (currencyRates.any((c) => c.symbol == symbol)) {
      return null;
    }

    final currencyData = {'symbol': symbol, 'rate': rate};
    final targetGroupId = groupId ?? _currentTransactionGroup!.id!;

    try {
      // Always try online first
      DocumentReference docRef = await firestore
          .collection('transaction_groups')
          .doc(targetGroupId)
          .collection('currency_rates')
          .add(currencyData);

      DocumentSnapshot doc = await docRef.get();
      return CurrencyRate.fromFirestore(doc);
    } catch (e) {
      // If it fails due to network issues, queue for later
      if (e is FirebaseException &&
          (e.code == 'unavailable' ||
              e.code == 'deadline-exceeded' ||
              e.code == 'permission-denied')) {
        final operationId = await _offlineQueueService.createOperationId();
        final operation = OfflineOperation(
          id: operationId,
          type: 'add_currency_rate',
          groupId: targetGroupId,
          data: currencyData,
          timestamp: DateTime.now(),
        );

        await _offlineQueueService.queueOperation(operation);

        // Add to local state for immediate UI feedback
        final tempCurrencyRate =
            CurrencyRate(id: operationId, symbol: symbol, rate: rate);
        currencyRates.add(tempCurrencyRate);
        this._notify();

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Currency rate saved offline. Will sync when connection is restored.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return tempCurrencyRate;
      }
      // Re-throw other errors
      rethrow;
    }
  }

  Future<bool> updateCurrencyRate(String id, double rate) async {
    if (!this.canModifyData()) return false;

    try {
      await firestore
          .collection('transaction_groups')
          .doc(_currentTransactionGroup!.id)
          .collection('currency_rates')
          .doc(id)
          .update({'rate': rate});
      return true;
    } catch (e) {
      print('Error updating currency rate: $e');
      return false;
    }
  }

  Future<bool> removeCurrencyRate(CurrencyRate currencyRate) async {
    if (user == null || !this.canModifyData()) return false;

    // Check if currency is default currency
    if (_currentTransactionGroup!.defaultCurrencyId == currencyRate.id) {
      return false;
    }

    // Check if currency rate is currently being used in any transactions
    for (var transaction in transactions) {
      if (transaction.currencySymbol == currencyRate.symbol) {
        return false;
      }
    }

    await firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('currency_rates')
        .doc(currencyRate.id)
        .delete();

    return true;
  }

  String getCurrentTransactionCurrencySymbol() {
    if (this.currentTransactionGroup == null) return '';
    String id = this.currentTransactionGroup!.defaultCurrencyId!;
    if (id.isEmpty) return '';
    if (currencyRates.isEmpty) return '';
    try {
      CurrencyRate currencyRate = currencyRates.firstWhere(
        (element) => element.id == id,
        orElse: () => CurrencyRate(id: '', symbol: '', rate: 0),
      );
      return currencyRate.symbol;
    } catch (e) {
      return '';
    }
  }
}
