// lib/core/services/offline_manager.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Comprehensive offline manager for handling app functionality without internet
class OfflineManager {
  static final OfflineManager _instance = OfflineManager._internal();
  factory OfflineManager() => _instance;
  OfflineManager._internal();

  final Connectivity _connectivity = Connectivity();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  bool _isOffline = false;
  bool _isInitialized = false;
  StreamSubscription<ConnectivityResult>? _connectivitySubscription;
  Timer? _syncTimer;
  
  final List<OfflineOperation> _offlineQueue = [];
  final List<Function(bool)> _connectivityListeners = [];
  final List<Function()> _syncListeners = [];
  
  // Storage keys
  static const String _offlineQueueKey = 'offline_operations_queue_v2';
  static const String _offlineDataKey = 'offline_cached_data_v2';
  static const String _lastSyncTimestampKey = 'last_offline_sync_timestamp';
  static const String _offlineStatsKey = 'offline_statistics';
  
  // Configuration
  static const Duration _syncRetryInterval = Duration(minutes: 2);
  static const int _maxQueueSize = 1000;
  static const int _maxRetryAttempts = 5;

  // Getters
  bool get isOffline => _isOffline;
  bool get isInitialized => _isInitialized;
  int get queueSize => _offlineQueue.length;
  List<OfflineOperation> get pendingOperations => List.unmodifiable(_offlineQueue);

  /// Initialize offline manager
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check initial connectivity
      await _checkConnectivity();
      
      // Load offline queue from storage
      await _loadOfflineQueue();
      
      // Start connectivity monitoring
      _startConnectivityMonitoring();
      
      // Start periodic sync attempts
      _startPeriodicSync();
      
