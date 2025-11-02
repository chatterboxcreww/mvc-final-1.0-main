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

  bool get isContentAvailable => _breakfastFeed.isNotEmpty || _lunchFeed.isNotEmpty || _dinnerFeed.isNotEmpty || _coffeeFeed.isNotEmpty || _teaFeed.isNotEmpty;

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
        
        // Add coffee and tea feeds - combine Firebase data with generated content
        final coffeeFromFirebase = _parseMealListFromSnapshot(data['coffee']?['items']);
        final teaFromFirebase = _parseMealListFromSnapshot(data['tea']?['items']);
        
        _coffeeFeed = [...coffeeFromFirebase, ..._generateCoffeeContent()];
        _teaFeed = [...teaFromFirebase, ..._generateTeaContent()];

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
    List<CuratedContentItem> beverageList = [];

    // Determine meal category based on time
    if (currentHour >= 4 && currentHour < 11) {
      sourceList = _breakfastFeed;
    } else if (currentHour >= 11 && currentHour < 17) {
      sourceList = _lunchFeed;
    } else {
      sourceList = _dinnerFeed;
    }

    // Add beverage content based on user preferences and time
    if (userData.prefersCoffee == true) {
      // Show coffee content primarily in morning (6-12) and early afternoon (12-15)
      if (currentHour >= 6 && currentHour < 15) {
        beverageList.addAll(_coffeeFeed);
      }
    }
    
    if (userData.prefersTea == true) {
      // Show tea content throughout the day, especially afternoon/evening (14-22)
      if (currentHour >= 14 && currentHour < 22) {
        beverageList.addAll(_teaFeed);
      } else if (currentHour >= 6 && currentHour < 14) {
        // Show a subset of tea options in morning/midday
        beverageList.addAll(_teaFeed.take(6));
      }
    }

    // Combine meal and beverage content
    final combinedList = [...sourceList, ...beverageList];
    
    if (combinedList.isEmpty) return [];

    return _applyHealthAndDietaryFilters(combinedList, userData);
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

  List<CuratedContentItem> _generateCoffeeContent() {
    return [
      CuratedContentItem(
        id: 'coffee_espresso_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Espresso - Pure Energy Shot',
        description: 'A concentrated shot of pure coffee energy to kickstart your day',
        category: 'coffee',
        healthBenefit: 'Rich in antioxidants, improves mental alertness, boosts metabolism',
        imageUrl: 'assets/coffee/espresso.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'espresso', 'energy', 'antioxidants'],
        goodForDiseases: ['fatigue', 'low_energy'],
        badForDiseases: ['anxiety', 'insomnia'],
        allergens: [],
        ingredients: ['1 shot espresso (30ml)', 'Freshly ground coffee beans'],
        instructions: ['Grind coffee beans to fine consistency', 'Tamp grounds evenly in portafilter', 'Extract for 25-30 seconds', 'Serve immediately'],
        nutrition: {'Calories': '3 kcal', 'Protein': '0.1g', 'Carbs': '0g', 'Fat': '0g', 'Caffeine': '64mg'},
      ),
      CuratedContentItem(
        id: 'coffee_americano_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Americano - Bold & Smooth',
        description: 'Diluted espresso for a smoother, longer coffee experience',
        category: 'coffee',
        healthBenefit: 'Low calorie, improves cognitive function, reduces risk of type 2 diabetes',
        imageUrl: 'assets/coffee/americano.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'americano', 'low_calorie', 'diabetes_friendly'],
        goodForDiseases: ['diabetes', 'cognitive_decline'],
        badForDiseases: ['anxiety', 'heart_conditions'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'coffee_latte_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Latte - Creamy Comfort',
        description: 'Espresso with steamed milk for a creamy, comforting drink',
        category: 'coffee',
        healthBenefit: 'Contains calcium from milk, provides energy, supports bone health',
        imageUrl: 'assets/coffee/latte.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'latte', 'dairy', 'calcium'],
        goodForDiseases: ['osteoporosis', 'bone_weakness'],
        badForDiseases: ['lactose_intolerance'],
        allergens: ['milk'],
      ),
      CuratedContentItem(
        id: 'coffee_cappuccino_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Cappuccino - Frothy Delight',
        description: 'Equal parts espresso, steamed milk, and milk foam',
        category: 'coffee',
        healthBenefit: 'Balanced caffeine intake, contains probiotics from milk, improves focus',
        imageUrl: 'assets/coffee/cappuccino.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'cappuccino', 'dairy', 'probiotics'],
        goodForDiseases: ['digestive_issues', 'concentration_problems'],
        badForDiseases: ['lactose_intolerance'],
        allergens: ['milk'],
      ),
      CuratedContentItem(
        id: 'coffee_macchiato_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Macchiato - Marked Perfection',
        description: 'Espresso "marked" with a dollop of steamed milk foam',
        category: 'coffee',
        healthBenefit: 'Strong antioxidant properties, enhances physical performance, burns fat',
        imageUrl: 'assets/coffee/macchiato.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'macchiato', 'antioxidants', 'performance'],
        goodForDiseases: ['obesity', 'metabolic_syndrome'],
        badForDiseases: ['anxiety', 'lactose_intolerance'],
        allergens: ['milk'],
      ),
      CuratedContentItem(
        id: 'coffee_mocha_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Mocha - Chocolate Bliss',
        description: 'Coffee and chocolate combined for the ultimate treat',
        category: 'coffee',
        healthBenefit: 'Mood booster from chocolate, antioxidants, improves brain function',
        imageUrl: 'assets/coffee/mocha.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'mocha', 'chocolate', 'mood_boost'],
        goodForDiseases: ['depression', 'cognitive_decline'],
        badForDiseases: ['lactose_intolerance', 'diabetes'],
        allergens: ['milk'],
      ),
      CuratedContentItem(
        id: 'coffee_cold_brew_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Cold Brew - Smooth & Refreshing',
        description: 'Slow-brewed coffee for a smooth, less acidic taste',
        category: 'coffee',
        healthBenefit: 'Lower acidity, easier on stomach, sustained energy release',
        imageUrl: 'assets/coffee/cold_brew.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'cold_brew', 'low_acid', 'gentle'],
        goodForDiseases: ['acid_reflux', 'stomach_sensitivity'],
        badForDiseases: ['insomnia'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'coffee_french_press_${DateTime.now().millisecondsSinceEpoch}',
        title: 'French Press - Full-bodied Flavor',
        description: 'Rich, full-bodied coffee with natural oils preserved',
        category: 'coffee',
        healthBenefit: 'Contains beneficial oils, high antioxidant content, reduces inflammation',
        imageUrl: 'assets/coffee/french_press.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'french_press', 'antioxidants', 'anti_inflammatory'],
        goodForDiseases: ['inflammation', 'arthritis'],
        badForDiseases: ['high_cholesterol'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'coffee_bulletproof_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Bulletproof Coffee - Energy & Focus',
        description: 'Coffee blended with butter and MCT oil for sustained energy',
        category: 'coffee',
        healthBenefit: 'Sustained energy, mental clarity, supports ketosis, healthy fats',
        imageUrl: 'assets/coffee/bulletproof.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'bulletproof', 'keto', 'sustained_energy'],
        goodForDiseases: ['fatigue', 'brain_fog'],
        badForDiseases: ['lactose_intolerance', 'high_cholesterol'],
        allergens: ['milk'],
      ),
      CuratedContentItem(
        id: 'coffee_decaf_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Decaf - All Flavor, No Jitters',
        description: 'Enjoy coffee taste without the caffeine kick',
        category: 'coffee',
        healthBenefit: 'Antioxidants without caffeine, suitable for evening, reduces anxiety',
        imageUrl: 'assets/coffee/decaf.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['coffee', 'decaf', 'caffeine_free', 'evening'],
        goodForDiseases: ['anxiety', 'insomnia'],
        badForDiseases: [],
        allergens: [],
      ),
    ];
  }

  List<CuratedContentItem> _generateTeaContent() {
    return [
      CuratedContentItem(
        id: 'tea_green_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Green Tea - Antioxidant Powerhouse',
        description: 'Light, refreshing tea packed with healthy antioxidants',
        category: 'tea',
        healthBenefit: 'High in EGCG, boosts metabolism, supports weight loss, fights cancer',
        imageUrl: 'assets/tea/green_tea.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'green_tea', 'antioxidants', 'weight_loss'],
        goodForDiseases: ['obesity', 'cancer_risk', 'metabolic_syndrome'],
        badForDiseases: ['iron_deficiency'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_black_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Black Tea - Classic Energy',
        description: 'Bold, robust tea for a strong energy boost',
        category: 'tea',
        healthBenefit: 'Heart health, improves focus, contains theaflavins, reduces cholesterol',
        imageUrl: 'assets/tea/black_tea.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'black_tea', 'heart_health', 'energy'],
        goodForDiseases: ['heart_disease', 'high_cholesterol', 'fatigue'],
        badForDiseases: ['anxiety', 'insomnia'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_white_${DateTime.now().millisecondsSinceEpoch}',
        title: 'White Tea - Delicate & Pure',
        description: 'Subtle, delicate tea with the highest antioxidant content',
        category: 'tea',
        healthBenefit: 'Highest antioxidants, anti-aging properties, protects skin, gentle caffeine',
        imageUrl: 'assets/tea/white_tea.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'white_tea', 'antioxidants', 'anti_aging'],
        goodForDiseases: ['skin_aging', 'oxidative_stress'],
        badForDiseases: [],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_oolong_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Oolong Tea - Balanced Complexity',
        description: 'Partially fermented tea with complex flavors',
        category: 'tea',
        healthBenefit: 'Boosts metabolism, aids digestion, balances blood sugar, mental alertness',
        imageUrl: 'assets/tea/oolong_tea.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'oolong', 'metabolism', 'diabetes_friendly'],
        goodForDiseases: ['diabetes', 'digestive_issues', 'obesity'],
        badForDiseases: ['anxiety'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_chamomile_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Chamomile Tea - Calming Comfort',
        description: 'Soothing herbal tea perfect for relaxation',
        category: 'tea',
        healthBenefit: 'Promotes sleep, reduces anxiety, anti-inflammatory, aids digestion',
        imageUrl: 'assets/tea/chamomile_tea.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'herbal', 'chamomile', 'sleep', 'relaxation'],
        goodForDiseases: ['anxiety', 'insomnia', 'inflammation'],
        badForDiseases: [],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_peppermint_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Peppermint Tea - Refreshing Relief',
        description: 'Cooling herbal tea for digestive comfort',
        category: 'tea',
        healthBenefit: 'Aids digestion, relieves nausea, freshens breath, reduces stress',
        imageUrl: 'assets/tea/peppermint_tea.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'herbal', 'peppermint', 'digestion'],
        goodForDiseases: ['digestive_issues', 'nausea', 'stress'],
        badForDiseases: ['acid_reflux'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_ginger_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Ginger Tea - Warming Wellness',
        description: 'Spicy, warming tea with powerful health benefits',
        category: 'tea',
        healthBenefit: 'Anti-inflammatory, aids nausea, boosts immunity, improves circulation',
        imageUrl: 'assets/tea/ginger_tea.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'herbal', 'ginger', 'anti_inflammatory'],
        goodForDiseases: ['inflammation', 'nausea', 'poor_circulation'],
        badForDiseases: ['acid_reflux'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_earl_grey_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Earl Grey - Bergamot Elegance',
        description: 'Black tea infused with bergamot oil for citrusy notes',
        category: 'tea',
        healthBenefit: 'Mood enhancement, digestive support, cholesterol reduction, stress relief',
        imageUrl: 'assets/tea/earl_grey.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'black_tea', 'bergamot', 'mood_boost'],
        goodForDiseases: ['depression', 'high_cholesterol', 'stress'],
        badForDiseases: ['anxiety'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_matcha_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Matcha - Concentrated Zen',
        description: 'Powdered green tea for maximum antioxidant benefits',
        category: 'tea',
        healthBenefit: 'L-theanine for calm focus, detoxifying, boosts metabolism, sustained energy',
        imageUrl: 'assets/tea/matcha.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'matcha', 'green_tea', 'focus', 'energy'],
        goodForDiseases: ['brain_fog', 'obesity', 'oxidative_stress'],
        badForDiseases: ['anxiety'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_hibiscus_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Hibiscus Tea - Ruby Red Health',
        description: 'Tart, colorful herbal tea rich in vitamin C',
        category: 'tea',
        healthBenefit: 'Lowers blood pressure, rich in vitamin C, supports liver health, antioxidants',
        imageUrl: 'assets/tea/hibiscus.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'herbal', 'hibiscus', 'vitamin_c', 'heart_health'],
        goodForDiseases: ['high_blood_pressure', 'liver_issues', 'immune_weakness'],
        badForDiseases: ['low_blood_pressure'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_rooibos_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Rooibos - Caffeine-Free Comfort',
        description: 'South African red bush tea, naturally caffeine-free',
        category: 'tea',
        healthBenefit: 'Caffeine-free, rich in minerals, anti-allergenic, supports bone health',
        imageUrl: 'assets/tea/rooibos.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'herbal', 'rooibos', 'caffeine_free'],
        goodForDiseases: ['allergies', 'osteoporosis', 'insomnia'],
        badForDiseases: [],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_turmeric_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Turmeric Tea - Golden Healing',
        description: 'Golden spice tea with powerful anti-inflammatory properties',
        category: 'tea',
        healthBenefit: 'Anti-inflammatory, pain relief, immune support, brain health',
        imageUrl: 'assets/tea/turmeric.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'herbal', 'turmeric', 'anti_inflammatory'],
        goodForDiseases: ['inflammation', 'arthritis', 'immune_weakness'],
        badForDiseases: ['gallstones'],
        allergens: [],
      ),
      CuratedContentItem(
        id: 'tea_jasmine_${DateTime.now().millisecondsSinceEpoch}',
        title: 'Jasmine Tea - Floral Serenity',
        description: 'Green tea scented with jasmine flowers for aromatherapy benefits',
        category: 'tea',
        healthBenefit: 'Stress reduction, aromatherapy benefits, antioxidants, mood enhancement',
        imageUrl: 'assets/tea/jasmine.jpg',
        timestamp: DateTime.now().millisecondsSinceEpoch,
        isPersonalized: true,
        keywords: ['tea', 'green_tea', 'jasmine', 'stress_relief'],
        goodForDiseases: ['stress', 'anxiety', 'depression'],
        badForDiseases: [],
        allergens: [],
      ),
    ];
  }
}
