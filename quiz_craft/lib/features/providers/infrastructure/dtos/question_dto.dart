import '../../domain/entities/question_entity.dart';
import 'answer_dto.dart';

class QuestionDto {
  final String id;
  final String text;
  final List<AnswerDto> answers;
  final int order;

  QuestionDto({
    required this.id,
    required this.text,
    this.answers = const [],
    this.order = 0,
  });

  factory QuestionDto.fromMap(Map<String, dynamic> map) {
    final list = <AnswerDto>[];
    if (map['answers'] is List) {
      for (final a in map['answers']) {
        if (a is Map<String, dynamic>) list.add(AnswerDto.fromMap(a));
      }
    }

    return QuestionDto(
      id: map['id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      answers: list,
      order: (map['order'] is int) ? map['order'] as int : (map['order'] is num ? (map['order'] as num).toInt() : 0),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'text': text,
        'answers': answers.map((a) => a.toMap()).toList(),
        'order': order,
      };

  QuestionEntity toEntity() {
    return QuestionEntity(
      id: id,
      text: text,
      answers: answers.map((a) => a.toEntity()).toList(),
      order: order,
    );
  }

  factory QuestionDto.fromEntity(QuestionEntity e) => QuestionDto(id: e.id, text: e.text, answers: e.answers.map((a) => AnswerDto.fromMap(a.toMap())).toList(), order: e.order);
}
