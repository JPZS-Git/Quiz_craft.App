import '../../domain/entities/question_entity.dart';
import '../dtos/question_dto.dart';
import 'package:quizcraft/features/answers/infrastructure/mappers/answer_mapper.dart';

class QuestionMapper {
  QuestionMapper._();

  static QuestionDto toDto(QuestionEntity e) {
    return QuestionDto(
      id: e.id,
      quizId: e.quizId,
      text: e.text,
      answers: e.answers.map((a) => AnswerMapper.toDto(a)).toList(),
      order: e.order,
      createdAt: e.createdAt.toIso8601String(),
      updatedAt: e.updatedAt.toIso8601String(),
    );
  }

  static QuestionEntity toEntity(QuestionDto d) {
    return QuestionEntity(
      id: d.id,
      quizId: d.quizId,
      text: d.text,
      answers: d.answers.map((a) => AnswerMapper.toEntity(a)).toList(),
      order: d.order,
      createdAt: DateTime.tryParse(d.createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(d.updatedAt) ?? DateTime.now(),
    );
  }
}
