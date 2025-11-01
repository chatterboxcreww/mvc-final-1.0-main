// lib/core/models/achievement.dart

// Achievement categories
enum AchievementCategory {
  water,
  steps,
  sleep,
  
  meditation,
  level,
  combo,
  social,
  app,
  explorer,
  time,
  seasonal,
  challenge
}

class Achievement {
  final String id;
  final String name;
  final String description;
  final String icon;
  final bool isUnlocked;
  final DateTime? unlockedAt;
  final AchievementCategory category;
  final double progress; // Progress towards achievement (0.0 to 1.0)
  int currentValue; // Current value towards target
  final int targetValue; // Target value to unlock achievement

  Achievement({
    required this.id,
    required this.name,
    required this.description,
    required this.icon,
    this.isUnlocked = false,
    this.unlockedAt,
    required this.category,
    this.progress = 0.0,
    this.currentValue = 0,
    required this.targetValue,
  });

  // Create a copy of this achievement with updated properties
  Achievement copyWith({
    String? id,
    String? name,
    String? description,
    String? icon,
    bool? isUnlocked,
    DateTime? unlockedAt,
    AchievementCategory? category,
    double? progress,
    int? currentValue,
    int? targetValue,
  }) {
    return Achievement(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      icon: icon ?? this.icon,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      unlockedAt: unlockedAt ?? this.unlockedAt,
      category: category ?? this.category,
      progress: progress ?? this.progress,
      currentValue: currentValue ?? this.currentValue,
      targetValue: targetValue ?? this.targetValue,
    );
  }

  // Convert achievement to JSON for Firebase
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'isUnlocked': isUnlocked,
      'unlockedAt': unlockedAt?.toIso8601String(),
      'category': category.toString().split('.').last,
      'progress': progress,
      'currentValue': currentValue,
      'targetValue': targetValue,
    };
  }

  // Create achievement from Firebase JSON
  factory Achievement.fromJson(Map<String, dynamic> json) {
    return Achievement(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      icon: json['icon'] as String,
      isUnlocked: json['isUnlocked'] as bool? ?? false,
      unlockedAt: json['unlockedAt'] != null
          ? DateTime.parse(json['unlockedAt'] as String)
          : null,
      category: json['category'] != null
          ? AchievementCategory.values.firstWhere(
              (e) => e.toString().split('.').last == json['category'],
              orElse: () => AchievementCategory.combo)
          : AchievementCategory.combo,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      currentValue: (json['currentValue'] as num?)?.toInt() ?? 0,
      targetValue: (json['targetValue'] as num?)?.toInt() ?? 1,
    );
  }

  // Helper method to get category from achievement ID
  static AchievementCategory getCategoryFromId(String id) {
    if (id.startsWith('water')) return AchievementCategory.water;
    if (id.startsWith('steps')) return AchievementCategory.steps;
    if (id.startsWith('sleep')) return AchievementCategory.sleep;
    
    if (id.startsWith('meditation')) return AchievementCategory.meditation;
    if (id.startsWith('level')) return AchievementCategory.level;
    if (id.startsWith('combo') || id.startsWith('perfect')) return AchievementCategory.combo;
    if (id.startsWith('social')) return AchievementCategory.social;
    if (id.startsWith('app_usage')) return AchievementCategory.app;
    if (id.startsWith('explorer')) return AchievementCategory.explorer;
    if (id.startsWith('time')) return AchievementCategory.time;
    if (id.startsWith('seasonal')) return AchievementCategory.seasonal;
    if (id.startsWith('challenge')) return AchievementCategory.challenge;
    return AchievementCategory.combo;
  }
}
