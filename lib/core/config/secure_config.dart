// lib/core/config/secure_config.dart

import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';

/// Secure configuration management for sensitive app settings
class SecureConfig {
  static final SecureConfig _instance = SecureConfig._internal();
  factory SecureConfig() => _instance;
  SecureConfig._internal();

  static const FlutterSecureStorage _secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_PKCS1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock_this_device,
    ),
  );

  static Map<String, dynamic> _config = {};
  static bool _isInitialized = false;
  
  // Configuration keys
  static const String _configKey = 'secure_app_config_v2';
  static const String _encryptionKeyKey = 'app_encryption_key';
  static const String _configVersionKey = 'config_version';
  static const String _deviceIdKey = 'device_id';
  
  // Current config version
  static const int _currentConfigVersion = 2;

  /// Initialize secure configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // Check if we need to migrate or create new config
      await _checkAndMigrateConfig();
      
      // Load configuration from secure storage
      final configString = await _secureStorage.read(key: _configKey);
      
      if (configString != null && configString.isNotEmpty) {
        try {
          _config = jsonDecode(configString);
          debugPrint('SecureConfig: Loaded existing configuration');
        } catch (e) {
          debugPrint('SecureConfig: Error parsing config, regenerating: $e');
          await _generateDefaultConfig();
        }
      } else {
        await _generateDefaultConfig();
      }
      
      // Ensure device ID exists
      await _ensureDeviceId();
      
      _isInitialized = true;
      debugPrint('SecureConfig: Initialization complete');
    } catch (e) {
      debugPrint('SecureConfig: Initialization error: $e');
      // Fallback to default config
      await _generateDefaultConfig();
      _isInitialized = true;
    }
  }

  /// Check and migrate configuration if needed
  static Future<void> _checkAndMigrateConfig() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currentVersion = prefs.getInt(_configVersionKey) ?? 0;
      
      if (currentVersion < _currentConfigVersion) {
        debugPrint('SecureConfig: Migrating from version $currentVersion to $_currentConfigVersion');
        
        // Perform migration based on version
        if (currentVersion == 0) {
          // First time setup or migration from v1
          await _migrateFromV1();
        }
        
        // Update version
        await prefs.setInt(_configVersionKey, _currentConfigVersion);
        debugPrint('SecureConfig: Migration complete');
      }
    } catch (e) {
      debugPrint('SecureConfig: Migration error: $e');
    }
  }

  /// Migrate from version 1 configuration
  static Future<void> _migrateFromV1() async {
    try {
      // Clear old insecure configuration
      final prefs = await SharedPreferences.getInstance();
      final oldKeys = prefs.getKeys().where((key) => key.startsWith('config_')).toList();
      for (final key in oldKeys) {
        await prefs.remove(key);
      }
      
      // Clear old secure storage entries
      await _secureStorage.delete(key: 'secure_app_config');
      
      debugPrint('SecureConfig: Cleared old configuration');
    } catch (e) {
      debugPrint('SecureConfig: V1 migration error: $e');
    }
  }

  /// Generate default secure configuration
  static Future<void> _generateDefaultConfig() async {
    try {
      _config = {
        'app_version': '1.0.0',
        'encryption_key': _generateSecureKey(),
        'api_timeout': 30000,
        'cache_ttl': 300000,
        'max_retry_attempts': 3,
        'batch_size': 50,
        'sync_interval': 300000,
        'offline_mode_enabled': true,
        'analytics_enabled': true,
        'crash_reporting_enabled': true,
        'performance_monitoring_enabled': true,
        'debug_mode': kDebugMode,
        'created_at': DateTime.now().toIso8601String(),
        'last_updated': DateTime.now().toIso8601String(),
      };
      
      await _saveConfig();
      debugPrint('SecureConfig: Generated default configuration');
    } catch (e) {
      debugPrint('SecureConfig: Error generating default config: $e');
    }
  }

  /// Generate a secure encryption key
  static String _generateSecureKey() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (i) => random.nextInt(256));
    return base64Encode(bytes);
  }

  /// Ensure device ID exists
  static Future<void> _ensureDeviceId() async {
    try {
      String? deviceId = await _secureStorage.read(key: _deviceIdKey);
      
      if (deviceId == null || deviceId.isEmpty) {
        // Generate new device ID
        deviceId = _generateDeviceId();
        await _secureStorage.write(key: _deviceIdKey, value: deviceId);
        debugPrint('SecureConfig: Generated new device ID');
      }
      
      _config['device_id'] = deviceId;
    } catch (e) {
      debugPrint('SecureConfig: Error ensuring device ID: $e');
      // Fallback to timestamp-based ID
      _config['device_id'] = 'device_${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Generate unique device ID
  static String _generateDeviceId() {
    final random = Random.secure();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final randomBytes = List<int>.generate(16, (i) => random.nextInt(256));
    final combined = '$timestamp${base64Encode(randomBytes)}';
    final hash = sha256.convert(utf8.encode(combined));
    return hash.toString().substring(0, 32);
  }

  /// Save configuration to secure storage
  static Future<void> _saveConfig() async {
    try {
      _config['last_updated'] = DateTime.now().toIso8601String();
      final configString = jsonEncode(_config);
      await _secureStorage.write(key: _configKey, value: configString);
    } catch (e) {
      debugPrint('SecureConfig: Error saving config: $e');
    }
  }

  /// Get configuration value
  static T? get<T>(String key, {T? defaultValue}) {
    _ensureInitialized();
    return _config[key] as T? ?? defaultValue;
  }

  /// Set configuration value
  static Future<void> set<T>(String key, T value) async {
    _ensureInitialized();
    _config[key] = value;
    await _saveConfig();
  }

  /// Get encryption key
  static String get encryptionKey {
    return get<String>('encryption_key') ?? _generateSecureKey();
  }

  /// Get device ID
  static String get deviceId {
    return get<String>('device_id') ?? 'unknown_device';
  }

  /// Get API timeout
  static int get apiTimeout {
    return get<int>('api_timeout') ?? 30000;
  }

  /// Get cache TTL
  static int get cacheTtl {
    return get<int>('cache_ttl') ?? 300000;
  }

  /// Get max retry attempts
  static int get maxRetryAttempts {
    return get<int>('max_retry_attempts') ?? 3;
  }

  /// Get batch size
  static int get batchSize {
    return get<int>('batch_size') ?? 50;
  }

  /// Get sync interval
  static int get syncInterval {
    return get<int>('sync_interval') ?? 300000;
  }

  /// Check if offline mode is enabled
  static bool get isOfflineModeEnabled {
    return get<bool>('offline_mode_enabled') ?? true;
  }

  /// Check if analytics is enabled
  static bool get isAnalyticsEnabled {
    return get<bool>('analytics_enabled') ?? true;
  }

  /// Check if crash reporting is enabled
  static bool get isCrashReportingEnabled {
    return get<bool>('crash_reporting_enabled') ?? true;
  }

  /// Check if performance monitoring is enabled
  static bool get isPerformanceMonitoringEnabled {
    return get<bool>('performance_monitoring_enabled') ?? true;
  }

  /// Check if debug mode is enabled
  static bool get isDebugMode {
    return get<bool>('debug_mode') ?? kDebugMode;
  }

  /// Update configuration
  static Future<void> updateConfig(Map<String, dynamic> updates) async {
    _ensureInitialized();
    
    for (final entry in updates.entries) {
      _config[entry.key] = entry.value;
    }
    
    await _saveConfig();
    debugPrint('SecureConfig: Updated ${updates.length} configuration values');
  }

  /// Get all configuration
  static Map<String, dynamic> getAllConfig() {
    _ensureInitialized();
    return Map<String, dynamic>.from(_config);
  }

  /// Reset configuration to defaults
  static Future<void> resetToDefaults() async {
    await _generateDefaultConfig();
    debugPrint('SecureConfig: Reset to default configuration');
  }

  /// Clear all configuration
  static Future<void> clearAll() async {
    try {
      await _secureStorage.delete(key: _configKey);
      await _secureStorage.delete(key: _deviceIdKey);
      _config.clear();
      _isInitialized = false;
      debugPrint('SecureConfig: Cleared all configuration');
    } catch (e) {
      debugPrint('SecureConfig: Error clearing configuration: $e');
    }
  }

  /// Validate configuration integrity
  static bool validateConfig() {
    _ensureInitialized();
    
    // Check required keys
    final requiredKeys = [
      'encryption_key',
      'device_id',
      'created_at',
    ];
    
    for (final key in requiredKeys) {
      if (!_config.containsKey(key) || _config[key] == null) {
        debugPrint('SecureConfig: Missing required key: $key');
        return false;
      }
    }
    
    // Validate encryption key format
    final encryptionKey = _config['encryption_key'] as String?;
    if (encryptionKey == null || encryptionKey.length < 32) {
      debugPrint('SecureConfig: Invalid encryption key');
      return false;
    }
    
    return true;
  }

  /// Get configuration statistics
  static Map<String, dynamic> getStats() {
    _ensureInitialized();
    
    return {
      'total_keys': _config.length,
      'is_valid': validateConfig(),
      'created_at': _config['created_at'],
      'last_updated': _config['last_updated'],
      'config_version': _currentConfigVersion,
      'device_id': deviceId,
    };
  }

  /// Ensure initialization
  static void _ensureInitialized() {
    if (!_isInitialized) {
      throw StateError('SecureConfig not initialized. Call SecureConfig.initialize() first.');
    }
  }

  /// Export configuration (for backup/debugging)
  static Future<String> exportConfig({bool includeSecrets = false}) async {
    _ensureInitialized();
    
    final exportData = Map<String, dynamic>.from(_config);
    
    if (!includeSecrets) {
      // Remove sensitive data
      exportData.remove('encryption_key');
      exportData.remove('device_id');
    }
    
    return jsonEncode(exportData);
  }

  /// Import configuration (for restore)
  static Future<bool> importConfig(String configJson) async {
    try {
      final importedConfig = jsonDecode(configJson) as Map<String, dynamic>;
      
      // Validate imported config
      if (importedConfig.isEmpty) {
        debugPrint('SecureConfig: Empty configuration provided');
        return false;
      }
      
      // Merge with current config (preserve device-specific settings)
      final deviceId = _config['device_id'];
      final encryptionKey = _config['encryption_key'];
      
      _config = importedConfig;
      
      // Restore device-specific settings
      if (deviceId != null) _config['device_id'] = deviceId;
      if (encryptionKey != null) _config['encryption_key'] = encryptionKey;
      
      await _saveConfig();
      debugPrint('SecureConfig: Configuration imported successfully');
      return true;
    } catch (e) {
      debugPrint('SecureConfig: Error importing configuration: $e');
      return false;
    }
  }
}