import '../../domain/entities/attempt_entity.dart';
import '../dtos/attempt_dto.dart';

class AttemptMapper {
  AttemptMapper._();

  static AttemptDto toDto(AttemptEntity e) {
    return AttemptDto(
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

  static AttemptEntity toEntity(AttemptDto d) {
    return AttemptEntity(
      id: d.id,
      quizId: d.quizId,
      userId: d.userId,
      status: d.status,
      answersData: d.answersData,
      correctCount: d.correctCount,
      totalCount: d.totalCount,
      scorePercentage: d.scorePercentage,
      durationSeconds: d.durationSeconds,
      startedAt: DateTime.tryParse(d.startedAt) ?? DateTime.now(),
      finishedAt: d.finishedAt != null ? DateTime.tryParse(d.finishedAt!) : null,
      createdAt: DateTime.tryParse(d.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(d.updatedAt) ?? DateTime.now(),
    );
  }
}
