// lib/core/services/auth_state_manager.dart

import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_data.dart';
import 'auth_service.dart';

/// Centralized authentication state management
/// Single source of truth for all auth-related state
class AuthStateManager {
  static final AuthStateManager _instance = AuthStateManager._internal();
  factory AuthStateManager() => _instance;
  AuthStateManager._internal();

  final AuthService _authService = AuthService();
  final StreamController<AuthState> _stateController = StreamController<AuthState>.broadcast();
  
  AuthState _currentState = AuthState.unknown;
  User? _currentUser;
  UserData? _userData;
  String? _lastError;

  // Getters
  Stream<AuthState> get authStateStream => _stateController.stream;
  AuthState get currentState => _currentState;
  User? get currentUser => _currentUser;
  UserData? get userData => _userData;
  String? get lastError => _lastError;

  /// Initialize the auth state manager
  Future<void> initialize() async {
    print('AuthStateManager: Initializing...');
    
    // Listen to Firebase auth changes
    FirebaseAuth.instance.authStateChanges().listen(_handleAuthStateChange);
    
    // Check initial state
    await _checkInitialState();
  }

  /// Handle Firebase auth state changes
  void _handleAuthStateChange(User? user) {
    print('AuthStateManager: Firebase auth state changed - User: ${user?.uid ?? "null"}');
    
    _currentUser = user;
    
    if (user == null) {
      _updateState(AuthState.unauthenticated);
      _userData = null;
    } else {
      _updateState(AuthState.authenticated);
      _loadUserData();
    }
  }

  /// Check initial authentication state
  Future<void> _checkInitialState() async {
    try {
      _updateState(AuthState.loading);
      
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        _currentUser = user;
        _updateState(AuthState.authenticated);
        await _loadUserData();
      } else {
        // Try silent sign-in
        final silentUser = await _authService.silentSignIn();
        if (silentUser != null) {
          _currentUser = silentUser;
          _updateState(AuthState.authenticated);
          await _loadUserData();
        } else {
          _updateState(AuthState.unauthenticated);
        }
      }
    } catch (e) {
      print('AuthStateManager: Error checking initial state: $e');
      _lastError = e.toString();
      _updateState(AuthState.error);
    }
  }

  /// Load user data
  Future<void> _loadUserData() async {
    try {
      if (_currentUser == null) return;
      
      _updateState(AuthState.loadingUserData);
      
      final userData = await _authService.loadUserDataFromFirestore();
      if (userData != null) {
        _userData = userData;
        _updateState(AuthState.ready);
      } else {
        // New user - create empty data
        _userData = UserData(userId: _currentUser!.uid);
        _updateState(AuthState.needsOnboarding);
      }
    } catch (e) {
      print('AuthStateManager: Error loading user data: $e');
      _lastError = e.toString();
      _updateState(AuthState.error);
    }
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    try {
      _updateState(AuthState.signingIn);
      
      final user = await _authService.signInWithGoogle();
      if (user != null) {
        _currentUser = user;
        _updateState(AuthState.authenticated);
        await _loadUserData();
        return true;
      } else {
        _updateState(AuthState.unauthenticated);
        return false;
      }
    } catch (e) {
      print('AuthStateManager: Sign in error: $e');
      _lastError = e.toString();
      _updateState(AuthState.error);
      return false;
    }
  }

  /// Sign out
  Future<void> signOut() async {
    try {
      _updateState(AuthState.signingOut);
      
      await _authService.signOut();
      _currentUser = null;
      _userData = null;
      _lastError = null;
      
      _updateState(AuthState.unauthenticated);
    } catch (e) {
      print('AuthStateManager: Sign out error: $e');
      _lastError = e.toString();
      _updateState(AuthState.error);
    }
  }

  /// Update user data
  Future<bool> updateUserData(UserData newData) async {
    try {
      if (_currentUser == null) return false;
      
      await _authService.saveUserDataToFirestore(newData);
      _userData = newData;
      
      // Update state based on profile completeness
      if (newData.isProfileComplete) {
        _updateState(AuthState.ready);
      } else {
        _updateState(AuthState.needsOnboarding);
      }
      
      return true;
    } catch (e) {
      print('AuthStateManager: Error updating user data: $e');
      _lastError = e.toString();
      return false;
    }
  }

  /// Update internal state and notify listeners
  void _updateState(AuthState newState) {
    if (_currentState != newState) {
      print('AuthStateManager: State changed from $_currentState to $newState');
      _currentState = newState;
      _stateController.add(newState);
    }
  }

  /// Dispose resources
  void dispose() {
    _stateController.close();
  }
}

/// Authentication states
enum AuthState {
  unknown,
  loading,
  unauthenticated,
  signingIn,
  authenticated,
  loadingUserData,
  needsOnboarding,
  ready,
  signingOut,
  error,
}