      _isInitialized = true;
      debugPrint('OfflineManager: Initialized (offline: $_isOffline, queue: ${_offlineQueue.length})');
    } catch (e) {
      debugPrint('OfflineManager: Initialization error: $e');
    }
  }

  /// Start monitoring connectivity changes
  void _startConnectivityMonitoring() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((result) async {
      final wasOffline = _isOffline;
      _isOffline = result == ConnectivityResult.none;
      
      debugPrint('OfflineManager: Connectivity changed - Offline: $_isOffline');
      
      // Notify listeners
      for (final listener in _connectivityListeners) {
        try {
          listener(_isOffline);
        } catch (e) {
          debugPrint('OfflineManager: Error in connectivity listener: $e');
        }
      }
      
      // If we just came online, try to sync
      if (wasOffline && !_isOffline) {
        debugPrint('OfflineManager: Device came online, attempting sync');
        await syncOfflineOperations();
      }
    });
  }

  /// Start periodic sync attempts
  void _startPeriodicSync() {
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(_syncRetryInterval, (_) async {
      if (!_isOffline && _offlineQueue.isNotEmpty) {
        await syncOfflineOperations();
      }
    });
  }

  /// Check current connectivity status
  Future<void> _checkConnectivity() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isOffline = result == ConnectivityResult.none;
    } catch (e) {
      debugPrint('OfflineManager: Error checking connectivity: $e');
      _isOffline = true; // Assume offline on error
    }
  }

  /// Handle operation when offline or online
  Future<void> handleOperation(OfflineOperation operation) async {
    if (_isOffline) {
      await _queueOfflineOperation(operation);
    } else {
      try {
        await operation.execute();
        debugPrint('OfflineManager: Executed operation online: ${operation.type}');
      } catch (e) {
        debugPrint('OfflineManager: Online operation failed, queuing: $e');
        await _queueOfflineOperation(operation);
      }
    }
  }

  /// Queue operation for offline execution
  Future<void> _queueOfflineOperation(OfflineOperation operation) async {
    // Check queue size limit
    if (_offlineQueue.length >= _maxQueueSize) {
      // Remove oldest operations to make space
      final removeCount = _offlineQueue.length - _maxQueueSize + 1;
      _offlineQueue.removeRange(0, removeCount);
      debugPrint('OfflineManager: Queue full, removed $removeCount old operations');
    }
    
    _offlineQueue.add(operation);
    await _persistOfflineQueue();
    
    debugPrint('OfflineManager: Queued offline operation: ${operation.type} (queue: ${_offlineQueue.length})');
  }

  /// Sync all offline operations
  Future<void> syncOfflineOperations() async {
    if (_isOffline || _offlineQueue.isEmpty) return;
    
    debugPrint('OfflineManager: Starting sync of ${_offlineQueue.length} operations');
    
    final operationsToSync = List<OfflineOperation>.from(_offlineQueue);
    final successfulOperations = <OfflineOperation>[];
    final failedOperations = <OfflineOperation>[];
    
    for (final operation in operationsToSync) {
      try {
        await operation.execute();
        successfulOperations.add(operation);
        debugPrint('OfflineManager: Synced operation: ${operation.type}');
      } catch (e) {
        operation.incrementRetryCount();
        
        if (operation.retryCount >= _maxRetryAttempts) {
          debugPrint('OfflineManager: Operation failed permanently: ${operation.type} (${operation.retryCount} attempts)');
          failedOperations.add(operation);
        } else {
          debugPrint('OfflineManager: Operation failed, will retry: ${operation.type} (attempt ${operation.retryCount})');
          failedOperations.add(operation);
        }
      }
    }
    
    // Remove successful operations from queue
    for (final operation in successfulOperations) {
      _offlineQueue.remove(operation);
    }
    
    // Remove permanently failed operations
    final permanentlyFailed = failedOperations.where((op) => op.retryCount >= _maxRetryAttempts).toList();
    for (final operation in permanentlyFailed) {
      _offlineQueue.remove(operation);
    }
    
    await _persistOfflineQueue();
    await _updateSyncStats(successfulOperations.length, permanentlyFailed.length);
    
    // Notify sync listeners
    for (final listener in _syncListeners) {
      try {
        listener();
      } catch (e) {
        debugPrint('OfflineManager: Error in sync listener: $e');
      }
    }
    
    debugPrint('OfflineManager: Sync complete - Success: ${successfulOperations.length}, Failed: ${permanentlyFailed.length}, Remaining: ${_offlineQueue.length}');
  }

  /// Cache data for offline access
  Future<void> cacheData(String key, Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = await _getCachedData();
      
      cachedData[key] = {
        'data': data,
        'timestamp': DateTime.now().toIso8601String(),
        'version': 1,
      };
      
      await prefs.setString(_offlineDataKey, jsonEncode(cachedData));
      debugPrint('OfflineManager: Cached data for key: $key');
    } catch (e) {
      debugPrint('OfflineManager: Error caching data: $e');
    }
  }

  /// Get cached data
  Future<Map<String, dynamic>?> getCachedData(String key) async {
    try {
      final cachedData = await _getCachedData();
      final entry = cachedData[key];
      
      if (entry != null) {
        final timestamp = DateTime.parse(entry['timestamp']);
        final age = DateTime.now().difference(timestamp);
        
        // Return data if it's less than 24 hours old
        if (age.inHours < 24) {
          return entry['data'] as Map<String, dynamic>?;
        } else {
          // Remove expired data
          cachedData.remove(key);
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_offlineDataKey, jsonEncode(cachedData));
        }
      }
    } catch (e) {
      debugPrint('OfflineManager: Error getting cached data: $e');
    }
    
    return null;
  }

  /// Get all cached data
  Future<Map<String, dynamic>> _getCachedData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString(_offlineDataKey) ?? '{}';
      return jsonDecode(dataString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('OfflineManager: Error loading cached data: $e');
      return {};
    }
  }

  /// Clear cached data
  Future<void> clearCachedData({String? key}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      if (key != null) {
        final cachedData = await _getCachedData();
        cachedData.remove(key);
        await prefs.setString(_offlineDataKey, jsonEncode(cachedData));
        debugPrint('OfflineManager: Cleared cached data for key: $key');
      } else {
        await prefs.remove(_offlineDataKey);
        debugPrint('OfflineManager: Cleared all cached data');
      }
    } catch (e) {
      debugPrint('OfflineManager: Error clearing cached data: $e');
    }
  }

  /// Persist offline queue to storage
  Future<void> _persistOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueData = _offlineQueue.map((op) => op.toJson()).toList();
      await prefs.setString(_offlineQueueKey, jsonEncode(queueData));
    } catch (e) {
      debugPrint('OfflineManager: Error persisting offline queue: $e');
    }
  }

  /// Load offline queue from storage
  Future<void> _loadOfflineQueue() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final queueString = prefs.getString(_offlineQueueKey);
      
      if (queueString != null && queueString.isNotEmpty) {
        final queueData = jsonDecode(queueString) as List<dynamic>;
        _offlineQueue.clear();
        
        for (final operationData in queueData) {
          try {
            final operation = OfflineOperation.fromJson(operationData);
            _offlineQueue.add(operation);
          } catch (e) {
            debugPrint('OfflineManager: Error loading operation from queue: $e');
          }
        }
        
        debugPrint('OfflineManager: Loaded ${_offlineQueue.length} operations from storage');
      }
    } catch (e) {
      debugPrint('OfflineManager: Error loading offline queue: $e');
    }
  }

  /// Update sync statistics
  Future<void> _updateSyncStats(int successful, int failed) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsString = prefs.getString(_offlineStatsKey) ?? '{}';
      final stats = jsonDecode(statsString) as Map<String, dynamic>;
      
      stats['totalSynced'] = (stats['totalSynced'] ?? 0) + successful;
      stats['totalFailed'] = (stats['totalFailed'] ?? 0) + failed;
      stats['lastSyncTime'] = DateTime.now().toIso8601String();
      stats['syncCount'] = (stats['syncCount'] ?? 0) + 1;
      
      await prefs.setString(_offlineStatsKey, jsonEncode(stats));
      await prefs.setString(_lastSyncTimestampKey, DateTime.now().toIso8601String());
    } catch (e) {
      debugPrint('OfflineManager: Error updating sync stats: $e');
    }
  }

  /// Get offline statistics
  Future<Map<String, dynamic>> getOfflineStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final statsString = prefs.getString(_offlineStatsKey) ?? '{}';
      final stats = jsonDecode(statsString) as Map<String, dynamic>;
      
      return {
        'isOffline': _isOffline,
        'queueSize': _offlineQueue.length,
        'totalSynced': stats['totalSynced'] ?? 0,
        'totalFailed': stats['totalFailed'] ?? 0,
        'lastSyncTime': stats['lastSyncTime'],
        'syncCount': stats['syncCount'] ?? 0,
        'cacheSize': (await _getCachedData()).length,
      };
    } catch (e) {
      debugPrint('OfflineManager: Error getting offline stats: $e');
      return {};
    }
  }

  /// Add connectivity listener
  void addConnectivityListener(Function(bool isOffline) listener) {
    _connectivityListeners.add(listener);
  }

  /// Remove connectivity listener
  void removeConnectivityListener(Function(bool isOffline) listener) {
    _connectivityListeners.remove(listener);
  }

  /// Add sync listener
  void addSyncListener(Function() listener) {
    _syncListeners.add(listener);
  }

  /// Remove sync listener
  void removeSyncListener(Function() listener) {
    _syncListeners.remove(listener);
  }

  /// Force sync attempt
  Future<void> forceSyncAttempt() async {
    await _checkConnectivity();
    if (!_isOffline) {
      await syncOfflineOperations();
    }
  }

  /// Clear all offline data
  Future<void> clearAllOfflineData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_offlineQueueKey);
      await prefs.remove(_offlineDataKey);
      await prefs.remove(_offlineStatsKey);
      
      _offlineQueue.clear();
      
      debugPrint('OfflineManager: Cleared all offline data');
    } catch (e) {
      debugPrint('OfflineManager: Error clearing offline data: $e');
    }
  }

  /// Dispose resources
  void dispose() {
    _connectivitySubscription?.cancel();
    _syncTimer?.cancel();
    _connectivityListeners.clear();
    _syncListeners.clear();
  }
}

