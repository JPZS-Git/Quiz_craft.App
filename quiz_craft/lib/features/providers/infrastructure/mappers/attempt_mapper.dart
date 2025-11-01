import '../../domain/entities/attempt_entity.dart';
import '../dtos/attempt_dto.dart';

class AttemptMapper {
  AttemptMapper._();

  static AttemptDto toDto(AttemptEntity e) {
    return AttemptDto(
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

  static AttemptEntity toEntity(AttemptDto d) {
    return AttemptEntity(
      id: d.id,
      quizId: d.quizId,
      userId: d.userId,
      correctCount: d.correctCount,
      totalCount: d.totalCount,
      score: d.score,
      startedAt: DateTime.tryParse(d.startedAt) ?? DateTime.now(),
      finishedAt: d.finishedAt != null ? DateTime.tryParse(d.finishedAt!) : null,
    );
  }
}
