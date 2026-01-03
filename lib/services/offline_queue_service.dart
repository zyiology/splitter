// lib/services/offline_queue_service.dart
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

class OfflineOperation {
  final String id;
  final String type; // 'add_transaction', 'add_participant', 'add_currency_rate'
  final String groupId;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final int retryCount;

  OfflineOperation({
    required this.id,
    required this.type,
    required this.groupId,
    required this.data,
    required this.timestamp,
    this.retryCount = 0,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'groupId': groupId,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  factory OfflineOperation.fromJson(Map<String, dynamic> json) {
    return OfflineOperation(
      id: json['id'],
      type: json['type'],
      groupId: json['groupId'],
      data: Map<String, dynamic>.from(json['data']),
      timestamp: DateTime.parse(json['timestamp']),
      retryCount: json['retryCount'] ?? 0,
    );
  }

  OfflineOperation copyWith({
    String? id,
    String? type,
    String? groupId,
    Map<String, dynamic>? data,
    DateTime? timestamp,
    int? retryCount,
  }) {
    return OfflineOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      groupId: groupId ?? this.groupId,
      data: data ?? this.data,
      timestamp: timestamp ?? this.timestamp,
      retryCount: retryCount ?? this.retryCount,
    );
  }
}

class OfflineQueueService {
  static const String _queueKey = 'offline_operations_queue';
  static const int _maxRetries = 3;
  
  SharedPreferences? _prefs;
  final List<OfflineOperation> _queue = [];
  final Uuid _uuid = Uuid();

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    await _loadQueueFromStorage();
  }

  List<OfflineOperation> get pendingOperations => List.unmodifiable(_queue);
  
  bool get hasPendingOperations => _queue.isNotEmpty;

  Future<void> queueOperation(OfflineOperation operation) async {
    _queue.add(operation);
    await _saveQueueToStorage();
    print('Queued offline operation: ${operation.type} for group ${operation.groupId}');
  }

  Future<String> createOperationId() async {
    return _uuid.v4();
  }

  Future<void> removeOperation(String operationId) async {
    _queue.removeWhere((op) => op.id == operationId);
    await _saveQueueToStorage();
  }

  Future<void> incrementRetryCount(String operationId) async {
    final index = _queue.indexWhere((op) => op.id == operationId);
    if (index != -1) {
      _queue[index] = _queue[index].copyWith(retryCount: _queue[index].retryCount + 1);
      await _saveQueueToStorage();
    }
  }

  Future<List<OfflineOperation>> getOperationsToProcess() async {
    // Return operations that haven't exceeded max retries
    return _queue.where((op) => op.retryCount < _maxRetries).toList();
  }

  Future<void> clearFailedOperations() async {
    _queue.removeWhere((op) => op.retryCount >= _maxRetries);
    await _saveQueueToStorage();
  }

  Future<void> _loadQueueFromStorage() async {
    if (_prefs == null) return;
    
    final queueJson = _prefs!.getString(_queueKey);
    if (queueJson != null) {
      try {
        final List<dynamic> queueList = jsonDecode(queueJson);
        _queue.clear();
        _queue.addAll(queueList.map((json) => OfflineOperation.fromJson(json)));
        print('Loaded ${_queue.length} offline operations from storage');
      } catch (e) {
        print('Error loading offline queue: $e');
        // Clear corrupted data
        await _prefs!.remove(_queueKey);
      }
    }
  }

  Future<void> _saveQueueToStorage() async {
    if (_prefs == null) return;
    
    try {
      final queueJson = jsonEncode(_queue.map((op) => op.toJson()).toList());
      await _prefs!.setString(_queueKey, queueJson);
    } catch (e) {
      print('Error saving offline queue: $e');
    }
  }

  Future<void> clearAllOperations() async {
    _queue.clear();
    await _saveQueueToStorage();
  }
}