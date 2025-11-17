class AttemptEntity {
  final String id;
  final String quizId;
  final String? userId;
  final int correctCount;
  final int totalCount;
  final double score; // percentage 0..100
  final DateTime startedAt;
  final DateTime? finishedAt;

  AttemptEntity({
    required this.id,
    required this.quizId,
    this.userId,
    this.correctCount = 0,
    this.totalCount = 0,
    this.score = 0.0,
    DateTime? startedAt,
    this.finishedAt,
  }) : startedAt = startedAt ?? DateTime.now();

  factory AttemptEntity.fromMap(Map<String, dynamic> map) {
    final started = map['started_at'] != null ? DateTime.tryParse(map['started_at'].toString()) : null;
    final finished = map['finished_at'] != null ? DateTime.tryParse(map['finished_at'].toString()) : null;
    return AttemptEntity(
      id: map['id']?.toString() ?? '',
      quizId: map['quiz_id']?.toString() ?? '',
      userId: map['user_id'] as String?,
      correctCount: (map['correct_count'] is int) ? map['correct_count'] as int : (map['correct_count'] is num ? (map['correct_count'] as num).toInt() : 0),
      totalCount: (map['total_count'] is int) ? map['total_count'] as int : (map['total_count'] is num ? (map['total_count'] as num).toInt() : 0),
      score: (map['score'] is num) ? (map['score'] as num).toDouble() : (double.tryParse(map['score']?.toString() ?? '') ?? 0.0),
      startedAt: started ?? DateTime.now(),
      finishedAt: finished,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'user_id': userId,
        'correct_count': correctCount,
        'total_count': totalCount,
        'score': score,
        'started_at': startedAt.toIso8601String(),
        'finished_at': finishedAt?.toIso8601String(),
      };
}
