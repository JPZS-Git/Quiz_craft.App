class AttemptEntity {
  final String id;
  final String quizId;
  final String? userId;
  final String status; // 'in_progress', 'completed', 'abandoned'
  final Map<String, String>? answersData; // {"question_id": "answer_id"}
  final int correctCount;
  final int totalCount;
  final double scorePercentage; // 0..100
  final int? durationSeconds;
  final DateTime startedAt;
  final DateTime? finishedAt;
  final DateTime createdAt;
  final DateTime updatedAt;

  AttemptEntity({
    required this.id,
    required this.quizId,
    this.userId,
    this.status = 'in_progress',
    this.answersData,
    this.correctCount = 0,
    this.totalCount = 0,
    this.scorePercentage = 0.0,
    this.durationSeconds,
    DateTime? startedAt,
    this.finishedAt,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : startedAt = startedAt ?? DateTime.now(),
       createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  factory AttemptEntity.fromMap(Map<String, dynamic> map) {
    final started = map['started_at'] != null ? DateTime.tryParse(map['started_at'].toString()) : null;
    final finished = map['finished_at'] != null ? DateTime.tryParse(map['finished_at'].toString()) : null;
    final createdAt = map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now();
    final updatedAt = map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? createdAt : createdAt;

    // Parse answersData JSONB
    Map<String, String>? parsedAnswersData;
    if (map['answers_data'] != null) {
      if (map['answers_data'] is Map) {
        parsedAnswersData = (map['answers_data'] as Map).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    }

    return AttemptEntity(
      id: map['id']?.toString() ?? '',
      quizId: map['quiz_id']?.toString() ?? '',
      userId: map['user_id'] as String?,
      status: map['status']?.toString() ?? 'in_progress',
      answersData: parsedAnswersData,
      correctCount: (map['correct_count'] is int) ? map['correct_count'] as int : (map['correct_count'] is num ? (map['correct_count'] as num).toInt() : 0),
      totalCount: (map['total_count'] is int) ? map['total_count'] as int : (map['total_count'] is num ? (map['total_count'] as num).toInt() : 0),
      scorePercentage: (map['score_percentage'] is num) ? (map['score_percentage'] as num).toDouble() : (double.tryParse(map['score_percentage']?.toString() ?? '') ?? 0.0),
      durationSeconds: map['duration_seconds'] as int?,
      startedAt: started ?? DateTime.now(),
      finishedAt: finished,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'user_id': userId,
        'status': status,
        'answers_data': answersData,
        'correct_count': correctCount,
        'total_count': totalCount,
        'score_percentage': scorePercentage,
        'duration_seconds': durationSeconds,
        'started_at': startedAt.toIso8601String(),
        'finished_at': finishedAt?.toIso8601String(),
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
