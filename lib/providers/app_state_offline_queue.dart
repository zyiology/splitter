part of 'app_state.dart';

extension AppStateOfflineQueue on AppState {
  // Getter for pending operations count (for UI indicators)
  int get pendingOperationsCount =>
      _offlineQueueService.pendingOperations.length;
  bool get hasPendingOperations => _offlineQueueService.hasPendingOperations;

  // Process offline operations queue
  Future<void> _processOfflineQueue() async {
    final operationsToProcess =
        await _offlineQueueService.getOperationsToProcess();

    for (final operation in operationsToProcess) {
      try {
        await _executeOfflineOperation(operation);
        await _offlineQueueService.removeOperation(operation.id);
        print('Successfully processed offline operation: ${operation.type}');
      } catch (e) {
        print('Failed to process offline operation ${operation.id}: $e');
        await _offlineQueueService.incrementRetryCount(operation.id);

        if (operation.retryCount >= 2) {
          print('Operation ${operation.id} exceeded max retries, will be removed');
        }
      }
    }

    // Clean up failed operations
    await _offlineQueueService.clearFailedOperations();
    this._notify();
  }

  Future<void> _executeOfflineOperation(OfflineOperation operation) async {
    switch (operation.type) {
      case 'add_transaction':
        await firestore
            .collection('transaction_groups')
            .doc(operation.groupId)
            .collection('transactions')
            .add(operation.data);
        break;
      case 'add_participant':
        await firestore
            .collection('transaction_groups')
            .doc(operation.groupId)
            .collection('participants')
            .add(operation.data);
        break;
      case 'add_currency_rate':
        await firestore
            .collection('transaction_groups')
            .doc(operation.groupId)
            .collection('currency_rates')
            .add(operation.data);
        break;
      default:
        throw Exception('Unknown operation type: ${operation.type}');
    }
  }
}
