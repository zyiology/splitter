part of 'app_state.dart';

extension AppStateAuth on AppState {
  Future<void> _initialize() async {
    print('Initializing AppState...');

    await _googleSignIn.initialize();

    // Initialize offline queue service
    await _offlineQueueService.initialize();

    // Initialize connectivity monitoring
    await this._initConnectivityMonitoring();

    // have to handle initial state else there's a race condition?
    User? currentUser = _auth.currentUser;
    if (currentUser != null) {
      user = currentUser;
      this._listenTransactionGroups();
    }

    _auth.authStateChanges().listen((User? newUser) {
      print('Auth state changed: ${newUser?.uid}');
      user = newUser;

      // only set up Firestore listeners if user is logged in
      if (user != null) {
        this._listenTransactionGroups();
      } else {
        participants = [];
        currencyRates = [];
        transactions = [];
        settlements = [];
      }
      this._notify();
      print('isLoading: $isLoading');
    });

    isLoading = false;
    this._notify();
  }

  // Google Sign-In
  Future<void> signInWithGoogle() async {
    try {
      isLoading = true;
      this._notify();

      // Trigger the auth flow
      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();

      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final String? idToken = googleAuth.idToken;
      if (idToken == null) {
        isLoading = false;
        this._notify();
        return;
      }

      // Create a new credential
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: idToken,
      );

      await _auth.signInWithCredential(credential);

      // redundant, handled by cloud function
      // Sign in to Firebase with the Google [UserCredential]
      // final UserCredential userCredential = await _auth.signInWithCredential(credential);
      // final User? user = userCredential.user;

      // if (user != null) {
      //   // check if public profile exists
      //   final publicProfileRef = firestore
      //     .collection('publicProfiles')
      //     .where('userId', isEqualTo: user.uid)
      //     .limit(1);

      //   final querySnapshot = await publicProfileRef.get();

      //   if (querySnapshot.docs.isEmpty) {
      //     // create public profile
      //     final publicProfile = PublicProfile(
      //       userId: user.uid,
      //       displayName: user.displayName ?? 'No Name',
      //       photoURL: user.photoURL,
      //     );

      //     await firestore
      //       .collection('publicProfiles')
      //       .doc(user.uid) // use the user's uid as the document ID
      //       .set(publicProfile.toMap());

      if (pendingInviteToken != null && pendingInviteToken!.isNotEmpty) {
        print('Pending invite token found: $pendingInviteToken');
        try {
          bool success = await this.joinTransactionGroup(pendingInviteToken!);
          if (success) {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(content: Text('Successfully joined group via link!')),
            );
          } else {
            scaffoldMessengerKey.currentState?.showSnackBar(
              SnackBar(
                content: Text(
                  'Failed to join group via link. The token might be invalid or expired.',
                ),
              ),
            );
          }
        } catch (e) {
          print('Error processing pending invite token: $e');
          scaffoldMessengerKey.currentState?.showSnackBar(
            SnackBar(
              content: Text('An error occurred while trying to join the group.'),
            ),
          );
        } finally {
          pendingInviteToken = null;
        }
      }

      isLoading = false;
      this._notify();
    } catch (e) {
      isLoading = false;
      this._notify();
      print(e);
      // TODO handle error in production
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
    await _googleSignIn.signOut();
    pendingInviteToken = null;
    // Clear any additional state if needed
    this._notify();
  }
}
