# Offline Functionality Demo Guide

## How to Test the Offline Features

### Prerequisites
1. Build and install the app on a device or emulator
2. Sign in with Google account
3. Create or join a transaction group

### Demo Scenarios

#### Scenario 1: Basic Offline Operation
1. **Go Offline**: Turn on airplane mode or disable WiFi/mobile data
2. **Observe UI Changes**:
   - App bar turns orange
   - Cloud-off icon appears
   - "Offline - Only additions allowed" banner shows
3. **Add a Transaction**:
   - Navigate to transaction group
   - Try to add a new transaction
   - Notice the transaction appears with a sync icon (pending)
   - Orange snackbar shows "Transaction saved offline..."
4. **Go Online**: Re-enable internet connection
5. **Observe Sync**:
   - Pending operations banner appears briefly
   - Green snackbar shows "X offline operations synced successfully!"
   - Sync icon disappears from the transaction

#### Scenario 2: Offline Restrictions
1. **Go Offline**: Disable internet connection
2. **Try Modifications**:
   - Try to delete a transaction → Red snackbar: "Cannot modify data while offline"
   - Try to edit a participant → Same restriction message
   - Try to update currency rates → Same restriction message
3. **Verify Additions Work**:
   - Add new participant → Works, shows pending indicator
   - Add new currency rate → Works, shows pending indicator

#### Scenario 3: Queue Persistence
1. **Go Offline**: Disable internet connection
2. **Add Multiple Items**:
   - Add 2-3 transactions
   - Add 1-2 participants
   - Notice pending operations counter increases
3. **Close App**: Force close the app completely
4. **Reopen App**: Launch app again (still offline)
5. **Verify Persistence**:
   - Pending operations counter shows correct count
   - All offline items still show pending indicators
6. **Go Online**: Enable internet connection
7. **Verify Sync**: All items sync successfully

#### Scenario 4: Connection State Monitoring
1. **Start Online**: Begin with internet connection
2. **Monitor Real-time Changes**:
   - Toggle airplane mode on/off repeatedly
   - Notice immediate UI changes (app bar color, icons)
   - No delay in detecting connection changes
3. **Test Poor Connection**:
   - Use very slow WiFi or mobile data
   - Try adding transactions
   - App should handle timeouts gracefully

### Expected Behaviors

#### Visual Indicators
- **Offline State**: Orange app bar, cloud-off icon, offline banner
- **Pending Operations**: Blue banner with sync icon and count
- **Pending Items**: Orange sync icon next to item, "Pending sync..." text
- **Online State**: Normal blue app bar, no special indicators

#### Snackbar Messages
- **Offline Save**: "Transaction/Participant/Currency rate saved offline. Will sync when connection is restored." (Orange)
- **Modification Blocked**: "Cannot modify data while offline. Only additions are allowed." (Red)
- **Sync Success**: "X offline operations synced successfully!" (Green)
- **Sync Partial Failure**: "Some offline operations failed to sync" (Orange)

#### Data Behavior
- **Offline Reads**: All cached data remains accessible
- **Offline Additions**: Items appear immediately with pending status
- **Offline Modifications**: Blocked with user feedback
- **Online Sync**: Automatic, with retry logic for failures

### Troubleshooting

#### If Sync Fails
1. Check internet connection stability
2. Verify Firebase project permissions
3. Look for error messages in debug console
4. Failed operations are retried up to 3 times
5. After max retries, operations are removed from queue

#### If UI Doesn't Update
1. Ensure `connectivity_plus` permissions are granted
2. Check if device properly reports connectivity changes
3. Restart app if connectivity monitoring seems stuck

#### If Queue Doesn't Persist
1. Check device storage permissions
2. Verify `shared_preferences` is working
3. Look for JSON parsing errors in debug console

### Performance Notes
- Offline persistence uses device storage (minimal impact)
- Queue processing is automatic and efficient
- UI updates are immediate and responsive
- Sync operations are batched for better performance

### Security Considerations
- Offline data is stored locally on device
- Queue operations use same Firebase security rules
- No sensitive data is exposed in offline storage
- Sync operations require valid authentication