import 'package:quizcraft/features/answers/domain/entities/answer_entity.dart';

class QuestionEntity {
  final String id;
  final String text;
  final List<AnswerEntity> answers;
  final int order;

  QuestionEntity({
    required this.id,
    required this.text,
    this.answers = const [],
    this.order = 0,
  });

  factory QuestionEntity.fromMap(Map<String, dynamic> map) {
    final list = <AnswerEntity>[];
    if (map['answers'] is List) {
      for (final a in map['answers']) {
        if (a is Map<String, dynamic>) list.add(AnswerEntity.fromMap(a));
      }
    }

    return QuestionEntity(
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
}
