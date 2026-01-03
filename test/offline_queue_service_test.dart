// test/offline_queue_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splitter/services/offline_queue_service.dart';

void main() {
  group('OfflineQueueService', () {
    late OfflineQueueService service;

    setUp(() async {
      // Mock SharedPreferences
      SharedPreferences.setMockInitialValues({});
      service = OfflineQueueService();
      await service.initialize();
    });

    test('should initialize with empty queue', () {
      expect(service.pendingOperations, isEmpty);
      expect(service.hasPendingOperations, false);
    });

    test('should queue operations', () async {
      final operation = OfflineOperation(
        id: 'test-id',
        type: 'add_transaction',
        groupId: 'group-1',
        data: {'amount': 100.0, 'payer': 'Alice'},
        timestamp: DateTime.now(),
      );

      await service.queueOperation(operation);

      expect(service.pendingOperations.length, 1);
      expect(service.hasPendingOperations, true);
      expect(service.pendingOperations.first.id, 'test-id');
    });

    test('should remove operations', () async {
      final operation = OfflineOperation(
        id: 'test-id',
        type: 'add_transaction',
        groupId: 'group-1',
        data: {'amount': 100.0, 'payer': 'Alice'},
        timestamp: DateTime.now(),
      );

      await service.queueOperation(operation);
      expect(service.pendingOperations.length, 1);

      await service.removeOperation('test-id');
      expect(service.pendingOperations, isEmpty);
    });

    test('should increment retry count', () async {
      final operation = OfflineOperation(
        id: 'test-id',
        type: 'add_transaction',
        groupId: 'group-1',
        data: {'amount': 100.0, 'payer': 'Alice'},
        timestamp: DateTime.now(),
        retryCount: 0,
      );

      await service.queueOperation(operation);
      await service.incrementRetryCount('test-id');

      expect(service.pendingOperations.first.retryCount, 1);
    });

    test('should filter operations to process based on retry count', () async {
      final operation1 = OfflineOperation(
        id: 'test-id-1',
        type: 'add_transaction',
        groupId: 'group-1',
        data: {'amount': 100.0, 'payer': 'Alice'},
        timestamp: DateTime.now(),
        retryCount: 2, // Under max retries
      );

      final operation2 = OfflineOperation(
        id: 'test-id-2',
        type: 'add_transaction',
        groupId: 'group-1',
        data: {'amount': 200.0, 'payer': 'Bob'},
        timestamp: DateTime.now(),
        retryCount: 3, // At max retries
      );

      await service.queueOperation(operation1);
      await service.queueOperation(operation2);

      final operationsToProcess = await service.getOperationsToProcess();
      expect(operationsToProcess.length, 1);
      expect(operationsToProcess.first.id, 'test-id-1');
    });

    test('should clear failed operations', () async {
      final operation1 = OfflineOperation(
        id: 'test-id-1',
        type: 'add_transaction',
        groupId: 'group-1',
        data: {'amount': 100.0, 'payer': 'Alice'},
        timestamp: DateTime.now(),
        retryCount: 2,
      );

      final operation2 = OfflineOperation(
        id: 'test-id-2',
        type: 'add_transaction',
        groupId: 'group-1',
        data: {'amount': 200.0, 'payer': 'Bob'},
        timestamp: DateTime.now(),
        retryCount: 3, // Will be removed
      );

      await service.queueOperation(operation1);
      await service.queueOperation(operation2);
      expect(service.pendingOperations.length, 2);

      await service.clearFailedOperations();
      expect(service.pendingOperations.length, 1);
      expect(service.pendingOperations.first.id, 'test-id-1');
    });

    test('should persist and restore queue from storage', () async {
      final operation = OfflineOperation(
        id: 'test-id',
        type: 'add_transaction',
        groupId: 'group-1',
        data: {'amount': 100.0, 'payer': 'Alice'},
        timestamp: DateTime.now(),
      );

      await service.queueOperation(operation);
      expect(service.pendingOperations.length, 1);

      // Create new service instance to test persistence
      final newService = OfflineQueueService();
      await newService.initialize();

      expect(newService.pendingOperations.length, 1);
      expect(newService.pendingOperations.first.id, 'test-id');
      expect(newService.pendingOperations.first.type, 'add_transaction');
    });
  });
}