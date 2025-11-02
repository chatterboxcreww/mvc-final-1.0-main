// lib/core/services/batch_operations_service.dart

import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for batching Firebase operations to improve performance and reduce costs
class BatchOperationsService {
  static final BatchOperationsService _instance = BatchOperationsService._internal();
  factory BatchOperationsService() => _instance;
  BatchOperationsService._internal();

  final Queue<BatchOperation> _pendingOperations = Queue<BatchOperation>();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  Timer? _batchTimer;
  Timer? _forceExecuteTimer;
  bool _isExecuting = false;
  
  // Configuration
  static const Duration _batchDelay = Duration(seconds: 2);
  static const Duration _maxBatchWait = Duration(seconds: 10);
  static const int _maxBatchSize = 500; // Firestore limit
  static const int _maxOperationsPerBatch = 450; // Leave some buffer
  
  // Statistics
  int _totalOperationsQueued = 0;
  int _totalBatchesExecuted = 0;
  int _totalOperationsExecuted = 0;
  DateTime? _lastBatchExecution;

  /// Queue an operation for batch execution
  void queueOperation(BatchOperation operation) {
    _pendingOperations.add(operation);
    _totalOperationsQueued++;
    
    debugPrint('BatchOperations: Queued ${operation.type} operation (${_pendingOperations.length} pending)');
    
    _scheduleBatchExecution();
  }

  /// Queue multiple operations at once
  void queueOperations(List<BatchOperation> operations) {
    for (final operation in operations) {
      _pendingOperations.add(operation);
      _totalOperationsQueued++;
    }
    
    debugPrint('BatchOperations: Queued ${operations.length} operations (${_pendingOperations.length} pending)');
    
    _scheduleBatchExecution();
  }

  /// Schedule batch execution with delay
  void _scheduleBatchExecution() {
    // Cancel existing timer
    _batchTimer?.cancel();
    
    // Don't schedule if already executing
    if (_isExecuting) return;
    
    // Schedule execution after delay
    _batchTimer = Timer(_batchDelay, () {
      if (!_isExecuting && _pendingOperations.isNotEmpty) {
        _executeBatch();
      }
    });
    
    // Force execution after max wait time
    _forceExecuteTimer ??= Timer(_maxBatchWait, () {
      if (!_isExecuting && _pendingOperations.isNotEmpty) {
        debugPrint('BatchOperations: Force executing batch after max wait time');
        _executeBatch();
      }
    });
  }

  /// Execute pending operations in batches
  Future<void> _executeBatch() async {
    if (_isExecuting || _pendingOperations.isEmpty) return;
    
    _isExecuting = true;
    _batchTimer?.cancel();
    _forceExecuteTimer?.cancel();
    _forceExecuteTimer = null;
    
    try {
      final user = _auth.currentUser;
      if (user == null) {
        debugPrint('BatchOperations: No authenticated user, clearing operations');
        _pendingOperations.clear();
        return;
      }
      
      // Group operations by type for better batching
      final groupedOperations = _groupOperationsByType();
      
      for (final group in groupedOperations) {
        await _executeBatchGroup(group, user.uid);
      }
      
      _totalBatchesExecuted++;
      _lastBatchExecution = DateTime.now();
      
      debugPrint('BatchOperations: Executed ${_totalOperationsExecuted} operations in ${_totalBatchesExecuted} batches');
      
    } catch (e) {
      debugPrint('BatchOperations: Error executing batch: $e');
      // Re-queue failed operations for retry
      // In a production app, you might want to implement exponential backoff
    } finally {
      _isExecuting = false;
      
      // Schedule next batch if there are more operations
      if (_pendingOperations.isNotEmpty) {
        _scheduleBatchExecution();
      }
    }
  }

  /// Group operations by type for efficient batching
  List<List<BatchOperation>> _groupOperationsByType() {
    final groups = <String, List<BatchOperation>>{};
    final operations = List<BatchOperation>.from(_pendingOperations);
    _pendingOperations.clear();
    
    // Group by collection and operation type
    for (final operation in operations) {
      final groupKey = '${operation.collection}_${operation.type}';
      groups[groupKey] ??= [];
      groups[groupKey]!.add(operation);
    }
    
    // Split large groups into smaller batches
    final result = <List<BatchOperation>>[];
    for (final group in groups.values) {
      while (group.isNotEmpty) {
        final batchSize = group.length > _maxOperationsPerBatch 
            ? _maxOperationsPerBatch 
            : group.length;
        result.add(group.take(batchSize).toList());
        group.removeRange(0, batchSize);
      }
    }
    
    return result;
  }