/// Base class for offline operations
abstract class OfflineOperation {
  final String id;
  final String type;
  final Map<String, dynamic> data;
  final DateTime timestamp;
  int retryCount;
  
  OfflineOperation({
    required this.type,
    required this.data,
    String? id,
    this.retryCount = 0,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
       timestamp = DateTime.now();

  /// Execute the operation
  Future<void> execute();

  /// Increment retry count
  void incrementRetryCount() {
    retryCount++;
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'data': data,
      'timestamp': timestamp.toIso8601String(),
      'retryCount': retryCount,
    };
  }

  /// Create from JSON
  static OfflineOperation fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String;
    
    switch (type) {
      case 'user_data_update':
        return UserDataUpdateOfflineOperation.fromJson(json);
      case 'step_data_update':
        return StepDataUpdateOfflineOperation.fromJson(json);
      case 'achievement_update':
        return AchievementUpdateOfflineOperation.fromJson(json);
      case 'water_update':
        return WaterUpdateOfflineOperation.fromJson(json);
      default:
        return GenericOfflineOperation.fromJson(json);
    }
  }
}

/// Generic offline operation
class GenericOfflineOperation extends OfflineOperation {
  GenericOfflineOperation({
    required String type,
    required Map<String, dynamic> data,
    String? id,
    int retryCount = 0,
  }) : super(type: type, data: data, id: id, retryCount: retryCount);

