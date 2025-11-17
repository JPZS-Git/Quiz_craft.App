import '../../domain/entities/quiz_entity.dart';
import '../dtos/quiz_dto.dart';
import 'question_mapper.dart';

class QuizMapper {
  QuizMapper._();

  static QuizDto toDto(QuizEntity e) {
    return QuizDto(
      id: e.id,
      title: e.title,
      description: e.description,
      authorId: e.authorId,
      topics: e.topics,
      questions: e.questions.map((q) => QuestionMapper.toDto(q)).toList(),
      isPublished: e.isPublished,
      createdAt: e.createdAt.toIso8601String(),
    );
  }

  static QuizEntity toEntity(QuizDto d) {
    return QuizEntity(
      id: d.id,
      title: d.title,
      description: d.description,
      authorId: d.authorId,
      topics: List<String>.from(d.topics),
      questions: d.questions.map((q) => QuestionMapper.toEntity(q)).toList(),
      isPublished: d.isPublished,
      createdAt: DateTime.tryParse(d.createdAt) ?? DateTime.now(),
    );
  }
}
