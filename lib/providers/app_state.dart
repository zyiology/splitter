// lib/providers/app_state.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:splitter/main.dart'; // Import for scaffoldMessengerKey
import 'package:splitter/models/currency_rate.dart';
import 'package:splitter/models/participant.dart';
import 'package:splitter/models/public_profile.dart';
import 'package:splitter/models/transaction.dart';
import 'package:splitter/models/transaction_group.dart';
import 'package:splitter/services/offline_queue_service.dart';
import 'package:splitter/services/settlement_service.dart';
import 'package:splitter/utils/input_utils.dart';

part 'app_state_auth.dart';
part 'app_state_connectivity.dart';
part 'app_state_groups.dart';
part 'app_state_participants.dart';
part 'app_state_currency_rates.dart';
part 'app_state_transactions.dart';
part 'app_state_profiles.dart';
part 'app_state_offline_queue.dart';

class AppState extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final List<StreamSubscription> _subscriptions = [];
  final OfflineQueueService _offlineQueueService = OfflineQueueService();

  // Connection state tracking
  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  String? pendingInviteToken;

  // cache for public profiles, to save on Firestore reads
  final Map<String, PublicProfile> _publicProfileCache = {};

  User? user;
  bool isLoading = true;
  StreamSubscription? _transactionGroupsSubscription;

  List<SplitterTransactionGroup> transactionGroups = [];
  SplitterTransactionGroup? _currentTransactionGroup;
  List<Participant> participants = [];
  List<CurrencyRate> currencyRates = [];
  List<SplitterTransaction> transactions = [];
  List<Settlement> settlements = [];
  bool _showTransactions = true;

  AppState() {
    this._initialize();
  }

  void _notify() {
    notifyListeners();
  }

  @override
  void dispose() {
    this._cancelAllSubscriptions();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}
