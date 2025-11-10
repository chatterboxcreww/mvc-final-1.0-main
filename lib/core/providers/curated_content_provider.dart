// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\providers\curated_content_provider.dart

// lib/core/providers/curated_content_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

import '../models/curated_content_item.dart';
import '../models/user_data.dart';

class CuratedContentProvider with ChangeNotifier {
  final DatabaseReference _dbRef = FirebaseDatabase.instance.ref('curatedContent');

  List<CuratedContentItem> _breakfastFeed = [];
  List<CuratedContentItem> _lunchFeed = [];
  List<CuratedContentItem> _dinnerFeed = [];
  List<CuratedContentItem> _coffeeFeed = [];
  List<CuratedContentItem> _teaFeed = [];

  bool get isContentAvailable => _breakfastFeed.isNotEmpty || _lunchFeed.isNotEmpty || _dinnerFeed.isNotEmpty;

  CuratedContentProvider() {
    fetchCuratedContent();
  }

  /// Fetches the entire curated content structure from Firebase.
  Future<void> fetchCuratedContent() async {
    try {
      final snapshot = await _dbRef.get();
      if (snapshot.exists && snapshot.value != null) {
        final data = snapshot.value as Map<dynamic, dynamic>;

        _breakfastFeed = _parseMealListFromSnapshot(data['breakfast']?['items']);
        _lunchFeed = _parseMealListFromSnapshot(data['lunch']?['items']);
        _dinnerFeed = _parseMealListFromSnapshot(data['dinner']?['items']);
        
        // Only use Firebase data for coffee and tea - no generated content
        _coffeeFeed = _parseMealListFromSnapshot(data['coffee']?['items']);
        _teaFeed = _parseMealListFromSnapshot(data['tea']?['items']);

        print('Fetched feed content: ${_breakfastFeed.length} breakfast, ${_lunchFeed.length} lunch, ${_dinnerFeed.length} dinner, ${_coffeeFeed.length} coffee, ${_teaFeed.length} tea items.');
      } else {
        _clearAllFeeds();
        print('No curatedContent node found in Firebase.');
      }
      notifyListeners();
    } catch (e) {
      print('Error fetching curated content: $e');
      _clearAllFeeds();
      notifyListeners();
    }
  }

  /// NEW: Public method to allow the UI to trigger a refresh.
  Future<void> refreshFeed() async {
    // print("Manual feed refresh triggered.");
    await fetchCuratedContent();
  }

  List<CuratedContentItem> _parseMealListFromSnapshot(dynamic mealItemsData) {
    if (mealItemsData == null || mealItemsData is! Map) return [];

    final mealMap = mealItemsData;
    return mealMap.entries.map((entry) {
      return CuratedContentItem.fromRTDB(entry.key, entry.value as Map<dynamic, dynamic>);
    }).toList();
  }

  void _clearAllFeeds() {
    _breakfastFeed = [];
    _lunchFeed = [];
    _dinnerFeed = [];
    _coffeeFeed = [];
    _teaFeed = [];
  }

  List<CuratedContentItem> getFilteredContent(UserData userData) {
    final int currentHour = DateTime.now().hour;
    List<CuratedContentItem> sourceList;

    // TIME-BASED MEAL FILTERING (as per requirements)
    // 4 AM - 9 AM: Breakfast
    // 9 AM - 4 PM: Lunch
    // 4 PM onwards: Dinner
    if (currentHour >= 4 && currentHour < 9) {
      sourceList = _breakfastFeed;
      print('🍳 Showing breakfast feed (4 AM - 9 AM)');
    } else if (currentHour >= 9 && currentHour < 16) {
      sourceList = _lunchFeed;
      print('🍛 Showing lunch feed (9 AM - 4 PM)');
    } else {
      sourceList = _dinnerFeed;
      print('🍽️ Showing dinner feed (4 PM onwards)');
    }

    // Only show meal items from Firebase - no coffee/tea in feed
    if (sourceList.isEmpty) {
      print('⚠️ No content available for current time slot');
      return [];
    }

    print('📊 Total items before filtering: ${sourceList.length}');
    final filtered = _applyHealthAndDietaryFilters(sourceList, userData);
    print('📊 Total items after filtering: ${filtered.length}');
    
    return filtered;
  }

  List<CuratedContentItem> _applyHealthAndDietaryFilters(List<CuratedContentItem> items, UserData userData) {
    final Set<String> userAllergiesLower = (userData.allergies ?? []).map((a) => a.trim().toLowerCase()).toSet();
    if (userAllergiesLower.contains("none")) userAllergiesLower.clear();

    final String? userDietLower = userData.dietPreference?.name.toLowerCase();

    // Health condition filtering
    final Set<String> userHealthConditions = {};
    if (userData.hasDiabetes == true) userHealthConditions.add("diabetes");
    if (userData.isSkinnyFat == true) userHealthConditions.add("skinny_fat");
    if (userData.hasProteinDeficiency == true) userHealthConditions.add("protein_deficiency");

    return items.where((item) {
      final itemKeywordsLower = item.keywords.map((kw) => kw.toLowerCase()).toSet();
      final itemAllergensLower = item.allergens.map((a) => a.toLowerCase()).toSet();
      final itemBadForDiseasesLower = item.badForDiseases.map((d) => d.toLowerCase()).toSet();

      // 1. Allergen filtering - CRITICAL: Remove items with user's allergens
      if (userAllergiesLower.isNotEmpty && userAllergiesLower.intersection(itemAllergensLower).isNotEmpty) {
        print('Filtering out ${item.title} due to allergens: ${userAllergiesLower.intersection(itemAllergensLower)}');
        return false;
      }

      // 2. Dietary preference filtering
      if (userDietLower == 'vegetarian') {
        if (itemKeywordsLower.contains('non_veg')) {
          print('Filtering out ${item.title} - non-veg item for vegetarian user');
          return false;
        }
      }
      
      if (userDietLower == 'vegan') {
        if (itemKeywordsLower.contains('non_veg') || 
            itemKeywordsLower.contains('dairy') || 
            itemAllergensLower.contains('milk') ||
            itemAllergensLower.contains('eggs')) {
          print('Filtering out ${item.title} - contains animal products for vegan user');
          return false;
        }
      }

      // 3. Health condition filtering - Remove items bad for user's conditions
      if (userHealthConditions.isNotEmpty) {
        final badConditionsMatch = userHealthConditions.intersection(itemBadForDiseasesLower);
        if (badConditionsMatch.isNotEmpty) {
          print('Filtering out ${item.title} - bad for user conditions: $badConditionsMatch');
          return false;
        }
      }

      // 4. Prioritize items good for user's health conditions
      if (userHealthConditions.isNotEmpty) {
        final itemGoodForDiseasesLower = item.goodForDiseases.map((d) => d.toLowerCase()).toSet();
        final goodConditionsMatch = userHealthConditions.intersection(itemGoodForDiseasesLower);
        
        // If user has health conditions, prefer items that are specifically good for those conditions
        if (goodConditionsMatch.isNotEmpty) {
          print('Prioritizing ${item.title} - good for user conditions: $goodConditionsMatch');
          return true;
        }
        
        // Also include items with relevant health keywords
        if (userData.hasDiabetes == true && itemKeywordsLower.contains('diabetes_friendly')) return true;
        if (userData.isSkinnyFat == true && itemKeywordsLower.contains('skinny_fat_friendly')) return true;
        if (userData.hasProteinDeficiency == true && itemKeywordsLower.contains('high_protein')) return true;
      }

      return true;
    }).toList();
  }


}
