// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\models\curated_content_item.dart

// lib/core/models/curated_content_item.dart

class CuratedContentItem {
  final String id;
  final String title;
  final String description;
  final String category;
  final String? imagePlaceholder;
  final String? imageUrl;
  final int timestamp;
  final bool isPersonalized;
  final String? healthBenefit;
  final List<String> keywords;
  final List<String> goodForDiseases;
  final List<String> badForDiseases;
  final List<String> allergens;
  final List<String> ingredients;
  final List<String> instructions;
  final Map<String, String> nutrition;

  CuratedContentItem({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.imagePlaceholder,
    this.imageUrl,
    required this.timestamp,
    required this.isPersonalized,
    this.healthBenefit,
    required this.keywords,
    required this.goodForDiseases,
    required this.badForDiseases,
    required this.allergens,
    List<String>? ingredients,
    List<String>? instructions,
    Map<String, String>? nutrition,
  }) : ingredients = ingredients ?? [],
       instructions = instructions ?? [],
       nutrition = nutrition ?? {};

  // MODIFIED: This factory constructor is now more robust to handle the exact RTDB structure.
  factory CuratedContentItem.fromRTDB(String id, Map<dynamic, dynamic> data) {
    // Helper to safely parse lists from Firebase, which can come as List or Map
    List<String> parseKeywords(dynamic keywordData) {
      if (keywordData == null) return [];
      if (keywordData is List) {
        return List<String>.from(keywordData.map((e) => e.toString()));
      }
      if (keywordData is Map) {
        return List<String>.from(keywordData.values.map((e) => e.toString()));
      }
      return [];
    }

    // Helper to parse nutrition map
    Map<String, String> parseNutrition(dynamic nutritionData) {
      if (nutritionData == null) return {};
      if (nutritionData is Map) {
        return Map<String, String>.from(
          nutritionData.map((key, value) => MapEntry(key.toString(), value.toString()))
        );
      }
      return {};
    }

    return CuratedContentItem(
      id: id,
      title: data['title'] ?? 'No Title Provided',
      description: data['description'] ?? 'No Description Available.',
      // Providing default values for fields that might be missing in the DB
      category: data['category'] ?? 'General',
      imagePlaceholder: data['imagePlaceholder'],
      imageUrl: data['imageUrl'],
      timestamp: data['timestamp'] ?? DateTime.now().millisecondsSinceEpoch,
      isPersonalized: data['isPersonalized'] ?? false,
      healthBenefit: data['healthBenefit'],
      keywords: parseKeywords(data['keywords']),
      goodForDiseases: parseKeywords(data['goodForDiseases']),
      badForDiseases: parseKeywords(data['badForDiseases']),
      allergens: parseKeywords(data['allergens']),
      ingredients: parseKeywords(data['ingredients']),
      instructions: parseKeywords(data['instructions']),
      nutrition: parseNutrition(data['nutrition']),
    );
  }
}
