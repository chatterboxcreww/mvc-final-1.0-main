// lib/core/services/session_manager.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_data.dart';
import 'auth_service.dart';
import 'storage_service.dart';

/// Manages user sessions and handles offline/online state transitions
class SessionManager {
  static final SessionManager _instance = SessionManager._internal();
  factory SessionManager() => _instance;
  SessionManager._internal();

  static const String _sessionKey = 'active_session';
  static const String _sessionTimestampKey = 'session_timestamp';
  static const String _lastActiveKey = 'last_active';
  static const String _deviceIdKey = 'device_id';
  
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  final Connectivity _connectivity = Connectivity();

  /// Check if there's a valid active session
  Future<bool> hasValidSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionData = prefs.getString(_sessionKey);
      final sessionTimestamp = prefs.getString(_sessionTimestampKey);
      final lastActive = prefs.getString(_lastActiveKey);
      
      if (sessionData == null || sessionTimestamp == null) {
        return false;
      }
      
      // Check if session is not expired (7 days)
      final sessionTime = DateTime.parse(sessionTimestamp);
      final daysSinceSession = DateTime.now().difference(sessionTime).inDays;
      
      if (daysSinceSession > 7) {
        print('SessionManager: Session expired (${daysSinceSession} days old)');
        await clearSession();
        return false;
      }
      
      // Check if user was recently active (24 hours)
      if (lastActive != null) {
        final lastActiveTime = DateTime.parse(lastActive);
        final hoursSinceActive = DateTime.now().difference(lastActiveTime).inHours;
        
        if (hoursSinceActive > 24) {
          print('SessionManager: User inactive for ${hoursSinceActive} hours');
          // Don't clear session, but mark as potentially stale
        }
      }
      
      // Verify Firebase Auth state
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        print('SessionManager: No Firebase user found');
        return false;
      }
      
      // Session is valid
      await updateLastActive();
      return true;
    } catch (e) {
      print('SessionManager: Error checking session validity: $e');
      return false;
    }
  }

  /// Create a new session
  Future<bool> createSession(User firebaseUser, UserData userData) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final sessionData = {
        'userId': firebaseUser.uid,
        'email': firebaseUser.email,
        'displayName': firebaseUser.displayName,
        'photoURL': firebaseUser.photoURL,
        'userData': userData.toJson(),
      };
      
      await prefs.setString(_sessionKey, jsonEncode(sessionData));
      await prefs.setString(_sessionTimestampKey, DateTime.now().toIso8601String());
      await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
      
      // Generate or retrieve device ID
      String? deviceId = prefs.getString(_deviceIdKey);
      if (deviceId == null) {
        deviceId = _generateDeviceId();
        await prefs.setString(_deviceIdKey, deviceId);
      }
      
      print('SessionManager: Session created for user ${firebaseUser.uid}');
      return true;
    } catch (e) {
      print('SessionManager: Error creating session: $e');
      return false;
    }
  }

  /// Update last active timestamp
  Future<void> updateLastActive() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastActiveKey, DateTime.now().toIso8601String());
    } catch (e) {
      print('SessionManager: Error updating last active: $e');
    }
  }

  /// Restore session data
  Future<Map<String, dynamic>?> getSessionData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionDataString = prefs.getString(_sessionKey);
      
      if (sessionDataString != null) {
        return jsonDecode(sessionDataString);
      }
    } catch (e) {
      print('SessionManager: Error getting session data: $e');
    }
    return null;
  }

  /// Clear current session
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      await prefs.remove(_sessionTimestampKey);
      await prefs.remove(_lastActiveKey);
      
      print('SessionManager: Session cleared');
    } catch (e) {
      print('SessionManager: Error clearing session: $e');
    }
  }

  /// Handle app lifecycle changes
  Future<void> onAppResumed() async {
    await updateLastActive();
    
    // Check if we need to refresh data
    final hasSession = await hasValidSession();
    if (hasSession) {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult != ConnectivityResult.none) {
        // Try to sync data when app resumes and online
        _backgroundSync();
      }
    }
  }

  /// Handle app being paused
  Future<void> onAppPaused() async {
    await updateLastActive();
  }

  /// Background sync when conditions are right
  Future<void> _backgroundSync() async {
    try {
      // This is a lightweight sync - don't block UI
      final sessionData = await getSessionData();
      if (sessionData != null) {
        final currentUser = FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          // Try to load latest data from Firestore
          final latestUserData = await _authService.loadUserDataFromFirestore();
          if (latestUserData != null) {
            // Update session with latest data
            await createSession(currentUser, latestUserData);
          }
        }
      }
    } catch (e) {
      // Silently fail - this is background operation
      print('SessionManager: Background sync failed: $e');
    }
  }

  /// Generate a pseudo-unique device ID
  String _generateDeviceId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final random = (timestamp.hashCode % 100000).toString();
    return 'device_${timestamp}_$random';
  }

  /// Restore user data from session
  Future<UserData?> restoreUserDataFromSession() async {
    try {
      final sessionData = await getSessionData();
      if (sessionData != null && sessionData['userData'] != null) {
        return UserData.fromJson(sessionData['userData']);
      }
    } catch (e) {
      print('SessionManager: Error restoring user data from session: $e');
    }
    return null;
  }

  /// Handle network connectivity changes
  Future<void> onConnectivityChanged(ConnectivityResult result) async {
    if (result != ConnectivityResult.none) {
      // Back online - try to sync
      final hasSession = await hasValidSession();
      if (hasSession) {
        _backgroundSync();
      }
    }
  }

  /// Check if session needs refresh
  Future<bool> needsRefresh() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final sessionTimestamp = prefs.getString(_sessionTimestampKey);
      
      if (sessionTimestamp != null) {
        final sessionTime = DateTime.parse(sessionTimestamp);
        final hoursSinceSession = DateTime.now().difference(sessionTime).inHours;
        
        // Refresh if session is older than 6 hours
        return hoursSinceSession > 6;
      }
      
      return true;
    } catch (e) {
      print('SessionManager: Error checking refresh need: $e');
      return true;
    }
  }
}
