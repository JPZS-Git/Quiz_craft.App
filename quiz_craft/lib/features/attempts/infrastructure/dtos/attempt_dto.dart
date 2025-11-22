import '../../domain/entities/attempt_entity.dart';

class AttemptDto {
  final String id;
  final String quizId;
  final String? userId;
  final String status;
  final Map<String, String>? answersData;
  final int correctCount;
  final int totalCount;
  final double scorePercentage;
  final int? durationSeconds;
  final String startedAt; // ISO string
  final String? finishedAt;
  final String createdAt;
  final String updatedAt;

  AttemptDto({
    required this.id,
    required this.quizId,
    this.userId,
    this.status = 'in_progress',
    this.answersData,
    this.correctCount = 0,
    this.totalCount = 0,
    this.scorePercentage = 0.0,
    this.durationSeconds,
    String? startedAt,
    this.finishedAt,
    String? createdAt,
    String? updatedAt,
  }) : startedAt = startedAt ?? DateTime.now().toIso8601String(),
       createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toIso8601String();

  factory AttemptDto.fromMap(Map<String, dynamic> map) {
    // Parse answersData JSONB
    Map<String, String>? parsedAnswersData;
    if (map['answers_data'] != null) {
      if (map['answers_data'] is Map) {
        parsedAnswersData = (map['answers_data'] as Map).map(
          (key, value) => MapEntry(key.toString(), value.toString()),
        );
      }
    }

    return AttemptDto(
      id: map['id']?.toString() ?? '',
      quizId: map['quiz_id']?.toString() ?? '',
      userId: map['user_id'] as String?,
      status: map['status']?.toString() ?? 'in_progress',
      answersData: parsedAnswersData,
      correctCount: (map['correct_count'] is int) ? map['correct_count'] as int : (map['correct_count'] is num ? (map['correct_count'] as num).toInt() : 0),
      totalCount: (map['total_count'] is int) ? map['total_count'] as int : (map['total_count'] is num ? (map['total_count'] as num).toInt() : 0),
      scorePercentage: (map['score_percentage'] is num) ? (map['score_percentage'] as num).toDouble() : (double.tryParse(map['score_percentage']?.toString() ?? '') ?? 0.0),
      durationSeconds: map['duration_seconds'] as int?,
      startedAt: map['started_at']?.toString() ?? DateTime.now().toIso8601String(),
      finishedAt: map['finished_at']?.toString(),
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
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
        'started_at': startedAt,
        'finished_at': finishedAt,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  AttemptEntity toEntity() {
    return AttemptEntity(
      id: id,
      quizId: quizId,
      userId: userId,
      status: status,
      answersData: answersData,
      correctCount: correctCount,
      totalCount: totalCount,
      scorePercentage: scorePercentage,
      durationSeconds: durationSeconds,
      startedAt: DateTime.tryParse(startedAt) ?? DateTime.now(),
      finishedAt: finishedAt != null ? DateTime.tryParse(finishedAt!) : null,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }

  factory AttemptDto.fromEntity(AttemptEntity e) => AttemptDto(
        id: e.id,
        quizId: e.quizId,
        userId: e.userId,
        status: e.status,
        answersData: e.answersData,
        correctCount: e.correctCount,
        totalCount: e.totalCount,
        scorePercentage: e.scorePercentage,
        durationSeconds: e.durationSeconds,
        startedAt: e.startedAt.toIso8601String(),
        finishedAt: e.finishedAt?.toIso8601String(),
        createdAt: e.createdAt.toIso8601String(),
        updatedAt: e.updatedAt.toIso8601String(),
      );
}
