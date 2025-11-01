// lib/core/services/content_filter_service.dart

import 'package:shared_preferences/shared_preferences.dart';

/// Service to filter content based on user age
/// Required for Google Play Families Policy compliance
class ContentFilterService {
  static final ContentFilterService _instance = ContentFilterService._internal();
  factory ContentFilterService() => _instance;
  ContentFilterService._internal();

  bool? _isChildMode;
  int? _userAge;

  /// Initialize the service and load age information
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isChildMode = prefs.getBool('child_mode') ?? false;
    _userAge = prefs.getInt('user_age');
  }

  /// Check if user is in child mode (under 13)
  bool get isChildMode => _isChildMode ?? false;

  /// Get user age
  int? get userAge => _userAge;

  /// Check if content is appropriate for user's age
  bool isContentAppropriate(int minimumAge) {
    if (_userAge == null) return false;
    return _userAge! >= minimumAge;
  }

  /// Filter features based on age
  Map<String, bool> getFeatureAccess() {
    if (_userAge == null) {
      return {
        'social_features': false,
        'leaderboard': false,
        'comments': false,
        'profile_sharing': false,
        'external_links': false,
        'advanced_analytics': false,
      };
    }

    final isChild = _userAge! < 13;

    return {
      // Social features restricted for children
      'social_features': !isChild,
      'leaderboard': !isChild,
      'comments': !isChild,
      'profile_sharing': !isChild,
      
      // External links restricted for children
      'external_links': !isChild,
      
      // Advanced analytics available for all ages
      'advanced_analytics': true,
      
      // Core health tracking available for all ages
      'step_tracking': true,
      'water_tracking': true,
      'sleep_tracking': true,
      'achievements': true,
    };
  }

  /// Get filtered curated content based on age
  List<Map<String, dynamic>> filterCuratedContent(List<Map<String, dynamic>> content) {
    if (_userAge == null) return [];

    return content.where((item) {
      final minimumAge = item['minimumAge'] as int? ?? 0;
      return _userAge! >= minimumAge;
    }).toList();
  }

  /// Get age-appropriate notification messages
  String getAgeAppropriateMessage(String messageType) {
    final isChild = _userAge != null && _userAge! < 13;

    switch (messageType) {
      case 'water_reminder':
        return isChild
            ? '💧 Time to drink some water!'
            : '💧 Stay hydrated! Time for some water.';
      case 'step_goal':
        return isChild
            ? '🎉 Great job! You reached your step goal!'
            : '🎉 Congratulations! You\'ve achieved your daily step goal!';
      case 'achievement_unlocked':
        return isChild
            ? '🏆 You earned a new badge!'
            : '🏆 Achievement Unlocked!';
      default:
        return '';
    }
  }

  /// Check if user can access social features
  bool canAccessSocialFeatures() {
    return !isChildMode;
  }

  /// Check if user can post comments
  bool canPostComments() {
    return !isChildMode;
  }

  /// Check if user can view leaderboard
  bool canViewLeaderboard() {
    return !isChildMode;
  }

  /// Check if user can share profile
  bool canShareProfile() {
    return !isChildMode;
  }

  /// Check if external links should be shown
  bool canShowExternalLinks() {
    return !isChildMode;
  }

  /// Get privacy-appropriate data collection settings
  Map<String, bool> getDataCollectionSettings() {
    final isChild = _userAge != null && _userAge! < 13;

    return {
      // Basic health data collection allowed for all ages
      'health_metrics': true,
      'activity_tracking': true,
      
      // Limited data collection for children
      'location_data': !isChild,
      'behavioral_analytics': !isChild,
      'third_party_sharing': !isChild,
      
      // No advertising for children
      'personalized_ads': !isChild,
    };
  }

  /// Clear age verification (for testing or logout)
  Future<void> clearAgeVerification() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('user_age');
    await prefs.remove('user_birthdate');
    await prefs.remove('age_verified');
    await prefs.remove('child_mode');
    _isChildMode = null;
    _userAge = null;
  }
}
