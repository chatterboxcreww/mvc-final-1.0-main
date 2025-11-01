// f:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\models\coach_insight.dart

class CoachInsight {
  final String id;
  final String title;
  final String message;
  final String category;
  final CoachInsightType type;
  final DateTime createdAt;
  final Map<String, dynamic>? data;

  const CoachInsight({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.type,
    required this.createdAt,
    this.data,
  });

  factory CoachInsight.fromJson(Map<String, dynamic> json) {
    return CoachInsight(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      category: json['category'] ?? '',
      type: CoachInsightType.values.firstWhere(
            (e) => e.name == json['type'],
        orElse: () => CoachInsightType.general,
      ),
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      data: json['data'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'category': category,
      'type': type.name,
      'createdAt': createdAt.toIso8601String(),
      'data': data,
    };
  }
}

enum CoachInsightType {
  general,
  steps,
  water,
  sleep,
  nutrition,
  achievement,
  motivation,
  warning,
}

