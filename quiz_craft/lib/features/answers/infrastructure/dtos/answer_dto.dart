import '../../domain/entities/answer_entity.dart';

class AnswerDto {
  final String id;
  final String questionId;
  final String text;
  final bool isCorrect;
  final String createdAt;
  final String updatedAt;

  AnswerDto({
    required this.id,
    required this.questionId,
    required this.text,
    this.isCorrect = false,
    String? createdAt,
    String? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toIso8601String();

  factory AnswerDto.fromMap(Map<String, dynamic> map) {
    return AnswerDto(
      id: map['id']?.toString() ?? '',
      questionId: map['question_id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'question_id': questionId,
        'text': text,
        'is_correct': isCorrect,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  AnswerEntity toEntity() {
    return AnswerEntity(
      id: id,
      questionId: questionId,
      text: text,
      isCorrect: isCorrect,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }

  factory AnswerDto.fromEntity(AnswerEntity e) => AnswerDto(
        id: e.id,
        questionId: e.questionId,
        text: e.text,
        isCorrect: e.isCorrect,
        createdAt: e.createdAt.toIso8601String(),
        updatedAt: e.updatedAt.toIso8601String(),
      );
}
