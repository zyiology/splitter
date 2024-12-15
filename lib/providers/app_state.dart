// lib/providers/app_state.dart
import 'package:flutter/material.dart';
import '../models/transaction.dart';
import '../models/currency_rate.dart';
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

  List<String> participants = [];
  List<CurrencyRate> currencyRates = [];
  List<SplitterTransaction> transactions = [];
  List<Settlement> settlements = [];
  bool _showTransactions = true;
  bool get showTransactions => _showTransactions;

  AppState() {
    _initialize();
  }

  Future<void> _initialize() async {
    print('Initializing AppState...');

    // have to handle initial state else there's a race condition?
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      user = currentUser;
      _setupFirestoreListeners();
    }

    _auth.authStateChanges().listen((User? newUser) {
      print('Auth state changed: ${newUser?.uid}');
      user = newUser;

      // only set up Firestore listeners if user is logged in
      if (user != null) {
        _setupFirestoreListeners();
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

  void _setupFirestoreListeners() {

    // Listen to participants
    firestore.collection('users').doc(user!.uid).collection('participants').snapshots().listen((snapshot) {
      participants = snapshot.docs.map((doc) => doc['name'].toString()).toList();
      notifyListeners();
    });

    // Listen to currency rates
    firestore.collection('users').doc(user!.uid).collection('currency_rates').snapshots().listen((snapshot) {
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
      .collection('users')
      .doc(user!.uid)
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

  Future<void> addParticipant(String name) async {
    if (!participants.contains(name.toLowerCase()) && user != null) {
      await firestore.collection('users').doc(user!.uid).collection('participants').add({
        'name': name.toLowerCase()
      });
    }
  }

  Future<void> removeParticipant(String id) async {
    if (user == null) return;
    await firestore
      .collection('users')
      .doc(user!.uid)
      .collection('participants')
      .doc(id)
      .delete();
  }

  // Future<void> setCurrencyRate(String symbol, double rate) async {
  //   if (user == null) return;
  //   await firestore
  //     .collection('users')
  //     .doc(user!.uid)
  //     .collection('currency_rates')
  //     .doc(symbol)
  //     .set({
  //   'rate': rate,
  // }, SetOptions(merge: true));
  // }

  Future<void> addCurrencyRate(String symbol, double rate) async {
    await firestore
      .collection('users')
      .doc(user!.uid)
      .collection('currency_rates')
      .add({'symbol': symbol, 'rate': rate});
  }

  Future<void> updateCurrencyRate(String id, double rate) async {
    await firestore
      .collection('users')
      .doc(user!.uid)
      .collection('currency_rates')
      .doc(id)
      .update({'rate': rate});
  }

  Future<void> removeCurrencyRate(String id) async {
    if (user == null) return;
    await firestore
      .collection('users')
      .doc(user!.uid)
      .collection('currency_rates')
      .doc(id)
      .delete();
    // QuerySnapshot snapshot = await firestore
    //   .collection('users')
    //   .doc(user!.uid)
    //   .collection('currency_rates')
    //   .where('symbol', isEqualTo: symbol)
    //   .get();
    // for (var doc in snapshot.docs) {
    //   await firestore.collection('currency_rates').doc(doc.id).delete();
    // }
  }

  // Transactions
  Future<String> addTransaction(SplitterTransaction transaction) async {
    // await firestore.collection('transactions').add(transaction.toMap());
    DocumentReference docRef = await firestore
      .collection('users')
      .doc(_auth.currentUser!.uid)
      .collection('transactions')
      .add(transaction.toMap());

    String transactionId = docRef.id;
    return transactionId;
  }

  Future<void> removeTransaction(String id) async {
    if (user == null) return;
    await firestore
      .collection('users')
      .doc(user!.uid)
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
        .collection('users')
        .doc(user!.uid)
        .collection('participants')
        .get();
    for (var doc in participantsSnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete currency_rates
    QuerySnapshot currencySnapshot = await firestore
        .collection('users')
        .doc(user!.uid)
        .collection('currency_rates')
        .get();
    for (var doc in currencySnapshot.docs) {
      batch.delete(doc.reference);
    }

    // Delete transactions
    QuerySnapshot transactionsSnapshot = await firestore
        .collection('users')
        .doc(user!.uid)
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

  void toggleView() {
    _showTransactions = !_showTransactions;
    notifyListeners();
  }
}
