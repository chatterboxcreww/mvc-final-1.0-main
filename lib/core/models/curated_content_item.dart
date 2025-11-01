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
  });

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
    );
  }
}
