class LeaderboardEntry {
  final String id;
  final String displayName;
  final String? photoUrl;
  final int todaySteps;
  final double caloriesBurned;
  final DateTime timestamp;

  LeaderboardEntry({
    required this.id,
    required this.displayName,
    this.photoUrl,
    required this.todaySteps,
    required this.caloriesBurned,
    required this.timestamp,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] ?? '',
      displayName: json['displayName'] ?? 'Anonymous',
      photoUrl: json['photoUrl'],
      todaySteps: json['todaySteps'] ?? 0,
      caloriesBurned: (json['caloriesBurned'] as num?)?.toDouble() ?? 0.0,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'todaySteps': todaySteps,
      'caloriesBurned': caloriesBurned,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
