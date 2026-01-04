part of 'app_state.dart';

extension AppStateTransactions on AppState {
  bool get showTransactions => _showTransactions;

  // Transactions
  Future<String> addTransaction(SplitterTransaction transaction) async {
    try {
      // Always try online first
      DocumentReference docRef = await firestore
          .collection('transaction_groups')
          .doc(_currentTransactionGroup!.id)
          .collection('transactions')
          .add(transaction.toMap());

      return docRef.id;
    } catch (e) {
      // If it fails due to network issues, queue for later
      if (e is FirebaseException &&
          (e.code == 'unavailable' ||
              e.code == 'deadline-exceeded' ||
              e.code == 'permission-denied')) {
        final operationId = await _offlineQueueService.createOperationId();
        final operation = OfflineOperation(
          id: operationId,
          type: 'add_transaction',
          groupId: _currentTransactionGroup!.id!,
          data: transaction.toMap(),
          timestamp: DateTime.now(),
        );

        await _offlineQueueService.queueOperation(operation);

        // Add to local state for immediate UI feedback with pending indicator
        final tempTransaction = transaction.copyWith(
          id: operationId,
          isPending: true,
        );
        transactions.add(tempTransaction);
        this._notify();

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Transaction saved offline. Will sync when connection is restored.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return operationId;
      }
      // Re-throw other errors (validation, permissions, etc.)
      rethrow;
    }
  }

  Future<void> removeTransaction(String id) async {
    if (user == null || !this.canModifyData()) return;

    await firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('transactions')
        .doc(id.toString())
        .delete();
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
    this._notify();
  }

  void toggleView([bool? showTransactions]) {
    _showTransactions = showTransactions ?? !_showTransactions;
    this._notify();
  }
}
