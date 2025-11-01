// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\providers\user_data_provider.dart

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_data.dart';
import '../models/daily_step_data.dart';
import '../services/auth_service.dart';
import '../services/storage_service.dart';
import '../services/data_sync_manager.dart';
import '../services/daily_sync_service.dart';
import '../utils/image_utils.dart';

class UserDataProvider with ChangeNotifier {
  UserData _userData = UserData(userId: '');
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final Connectivity _connectivity = Connectivity();
  final DataSyncManager _syncManager = DataSyncManager();
  final DailySyncService _dailySyncService = DailySyncService();
  
  // SharedPreferences instance for instant cache access
  late SharedPreferences _prefs;
  
  // Instagram-style properties
  bool _isInitialized = false;
  bool _isSyncing = false;
  bool _isOnline = true;
  DateTime? _lastDataUpdate;
  
  // Current user reference
  User? _currentUser;

  // Error handling
  String? _lastError;
  bool _isLoading = false;

  // Cache for Firebase user
  User? _cachedUser;

  // Data integrity status
  bool _dataIntegrityVerified = false;

  // Getters
  UserData get userData => _userData;
  String? get lastError => _lastError;
  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;
  DateTime? get lastDataUpdate => _lastDataUpdate;
  bool get isOnline => _isOnline;
  bool get isSyncing => _isSyncing;
  bool get dataIntegrityVerified => _dataIntegrityVerified;
  
  // Setter for direct assignment (used by AuthWrapper for new users)
  set userData(UserData newUserData) {
    _userData = newUserData.sanitized();
    notifyListeners();
  }
  
  /// Gets the current Firebase user
  User? getCurrentUser() {
    return _cachedUser ?? FirebaseAuth.instance.currentUser;
  }

  // Offline data cache - Enhanced for social media-like persistence
  static const String _userDataCacheKey = 'user_data_cache_v2';
  static const String _lastSyncKey = 'last_user_data_sync_v2';
  static const String _dataHashKey = 'user_data_integrity_hash';
  static const String _lastUpdateKey = 'last_data_update_timestamp';
  static const String _criticalDataKey = 'critical_user_data_backup';

  /// Initialize the provider like a social media app
  Future<void> initializeSocialMediaStyle() async {
    if (_isInitialized) return;

    try {
      // Initialize SharedPreferences first
      _prefs = await SharedPreferences.getInstance();
      
      // Initialize DataSyncManager
      await _syncManager.initialize();
      
      // Check for persisted auth state first
      final hasPersistedAuth = await checkPersistedAuthState();
      
      // Set current user from Firebase or cached state
      _currentUser = FirebaseAuth.instance.currentUser;
      _cachedUser = _currentUser;
      
      // If no Firebase user but we have persisted auth, try to restore
      if (_currentUser == null && hasPersistedAuth) {
        print('UserDataProvider: Attempting to restore session from persisted auth');
        // The checkPersistedAuthState already set up cached user data
        _currentUser = _cachedUser;
      }
      
      // Check connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      _isOnline = connectivityResult != ConnectivityResult.none;
      
      // Add connectivity listener to sync manager
      _syncManager.addConnectivityListener(_onConnectivityChanged);
      _syncManager.addSyncListener(_onSyncStatusChanged);
      
      // Load from multiple cache layers (Instagram-style)
      await _loadFromMultipleCacheLayers();
      
      _isInitialized = true;
      print('UserDataProvider: Initialized with social media-style data management and DataSyncManager');
    } catch (e) {
      print('UserDataProvider: Initialization error: $e');
    }
  }

  /// Saves the current authentication state to local storage with validation
  Future<void> _saveAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = _cachedUser != null;
      
      await prefs.setBool('is_authenticated', isAuthenticated);
      
