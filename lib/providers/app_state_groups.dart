part of 'app_state.dart';

extension AppStateGroups on AppState {
  void updateCurrentTransactionGroup(SplitterTransactionGroup transactionGroup) {
    print('Updating current transaction group: ${transactionGroup.id}');
    // Cancel existing subscriptions
    this._cancelAllSubscriptions();

    _currentTransactionGroup = transactionGroup;
    setupTransactionGroupListeners();
    this._notify();
  }

  SplitterTransactionGroup? get currentTransactionGroup => _currentTransactionGroup;

  void _listenTransactionGroups() {
    _transactionGroupsSubscription = firestore
        .collection('transaction_groups')
        .where('sharedWith', arrayContains: user!.uid)
        .snapshots()
        .listen((snapshot) {
      transactionGroups = snapshot.docs.map((doc) {
        return SplitterTransactionGroup.fromFirestore(doc);
      }).toList();
      this._notify();
    }, onError: (error) {
      print('Error fetching transaction groups: $error');
    });
  }

  void setupTransactionGroupListeners() {
    print('Setting up listeners for transaction group: ${_currentTransactionGroup!.id}');

    // Listen to participants
    StreamSubscription participantsSubscription = firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('participants')
        .snapshots()
        .listen((snapshot) {
      participants = snapshot.docs.map((doc) {
        return Participant.fromFirestore(doc.id, doc.data());
      }).toList();
      this._notify();
    }, onError: (error) {
      print('Error fetching participants: $error');
    });

    _subscriptions.add(participantsSubscription);
    print('listening to participants');

    // Listen to currency rates
    StreamSubscription currencyRatesSubscription = firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('currency_rates')
        .snapshots()
        .listen((snapshot) {
      currencyRates = snapshot.docs.map((doc) {
        return CurrencyRate(
          id: doc.id,
          symbol: doc['symbol'],
          rate: doc['rate'],
        );
      }).toList();
      this._notify();
    }, onError: (error) {
      print('Error fetching currency rates: $error');
    });

    _subscriptions.add(currencyRatesSubscription);
    print('listening to currency rates');

    // Listen to transactions
    StreamSubscription transactionsSubscription = firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('transactions')
        .snapshots()
        .listen((snapshot) {
      transactions = snapshot.docs.map((doc) {
        return SplitterTransaction.fromMap(doc.id, doc.data());
      }).toList();
      this._notify();
    }, onError: (error) {
      print('Error fetching transactions: $error');
    });

    _subscriptions.add(transactionsSubscription);
    print('listening to transactions');
  }

  Future<SplitterTransactionGroup> addTransactionGroup(
    SplitterTransactionGroup transactionGroup,
  ) async {
    DocumentReference docRef = await firestore
        .collection('transaction_groups')
        .add(transactionGroup.toFirestore());
    return transactionGroup.copyWith(id: docRef.id);
  }

  Future<void> updateTransactionGroup(
    SplitterTransactionGroup transactionGroup,
  ) async {
    await firestore
        .collection('transaction_groups')
        .doc(transactionGroup.id)
        .update(transactionGroup.toFirestore());
  }

  Future<void> removeTransactionGroup(String id) async {
    final docRef = firestore.collection('transaction_groups').doc(id);
    final doc = await docRef.get();
    if (!doc.exists) return;

    // remove the user from the sharedWith list
    final transactionGroup = SplitterTransactionGroup.fromFirestore(doc);
    final updatedSharedWith =
        List<String>.from(transactionGroup.sharedWith)..remove(user!.uid);

    // remove subscriptions if the current transaction group is being removed
    if (_currentTransactionGroup?.id == id) {
      this._cancelAllSubscriptions();
      _currentTransactionGroup = null;
      participants = [];
      currencyRates = [];
      transactions = [];
      settlements = [];
    }

    if (updatedSharedWith.isEmpty) {
      await docRef.delete();
    } else {
      await docRef.update({'sharedWith': updatedSharedWith});
    }

    this._notify();
  }

  Future<void> clearData() async {
    // Implement logic to clear all data from Firestore
    if (user == null) return;

    WriteBatch batch = firestore.batch();

    // Delete participants
    QuerySnapshot participantsSnapshot = await firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('participants')
        .get();
    for (var doc in participantsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete currency_rates
    QuerySnapshot currencySnapshot = await firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('currency_rates')
        .get();
    for (var doc in currencySnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete transactions
    QuerySnapshot transactionsSnapshot = await firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('transactions')
        .get();
    for (var doc in transactionsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    await batch.commit();

    // Clear local state
    settlements.clear();

    this._notify();
  }

  void _cancelAllSubscriptions() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    _transactionGroupsSubscription?.cancel();
  }

  Future<bool> joinTransactionGroup(String inviteToken) async {
    try {
      // Get a reference to the function using the Firebase Functions
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'addUserToGroup',
      );

      // Call the function
      final result = await callable.call(<String, dynamic>{
        'inviteToken': inviteToken,
      });

      // Check the result
      final data = result.data as Map<String, dynamic>;
      if (data['success'] == true) {
        String groupId = data['groupId'];
        print('Successfully joined group: $groupId');
        return true;
      } else {
        return false;
      }
    } on FirebaseFunctionsException catch (e) {
      print('FirebaseFunctionsException: ${e.code} - ${e.message}');
      return false;
    } catch (e) {
      print('Error joining transaction group: $e');
      return false;
    }
    // QuerySnapshot<Map<String, dynamic>> snapshot = await firestore
    //   .collection('transaction_groups')
    //   .where('inviteToken', isEqualTo: inviteToken)
    //   .limit(1)
    //   .get();

    // if (snapshot.docs.isNotEmpty) {
    //   DocumentSnapshot<Map<String, dynamic>> doc = snapshot.docs.first;
    //   SplitterTransactionGroup transactionGroup = SplitterTransactionGroup.fromFirestore(doc);
    //   try {
    //     await firestore
    //       .collection('transaction_groups')
    //       .doc(transactionGroup.id)
    //       .update({
    //         'sharedWith': FieldValue.arrayUnion([user!.uid])
    //       });
    //     return true;
    //   } catch (e) {
    //     print('Error joining transaction group: $e');
    //     return false;
    //   }
    // }
    // return false;
  }
}