  @override
  Future<void> execute() async {
    // Generic execution - override in specific implementations
    debugPrint('GenericOfflineOperation: Executing $type');
  }

  static GenericOfflineOperation fromJson(Map<String, dynamic> json) {
    return GenericOfflineOperation(
      type: json['type'],
      data: json['data'],
      id: json['id'],
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// User data update offline operation
class UserDataUpdateOfflineOperation extends OfflineOperation {
  UserDataUpdateOfflineOperation({
    required Map<String, dynamic> userData,
    String? id,
    int retryCount = 0,
  }) : super(
    type: 'user_data_update',
    data: userData,
    id: id,
    retryCount: retryCount,
  );

  @override
  Future<void> execute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .update({
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
  }

  static UserDataUpdateOfflineOperation fromJson(Map<String, dynamic> json) {
    return UserDataUpdateOfflineOperation(
      userData: json['data'],
      id: json['id'],
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// Step data update offline operation
class StepDataUpdateOfflineOperation extends OfflineOperation {
  StepDataUpdateOfflineOperation({
    required Map<String, dynamic> stepData,
    String? id,
    int retryCount = 0,
  }) : super(
    type: 'step_data_update',
    data: stepData,
    id: id,
    retryCount: retryCount,
  );

  @override
  Future<void> execute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final date = data['date'] as String;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('stepData')
        .doc(date)
        .set({
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static StepDataUpdateOfflineOperation fromJson(Map<String, dynamic> json) {
    return StepDataUpdateOfflineOperation(
      stepData: json['data'],
      id: json['id'],
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// Achievement update offline operation
class AchievementUpdateOfflineOperation extends OfflineOperation {
  AchievementUpdateOfflineOperation({
    required Map<String, dynamic> achievementData,
    String? id,
    int retryCount = 0,
  }) : super(
    type: 'achievement_update',
    data: achievementData,
    id: id,
    retryCount: retryCount,
  );

  @override
  Future<void> execute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('achievements')
        .doc('progress')
        .set({
      'progress': data,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static AchievementUpdateOfflineOperation fromJson(Map<String, dynamic> json) {
    return AchievementUpdateOfflineOperation(
      achievementData: json['data'],
      id: json['id'],
      retryCount: json['retryCount'] ?? 0,
    );
  }
}

/// Water update offline operation
class WaterUpdateOfflineOperation extends OfflineOperation {
  WaterUpdateOfflineOperation({
    required Map<String, dynamic> waterData,
    String? id,
    int retryCount = 0,
  }) : super(
    type: 'water_update',
    data: waterData,
    id: id,
    retryCount: retryCount,
  );

  @override
  Future<void> execute() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('No authenticated user');

    final date = data['date'] as String;
    await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('waterData')
        .doc(date)
        .set({
      ...data,
      'lastUpdated': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static WaterUpdateOfflineOperation fromJson(Map<String, dynamic> json) {
    return WaterUpdateOfflineOperation(
      waterData: json['data'],
      id: json['id'],
      retryCount: json['retryCount'] ?? 0,
    );
  }
}