import 'package:quizcraft/features/answers/domain/entities/answer_entity.dart';

class QuestionEntity {
  final String id;
  final String quizId;
  final String text;
  final List<AnswerEntity> answers;
  final int order;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuestionEntity({
    required this.id,
    required this.quizId,
    required this.text,
    this.answers = const [],
    this.order = 0,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  factory QuestionEntity.fromMap(Map<String, dynamic> map) {
    final list = <AnswerEntity>[];
    if (map['answers'] is List) {
      for (final a in map['answers']) {
        if (a is Map<String, dynamic>) list.add(AnswerEntity.fromMap(a));
      }
    }

    final createdAt = map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now();
    final updatedAt = map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? createdAt : createdAt;

    return QuestionEntity(
      id: map['id']?.toString() ?? '',
      quizId: map['quiz_id']?.toString() ?? '',
      text: map['text']?.toString() ?? '',
      answers: list,
      order: (map['order'] is int) ? map['order'] as int : (map['order'] is num ? (map['order'] as num).toInt() : 0),
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'quiz_id': quizId,
        'text': text,
        'answers': answers.map((a) => a.toMap()).toList(),
        'order': order,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
      };
}
