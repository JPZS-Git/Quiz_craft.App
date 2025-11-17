import '../../domain/entities/attempt_entity.dart';

class AttemptDto {
  final String id;
  final String quizId;
  final String? userId;
  final int correctCount;
  final int totalCount;
  final double score;
  final String startedAt; // ISO string
  final String? finishedAt;

  AttemptDto({
    required this.id,
    required this.quizId,
    this.userId,
    this.correctCount = 0,
    this.totalCount = 0,
    this.score = 0.0,
    String? startedAt,
    this.finishedAt,
  }) : startedAt = startedAt ?? DateTime.now().toIso8601String();

  factory AttemptDto.fromMap(Map<String, dynamic> map) {
    return AttemptDto(
      id: map['id']?.toString() ?? '',
      quizId: map['quiz_id']?.toString() ?? '',
      userId: map['user_id'] as String?,
      correctCount: (map['correct_count'] is int) ? map['correct_count'] as int : (map['correct_count'] is num ? (map['correct_count'] as num).toInt() : 0),
      totalCount: (map['total_count'] is int) ? map['total_count'] as int : (map['total_count'] is num ? (map['total_count'] as num).toInt() : 0),
      score: (map['score'] is num) ? (map['score'] as num).toDouble() : (double.tryParse(map['score']?.toString() ?? '') ?? 0.0),
      startedAt: map['started_at']?.toString() ?? DateTime.now().toIso8601String(),
      finishedAt: map['finished_at']?.toString(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'user_id': userId,
        'correct_count': correctCount,
        'total_count': totalCount,
        'score': score,
        'started_at': startedAt,
        'finished_at': finishedAt,
      };

  AttemptEntity toEntity() {
    return AttemptEntity(
      id: id,
      quizId: quizId,
      userId: userId,
      correctCount: correctCount,
      totalCount: totalCount,
      score: score,
      startedAt: DateTime.tryParse(startedAt) ?? DateTime.now(),
      finishedAt: finishedAt != null ? DateTime.tryParse(finishedAt!) : null,
    );
  }

  factory AttemptDto.fromEntity(AttemptEntity e) => AttemptDto(
        id: e.id,
        quizId: e.quizId,
        userId: e.userId,
        correctCount: e.correctCount,
        totalCount: e.totalCount,
        score: e.score,
        startedAt: e.startedAt.toIso8601String(),
        finishedAt: e.finishedAt?.toIso8601String(),
      );
}