      if (isAuthenticated && _cachedUser != null) {
        // Validate user data before saving
        if (_cachedUser!.uid.isEmpty) {
          print('UserDataProvider: Cannot save auth state - invalid user UID');
          return;
        }
        
        await prefs.setString('cached_user_uid', _cachedUser!.uid);
        await prefs.setString('cached_user_email', _cachedUser!.email ?? '');
        await prefs.setString('cached_user_display_name', _cachedUser!.displayName ?? '');
        await prefs.setString('cached_user_photo_url', _cachedUser!.photoURL ?? '');
        await prefs.setString('auth_timestamp', DateTime.now().toIso8601String());
        
        // Save Firebase token if available for better auth persistence
        try {
          final idToken = await _cachedUser!.getIdToken(false); // Don't force refresh
          if (idToken != null && idToken.isNotEmpty) {
            await prefs.setString('cached_user_token', idToken);
          }
        } catch (tokenError) {
          print('UserDataProvider: Error saving token (non-critical): $tokenError');
          // Don't fail the entire save operation for token errors
        }
        
        print('UserDataProvider: Auth state saved successfully for user: ${_cachedUser!.email ?? _cachedUser!.uid}');
      } else {
        await _clearAuthState();
      }
    } catch (e) {
      print('UserDataProvider: Error saving auth state: $e');
    }
  }

  /// Checks if there's a persisted authentication state
  Future<bool> checkPersistedAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isAuthenticated = prefs.getBool('is_authenticated') ?? false;
      final authTimestamp = prefs.getString('auth_timestamp');
      final cachedUserUid = prefs.getString('cached_user_uid');
      final cachedUserEmail = prefs.getString('cached_user_email');
      final cachedDisplayName = prefs.getString('cached_user_display_name');
      final cachedPhotoUrl = prefs.getString('cached_user_photo_url');
      
      if (isAuthenticated && authTimestamp != null && cachedUserUid != null) {
        // Check if auth state is not too old (extend to 90 days for better persistence)
        final authTime = DateTime.parse(authTimestamp);
        if (DateTime.now().difference(authTime).inDays > 90) {
          print('Persisted auth state is too old, clearing');
          await _clearAuthState();
          return false;
        }
        
        // If we have a cached user ID, attempt to restore Firebase auth state
        if (_cachedUser == null && cachedUserUid.isNotEmpty) {
          _cachedUser = FirebaseAuth.instance.currentUser;
          
          // If Firebase auth doesn't have the current user but we have cached credentials,
          // create a mock user object to work with cached data
          if (_cachedUser == null) {
            print('Firebase auth unavailable, using cached auth data for offline experience');
            // Store the cached UID to try silent sign-in later
            _userData = _userData.copyWith(
              userId: cachedUserUid,
              name: cachedDisplayName?.isNotEmpty == true ? cachedDisplayName!.split(' ').first : null,
              profilePicturePath: cachedPhotoUrl?.isNotEmpty == true ? cachedPhotoUrl : null,
            );
            
            // Mark that we have cached user data but need to restore Firebase auth later
            await prefs.setBool('needs_silent_signin', true);
          } else {
            // Firebase auth is available, clear the flag
            await prefs.setBool('needs_silent_signin', false);
          }
        }
        
        print('UserDataProvider: Using persisted auth state for user: ${cachedUserEmail ?? cachedUserUid}');
        return true;
      }
      return false;
    } catch (e) {
      print('Error checking persisted auth state: $e');
      return false;
    }
  }
  
  /// Clears authentication state from local storage
  Future<void> _clearAuthState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('is_authenticated');
      await prefs.remove('cached_user_uid');
      await prefs.remove('cached_user_email');
      await prefs.remove('cached_user_display_name');
      await prefs.remove('cached_user_photo_url');
      await prefs.remove('cached_user_token');
      await prefs.remove('auth_timestamp');
      await prefs.remove('needs_silent_signin');
      print('UserDataProvider: Auth state cleared completely');
    } catch (e) {
      print('Error clearing auth state: $e');
    }
  }

  /// Load user data from local storage (daily sync approach)
  Future<void> _loadUserDataFromLocal() async {
    try {
      final localUserData = await _dailySyncService.getLocalUserData();
      if (localUserData != null) {
        _userData = localUserData;
        debugPrint('UserDataProvider: Loaded user data from local storage');
      } else {
        debugPrint('UserDataProvider: No local user data found');
      }
    } catch (e) {
      print('Error clearing auth state: $e');
    }
  }

  /// Save user data to local storage immediately

  /// Load user data with improved error recovery and retry logic
  Future<bool> loadUserData() async {
    // Prevent concurrent loading
    if (_isLoading) {
      print('UserDataProvider: Load already in progress, waiting...');
      // Wait for current load to complete
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 100));
      }
      return _userData.userId.isNotEmpty;
    }

    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      final isOnline = connectivityResult != ConnectivityResult.none;

      print('UserDataProvider: Network status - Online: $isOnline');

      // Get cached user or fetch from Firebase
      _cachedUser = FirebaseAuth.instance.currentUser;

      // Always try to load from local cache first
      final cachedData = await _loadFromLocalCache();
      if (cachedData != null) {
        _userData = cachedData;
        print('UserDataProvider: Loaded data from offline cache');
        
        // If we have cache data and we're offline, return success
        if (!isOnline) {
          _isLoading = false;
          notifyListeners();
          return true;
        }
        
        // If online, continue to sync with Firebase but don't block on it
        notifyListeners(); // Update UI with cache data immediately
      }

      // Handle authentication state
      if (_cachedUser == null && isOnline) {
        print('UserDataProvider: No cached user, checking persisted auth...');
        
        final hasPersistedAuth = await checkPersistedAuthState();
        if (hasPersistedAuth) {
          print('UserDataProvider: Using persisted auth state');
          
          // Try to restore Firebase auth
          try {
            _cachedUser = await _authService.silentSignIn().timeout(
              const Duration(seconds: 10),
            );
            if (_cachedUser != null) {
              print('UserDataProvider: Successfully restored Firebase auth');
              await _saveAuthState();
            }
          } catch (e) {
            print('UserDataProvider: Failed to restore Firebase auth: $e');
            // Continue with cached data if available
            if (cachedData != null) {
              _isLoading = false;
              notifyListeners();
              return true;
            }
          }
        }
      }

      // If still no user, handle appropriately
      if (_cachedUser == null) {
        if (cachedData != null) {
          print('UserDataProvider: No user but have cached data, using offline mode');
          _isLoading = false;
          notifyListeners();
          return true;
        }
        
        print('UserDataProvider: No user found, clearing data');
        _userData = UserData(userId: '');
        await _clearLocalCache();
        await _clearAuthState();
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('UserDataProvider: User found, loading data from Firestore...');

      // Try to load from Firestore with retry logic
      UserData? loadedData;
      if (isOnline) {
        int retryCount = 0;
        const maxRetries = 2;
        
        while (retryCount <= maxRetries && loadedData == null) {
          try {
            loadedData = await _authService.loadUserDataFromFirestore().timeout(
              Duration(seconds: 15 + (retryCount * 5)), // Progressive timeout
            );
            break;
          } catch (e) {
            retryCount++;
            print('UserDataProvider: Firestore loading attempt $retryCount failed: $e');
            
            // Check if it's a network/timeout error
            final isNetworkError = e.toString().contains('network') ||
                                 e.toString().contains('timeout') ||
                                 e.toString().contains('connection') ||
                                 e.toString().contains('Failed host lookup');
            
            if (isNetworkError && retryCount <= maxRetries) {
              print('UserDataProvider: Network error, retrying in ${retryCount * 2}s...');
              await Future.delayed(Duration(seconds: retryCount * 2));
            } else if (!isNetworkError) {
              print('UserDataProvider: Non-network error, stopping retries');
              break;
            }
          }
        }
      }

      if (loadedData != null) {
        print('UserDataProvider: Data loaded from Firestore');
        _userData = loadedData.copyWith().sanitized();
        await _saveToLocalCache(_userData);

        // Update profile picture if needed
        String? googlePhotoURL = ImageUtils.processGooglePhotoUrl(_cachedUser!.photoURL);
        if (_shouldUpdateProfilePicture(googlePhotoURL)) {
          _userData = _userData.copyWith(profilePicturePath: googlePhotoURL);
          await _saveToLocalCache(_userData);
        }
      } else if (cachedData == null) {
        print('UserDataProvider: Creating new user data');
        _userData = UserData(userId: _cachedUser!.uid);
        await _saveToLocalCache(_userData);
      }
      // If cachedData exists but loadedData is null, keep using cachedData

      // Finalize loading
      _isLoading = false;
      notifyListeners();
      await _saveAuthState();
      return true;
      
    } catch (e) {
      print('UserDataProvider: Critical error in loadUserData: $e');
      
      // Determine if this is a recoverable error
      final isRecoverableError = e.toString().contains('network') ||
                               e.toString().contains('timeout') ||
                               e.toString().contains('connection');
      
      if (isRecoverableError) {
        _lastError = "Network error. Using offline data.";
        
        // Try to use cached data
        try {
          final cachedData = await _loadFromLocalCache();
          if (cachedData != null) {
            _userData = cachedData;
            print('UserDataProvider: Using cached data due to network error');
            _isLoading = false;
            notifyListeners();
            return true;
          }
        } catch (cacheError) {
          print('UserDataProvider: Cache recovery failed: $cacheError');
        }
      } else {
        _lastError = "Failed to load user data: $e";
      }

      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Helper method to determine if profile picture should be updated
  bool _shouldUpdateProfilePicture(String? googlePhotoURL) {
    return _userData.profilePicturePath == null ||
           (_userData.profilePicturePath!.isEmpty && googlePhotoURL != null && googlePhotoURL.isNotEmpty) ||
           (_userData.profilePicturePath!.isNotEmpty && _userData.profilePicturePath != googlePhotoURL);
  }

  /// Saves user data to local cache for offline access
  Future<void> _saveToLocalCache(UserData userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      // Store as proper JSON instead of .toString()
      final Map<String, dynamic> userDataJson = userData.toJson();
      await prefs.setString(_userDataCacheKey, jsonEncode(userDataJson));
      await prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      
      // Also save critical fields individually for quick access
      await prefs.setString('user_name', userData.name ?? '');
      await prefs.setInt('user_age', userData.age ?? 0);
      await prefs.setDouble('user_height', userData.height ?? 0.0);
      await prefs.setDouble('user_weight', userData.weight ?? 0.0);
      await prefs.setInt('user_level', userData.level);
      await prefs.setInt('daily_step_goal', userData.dailyStepGoal ?? 10000);
      await prefs.setInt('daily_water_goal', userData.dailyWaterGoal ?? 8);
      await prefs.setString('profile_picture_path', userData.profilePicturePath ?? '');
      
      print('UserDataProvider: Saved complete data to local cache');
    } catch (e) {
      print('UserDataProvider: Error saving to cache: $e');
    }
  }

  /// Loads user data from local cache
  Future<UserData?> _loadFromLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedDataString = prefs.getString(_userDataCacheKey);
      final lastSyncString = prefs.getString(_lastSyncKey);

      if (cachedDataString != null) {
        // Check if cache is not too old (30 days max instead of 7)
        if (lastSyncString != null) {
          final lastSync = DateTime.parse(lastSyncString);
          if (DateTime.now().difference(lastSync).inDays > 30) {
            print('UserDataProvider: Cache is too old, ignoring');
            return null;
          }
        }

        try {
          // Parse proper JSON
          final Map<String, dynamic> userDataJson = jsonDecode(cachedDataString);
          final userData = UserData.fromJson(userDataJson);
          print('UserDataProvider: Successfully loaded data from cache');
          return userData;
        } catch (parseError) {
          print('UserDataProvider: Error parsing cached JSON, falling back to basic data: $parseError');
          
          // Fallback: construct UserData from individual fields
          final String userId = FirebaseAuth.instance.currentUser?.uid ?? '';
          final String name = prefs.getString('user_name') ?? '';
          final int age = prefs.getInt('user_age') ?? 0;
          final double height = prefs.getDouble('user_height') ?? 0.0;
          final double weight = prefs.getDouble('user_weight') ?? 0.0;
          final int level = prefs.getInt('user_level') ?? 1;
          final int stepGoal = prefs.getInt('daily_step_goal') ?? 10000;
          final int waterGoal = prefs.getInt('daily_water_goal') ?? 8;
          final String profilePicture = prefs.getString('profile_picture_path') ?? '';
          
          return UserData(
            userId: userId,
            name: name.isNotEmpty ? name : null,
            age: age > 0 ? age : null,
            height: height > 0 ? height : null,
            weight: weight > 0 ? weight : null,
            level: level,
            dailyStepGoal: stepGoal,
            dailyWaterGoal: waterGoal,
            profilePicturePath: profilePicture.isNotEmpty ? profilePicture : null,
            memberSince: DateTime.now().subtract(const Duration(days: 30)), // Reasonable default
          );
        }
      }
    } catch (e) {
      print('UserDataProvider: Error loading from cache: $e');
    }
    return null;
  }

  /// Clears local cache
  Future<void> _clearLocalCache() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_userDataCacheKey);
      await prefs.remove(_lastSyncKey);
    } catch (e) {
      print('UserDataProvider: Error clearing cache: $e');
    }
  }

  // ==== INSTAGRAM-LIKE DATA MANAGEMENT METHODS ====

  /// Load user data with Instagram-like instant access
  Future<void> loadUserDataSocialStyle() async {
    if (_currentUser == null) return;

    // First, show cached data immediately (Instagram-style)
    await _loadFromInstantCache();
    
    try {
      // For now, perform actual Firebase fetch directly
      await _performUserDataFetch();
      
    } catch (e) {
      print('UserDataProvider: Error loading user data: $e');
      // Fallback to cached data
      await _loadFromCriticalBackup();
    }
  }

  /// Instant cache loading for immediate UI updates
  Future<void> _loadFromInstantCache() async {
    try {
      final cachedData = _prefs.getString(_userDataCacheKey);
      if (cachedData != null) {
        final data = json.decode(cachedData);
        _populateFromCacheData(data);
        print('UserDataProvider: Loaded instant cache data');
        notifyListeners();
      }
    } catch (e) {
      print('UserDataProvider: Error loading instant cache: $e');
    }
  }

  /// Load from multiple cache layers (like Instagram's architecture)
  Future<void> _loadFromMultipleCacheLayers() async {
    // Layer 1: Instant cache (SharedPreferences)
    await _loadFromInstantCache();
    
    // Layer 2: Critical data backup
    await _loadFromCriticalBackup();
    
    // Layer 3: Verify data integrity
    await _verifyDataIntegrity();
  }

  /// Load critical backup data
  Future<void> _loadFromCriticalBackup() async {
    try {
      final backupData = _prefs.getString(_criticalDataKey);
      if (backupData != null) {
        final data = json.decode(backupData);
        _populateFromCacheData(data);
        print('UserDataProvider: Loaded from critical backup');
        notifyListeners();
      }
    } catch (e) {
      print('UserDataProvider: Error loading critical backup: $e');
    }
  }

  /// Verify data integrity like social media apps
  Future<void> _verifyDataIntegrity() async {
    try {
      final storedHash = _prefs.getString(_dataHashKey);
      final currentData = _generateDataForSync();
      final currentHash = _generateDataHash(json.encode(currentData));
      
      if (storedHash != null && storedHash != currentHash) {
        print('UserDataProvider: Data integrity issue detected, will sync later...');
        _dataIntegrityVerified = false;
      } else {
        _dataIntegrityVerified = true;
      }
    } catch (e) {
      print('UserDataProvider: Error verifying data integrity: $e');
    }
  }

  /// Generate hash for data integrity
  String _generateDataHash(String data) {
    return data.hashCode.toString();
  }

  /// Populate user data from cache (compatible with existing UserData structure)
  void _populateFromCacheData(Map<String, dynamic> data) {
    try {
      if (data.containsKey('userData')) {
        // If it's wrapped in userData key
        final userData = UserData.fromJson(data['userData']);
        _userData = userData;
      } else {
        // Direct data
        final userData = UserData.fromJson(data);
        _userData = userData;
      }
      
      _lastDataUpdate = DateTime.tryParse(data['lastDataUpdate'] ?? '') ?? DateTime.now();
    } catch (e) {
      print('UserDataProvider: Error populating from cache data: $e');
      // Fallback to empty user data
      _userData = UserData(userId: _currentUser?.uid ?? '');
    }
  }

  /// Perform actual Firebase data fetch
  Future<void> _performUserDataFetch() async {
    try {
      // Use existing auth service method
      final loadedData = await _authService.loadUserDataFromFirestore();
      
      if (loadedData != null) {
        _userData = loadedData.sanitized();
        
        // Save to all cache layers immediately
        await _saveToAllCacheLayers();
        
        // Update timestamp
        _lastDataUpdate = DateTime.now();
        await _prefs.setString(_lastUpdateKey, _lastDataUpdate!.toIso8601String());
        
        print('UserDataProvider: Fresh data loaded from Firebase');
        notifyListeners();
      }
    } catch (e) {
      print('UserDataProvider: Error fetching from Firebase: $e');
      throw e;
    }
  }

  /// Save to all cache layers for Instagram-like persistence
  Future<void> _saveToAllCacheLayers() async {
    try {
      // Initialize _prefs if not already initialized
      if (!_isInitialized) {
        try {
          _prefs = await SharedPreferences.getInstance();
        } catch (e) {
          print('UserDataProvider: Failed to initialize SharedPreferences: $e');
          return; // Skip cache saving if we can't initialize
        }
      }
      
      final dataToSave = _generateDataForSync();
      final dataJson = json.encode(dataToSave);
      final dataHash = _generateDataHash(dataJson);
      
      // Layer 1: Instant cache
      await _prefs.setString(_userDataCacheKey, dataJson);
      
      // Layer 2: Critical backup
      await _prefs.setString(_criticalDataKey, dataJson);
      
      // Layer 3: Data integrity hash
      await _prefs.setString(_dataHashKey, dataHash);
      
      // Update timestamps
      await _prefs.setString(_lastSyncKey, DateTime.now().toIso8601String());
      await _prefs.setString(_lastUpdateKey, DateTime.now().toIso8601String());
      
      print('UserDataProvider: Saved to all cache layers');
    } catch (e) {
      print('UserDataProvider: Error saving to cache layers: $e');
    }
  }

  /// Generate data for sync operations
  Map<String, dynamic> _generateDataForSync() {
    return {
      'userData': _userData.toJson(),
      'lastDataUpdate': DateTime.now().toIso8601String(),
      'syncTimestamp': DateTime.now().millisecondsSinceEpoch,
    };
  }

  /// Update user data with Instagram-like queue management (simplified version)
  Future<void> updateUserDataSocialStyle(Map<String, dynamic> updates) async {
    try {
      // Apply updates immediately to local data
      _applyLocalUpdates(updates);
      
      // Save to local cache immediately
      await _saveToAllCacheLayers();
      
      // For now, sync directly instead of using queue
      if (_isOnline) {
        try {
          await _authService.saveUserDataToFirestore(_userData);
          print('UserDataProvider: Data synced to Firebase');
        } catch (e) {
          print('UserDataProvider: Firebase sync failed: $e');
        }
      }
      
      notifyListeners();
      print('UserDataProvider: User data updated with social media style');
    } catch (e) {
      print('UserDataProvider: Error updating user data: $e');
    }
  }

  /// Apply updates locally for immediate UI response
  void _applyLocalUpdates(Map<String, dynamic> updates) {
    if (updates.containsKey('name')) {
      _userData = _userData.copyWith(name: updates['name']);
    }
    if (updates.containsKey('age')) {
      _userData = _userData.copyWith(age: updates['age']);
    }
    if (updates.containsKey('height')) {
      _userData = _userData.copyWith(height: updates['height']);
    }
    if (updates.containsKey('weight')) {
      _userData = _userData.copyWith(weight: updates['weight']);
    }
    if (updates.containsKey('dailyStepGoal')) {
      _userData = _userData.copyWith(dailyStepGoal: updates['dailyStepGoal']);
    }
    if (updates.containsKey('dailyWaterGoal')) {
      _userData = _userData.copyWith(dailyWaterGoal: updates['dailyWaterGoal']);
    }
    // Add more fields as needed
  }

  /// Sync status change handler
  void _onSyncStatusChanged() {
    _isSyncing = _syncManager.isSyncing;
    notifyListeners();
  }

  /// Connectivity change handler
  void _onConnectivityChanged(bool isOnline) {
    _isOnline = isOnline;
    notifyListeners();
    
    if (isOnline) {
      print('UserDataProvider: Connectivity restored, DataSyncManager will handle pending sync');
    }
  }

    /// Updates user data with mutex lock to prevent concurrent operations
  Future<bool> updateUserData(UserData newData) async {
    // Ensure basic initialization
    if (!_isInitialized) {
      try {
        _prefs = await SharedPreferences.getInstance();
        _isInitialized = true;
      } catch (e) {
        print('UserDataProvider: Failed to initialize during update: $e');
        // Continue without cache if initialization fails
      }
    }
    // Prevent concurrent updates with timeout
    if (_isLoading) {
      print('UserDataProvider: Update already in progress, waiting...');
      int waitCount = 0;
      while (_isLoading && waitCount < 50) { // Max 5 seconds wait
        await Future.delayed(const Duration(milliseconds: 100));
        waitCount++;
      }
      if (_isLoading) {
        print('UserDataProvider: Timeout waiting for previous update, forcing reset');
        _isLoading = false; // Force reset if stuck
      }
    }

    try {
      // Show loading state briefly
      _isLoading = true;
      _lastError = null;
      notifyListeners();

      // Create a copy of the new data to avoid mutating the input
      UserData dataToUpdate = newData.copyWith();

      // Validate the new data
      Map<String, String> validationErrors = dataToUpdate.validate();
      if (validationErrors.isNotEmpty) {
        _lastError = "Validation errors: ${validationErrors.values.join(', ')}";
        return false;
      }

      // Ensure memberSince is preserved
      if (_userData.memberSince != null && dataToUpdate.memberSince == null) {
        dataToUpdate = dataToUpdate.copyWith(memberSince: _userData.memberSince);
      } else if (_userData.memberSince == null && dataToUpdate.name != null) {
        dataToUpdate = dataToUpdate.copyWith(memberSince: DateTime.now());
      }

      // Sanitize data to ensure it's valid
      _userData = dataToUpdate.sanitized();

      // Ensure profile picture is preserved
      _cachedUser = _cachedUser ?? FirebaseAuth.instance.currentUser;
      if(_cachedUser != null && _shouldUpdateProfilePicture(null)) {
        String? googlePhotoURL = ImageUtils.processGooglePhotoUrl(_cachedUser!.photoURL);
        if (googlePhotoURL != null && googlePhotoURL.isNotEmpty) {
          _userData = _userData.copyWith(profilePicturePath: googlePhotoURL);
        }
      }

      // Update UI immediately for instant feedback
      notifyListeners();

      // Save to local storage immediately (daily sync approach)
      await _dailySyncService.saveLocalUserData(_userData);
      debugPrint('UserDataProvider: User data saved to local storage for daily sync');

      // Also save to existing cache for backward compatibility
      await _saveToAllCacheLayers();

      // NO direct Firebase sync - this will happen at sleep time via daily sync service
      
      return true;
    } catch (e) {
      _lastError = "Failed to update user data: $e";
      debugPrint('UserDataProvider: $_lastError');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Resets user data to initial state
  Future<bool> resetUserData() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      _cachedUser = _cachedUser ?? FirebaseAuth.instance.currentUser;
      String? googleName, googlePhotoUrl;

      if(_cachedUser != null){
        googleName = _cachedUser!.displayName;
        if (googleName != null && googleName.contains(' ')) {
          googleName = googleName.split(' ').first;
        }
        googlePhotoUrl = ImageUtils.processGooglePhotoUrl(_cachedUser!.photoURL);
      }

      _userData = UserData(
          userId: _cachedUser?.uid ?? '',
          name: googleName,
          profilePicturePath: googlePhotoUrl,
          memberSince: DateTime.now()
      );

      // Save locally first
      await _saveToLocalCache(_userData);

      // Try to save to Firestore if online
      final connectivityResult = await _connectivity.checkConnectivity();
      if (_cachedUser != null && connectivityResult != ConnectivityResult.none) {
        try {
          await _authService.saveUserDataToFirestore(_userData).timeout(
            const Duration(seconds: 20),
            onTimeout: () => throw Exception('Firestore save timeout'),
          );
        } catch (e) {
          print('UserDataProvider: Firestore reset failed, data reset locally: $e');
        }
      }

      await _storageService.setOnboardingComplete(false);
      _dataIntegrityVerified = false;

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = "Failed to reset user data: $e";
      print('UserDataProvider: $_lastError');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Completes the onboarding process
  Future<bool> completeOnboarding() async {
    _isLoading = true;
    _lastError = null;
    notifyListeners();

    try {
      print('PROVIDER DEBUG: Starting completeOnboarding process');
      
      // First ensure we have required data for profile completion
      if (_userData.name == null || _userData.age == null || _userData.height == null || 
          _userData.weight == null || _userData.gender == null) {
        _lastError = "Missing required user profile data";
        print('PROVIDER DEBUG: $_lastError');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Also check for health goals
      if (_userData.dailyStepGoal == null || _userData.dailyWaterGoal == null) {
        _lastError = "Missing required health goals data";
        print('PROVIDER DEBUG: $_lastError');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('PROVIDER DEBUG: All required fields validated');
      
      // Make sure health goals are set with defaults if needed
      UserData updatedData = _userData.copyWith(
        dailyStepGoal: _userData.dailyStepGoal ?? 10000,
        dailyWaterGoal: _userData.dailyWaterGoal ?? 8,
        dailyCalorieGoal: _userData.dailyCalorieGoal ?? 2000,
        sleepGoalHours: _userData.sleepGoalHours ?? 8,
      );

      // Force direct save to Firestore
      bool updateSuccess = await updateUserData(updatedData);
      if (!updateSuccess) {
        _lastError = "Failed to update user data during onboarding completion";
        print('PROVIDER DEBUG: $_lastError');
        _isLoading = false;
        notifyListeners();
        return false;
      }

      print('PROVIDER DEBUG: User data updated successfully');
      
      // Attempt direct Firebase sync to ensure data is saved remotely
      try {
        await _authService.saveUserDataToFirestore(_userData);
        print('PROVIDER DEBUG: Successfully saved user data to Firestore');
      } catch (firebaseError) {
        print('PROVIDER DEBUG: Warning - Firebase save had error: $firebaseError');
        // Continue anyway since we have local data updated
      }

      // Also update local storage to mark onboarding as complete
      await _storageService.setOnboardingComplete(true);
      
      // Double verify the flag was set
      final onboardingComplete = await _storageService.isOnboardingComplete();
      print('PROVIDER DEBUG: Onboarding flag verification: $onboardingComplete');
      
      print('PROVIDER DEBUG: Onboarding successfully completed');
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _lastError = "Failed to complete onboarding: $e";
      print('PROVIDER DEBUG: $_lastError');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Method to explicitly check and fix data integrity issues
  Future<bool> checkAndFixDataIntegrity() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _verifyDataIntegrity();
      _isLoading = false;
      notifyListeners();
      return _dataIntegrityVerified;
    } catch (e) {
      _lastError = "Data integrity check failed: $e";
      print('UserDataProvider: $_lastError');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Method to clear cached user and force refresh
  void clearCache() {
    _cachedUser = null;
    _dataIntegrityVerified = false;
    _clearLocalCache();
  }

  /// Method to sync local changes to Firebase when connection is restored
  Future<bool> syncLocalChangesToFirebase() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('UserDataProvider: Cannot sync - no network connection');
        return false;
      }

      _cachedUser = _cachedUser ?? FirebaseAuth.instance.currentUser;
      if (_cachedUser == null) {
        print('UserDataProvider: Cannot sync - no authenticated user');
        return false;
      }

      await _authService.saveUserDataToFirestore(_userData).timeout(
        const Duration(seconds: 20),
        onTimeout: () => throw Exception('Sync timeout'),
      );

      print('UserDataProvider: Successfully synced local changes to Firebase');
      return true;
    } catch (e) {
      // print('UserDataProvider: Sync failed: $e');
      return false;
    }
  }

  /// Updates specific user preference
  Future<bool> updateUserPreference(String key, dynamic value) async {
    try {
      UserData updatedData;

      switch (key) {
        case 'waterReminderEnabled':
          updatedData = _userData.copyWith(waterReminderEnabled: value as bool);
          break;
        case 'morningWalkReminderEnabled':
          updatedData = _userData.copyWith(morningWalkReminderEnabled: value as bool);
          break;
        case 'wakeupNotificationEnabled':
          updatedData = _userData.copyWith(wakeupNotificationEnabled: value as bool);
          break;
        case 'sleepNotificationEnabled':
          updatedData = _userData.copyWith(sleepNotificationEnabled: value as bool);
          break;
        case 'dailyStepGoal':
          updatedData = _userData.copyWith(dailyStepGoal: value as int);
          break;
        case 'dailyWaterGoal':
          updatedData = _userData.copyWith(dailyWaterGoal: value as int);
          break;
        default:
          // print('UserDataProvider: Unknown preference key: $key');
          return false;
      }

      return await updateUserData(updatedData);
    } catch (e) {
      // print('UserDataProvider: Error updating preference $key: $e');
      return false;
    }
  }

  /// Gets a specific user preference
  T? getUserPreference<T>(String key) {
    try {
      switch (key) {
        case 'waterReminderEnabled':
          return _userData.waterReminderEnabled as T;
        case 'morningWalkReminderEnabled':
          return _userData.morningWalkReminderEnabled as T;
        case 'wakeupNotificationEnabled':
          return _userData.wakeupNotificationEnabled as T;
        case 'sleepNotificationEnabled':
          return _userData.sleepNotificationEnabled as T;
        case 'dailyStepGoal':
          return _userData.dailyStepGoal as T;
        case 'dailyWaterGoal':
          return _userData.dailyWaterGoal as T;
        case 'prefersCoffee':
          return _userData.prefersCoffee as T;
        case 'prefersTea':
          return _userData.prefersTea as T;
        default:
          // print('UserDataProvider: Unknown preference key: $key');
          return null;
      }
    } catch (e) {
      // print('UserDataProvider: Error getting preference $key: $e');
      return null;
    }
  }

  /// Forces a refresh of user data from Firebase
  Future<bool> refreshFromFirebase() async {
    _cachedUser = null; // Clear cache to force refresh
    return await loadUserData();
  }

  /// Dispose method for proper cleanup
  @override
  void dispose() {
    // Clean up DataSyncManager resources
    _syncManager.removeConnectivityListener(_onConnectivityChanged);
    _syncManager.removeSyncListener(_onSyncStatusChanged);
    _syncManager.dispose();
    
    print('UserDataProvider: Disposing resources and DataSyncManager');
    super.dispose();
  }

  /// Force sync all pending operations
  Future<void> forceSyncAllData() async {
    if (_isInitialized && _isOnline) {
      try {
        await _syncManager.forceSyncPendingOperations();
        print('UserDataProvider: Force sync completed via DataSyncManager');
      } catch (e) {
        print('UserDataProvider: Force sync failed: $e');
        // Fallback to direct Firebase save
        try {
          await _authService.saveUserDataToFirestore(_userData);
          print('UserDataProvider: Fallback direct sync completed');
        } catch (fallbackError) {
          print('UserDataProvider: Fallback sync also failed: $fallbackError');
        }
      }
    }
  }

  /// Clear all cached data (for logout scenarios)
  Future<void> clearAllCacheData() async {
    try {
      await _prefs.remove(_userDataCacheKey);
      await _prefs.remove(_lastSyncKey);
      await _prefs.remove(_dataHashKey);
      await _prefs.remove(_lastUpdateKey);
      await _prefs.remove(_criticalDataKey);
      await _clearLocalCache();
      await _clearAuthState();
      print('UserDataProvider: All cache data cleared');
    } catch (e) {
      print('UserDataProvider: Error clearing cache data: $e');
    }
  }

  // Real-time Sync Control Methods

  /// Enable or disable real-time Firebase sync
  void setRealTimeSyncEnabled(bool enabled) {
    _dailySyncService.setRealTimeSyncEnabled(enabled);
    notifyListeners();
    print('UserDataProvider: Real-time sync ${enabled ? 'enabled' : 'disabled'}');
  }

  /// Check if real-time sync is enabled
  bool get isRealTimeSyncEnabled => _dailySyncService.isRealTimeSyncEnabled;

  /// Get detailed sync status
  Future<Map<String, dynamic>> getSyncStatus() async {
    return await _dailySyncService.getSyncStatus();
  }

  /// Perform emergency backup of all data
  Future<bool> performEmergencyBackup() async {
    try {
      _isSyncing = true;
      notifyListeners();
      
      final success = await _dailySyncService.performEmergencyBackup();
      
      _isSyncing = false;
      notifyListeners();
      
      if (success) {
        print('UserDataProvider: Emergency backup completed successfully');
      } else {
        print('UserDataProvider: Emergency backup failed');
      }
      
      return success;
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
      print('UserDataProvider: Emergency backup error: $e');
      return false;
    }
  }

  /// Update user data with immediate Firebase sync
  Future<void> updateUserDataWithImmediateSync(UserData userData) async {
    try {
      _userData = userData;
      
      // Save to local storage (will automatically sync to Firebase if real-time sync is enabled)
      await _dailySyncService.saveLocalUserData(userData);
      
      notifyListeners();
      print('UserDataProvider: User data updated with immediate sync');
    } catch (e) {
      print('UserDataProvider: Error updating user data with immediate sync: $e');
    }
  }

  // Water Glass Count Management

  /// Get current water glass count
  Future<int> getWaterGlassCount() async {
    return await _dailySyncService.getWaterGlassCount();
  }

  /// Increment water glass count
  Future<int> incrementWaterGlass() async {
    try {
      final newCount = await _dailySyncService.incrementWaterGlassCount();
      notifyListeners();
      print('UserDataProvider: Water glass count incremented to: $newCount');
      return newCount;
    } catch (e) {
      print('UserDataProvider: Error incrementing water glass count: $e');
      return await getWaterGlassCount();
    }
  }

  /// Decrement water glass count
  Future<int> decrementWaterGlass() async {
    try {
      final newCount = await _dailySyncService.decrementWaterGlassCount();
      notifyListeners();
      print('UserDataProvider: Water glass count decremented to: $newCount');
      return newCount;
    } catch (e) {
      print('UserDataProvider: Error decrementing water glass count: $e');
      return await getWaterGlassCount();
    }
  }

  /// Set water glass count to specific value
  Future<void> setWaterGlassCount(int count) async {
    try {
      await _dailySyncService.saveWaterGlassCount(count);
      notifyListeners();
      print('UserDataProvider: Water glass count set to: $count');
    } catch (e) {
      print('UserDataProvider: Error setting water glass count: $e');
    }
  }

  // Water Milestone Methods

  /// Check if water milestone (9 glasses) has been reached today
  Future<bool> hasReachedWaterMilestoneToday() async {
    return await _dailySyncService.hasReachedWaterMilestoneToday();
  }

  /// Check if water milestone experience has been awarded today
  Future<bool> hasWaterMilestoneExpBeenAwarded() async {
    return await _dailySyncService.hasWaterMilestoneExpBeenAwarded();
  }

  /// Get comprehensive water milestone status
  Future<Map<String, dynamic>> getWaterMilestoneStatus() async {
    return await _dailySyncService.getWaterMilestoneStatus();
  }

  // Step Tracking Methods

  /// Get today's step count
  Future<int> getTodaysStepCount() async {
    return await _dailySyncService.getTodaysStepCount();
  }

  /// Update today's step count
  Future<void> updateTodaysStepCount(int steps, {int? goal}) async {
    try {
      await _dailySyncService.updateTodaysStepCount(steps, goal: goal);
      notifyListeners();
      print('UserDataProvider: Today\'s step count updated to: $steps${goal != null ? ' (goal: $goal)' : ''}');
    } catch (e) {
      print('UserDataProvider: Error updating step count: $e');
    }
  }

  /// Add steps to today's count (incremental tracking)
  Future<int> addStepsToToday(int additionalSteps) async {
    try {
      final newTotal = await _dailySyncService.addStepsToToday(additionalSteps);
      notifyListeners();
      print('UserDataProvider: Added $additionalSteps steps, total: $newTotal');
      return newTotal;
    } catch (e) {
      print('UserDataProvider: Error adding steps: $e');
      return await getTodaysStepCount();
    }
  }

  /// Get step data for recent days
  Future<List<DailyStepData>> getRecentStepData(int days) async {
    return await _dailySyncService.getRecentStepData(days);
  }

  /// Set today's step goal
  Future<void> setTodaysStepGoal(int goal) async {
    try {
      await _dailySyncService.setTodaysStepGoal(goal);
      notifyListeners();
      print('UserDataProvider: Today\'s step goal set to: $goal');
    } catch (e) {
      print('UserDataProvider: Error setting step goal: $e');
    }
  }

  /// Get today's step goal
  Future<int> getTodaysStepGoal() async {
    return await _dailySyncService.getTodaysStepGoal();
  }

  /// Get weekly step summary
  Future<Map<String, dynamic>> getWeeklyStepSummary() async {
    try {
      final weekData = await getRecentStepData(7);
      final totalSteps = weekData.fold(0, (sum, data) => sum + data.steps);
      final averageSteps = weekData.isEmpty ? 0 : (totalSteps / weekData.length).round();
      final maxSteps = weekData.isEmpty ? 0 : weekData.map((d) => d.steps).reduce((a, b) => a > b ? a : b);
      
      return {
        'totalSteps': totalSteps,
        'averageSteps': averageSteps,
        'maxSteps': maxSteps,
        'daysTracked': weekData.length,
        'data': weekData,
      };
    } catch (e) {
      print('UserDataProvider: Error getting weekly step summary: $e');
      return {
        'totalSteps': 0,
        'averageSteps': 0,
        'maxSteps': 0,
        'daysTracked': 0,
        'data': <DailyStepData>[],
      };
    }
  }
}

