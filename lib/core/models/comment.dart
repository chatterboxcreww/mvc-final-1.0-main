// F:\latestmvc\latestmvc\mvc-final-1.0-main\lib\core\models\comment.dart

// lib/core/models/comment.dart

class Comment {
  final String id;
  final String text;
  final String userId;
  final String userName;
  final String? userProfilePicture;
  final DateTime timestamp;

  Comment({
    required this.id,
    required this.text,
    required this.userId,
    required this.userName,
    this.userProfilePicture,
    required this.timestamp,
  });

  factory Comment.fromRTDB(String id, Map<dynamic, dynamic> data) {
    return Comment(
      id: id,
      text: data['text'] ?? '',
      userId: data['userId'] ?? '',
      userName: data['userName'] ?? 'Anonymous',
      userProfilePicture: data['userProfilePicture'],
      timestamp: data['timestamp'] != null
          ? DateTime.parse(data['timestamp'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'userId': userId,
      'userName': userName,
      'userProfilePicture': userProfilePicture,
      'timestamp': timestamp.toIso8601String(),
    };
  }
}
