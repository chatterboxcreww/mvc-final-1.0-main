// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\services\auth_service.dart

import 'dart:async';
import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../models/user_data.dart';
import 'notification_service.dart';
import 'storage_service.dart';
import '../utils/image_utils.dart';

class AuthService {
   // Singleton pattern
   static final AuthService _instance = AuthService._internal();
   factory AuthService() => _instance;
   AuthService._internal();

   final FirebaseAuth _auth = FirebaseAuth.instance;
   GoogleSignIn _googleSignIn = GoogleSignIn(
     scopes: ['email', 'profile'],
   );
   final FirebaseFirestore _firestore = FirebaseFirestore.instance;
   final Connectivity _connectivity = Connectivity();

  // Constants
  static const int _queryTimeout = 20;
  static const int _maxRetries = 3;

  Stream<User?> get user {
    return _auth.authStateChanges().timeout(
      const Duration(seconds: 30),
      onTimeout: (sink) => sink.add(null),
    );
  }

  Future<User?> signInWithGoogle() async {
    try {
      print('AuthService: Starting Google Sign-In process...');
      
      // Check network connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      print('AuthService: Network connectivity: $connectivityResult');
      
      // For development/testing - allow offline demo mode
      if (connectivityResult == ConnectivityResult.none) {
        print('AuthService: No network connection detected');
        // Create a demo user for offline testing
        return await _createDemoUser();
      }
      
      // Test actual network connectivity with a simple ping
      bool hasRealConnectivity = await _testNetworkConnectivity();
      if (!hasRealConnectivity) {
        print('AuthService: Network connectivity test failed - using demo mode');
        return await _createDemoUser();
      }
      
      // Add a small delay to ensure connectivity is established
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Clear any existing Google Sign-In state
      try {
        await _googleSignIn.signOut();
      } catch (e) {
        print('AuthService: Warning - Could not sign out existing Google session: $e');
      }
      
      // Configure Google Sign-In with proper scopes (remove clientId for Android)
      _googleSignIn = GoogleSignIn(
        scopes: ['email', 'profile'],
      );
      
      // Start Google Sign-In with extended timeout
      final GoogleSignInAccount? googleUserAccount = await _googleSignIn.signIn().timeout(
        const Duration(seconds: 45),
        onTimeout: () => throw Exception("Google Sign-In timed out. Please try again."),
      );
      
      if (googleUserAccount == null) {
        print('AuthService: Google Sign-In was cancelled by user');
        return null; // User cancelled the sign-in
      }

      print('AuthService: Google account obtained, getting authentication...');
      final GoogleSignInAuthentication googleAuth = await googleUserAccount.authentication.timeout(
        const Duration(seconds: 30),
        onTimeout: () => throw Exception("Authentication token retrieval timed out."),
      );
      
      // Validate tokens more thoroughly
      if (googleAuth.accessToken == null || googleAuth.accessToken!.isEmpty ||
          googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        throw Exception("Failed to get valid Google authentication tokens. Please try again.");
      }

      print('AuthService: Creating Firebase credential...');
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      print('AuthService: Signing in with Firebase...');
      UserCredential userCredential = await _auth.signInWithCredential(credential)
          .timeout(const Duration(seconds: 30));
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        print('AuthService: Firebase sign-in successful, creating user document...');
        try {
          await _createOrUpdateUserDocument(firebaseUser);
          print('AuthService: Google Sign-In process completed successfully');
        } catch (e) {
          print('AuthService: Warning - Could not create/update user document: $e');
          // Continue anyway as the user is authenticated
        }
      }
      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error (Google Sign In): ${e.code} - ${e.message}');
      
      // If it's a network error, try demo mode
      if (e.code == 'network-request-failed') {
        print('AuthService: Network error detected, switching to demo mode');
        return await _createDemoUser();
      }
      
      String errorMessage = _getFirebaseErrorMessage(e.code);
      throw Exception(errorMessage);
    } on TimeoutException catch (e) {
      print('Google Sign In Timeout: $e');
      print('AuthService: Timeout detected, switching to demo mode');
      return await _createDemoUser();
    } on Exception catch (e) {
      print('Google Sign In Error: $e');
      
      // If it's a network-related error, try demo mode
      if (e.toString().contains('network') || e.toString().contains('timeout') || 
          e.toString().contains('connection') || e.toString().contains('resolve host')) {
        print('AuthService: Network-related error detected, switching to demo mode');
        return await _createDemoUser();
      }
      
      if (e.toString().contains('Exception:')) {
        rethrow; // Re-throw custom exceptions
      }
      throw Exception("An unexpected error occurred during Google Sign In. Please try again.");
    } on Error catch (e) {
      print('Google Sign In Error: $e');
      throw Exception("A system error occurred during Google Sign In. Please try again.");
    }
  }

  /// Test actual network connectivity by trying to reach Google's DNS
  Future<bool> _testNetworkConnectivity() async {
    try {
      // Try to resolve a hostname to test real connectivity
      final result = await InternetAddress.lookup('google.com').timeout(
        const Duration(seconds: 5),
      );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } catch (e) {
      print('AuthService: Network connectivity test failed: $e');
      return false;
    }
  }

  /// Create a demo user for offline testing
  Future<User?> _createDemoUser() async {
    try {
      print('AuthService: Creating demo user for offline mode');
      
      // Create a demo user with anonymous authentication
      final UserCredential userCredential = await _auth.signInAnonymously();
      final User? demoUser = userCredential.user;
      
      if (demoUser != null) {
        // Store demo user info locally
        await StorageService().setDemoMode(true);
        await StorageService().setOnboardingComplete(false);
        
        print('AuthService: Demo user created successfully: ${demoUser.uid}');
        return demoUser;
      }
      
      return null;
    } catch (e) {
      print('AuthService: Failed to create demo user: $e');
      return null;
    }
  }

  /// Get user-friendly error messages for Firebase Auth errors
  String _getFirebaseErrorMessage(String errorCode) {
    switch (errorCode) {
      case 'account-exists-with-different-credential':
        return 'An account already exists with a different sign-in method. Please use that method to sign in.';
      case 'invalid-credential':
        return 'The credential is invalid. Please try signing in again.';
      case 'operation-not-allowed':
        return 'Google Sign-In is not enabled. Please contact support.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'user-not-found':
        return 'No account found. Please sign up first.';
      case 'wrong-password':
        return 'Incorrect password. Please try again.';
      case 'network-request-failed':
        return 'Network error. Please check your connection and try again.';
      case 'too-many-requests':
        return 'Too many failed attempts. Please try again later.';
      default:
        return 'Sign-in failed. Please try again.';
    }
  }

  /// Check Google Sign-In configuration and connectivity
  Future<Map<String, dynamic>> checkSignInStatus() async {
    Map<String, dynamic> status = {};
    
    try {
      // Check if Google Sign-In is available
      status['isSignedIn'] = await _googleSignIn.isSignedIn();
      
      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      status['hasConnection'] = connectivityResult != ConnectivityResult.none;
      
      // Check Firebase Auth
      status['hasCurrentUser'] = _auth.currentUser != null;
      
      return status;
    } catch (e) {
      status['error'] = e.toString();
      return status;
    }
  }

  Future<User?> silentSignIn() async {
    try {
      // First check if we already have a valid Firebase user
      final currentUser = _auth.currentUser;
      if (currentUser != null) {
        print('AuthService: Found cached Firebase user: ${currentUser.uid}');
        // For offline scenarios, return the cached user without token validation
        final connectivityResult = await _connectivity.checkConnectivity();
        if (connectivityResult == ConnectivityResult.none) {
          print('AuthService: Offline mode - returning cached user');
          return currentUser;
        }
        
        // Verify the user is still valid by checking token with timeout
        try {
          await currentUser.getIdToken(true).timeout(const Duration(seconds: 5));
          print('AuthService: Firebase user token is valid');
          return currentUser;
        } catch (e) {
          print('AuthService: Firebase user token invalid, proceeding with silent sign-in: $e');
        }
      }

      // Check network connectivity
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('AuthService: No network connectivity for silent sign-in');
        return currentUser; // Return cached user even if offline
      }

      // Add a small delay before attempting silent sign-in to ensure network is ready
      await Future.delayed(const Duration(milliseconds: 300));

      // Check if silent sign-in is possible
      bool canSilentSignIn = false;
      try {
        canSilentSignIn = await _googleSignIn.isSignedIn().timeout(const Duration(seconds: 5));
      } catch (e) {
        print('AuthService: Error checking Google Sign-In status: $e');
        return currentUser;
      }
      
      if (!canSilentSignIn) {
        print('AuthService: Google Sign-In not available for silent sign-in');
        return currentUser;
      }

      print('AuthService: Attempting silent sign-in...');
      
      // Single attempt with reasonable timeout
      final googleUser = await _googleSignIn.signInSilently()
          .timeout(const Duration(seconds: 10));

      if (googleUser == null) {
        print('AuthService: Silent Google sign-in returned null');
        return currentUser;
      }

      print('AuthService: Silent Google sign-in successful');
      final googleAuth = await googleUser.authentication.timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Google authentication timeout'),
      );
      
      // Validate tokens
      if (googleAuth.accessToken == null || googleAuth.accessToken!.isEmpty ||
          googleAuth.idToken == null || googleAuth.idToken!.isEmpty) {
        print('AuthService: Invalid Google authentication tokens');
        return currentUser;
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential = await _auth.signInWithCredential(credential)
          .timeout(const Duration(seconds: 15));

      if (userCredential.user != null) {
        print('AuthService: Firebase silent authentication successful');
        try {
          await _createOrUpdateUserDocument(userCredential.user!);
        } catch (e) {
          print('AuthService: Warning - Could not create/update user document during silent sign-in: $e');
        }
        return userCredential.user;
      }

      print('AuthService: Firebase silent authentication failed');
      return currentUser;
    } on TimeoutException catch (e) {
      print('AuthService: Silent sign-in timeout: $e');
      return _auth.currentUser; // Return current user on timeout
    } catch (e) {
      print('AuthService: Silent sign-in error: $e');
      // Return any existing user to allow offline mode
      return _auth.currentUser;
    }
  }
  
  /// Check if silent sign-in is possible
  Future<bool> canSilentSignIn() async {
    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        return false;
      }
      
      return await _googleSignIn.isSignedIn();
    } catch (e) {
      print('AuthService: Error checking silent sign-in capability: $e');
      return false;
    }
  }

  Future<void> _createOrUpdateUserDocument(User firebaseUser) async {
    try {
      // Check network connectivity first
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('AuthService: Skipping user document creation - no network connection');
        return;
      }

      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: 15));

      if (!userDoc.exists) {
        String displayName = firebaseUser.displayName ?? "User";
        if (displayName.contains(' ')) {
          displayName = displayName.split(' ').first;
        }
        String? photoURL = ImageUtils.processGooglePhotoUrl(firebaseUser.photoURL);

        UserData newUserData = UserData(
          userId: firebaseUser.uid,
          name: displayName,
          email: firebaseUser.email,
          memberSince: DateTime.now(),
          profilePicturePath: photoURL,
        ).sanitized();

        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(newUserData.toJson())
            .timeout(const Duration(seconds: 15));

        await StorageService().setOnboardingComplete(false);
        print('Created new user document for UID: ${firebaseUser.uid}');
      } else {
        UserData existingData = UserData.fromJson(userDoc.data() as Map<String, dynamic>);
        String? currentGooglePhotoURL = ImageUtils.processGooglePhotoUrl(firebaseUser.photoURL);
        
        Map<String, dynamic> updates = {};

        if (existingData.profilePicturePath != currentGooglePhotoURL) {
          updates['profilePicturePath'] = currentGooglePhotoURL;
          print("Updated profile picture URL from Google for existing user.");
        }
        
        // Update email if it's missing
        if (existingData.email == null && firebaseUser.email != null) {
          updates['email'] = firebaseUser.email;
          print("Updated email for existing user: ${firebaseUser.email}");
        }
        
        if (updates.isNotEmpty) {
          await _firestore
              .collection('users')
              .doc(firebaseUser.uid)
              .update(updates)
              .timeout(const Duration(seconds: 15));
        }
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
      // Don't rethrow - allow authentication to continue even if document creation fails
    }
  }

  Future<void> signOut() async {
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _auth.signOut(),
        StorageService().clearAllLocalData(),
      ], eagerError: true);

      final notificationService = NotificationService(FlutterLocalNotificationsPlugin());
      await notificationService.cancelAllNotifications();
    } catch (e) {
      print('Sign Out Error: $e');
    }
  }

  Future<void> saveUserDataToFirestore(UserData userData) async {
    print('AuthService: 🔥 Starting saveUserDataToFirestore');
    
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      print('AuthService: ❌ No authenticated user found');
      throw Exception('No authenticated user found');
    }
    
    print('AuthService: ✅ User authenticated: ${currentUser.uid}');

    try {
      print('AuthService: Validating user data...');
      // Use lenient validation (isOnboarding: true) to allow partial data during onboarding
      final validationErrors = userData.validate(isOnboarding: true);
      if (validationErrors.isNotEmpty) {
        print('AuthService: ❌ Validation failed: ${validationErrors.values.join(', ')}');
        throw Exception('Data validation failed: ${validationErrors.values.join(', ')}');
      }
      print('AuthService: ✅ Data validation passed');

      print('AuthService: Checking connectivity...');
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('AuthService: ❌ No network connection');
        throw Exception('No network connection available');
      }
      print('AuthService: ✅ Network connection available: $connectivityResult');

      print('AuthService: Writing to Firestore collection: users/${currentUser.uid}');
      print('AuthService: Data to save: ${userData.toJson()}');
      
      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(userData.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: _queryTimeout));
      
      print('AuthService: ✅✅✅ User data SUCCESSFULLY saved to Firestore for UID: ${currentUser.uid}');
    } catch (e) {
      print('AuthService: ❌❌❌ FAILED to save user data to Firestore');
      print('AuthService: Error type: ${e.runtimeType}');
      print('AuthService: Error details: $e');
      rethrow;
    }
  }

  Future<UserData?> loadUserDataFromFirestore() async {
    User? currentUser = _auth.currentUser;
    if (currentUser == null) return null;

    try {
      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        print('No network connection - cannot load user data from Firestore');
        return null;
      }

      DocumentSnapshot doc = await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .get()
          .timeout(const Duration(seconds: _queryTimeout));

      if (doc.exists && doc.data() != null) {
        final userData = UserData.fromJson(doc.data() as Map<String, dynamic>);
        print('Loaded user data from Firestore for UID: ${currentUser.uid}');
        return userData;
      }

      print('No user data found in Firestore for UID: ${currentUser.uid}');
      return null;
    } catch (e) {
      // print('Failed to load user data from Firestore: $e');
      rethrow;
    }
  }

  String _sanitizeErrorMessage(String message) {
    return message.replaceAll(RegExp(r'[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}'), '[email]');
  }
}

