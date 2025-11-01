import '../../domain/entities/answer_entity.dart';
import '../dtos/answer_dto.dart';

class AnswerMapper {
  AnswerMapper._();

  static AnswerDto toDto(AnswerEntity e) {
    return AnswerDto(
      id: e.id,
      text: e.text,
      isCorrect: e.isCorrect,
    );
  }

  static AnswerEntity toEntity(AnswerDto d) {
    return AnswerEntity(
      id: d.id,
      text: d.text,
      isCorrect: d.isCorrect,
    );
  }
}
