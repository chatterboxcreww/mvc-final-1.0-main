// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\services\auth_service.dart

import 'dart:async';
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
  final GoogleSignIn _googleSignIn = GoogleSignIn(
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
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception("No internet connection. Please check your network and try again.");
      }
      
      // Start Google Sign-In
      final GoogleSignInAccount? googleUserAccount = await _googleSignIn.signIn();
      if (googleUserAccount == null) {
        print('AuthService: Google Sign-In was cancelled by user');
        return null; // User cancelled the sign-in
      }

      print('AuthService: Google account obtained, getting authentication...');
      final GoogleSignInAuthentication googleAuth = await googleUserAccount.authentication;
      
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
          .timeout(const Duration(seconds: _queryTimeout));
      User? firebaseUser = userCredential.user;

      if (firebaseUser != null) {
        print('AuthService: Firebase sign-in successful, creating user document...');
        await _createOrUpdateUserDocument(firebaseUser);
        print('AuthService: Google Sign-In process completed successfully');
      }
      return firebaseUser;
    } on FirebaseAuthException catch (e) {
      print('Firebase Auth Error (Google Sign In): ${e.code} - ${e.message}');
      String errorMessage = _getFirebaseErrorMessage(e.code);
      throw Exception(errorMessage);
    } catch (e) {
      print('Google Sign In Error: $e');
      if (e.toString().contains('Exception:')) {
        rethrow; // Re-throw custom exceptions
      }
      throw Exception("An unexpected error occurred during Google Sign In. Please try again.");
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
        // Verify the user is still valid by checking token
        try {
          await currentUser.getIdToken(true); // Force refresh
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

      // Check if silent sign-in is possible
      final canSilentSignIn = await _googleSignIn.isSignedIn();
      if (!canSilentSignIn) {
        print('AuthService: Google Sign-In not available for silent sign-in');
        return currentUser;
      }

      print('AuthService: Attempting silent sign-in...');
      
      // Single attempt with reasonable timeout
      final googleUser = await _googleSignIn.signInSilently()
          .timeout(const Duration(seconds: 15));

      if (googleUser == null) {
        print('AuthService: Silent Google sign-in returned null');
        return currentUser;
      }

      print('AuthService: Silent Google sign-in successful');
      final googleAuth = await googleUser.authentication;
      
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
          .timeout(const Duration(seconds: _queryTimeout));

      if (userCredential.user != null) {
        print('AuthService: Firebase silent authentication successful');
        await _createOrUpdateUserDocument(userCredential.user!);
        return userCredential.user;
      }

      print('AuthService: Firebase silent authentication failed');
      return currentUser;
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
      final DocumentSnapshot userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get()
          .timeout(const Duration(seconds: _queryTimeout));

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
            .timeout(const Duration(seconds: _queryTimeout));

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
              .timeout(const Duration(seconds: _queryTimeout));
        }
      }
    } catch (e) {
      print('Error creating/updating user document: $e');
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
    User? currentUser = _auth.currentUser;
    if (currentUser == null) {
      throw Exception('No authenticated user found');
    }

    try {
      final validationErrors = userData.validate();
      if (validationErrors.isNotEmpty) {
        throw Exception('Data validation failed: ${validationErrors.values.join(', ')}');
      }

      final connectivityResult = await _connectivity.checkConnectivity();
      if (connectivityResult == ConnectivityResult.none) {
        throw Exception('No network connection available');
      }

      await _firestore
          .collection('users')
          .doc(currentUser.uid)
          .set(userData.toJson(), SetOptions(merge: true))
          .timeout(const Duration(seconds: _queryTimeout));
      print('User data saved/merged to Firestore for UID: ${currentUser.uid}');
    } catch (e) {
      print('Failed to save user data to Firestore: $e');
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

