import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Advanced data synchronization manager that handles offline/online transitions
/// similar to social media apps like Instagram
class DataSyncManager {
  static final DataSyncManager _instance = DataSyncManager._internal();
  factory DataSyncManager() => _instance;
  DataSyncManager._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  
  // Sync states
  bool _isOnline = false;
  bool _isSyncing = false;
  final List<Map<String, dynamic>> _pendingOperations = [];
  Timer? _syncTimer;
  Timer? _heartbeatTimer;
  
  // Listeners
  final List<VoidCallback> _syncListeners = [];
  final List<Function(bool)> _connectivityListeners = [];
  
  // Constants
  static const String _pendingOpsKey = 'pending_sync_operations';
  static const String _lastSyncTimestampKey = 'last_full_sync_timestamp';
  static const String _offlineDataIntegrityKey = 'offline_data_integrity_hash';
  
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  List<Map<String, dynamic>> get pendingOperations => List.unmodifiable(_pendingOperations);

  /// Initialize the sync manager
  Future<void> initialize() async {
    await _checkConnectivity();
    _startConnectivityMonitoring();
    _startPeriodicSync();
    _startHeartbeat();
    await _loadPendingOperations();
    
    if (_isOnline && _pendingOperations.isNotEmpty) {
      _schedulePendingSync();
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOnline = _isOnline;
      _isOnline = result != ConnectivityResult.none;
      
      print('DataSyncManager: Connectivity changed - Online: $_isOnline');
      
      // Notify listeners about connectivity changes
      for (final listener in _connectivityListeners) {
        listener(_isOnline);
      }
      
      if (!wasOnline && _isOnline) {
        // Just came online - sync pending operations
        print('DataSyncManager: Device came online, syncing pending operations');
        await _syncPendingOperations();
      } else if (wasOnline && !_isOnline) {
        // Just went offline
        print('DataSyncManager: Device went offline');
      }
    });
  }

  /// Start periodic background sync (every 30 seconds when online)
  void _startPeriodicSync() {
    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (_isOnline && !_isSyncing) {
        await _syncPendingOperations();
      }
    });
  }

  /// Start heartbeat to maintain connection awareness
  void _startHeartbeat() {
    _heartbeatTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      await _checkConnectivity();
    });
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOnline = result != ConnectivityResult.none;
    } catch (e) {
      print('DataSyncManager: Error checking connectivity: $e');
      _isOnline = false;
    }
  }

  /// Add operation to pending sync queue - overloaded method for simple operations
  Future<void> queueOperation(Map<String, dynamic> operation) async {
    // Handle the simple operation format from UserDataProvider
    final fullOperation = {
      'id': '${DateTime.now().millisecondsSinceEpoch}_${operation['type']}',
      'type': operation['type'],
      'collection': 'users', // Default collection
      'documentId': null,
      'data': operation['data'] ?? {},
      'timestamp': DateTime.now().toIso8601String(),
      'priority': 1,
      'retryCount': 0,
      'maxRetries': 3,
    };
    
    _pendingOperations.add(fullOperation);
    await _savePendingOperations();
    
    print('DataSyncManager: Queued ${operation['type']} operation');
    
    // Try to sync immediately if online
    if (_isOnline && !_isSyncing) {
      _schedulePendingSync();
    }
  }

  /// Add operation to pending sync queue - full method signature
  Future<void> queueOperationFull({
    required String type,
    required String collection,
    required Map<String, dynamic> data,
    String? documentId,
    int priority = 1,
  }) async {
    final operation = {
      'id': '${DateTime.now().millisecondsSinceEpoch}_${type}_${collection}',
      'type': type, // 'create', 'update', 'delete'
      'collection': collection,
      'documentId': documentId,
      'data': data,
      'timestamp': DateTime.now().toIso8601String(),
      'priority': priority,
      'retryCount': 0,
      'maxRetries': 3,
    };
    
    _pendingOperations.add(operation);
    await _savePendingOperations();
    
    print('DataSyncManager: Queued ${type} operation for ${collection}');
    
    // Try to sync immediately if online
    if (_isOnline && !_isSyncing) {
      _schedulePendingSync();
    }
  }

  /// Schedule pending sync with debouncing
  void _schedulePendingSync() {
    Timer(const Duration(milliseconds: 500), () async {
      if (_isOnline && !_isSyncing) {
        await _syncPendingOperations();
      }
    });
  }

  /// Sync all pending operations
  Future<bool> _syncPendingOperations() async {
    if (_isSyncing || !_isOnline || _pendingOperations.isEmpty) {
      return true;
    }

    _isSyncing = true;
    _notifySyncListeners();
    
    try {
      // Sort by priority and timestamp
      _pendingOperations.sort((a, b) {
        final priorityComparison = (b['priority'] as int).compareTo(a['priority'] as int);
        if (priorityComparison != 0) return priorityComparison;
        return (a['timestamp'] as String).compareTo(b['timestamp'] as String);
      });

      final successfulOperations = <int>[];
      
      for (int i = 0; i < _pendingOperations.length; i++) {
        final operation = _pendingOperations[i];
        final success = await _executeOperation(operation);
        
        if (success) {
          successfulOperations.add(i);
        } else {
          // Increment retry count
          operation['retryCount'] = (operation['retryCount'] as int) + 1;
          
          // Remove if max retries exceeded
          if ((operation['retryCount'] as int) >= (operation['maxRetries'] as int)) {
            print('DataSyncManager: Operation ${operation['id']} exceeded max retries, removing');
            successfulOperations.add(i);
          }
        }
      }

      // Remove successful operations (in reverse order to maintain indices)
      for (int i = successfulOperations.length - 1; i >= 0; i--) {
        _pendingOperations.removeAt(successfulOperations[i]);
      }

      await _savePendingOperations();
      await _updateLastSyncTimestamp();
      
      print('DataSyncManager: Sync completed. ${successfulOperations.length} operations processed, ${_pendingOperations.length} remaining');
      
      return true;
    } catch (e) {
      print('DataSyncManager: Sync failed: $e');
      return false;
    } finally {
      _isSyncing = false;
      _notifySyncListeners();
    }
  }

  /// Execute a single operation
  Future<bool> _executeOperation(Map<String, dynamic> operation) async {
    try {
      // This would be implemented to call the appropriate Firebase/API methods
      // For now, we'll simulate the operation
      print('DataSyncManager: Executing ${operation['type']} on ${operation['collection']}');
      
      // Simulate network delay
      await Future.delayed(const Duration(milliseconds: 100));
      
      // In a real implementation, this would call Firebase methods
      // based on the operation type and collection
      
      return true; // Assume success for now
    } catch (e) {
      print('DataSyncManager: Operation failed: $e');
      return false;
    }
  }

  /// Save pending operations to local storage
  Future<void> _savePendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = jsonEncode(_pendingOperations);
      await prefs.setString(_pendingOpsKey, operationsJson);
    } catch (e) {
      print('DataSyncManager: Error saving pending operations: $e');
    }
  }

  /// Load pending operations from local storage
  Future<void> _loadPendingOperations() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final operationsJson = prefs.getString(_pendingOpsKey);
      
      if (operationsJson != null) {
        final List<dynamic> operations = jsonDecode(operationsJson);
        _pendingOperations.clear();
        _pendingOperations.addAll(operations.cast<Map<String, dynamic>>());
        
        print('DataSyncManager: Loaded ${_pendingOperations.length} pending operations');
      }
    } catch (e) {
      print('DataSyncManager: Error loading pending operations: $e');
      _pendingOperations.clear();
    }
  }

  /// Update last sync timestamp
  Future<void> _updateLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('DataSyncManager: Error updating sync timestamp: $e');
    }
  }

  /// Get last sync timestamp
  Future<DateTime?> getLastSyncTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncTimestampKey);
      return timestamp != null ? DateTime.parse(timestamp) : null;
    } catch (e) {
      print('DataSyncManager: Error getting sync timestamp: $e');
      return null;
    }
  }

  /// Force a full sync - alias for UserDataProvider compatibility
  Future<void> forceSyncPendingOperations() async {
    await forceSyncNow();
  }

  /// Force a full sync
  Future<bool> forceSyncNow() async {
    if (!_isOnline) {
      print('DataSyncManager: Cannot force sync - device is offline');
      return false;
    }
    
    return await _syncPendingOperations();
  }

  /// Clear all pending operations
  Future<void> clearPendingOperations() async {
    _pendingOperations.clear();
    await _savePendingOperations();
  }

  /// Add sync status listener
  void addSyncListener(VoidCallback listener) {
    _syncListeners.add(listener);
  }

  /// Remove sync status listener
  void removeSyncListener(VoidCallback listener) {
    _syncListeners.remove(listener);
  }

  /// Add connectivity listener
  void addConnectivityListener(Function(bool) listener) {
    _connectivityListeners.add(listener);
  }

  /// Remove connectivity listener
  void removeConnectivityListener(Function(bool) listener) {
    _connectivityListeners.remove(listener);
  }

  /// Notify sync listeners
  void _notifySyncListeners() {
    for (final listener in _syncListeners) {
      try {
        listener();
      } catch (e) {
        print('DataSyncManager: Error in sync listener: $e');
      }
    }
  }

  /// Get sync statistics
  Map<String, dynamic> getSyncStats() {
    return {
      'isOnline': _isOnline,
      'isSyncing': _isSyncing,
      'pendingOperationsCount': _pendingOperations.length,
      'operationsByType': _groupOperationsByType(),
    };
  }

  /// Group operations by type for statistics
  Map<String, int> _groupOperationsByType() {
    final Map<String, int> groups = {};
    for (final operation in _pendingOperations) {
      final type = operation['type'] as String;
      groups[type] = (groups[type] ?? 0) + 1;
    }
    return groups;
  }

  /// Dispose and cleanup
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _heartbeatTimer?.cancel();
    _syncListeners.clear();
    _connectivityListeners.clear();
  }
}
