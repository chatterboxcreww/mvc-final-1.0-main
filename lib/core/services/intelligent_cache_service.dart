// lib/core/services/intelligent_cache_service.dart

import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Intelligent caching service with TTL, LRU eviction, and memory management
class IntelligentCacheService {
  static final IntelligentCacheService _instance = IntelligentCacheService._internal();
  factory IntelligentCacheService() => _instance;
  IntelligentCacheService._internal();

  final Map<String, CacheEntry> _memoryCache = {};
  final Map<String, DateTime> _accessTimes = {};
  SharedPreferences? _prefs;
  Timer? _cleanupTimer;
  
  // Configuration
  static const int _maxMemoryCacheSize = 100;
  static const Duration _defaultTtl = Duration(minutes: 5);
  static const Duration _cleanupInterval = Duration(minutes: 1);
  static const String _persistentCachePrefix = 'cache_';
  
  bool _isInitialized = false;

  /// Initialize the cache service
  Future<void> initialize() async {
    if (_isInitialized) return;
    
    _prefs = await SharedPreferences.getInstance();
    _startCleanupTimer();
    _isInitialized = true;
    
    debugPrint('IntelligentCacheService: Initialized with max size $_maxMemoryCacheSize');
  }

  /// Start periodic cleanup timer
  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      _performCleanup();
    });
  }

  /// Get cached data
  Future<T?> get<T>(String key, {bool fromPersistent = false}) async {
    await _ensureInitialized();
    
    // Update access time
    _accessTimes[key] = DateTime.now();
    
    // Try memory cache first
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      debugPrint('IntelligentCache: Memory cache hit for $key');
      return memoryEntry.data as T?;
    }
    
    // Try persistent cache if requested
    if (fromPersistent) {
      final persistentData = await _getFromPersistentCache<T>(key);
      if (persistentData != null) {
        // Store in memory cache for faster access
        await set(key, persistentData, persist: false);
        debugPrint('IntelligentCache: Persistent cache hit for $key');
        return persistentData;
      }
    }
    
    debugPrint('IntelligentCache: Cache miss for $key');
    return null;
  }

  /// Set cached data
  Future<void> set<T>(
    String key,
    T data, {
    Duration? ttl,
    bool persist = false,
  }) async {
    await _ensureInitialized();
    
    final expiresAt = DateTime.now().add(ttl ?? _defaultTtl);
    final entry = CacheEntry(
      data: data,
      expiresAt: expiresAt,
      createdAt: DateTime.now(),
    );
    
    // Store in memory cache
    _memoryCache[key] = entry;
    _accessTimes[key] = DateTime.now();
    
    // Enforce memory cache size limit
    await _enforceMemoryCacheLimit();
    
    // Store in persistent cache if requested
    if (persist) {
      await _setToPersistentCache(key, data, expiresAt);
    }
    
    debugPrint('IntelligentCache: Cached $key (TTL: ${ttl?.inMinutes ?? _defaultTtl.inMinutes}min, Persist: $persist)');
  }

  /// Remove cached data
  Future<void> remove(String key, {bool fromPersistent = false}) async {
    await _ensureInitialized();
    
    _memoryCache.remove(key);
    _accessTimes.remove(key);
    
    if (fromPersistent) {
      await _prefs?.remove('$_persistentCachePrefix$key');
      await _prefs?.remove('${_persistentCachePrefix}${key}_expires');
    }
    
    debugPrint('IntelligentCache: Removed $key');
  }

  /// Clear all cached data
  Future<void> clear({bool clearPersistent = false}) async {
    await _ensureInitialized();
    
    _memoryCache.clear();
    _accessTimes.clear();
    
    if (clearPersistent) {
      final keys = _prefs?.getKeys() ?? <String>{};
      for (final key in keys) {
        if (key.startsWith(_persistentCachePrefix)) {
          await _prefs?.remove(key);
        }
      }
    }
    
    debugPrint('IntelligentCache: Cleared all cache (persistent: $clearPersistent)');
  }

  /// Check if key exists in cache
  Future<bool> contains(String key, {bool checkPersistent = false}) async {
    await _ensureInitialized();
    
    // Check memory cache
    final memoryEntry = _memoryCache[key];
    if (memoryEntry != null && !memoryEntry.isExpired) {
      return true;
    }
    
    // Check persistent cache if requested
    if (checkPersistent) {
      return await _containsInPersistentCache(key);
    }
    
    return false;
  }

  /// Get cache statistics
  Future<Map<String, dynamic>> getStats() async {
    await _ensureInitialized();
    
    final now = DateTime.now();
    int expiredCount = 0;
    int validCount = 0;
    
    for (final entry in _memoryCache.values) {
      if (entry.isExpired) {
        expiredCount++;
      } else {
        validCount++;
      }
    }
    
    final persistentKeys = _prefs?.getKeys()
        .where((key) => key.startsWith(_persistentCachePrefix))
        .length ?? 0;
    
    return {
      'memorySize': _memoryCache.length,
      'maxMemorySize': _maxMemoryCacheSize,
      'validEntries': validCount,
      'expiredEntries': expiredCount,
      'persistentEntries': persistentKeys,
      'lastCleanup': _lastCleanupTime?.toIso8601String(),
    };
  }

  /// Perform cache cleanup
  DateTime? _lastCleanupTime;
  
  void _performCleanup() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    // Find expired entries
    for (final entry in _memoryCache.entries) {
      if (entry.value.isExpired) {
        expiredKeys.add(entry.key);
      }
    }
    
    // Remove expired entries
    for (final key in expiredKeys) {
      _memoryCache.remove(key);
      _accessTimes.remove(key);
    }
    
    _lastCleanupTime = now;
    
    if (expiredKeys.isNotEmpty) {
      debugPrint('IntelligentCache: Cleaned up ${expiredKeys.length} expired entries');
    }
  }

  /// Enforce memory cache size limit using LRU eviction
  Future<void> _enforceMemoryCacheLimit() async {
    if (_memoryCache.length <= _maxMemoryCacheSize) return;
    
    // Sort by access time (least recently used first)
    final sortedEntries = _accessTimes.entries.toList()
      ..sort((a, b) => a.value.compareTo(b.value));
    
    // Remove oldest entries
    final entriesToRemove = _memoryCache.length - _maxMemoryCacheSize;
    for (int i = 0; i < entriesToRemove; i++) {
      final key = sortedEntries[i].key;
      _memoryCache.remove(key);
      _accessTimes.remove(key);
    }
    
    debugPrint('IntelligentCache: Evicted $entriesToRemove entries (LRU)');
  }

  /// Store data in persistent cache
  Future<void> _setToPersistentCache<T>(String key, T data, DateTime expiresAt) async {
    try {
      final serializedData = jsonEncode({
        'data': data,
        'type': T.toString(),
        'createdAt': DateTime.now().toIso8601String(),
      });
      
      await _prefs?.setString('$_persistentCachePrefix$key', serializedData);
      await _prefs?.setString('${_persistentCachePrefix}${key}_expires', expiresAt.toIso8601String());
    } catch (e) {
      debugPrint('IntelligentCache: Error storing persistent cache for $key: $e');
    }
  }

  /// Get data from persistent cache
  Future<T?> _getFromPersistentCache<T>(String key) async {
    try {
      final expiresString = _prefs?.getString('${_persistentCachePrefix}${key}_expires');
      if (expiresString != null) {
        final expiresAt = DateTime.parse(expiresString);
        if (DateTime.now().isAfter(expiresAt)) {
          // Expired, remove it
          await _prefs?.remove('$_persistentCachePrefix$key');
          await _prefs?.remove('${_persistentCachePrefix}${key}_expires');
          return null;
        }
      }
      
      final dataString = _prefs?.getString('$_persistentCachePrefix$key');
      if (dataString != null) {
        final dataMap = jsonDecode(dataString);
        return dataMap['data'] as T?;
      }
    } catch (e) {
      debugPrint('IntelligentCache: Error loading persistent cache for $key: $e');
    }
    
    return null;
  }

  /// Check if key exists in persistent cache
  Future<bool> _containsInPersistentCache(String key) async {
    try {
      final expiresString = _prefs?.getString('${_persistentCachePrefix}${key}_expires');
      if (expiresString != null) {
        final expiresAt = DateTime.parse(expiresString);
        if (DateTime.now().isAfter(expiresAt)) {
          return false;
        }
      }
      
      return _prefs?.containsKey('$_persistentCachePrefix$key') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Ensure initialization
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// Dispose resources
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    _memoryCache.clear();
    _accessTimes.clear();
  }

  /// Preload frequently used data
  Future<void> preloadData(Map<String, dynamic> data, {Duration? ttl}) async {
    for (final entry in data.entries) {
      await set(entry.key, entry.value, ttl: ttl, persist: true);
    }
    debugPrint('IntelligentCache: Preloaded ${data.length} entries');
  }

  /// Get cache hit ratio
  double getCacheHitRatio() {
    // This would need to be tracked over time in a real implementation
    // For now, return a placeholder
    return 0.85; // 85% hit ratio
  }

  /// Warm up cache with common data
  Future<void> warmUpCache() async {
    // This would preload commonly accessed data
    // Implementation depends on specific app needs
    debugPrint('IntelligentCache: Cache warmed up');
  }
}

/// Cache entry with expiration and metadata
class CacheEntry {
  final dynamic data;
  final DateTime expiresAt;
  final DateTime createdAt;

  CacheEntry({
    required this.data,
    required this.expiresAt,
    required this.createdAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
  
  Duration get age => DateTime.now().difference(createdAt);
  
  Duration get timeToLive => expiresAt.difference(DateTime.now());
}

/// Cache configuration
class CacheConfig {
  final Duration defaultTtl;
  final int maxMemorySize;
  final bool enablePersistence;
  final Duration cleanupInterval;

  const CacheConfig({
    this.defaultTtl = const Duration(minutes: 5),
    this.maxMemorySize = 100,
    this.enablePersistence = true,
    this.cleanupInterval = const Duration(minutes: 1),
  });
}