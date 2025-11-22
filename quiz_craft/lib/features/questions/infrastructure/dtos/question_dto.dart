import '../../domain/entities/question_entity.dart';
import 'package:quizcraft/features/answers/infrastructure/dtos/answer_dto.dart';

class QuestionDto {
  final String id;
  final String quizId;
  final String text;
  final List<AnswerDto> answers;
  final int order;
  final String createdAt;
  final String updatedAt;

  QuestionDto({
    required this.id,
    required this.quizId,
    required this.text,
    this.answers = const [],
    this.order = 0,
    String? createdAt,
    String? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toIso8601String();

  factory QuestionDto.fromMap(Map<String, dynamic> map) {
    final list = <AnswerDto>[];
    if (map['answers'] is List) {
      for (final a in map['answers']) {
        if (a is Map<String, dynamic>) list.add(AnswerDto.fromMap(a));
      }
    }

    return QuestionDto(
      id: map['id']?.toString() ?? '',
      quizId: map['quiz_id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      answers: list,
      order: (map['order'] is int) ? map['order'] as int : (map['order'] is num ? (map['order'] as num).toInt() : 0),
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'text': text,
        'answers': answers.map((a) => a.toMap()).toList(),
        'order': order,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  QuestionEntity toEntity() {
    return QuestionEntity(
      id: id,
      quizId: quizId,
      text: text,
      answers: answers.map((a) => a.toEntity()).toList(),
      order: order,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }

  factory QuestionDto.fromEntity(QuestionEntity e) => QuestionDto(
        id: e.id,
        quizId: e.quizId,
        text: e.text,
        answers: e.answers.map((a) => AnswerDto.fromMap(a.toMap())).toList(),
        order: e.order,
        createdAt: e.createdAt.toIso8601String(),
        updatedAt: e.updatedAt.toIso8601String(),
      );
}
