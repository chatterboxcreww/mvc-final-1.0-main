// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\providers\comment_provider.dart

// lib/core/providers/comment_provider.dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import FirebaseAuth

import '../models/comment.dart';

class CommentProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('comments');
  final ProfanityFilter _filter = ProfanityFilter();
  final FirebaseAuth _auth = FirebaseAuth.instance; // Add FirebaseAuth instance

  int _totalCommentCount = 0;
  StreamSubscription? _userCommentsSubscription;

  int get totalCommentCount => _totalCommentCount;

  CommentProvider() {
    _auth.authStateChanges().listen((user) {
      if (user != null) {
        _listenToUserComments(user.uid);
      } else {
        _totalCommentCount = 0;
        notifyListeners();
      }
    });
  }

  Future<void> addComment(String contentId, Comment comment) async {
    if (_filter.hasProfanity(comment.text)) {
      throw Exception('Comment contains inappropriate language.');
    }
    final newCommentRef = _dbRef.child(contentId).push();
    await newCommentRef.set(comment.toJson());
  }

  Stream<List<Comment>> getComments(String contentId) {
    return _dbRef.child(contentId).onValue.map((event) {
      final List<Comment> comments = [];
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        data.forEach((key, value) {
          comments.add(Comment.fromRTDB(key, value as Map<dynamic, dynamic>));
        });
        comments.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      }
      return comments;
    });
  }

  void _listenToUserComments(String userId) {
    _userCommentsSubscription?.cancel();
    _userCommentsSubscription = _dbRef
        .orderByChild('userId')
        .equalTo(userId)
        .onValue
        .listen((event) {
      if (event.snapshot.exists && event.snapshot.value != null) {
        final data = event.snapshot.value as Map<dynamic, dynamic>;
        _totalCommentCount = data.length;
      }
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _userCommentsSubscription?.cancel();
    super.dispose();
  }
}
