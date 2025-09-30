// lib/main.dart
import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
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
        child: AppWithLinkHandler(), // Changed to AppWithLinkHandler
      ),
    );
  } catch (e) {
    print("Firebase initialization failed: $e");
  }
}

class AppWithLinkHandler extends StatefulWidget {
  @override
  _AppWithLinkHandlerState createState() => _AppWithLinkHandlerState();
}

class _AppWithLinkHandlerState extends State<AppWithLinkHandler> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _initAppLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initAppLinks() async {
    final appLinks = AppLinks();
    
    // Handle the app link stream
    _sub = appLinks.uriLinkStream.listen((Uri uri) {
      _handleLink(context, uri);
    }, onError: (err) {
      print('App links stream error: $err');
    });
  }

  Future<void> _handleLink(BuildContext context, Uri link) async {
    print("Handling link: $link");
    if (link.scheme == 'https' &&
        link.host == 'splitter-2e1ae.web.app' &&
        link.pathSegments.isNotEmpty &&
        link.pathSegments.first == 'join') {
      final token = link.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        print("Extracted token: $token");
        final appState = Provider.of<AppState>(context, listen: false);

        if (appState.user == null) {
          // User is not logged in
          appState.pendingInviteToken = token;
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Please sign in to join the group.')),
          );
          // Assuming your app navigates to SignInScreen automatically when user is null
          // or by listening to appState.user changes elsewhere.
          print("User not logged in. Stored pending token. Sign-in required.");
        } else {
          // User is logged in
          print("User logged in. Attempting to join group directly.");
          try {
            bool success = await appState.joinTransactionGroup(token);
            if (success) {
              scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text('Successfully joined group with token: $token')),
              );
            } else {
              scaffoldMessengerKey.currentState?.showSnackBar(
                SnackBar(content: Text('Failed to join group with token: $token')),
              );
            }
          } catch (e) {
            print("Error joining group from link: $e");
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Error joining group: ${e.toString()}')),
            );
          }
        }
      } else {
        print("Token not found in link");
      }
    } else {
      print("Link not recognized as a join link.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return TransactionSettlementApp(); // The original app root
  }
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
