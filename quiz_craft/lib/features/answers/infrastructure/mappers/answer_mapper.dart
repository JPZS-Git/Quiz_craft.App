import '../../domain/entities/answer_entity.dart';
import '../dtos/answer_dto.dart';

class AnswerMapper {
  AnswerMapper._();

  static AnswerDto toDto(AnswerEntity e) {
    return AnswerDto(
      id: e.id,
      questionId: e.questionId,
      text: e.text,
      isCorrect: e.isCorrect,
      createdAt: e.createdAt.toIso8601String(),
      updatedAt: e.updatedAt.toIso8601String(),
    );
  }

  static AnswerEntity toEntity(AnswerDto d) {
    return AnswerEntity(
      id: d.id,
      questionId: d.questionId,
      text: d.text,
      isCorrect: d.isCorrect,
      createdAt: DateTime.tryParse(d.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(d.updatedAt) ?? DateTime.now(),
    );
  }
}
