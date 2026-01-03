# Offline Functionality Implementation

## Overview
This document describes the offline functionality implemented for the expense tracking app. The implementation follows a **hybrid approach** that combines Firestore's built-in offline persistence with a custom queuing system for new operations.

## Key Features Implemented

### 1. **Firestore Offline Persistence**
- Enabled via `Settings(persistenceEnabled: true)` in `main.dart`
- Automatically caches data locally for offline reading
- Handles synchronization when connection is restored

### 2. **Connection State Monitoring**
- Uses `connectivity_plus` package to monitor network connectivity
- Real-time updates to UI when connection state changes
- Automatic processing of offline queue when connection is restored

### 3. **Offline Operations Queue**
- Custom `OfflineQueueService` that persists operations to local storage
- Supports retry logic with maximum retry attempts
- Queues operations when network is unavailable

### 4. **Supported Offline Operations**
✅ **Allowed when offline:**
- Adding new transactions
- Adding new participants  
- Adding new currency rates

❌ **Blocked when offline:**
- Editing existing data
- Deleting data
- Group management operations

### 5. **User Experience Features**
- Visual indicators for offline status (orange app bar, cloud-off icon)
- Pending operations counter with badge
- Status messages for offline mode
- Snackbar notifications for sync status
- Pending indicators on offline-created items

## Technical Implementation

### Core Components

#### `OfflineQueueService`
- Manages queue of pending operations
- Persists to `SharedPreferences` for durability
- Handles retry logic and failure cleanup
- Supports operation types: `add_transaction`, `add_participant`, `add_currency_rate`

#### `AppState` Updates
- Added connectivity monitoring with `_initConnectivityMonitoring()`
- Enhanced add methods with offline support
- Added `canModifyData()` helper to block modifications when offline
- Automatic queue processing on connection restoration

#### Model Extensions
- Added `isPending` flag to `SplitterTransaction` and `Participant`
- Added `copyWith()` methods for creating pending versions

### Error Handling Strategy

```dart
try {
  // Always try online first
  return await onlineOperation();
} catch (e) {
  // If network error, queue for later
  if (e is FirebaseException && 
      (e.code == 'unavailable' || e.code == 'deadline-exceeded')) {
    await queueOfflineOperation();
    return optimisticResult;
  }
  rethrow; // Other errors bubble up
}
```

### UI Indicators

1. **App Bar Changes:**
   - Orange background when offline
   - Cloud-off icon when offline
   - Sync badge with pending operations count

2. **Status Messages:**
   - "Offline - Only additions allowed" banner
   - "X operations pending sync" banner
   - Success/failure snackbars for sync operations

3. **Item Indicators:**
   - Pending items show sync icon
   - Orange text for pending status

## Dependencies Added

```yaml
connectivity_plus: ^6.1.5
shared_preferences: ^2.5.3
```

## Configuration

### Firestore Settings
```dart
FirebaseFirestore.instance.settings = const Settings(persistenceEnabled: true);
```

### Queue Configuration
- Maximum retries: 3 attempts
- Storage key: `'offline_operations_queue'`
- Automatic cleanup of failed operations

## Usage Examples

### Adding a Transaction Offline
1. User creates transaction while offline
2. Transaction is queued in `OfflineQueueService`
3. Transaction appears in UI with pending indicator
4. When connection restored, transaction syncs to Firestore
5. Pending indicator disappears

### Connection State Changes
1. App monitors connectivity via `connectivity_plus`
2. UI updates immediately when state changes
3. Offline queue processes automatically on reconnection
4. User receives feedback about sync status

## Benefits

1. **Seamless User Experience:** Users can continue adding data offline
2. **Data Integrity:** No conflicts since only additions are allowed offline
3. **Reliable Sync:** Retry logic ensures operations eventually succeed
4. **Clear Feedback:** Users always know connection and sync status
5. **Minimal Code Changes:** Leverages Firestore's built-in capabilities

## Limitations

1. **No Offline Editing:** Modifications require internet connection
2. **No Offline Deletions:** Deletions require internet connection
3. **No Conflict Resolution:** Avoided by restricting offline operations
4. **Storage Dependent:** Offline queue relies on device storage

## Testing Recommendations

1. **Airplane Mode Testing:** Toggle airplane mode to test offline behavior
2. **Poor Connection Testing:** Test with slow/intermittent connections
3. **Queue Persistence:** Test app restart with pending operations
4. **Retry Logic:** Test with temporary network failures
5. **UI Indicators:** Verify all visual feedback works correctly

## Future Enhancements

1. **Smart Sync:** Prioritize certain operations during sync
2. **Conflict Resolution:** Add support for offline editing with conflict resolution
3. **Batch Operations:** Group related operations for efficient syncing
4. **Offline Analytics:** Track offline usage patterns
5. **Progressive Sync:** Sync operations in background progressively