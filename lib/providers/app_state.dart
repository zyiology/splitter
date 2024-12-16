// lib/providers/app_state.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/currency_rate.dart';
import "../models/transaction_group.dart";
import '../services/settlement_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;

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
    });
  }

  void setupTransactionGroupListeners() {

    // Listen to participants
    firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('participants')
      .snapshots()
      .listen((snapshot) {
        participants = snapshot.docs.map((doc) => doc['name'].toString()).toList();
        notifyListeners();
    });

    // Listen to currency rates
    firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('currency_rates')
      .snapshots()
      .listen((snapshot) {
        currencyRates = snapshot.docs.map((doc) {
          return CurrencyRate(
            symbol: doc['symbol'],
            rate: doc['rate'],
          );
        }).toList();
        notifyListeners();
    });

    // Listen to transactions
    firestore
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
    });
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
    await firestore
      .collection('transaction_groups')
      .doc(id)
      .delete();
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

  Future<void> addCurrencyRate(String symbol, double rate) async {
    await firestore
      .collection('transaction_groups')
      .doc(_currentTransactionGroup!.id)
      .collection('currency_rates')
      .add({'symbol': symbol, 'rate': rate});
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

  void toggleView([bool? newShowTransactions]) {
    _showTransactions = newShowTransactions ?? !_showTransactions;
    notifyListeners();
  }
}
