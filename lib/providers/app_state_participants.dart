part of 'app_state.dart';

extension AppStateParticipants on AppState {
  Future<void> addParticipant(String name) async {
    // sanitize the input
    name = InputUtils.sanitizeString(name);

    if (participants.any((p) => p.name == name.toLowerCase()) || user == null) {
      return; // Participant already exists or user not logged in
    }

    final participantData = {'name': name.toLowerCase()};

    try {
      // Always try online first
      await firestore
          .collection('transaction_groups')
          .doc(_currentTransactionGroup!.id)
          .collection('participants')
          .add(participantData);
    } catch (e) {
      // If it fails due to network issues, queue for later
      if (e is FirebaseException &&
          (e.code == 'unavailable' ||
              e.code == 'deadline-exceeded' ||
              e.code == 'permission-denied')) {
        final operationId = await _offlineQueueService.createOperationId();
        final operation = OfflineOperation(
          id: operationId,
          type: 'add_participant',
          groupId: _currentTransactionGroup!.id!,
          data: participantData,
          timestamp: DateTime.now(),
        );

        await _offlineQueueService.queueOperation(operation);

        // Add to local state for immediate UI feedback
        final tempParticipant = Participant(
          id: operationId,
          name: name.toLowerCase(),
          isPending: true,
        );
        participants.add(tempParticipant);
        this._notify();

        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              'Participant saved offline. Will sync when connection is restored.',
            ),
            backgroundColor: Colors.orange,
          ),
        );

        return;
      }
      // Re-throw other errors
      rethrow;
    }
  }

  Future<bool> removeParticipant(Participant participant) async {
    if (user == null || !this.canModifyData()) return false;

    // check if participant is currently being used in any transactions
    for (var transaction in transactions) {
      print('Checking transaction. Payer: ${transaction.payer}, Payees: ${transaction.payees}');
      if (transaction.payer == participant.name ||
          transaction.payees.contains(participant.name)) {
        return false;
      }
    }

    await firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('participants')
        .doc(participant.id)
        .delete();

    return true;
  }
}