  /// Execute a group of similar operations
  Future<void> _executeBatchGroup(List<BatchOperation> operations, String userId) async {
    if (operations.isEmpty) return;
    
    final batch = _firestore.batch();
    int operationsInBatch = 0;
    
    for (final operation in operations) {
      try {
        operation.addToBatch(batch, userId);
        operationsInBatch++;
        
        // Execute batch if it's getting full
        if (operationsInBatch >= _maxOperationsPerBatch) {
          await batch.commit();
          _totalOperationsExecuted += operationsInBatch;
          debugPrint('BatchOperations: Executed batch of $operationsInBatch operations');
          
          // Start new batch for remaining operations
          final newBatch = _firestore.batch();
          operationsInBatch = 0;
        }
      } catch (e) {
        debugPrint('BatchOperations: Error adding operation to batch: $e');
      }
    }
    
    // Execute remaining operations
    if (operationsInBatch > 0) {
      await batch.commit();
      _totalOperationsExecuted += operationsInBatch;
      debugPrint('BatchOperations: Executed final batch of $operationsInBatch operations');
    }
  }

  /// Force execute all pending operations immediately
  Future<void> forceExecute() async {
    _batchTimer?.cancel();
    _forceExecuteTimer?.cancel();
    
    if (_pendingOperations.isNotEmpty && !_isExecuting) {
      await _executeBatch();
    }
  }

  /// Get batch operation statistics
  Map<String, dynamic> getStats() {
    return {
      'totalOperationsQueued': _totalOperationsQueued,
      'totalBatchesExecuted': _totalBatchesExecuted,
      'totalOperationsExecuted': _totalOperationsExecuted,
      'pendingOperations': _pendingOperations.length,
      'isExecuting': _isExecuting,
      'lastBatchExecution': _lastBatchExecution?.toIso8601String(),
      'averageOperationsPerBatch': _totalBatchesExecuted > 0 
          ? (_totalOperationsExecuted / _totalBatchesExecuted).round()
          : 0,
    };
  }

  /// Clear all pending operations
  void clearPendingOperations() {
    _pendingOperations.clear();
    debugPrint('BatchOperations: Cleared all pending operations');
  }

  /// Dispose resources
  void dispose() {
    _batchTimer?.cancel();
    _forceExecuteTimer?.cancel();
    _pendingOperations.clear();
  }
}

/// Base class for batch operations
abstract class BatchOperation {
  final String type;
  final String collection;
  final Map<String, dynamic> data;
  final String? documentId;
  final DateTime timestamp;

  BatchOperation({
    required this.type,
    required this.collection,
    required this.data,
    this.documentId,
  }) : timestamp = DateTime.now();

  /// Add this operation to a Firestore batch
  void addToBatch(WriteBatch batch, String userId);
}

/// Create/Set operation
class CreateOperation extends BatchOperation {
  CreateOperation({
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
  }) : super(
    type: 'create',
    collection: collection,
    data: data,
    documentId: documentId,
  );

  @override
  void addToBatch(WriteBatch batch, String userId) {
    final docRef = documentId != null
        ? FirebaseFirestore.instance.collection('users').doc(userId).collection(collection).doc(documentId)
        : FirebaseFirestore.instance.collection('users').doc(userId).collection(collection).doc();
    
    batch.set(docRef, {
      ...data,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Update operation
class UpdateOperation extends BatchOperation {
  UpdateOperation({
    required String collection,
    required Map<String, dynamic> data,
    required String documentId,
  }) : super(
    type: 'update',
    collection: collection,
    data: data,
    documentId: documentId,
  );

  @override
  void addToBatch(WriteBatch batch, String userId) {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(documentId!);
    
    batch.update(docRef, {
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}

/// Delete operation
class DeleteOperation extends BatchOperation {
  DeleteOperation({
    required String collection,
    required String documentId,
  }) : super(
    type: 'delete',
    collection: collection,
    data: {},
    documentId: documentId,
  );

  @override
  void addToBatch(WriteBatch batch, String userId) {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection(collection)
        .doc(documentId!);
    
    batch.delete(docRef);
  }
}

/// User data update operation
class UserDataUpdateOperation extends BatchOperation {
  UserDataUpdateOperation({
    required Map<String, dynamic> data,
  }) : super(
    type: 'user_update',
    collection: 'users',
    data: data,
  );

  @override
  void addToBatch(WriteBatch batch, String userId) {
    final docRef = FirebaseFirestore.instance.collection('users').doc(userId);
    
    batch.update(docRef, {
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }
}

/// Achievement progress update operation
class AchievementUpdateOperation extends BatchOperation {
  AchievementUpdateOperation({
    required Map<String, dynamic> progressData,
  }) : super(
    type: 'achievement_update',
    collection: 'achievements',
    data: progressData,
    documentId: 'progress',
  );

  @override
  void addToBatch(WriteBatch batch, String userId) {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('achievements')
        .doc('progress');
    
    batch.set(docRef, {
      'progress': data,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}

/// Step data update operation
class StepDataUpdateOperation extends BatchOperation {
  StepDataUpdateOperation({
    required String date,
    required Map<String, dynamic> stepData,
  }) : super(
    type: 'step_update',
    collection: 'stepData',
    data: stepData,
    documentId: date,
  );

  @override
  void addToBatch(WriteBatch batch, String userId) {
    final docRef = FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .collection('stepData')
        .doc(documentId!);
    
    batch.set(docRef, {
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }
}