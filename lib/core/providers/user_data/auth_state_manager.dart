// lib/core/providers/user_data/auth_state_manager.dart

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/user_data.dart';

/// Manages authentication state persistence
class AuthStateManager {
  final SharedPreferences _prefs;
  User? _cachedUser;

  AuthStateManager(this._prefs);

  User? get cachedUser => _cachedUser;

  /// Save authentication state
  Future<void> saveAuthState(User? user) async {
    try {
      final isAuthenticated = user != null;
      
      await _prefs.setBool('is_authenticated', isAuthenticated);
      
      if (isAuthenticated && user != null) {
        if (user.uid.isEmpty) {
          debugPrint('AuthStateManager: Cannot save auth state - invalid user UID');
          return;
        }
        
        await _prefs.setString('cached_user_uid', user.uid);
        await _prefs.setString('cached_user_email', user.email ?? '');
        await _prefs.setString('cached_user_display_name', user.displayName ?? '');
        await _prefs.setString('cached_user_photo_url', user.photoURL ?? '');
        await _prefs.setString('auth_timestamp', DateTime.now().toIso8601String());
        
        try {
          final idToken = await user.getIdToken(false);
          if (idToken != null && idToken.isNotEmpty) {
            await _prefs.setString('cached_user_token', idToken);
          }
        } catch (tokenError) {
          debugPrint('AuthStateManager: Error saving token (non-critical): $tokenError');
        }
        
        _cachedUser = user;
        debugPrint('AuthStateManager: Auth state saved successfully for user: ${user.email ?? user.uid}');
      } else {
        await clearAuthState();
      }
    } catch (e) {
      debugPrint('AuthStateManager: Error saving auth state: $e');
    }
  }

  /// Check if there's a persisted authentication state
  Future<bool> checkPersistedAuthState() async {
    try {
      final isAuthenticated = _prefs.getBool('is_authenticated') ?? false;
      final authTimestamp = _prefs.getString('auth_timestamp');
      final cachedUserUid = _prefs.getString('cached_user_uid');
      final cachedUserEmail = _prefs.getString('cached_user_email');
      
      if (isAuthenticated && authTimestamp != null && cachedUserUid != null) {
        final authTime = DateTime.parse(authTimestamp);
        if (DateTime.now().difference(authTime).inDays > 90) {
          debugPrint('AuthStateManager: Persisted auth state is too old, clearing');
          await clearAuthState();
          return false;
        }
        
        _cachedUser = FirebaseAuth.instance.currentUser;
        
        if (_cachedUser == null) {
          debugPrint('AuthStateManager: Firebase auth unavailable, using cached auth data');
          await _prefs.setBool('needs_silent_signin', true);
        } else {
          await _prefs.setBool('needs_silent_signin', false);
        }
        
        debugPrint('AuthStateManager: Using persisted auth state for user: ${cachedUserEmail ?? cachedUserUid}');
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('AuthStateManager: Error checking persisted auth state: $e');
      return false;
    }
  }

  /// Clear authentication state
  Future<void> clearAuthState() async {
    try {
      await _prefs.remove('is_authenticated');
      await _prefs.remove('cached_user_uid');
      await _prefs.remove('cached_user_email');
      await _prefs.remove('cached_user_display_name');
      await _prefs.remove('cached_user_photo_url');
      await _prefs.remove('cached_user_token');
      await _prefs.remove('auth_timestamp');
      await _prefs.remove('needs_silent_signin');
      _cachedUser = null;
      debugPrint('AuthStateManager: Auth state cleared completely');
    } catch (e) {
      debugPrint('AuthStateManager: Error clearing auth state: $e');
    }
  }

  /// Check if silent sign-in is needed
  bool needsSilentSignIn() {
    return _prefs.getBool('needs_silent_signin') ?? false;
  }

  /// Update cached user
  void updateCachedUser(User? user) {
    _cachedUser = user;
  }

  /// Get current user (cached or from Firebase)
  User? getCurrentUser() {
    return _cachedUser ?? FirebaseAuth.instance.currentUser;
  }
}
