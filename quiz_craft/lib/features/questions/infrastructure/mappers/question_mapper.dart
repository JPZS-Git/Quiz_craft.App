import '../../domain/entities/question_entity.dart';
import '../dtos/question_dto.dart';
import 'package:quizcraft/features/answers/infrastructure/mappers/answer_mapper.dart';

class QuestionMapper {
  QuestionMapper._();

  static QuestionDto toDto(QuestionEntity e) {
    return QuestionDto(
      id: e.id,
      text: e.text,
      answers: e.answers.map((a) => AnswerMapper.toDto(a)).toList(),
      order: e.order,
    );
  }

  static QuestionEntity toEntity(QuestionDto d) {
    return QuestionEntity(
      id: d.id,
      text: d.text,
      answers: d.answers.map((a) => AnswerMapper.toEntity(a)).toList(),
      order: d.order,
    );
  }
}
