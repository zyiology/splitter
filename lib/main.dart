// lib/main.dart
import 'dart:async'; // Required for StreamSubscription
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Required for PlatformException
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
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
    _initUniLinks();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _initUniLinks() async {
    try {
      final initialUri = await getInitialUri();
      if (initialUri != null) {
        _handleLink(context, initialUri);
      }
    } on PlatformException {
      // Platform messages may fail, so we use a try/catch PlatformException.
      print("Failed to get initial link.");
    } on FormatException {
      print("Failed to parse initial link.");
    }

    _sub = uriLinkStream.listen((Uri? uri) {
      if (uri != null) {
        _handleLink(context, uri);
      }
    }, onError: (err) {
      print('uriLinkStream error: $err');
    });
  }

  void _handleLink(BuildContext context, Uri? link) {
    if (link == null) return;

    print("Handling link: $link");
    if (link.scheme == 'https' &&
        link.host == 'splitter-2e1ae.web.app' &&
        link.pathSegments.isNotEmpty &&
        link.pathSegments.first == 'join') {
      final token = link.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        print("Extracted token: $token");
        try {
          final appState = Provider.of<AppState>(context, listen: false);
          appState.joinTransactionGroup(token);
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Joining group with token: $token')),
          );
        } catch (e) {
          print("Error joining group from link: $e");
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(content: Text('Error joining group: ${e.toString()}')),
          );
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
