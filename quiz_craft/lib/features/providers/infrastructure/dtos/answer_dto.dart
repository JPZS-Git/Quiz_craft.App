import '../../domain/entities/answer_entity.dart';

class AnswerDto {
  final String id;
  final String text;
  final bool isCorrect;

  AnswerDto({
    required this.id,
    required this.text,
    this.isCorrect = false,
  });

  factory AnswerDto.fromMap(Map<String, dynamic> map) {
    return AnswerDto(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      isCorrect: map['is_correct'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'is_correct': isCorrect,
      };

  AnswerEntity toEntity() {
    return AnswerEntity(
      id: id,
      text: text,
      isCorrect: isCorrect,
    );
  }

  factory AnswerDto.fromEntity(AnswerEntity e) => AnswerDto(id: e.id, text: e.text, isCorrect: e.isCorrect);
}
