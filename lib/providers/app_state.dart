// lib/providers/app_state.dart
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/transaction.dart';
import '../models/currency_rate.dart';
import "../models/transaction_group.dart";
import '../services/settlement_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';


class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<StreamSubscription> _subscriptions = [];

  User? user;
  bool isLoading = true;

  List<SplitterTransactionGroup> transactionGroups = [];
  // String currentTransactionGroup!.id = '';
  SplitterTransactionGroup? _currentTransactionGroup;
  List<String> participants = [];
  List<CurrencyRate> currencyRates = [];
  List<SplitterTransaction> transactions = [];
  List<Settlement> settlements = [];
  bool _showTransactions = true;
  bool get showTransactions => _showTransactions;

  AppState() {
    _initialize();
  }

  void updateCurrentTransactionGroup(SplitterTransactionGroup transactionGroup) {
    // Cancel existing subscriptions
    _cancelAllSubscriptions();

    _currentTransactionGroup = transactionGroup;
    setupTransactionGroupListeners();
    notifyListeners();
  }
  
  SplitterTransactionGroup? get currentTransactionGroup => _currentTransactionGroup;

  Future<void> _initialize() async {
    print('Initializing AppState...');

    // have to handle initial state else there's a race condition?
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      user = currentUser;
      _listenTransactionGroups();
    }

    _auth.authStateChanges().listen((User? newUser) {
      print('Auth state changed: ${newUser?.uid}');
      user = newUser;

      // only set up Firestore listeners if user is logged in
      if (user != null) {
        _listenTransactionGroups();
      } else {
        participants = [];
        currencyRates = [];
        transactions = [];
        settlements = [];
      }
      notifyListeners();
      print('isLoading: $isLoading');
    });
    
    isLoading = false;
    notifyListeners();
  }

  void _listenTransactionGroups() {
    firestore.collection('transaction_groups').where('sharedWith', arrayContains: user!.uid).snapshots().listen((snapshot) {
      transactionGroups = snapshot.docs.map((doc) {
        return SplitterTransactionGroup.fromFirestore(doc);
      }).toList();
      notifyListeners();
    }, onError: (error) {
      print('Error fetching transaction groups: $error');
    });
  }

  // Add this method inside _HomeScreenState
  // Future<List<String>> fetchUserNames(List<String> userIds) async {
  //   if (userIds.isEmpty) return [];
  //   QuerySnapshot snapshot = await FirebaseFirestore.instance
  //       .collection('users')
  //       .where(FieldPath.documentId, whereIn: userIds)
  //       .get();
  //   return snapshot.docs.map((doc) => doc['displayName'] as String).toList();
  // }

  void setupTransactionGroupListeners() {

    // Listen to participants
    StreamSubscription participantsSubscription = firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('participants')
      .snapshots()
      .listen((snapshot) {
        participants = snapshot.docs.map((doc) => doc['name'].toString()).toList();
        notifyListeners();
    }, onError: (error) {
      print('Error fetching participants: $error');
    });

    _subscriptions.add(participantsSubscription);

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
        notifyListeners();
    }, onError: (error) {
      print('Error fetching currency rates: $error');
    });

    _subscriptions.add(currencyRatesSubscription);

    // Listen to transactions
    StreamSubscription transactionsSubscription = firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('transactions')
      .snapshots()
      .listen((snapshot) {
      transactions = snapshot.docs.map((doc) {
        return SplitterTransaction.fromMap(
          doc.id,
          doc.data()
        );
      }).toList();
      notifyListeners();
    }, onError: (error) {
      print('Error fetching transactions: $error');
    });

    _subscriptions.add(transactionsSubscription);
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading = true;
      notifyListeners();

      // Trigger the auth flow
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();

      if (googleUser == null) {
        isLoading = false;
        notifyListeners();
        return;
      }

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in to Firebase with the Google [UserCredential]
      await _auth.signInWithCredential(credential);

      isLoading = false;
      notifyListeners();
    } catch (e) {
      isLoading = false;
      notifyListeners();
      print(e);
      // TODO handle error in production
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    // Clear any additional state if needed
    notifyListeners();
  }

  Future<SplitterTransactionGroup> addTransactionGroup(SplitterTransactionGroup transactionGroup) async {
    DocumentReference docRef = await firestore
      .collection('transaction_groups')
      .add(transactionGroup.toFirestore());
    return transactionGroup.copyWith(id: docRef.id);
  }

  Future<void> updateTransactionGroup(SplitterTransactionGroup transactionGroup) async {
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
    final updatedSharedWith = List<String>.from(transactionGroup.sharedWith)
      ..remove(user!.uid);

    // remove subscriptions if the current transaction group is being removed
    if (_currentTransactionGroup?.id == id) {
      _cancelAllSubscriptions();
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
    
    notifyListeners();
  }

  Future<void> addParticipant(String name) async {
    if (!participants.contains(name.toLowerCase()) && user != null) {
      await firestore
        .collection('transaction_groups')
        .doc(_currentTransactionGroup!.id)
        .collection('participants').add({
        'name': name.toLowerCase()
      });
    }
  }

  Future<void> removeParticipant(String id) async {
    if (user == null) return;
    await firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('participants')
      .doc(id)
      .delete();
  }

  /// Adds a new currency exchange rate to a transaction group's currency rates collection.
  /// 
  /// [symbol] The currency symbol/code (e.g. "USD", "EUR")
  /// [rate] The exchange rate relative to the base currency
  /// [groupId] Optional transaction group ID. If not provided, uses current group
  Future<CurrencyRate> addCurrencyRate(String symbol, double rate, {String? groupId}) async {
    DocumentReference docRef = await firestore
      .collection('transaction_groups')
      .doc(groupId ?? _currentTransactionGroup!.id)
      .collection('currency_rates')
      .add({'symbol': symbol, 'rate': rate});

    DocumentSnapshot doc = await docRef.get();
    return CurrencyRate.fromFirestore(doc);
  }

  Future<void> updateCurrencyRate(String id, double rate) async {
    await firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('currency_rates')
      .doc(id)
      .update({'rate': rate});
  }

  Future<void> removeCurrencyRate(String id) async {
    if (user == null) return;
    await firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('currency_rates')
      .doc(id)
      .delete();
  }

  String getCurrentTransactionCurrencySymbol() {
    if (currentTransactionGroup == null) return '';
    String id = currentTransactionGroup!.defaultCurrencyId!;
    if (id.isEmpty) return '';
    if (currencyRates.isEmpty) return '';
    try {
      CurrencyRate currencyRate = currencyRates.firstWhere(
        (element) => element.id == id,
        orElse: () => CurrencyRate(id: '', symbol: '', rate: 0), // Default value
      );
      return currencyRate.symbol;
    } catch (e) {
      return ''; // Fallback if anything goes wrong
    }
  }

  // Transactions
  Future<String> addTransaction(SplitterTransaction transaction) async {
    // await firestore.collection('transactions').add(transaction.toMap());
    DocumentReference docRef = await firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('transactions')
      .add(transaction.toMap());

    String transactionId = docRef.id;
    return transactionId;
  }

  Future<void> removeTransaction(String id) async {
    if (user == null) return;
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
    notifyListeners();
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

    notifyListeners();
  }

  void _cancelAllSubscriptions() {
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
  }

  void toggleView([bool? showTransactions]) {
    _showTransactions = showTransactions ?? !_showTransactions;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelAllSubscriptions();
    super.dispose();
  }
}
