// lib/main.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/app_state.dart';
import 'screens/home_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();

void main() async {
  print("Initializing Firebase...");
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    runApp(
      ChangeNotifierProvider(
        create: (_) => AppState(),
        child: TransactionSettlementApp(),
      ),
    );
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
  
  // print("running app...");
  // runApp(
  //   ChangeNotifierProvider(
  //     create: (_) => AppState(),
  //     child: TransactionSettlementApp(),
  //   ),
  // );
}


class TransactionSettlementApp extends StatelessWidget {
  const TransactionSettlementApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Transaction Settlement',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: Consumer<AppState>(
        builder: (context, appState, _) {
          print("Building main app with isLoading: ${appState.isLoading}");
          return HomeScreen();
        },
      ),
      scaffoldMessengerKey: scaffoldMessengerKey,
    );
  }
}
