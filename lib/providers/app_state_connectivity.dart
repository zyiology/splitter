part of 'app_state.dart';

extension AppStateConnectivity on AppState {
  bool get isOnline => _isOnline;

  Future<void> _initConnectivityMonitoring() async {
    // Check initial connectivity state
    final connectivityResults = await Connectivity().checkConnectivity();
    _isOnline = !connectivityResults.contains(ConnectivityResult.none);

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((List<ConnectivityResult> results) async {
      bool wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);

      print(
        'Connectivity changed: ${results.map((r) => r.name).join(', ')}, isOnline: $_isOnline',
      );

      if (!wasOnline && _isOnline) {
        print('Connection restored, processing offline queue...');
        await this._onConnectionRestored();
      }

      this._notify();
    });
  }

  Future<void> _onConnectionRestored() async {
    try {
      await this._processOfflineQueue();

      if (_offlineQueueService.hasPendingOperations) {
        scaffoldMessengerKey.currentState?.showSnackBar(
          SnackBar(
            content: Text(
              '${_offlineQueueService.pendingOperations.length} offline operations synced successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      print('Error processing offline queue: $e');
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Some offline operations failed to sync'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  // Helper method to check if modifications are allowed
  bool canModifyData() {
    if (!_isOnline) {
      scaffoldMessengerKey.currentState?.showSnackBar(
        SnackBar(
          content: Text('Cannot modify data while offline. Only additions are allowed.'),
          backgroundColor: Colors.red,
        ),
      );
      return false;
    }
    return true;
  }
}
