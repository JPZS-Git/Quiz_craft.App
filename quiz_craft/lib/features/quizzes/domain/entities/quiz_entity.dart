import 'package:quizcraft/features/questions/domain/entities/question_entity.dart';
import 'package:quizcraft/features/answers/domain/entities/answer_entity.dart';

class QuizEntity {
  final String id;
  final String title;
  final String? description;
  final String? authorId;
  final List<String> topics;
  final List<QuestionEntity> questions;
  final bool isPublished;
  final DateTime createdAt;
  final DateTime updatedAt;

  QuizEntity({
    required this.id,
    required this.title,
    this.description,
    this.authorId,
    this.topics = const [],
    this.questions = const [],
    this.isPublished = false,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now();

  /// Create from a map (flexible parsing for lists and nested maps).
  factory QuizEntity.fromMap(Map<String, dynamic> map) {
    // parse topics: accept List<String> or comma-separated String
    List<String> parsedTopics = [];
    final t = map['topics'];
    if (t is List) {
      parsedTopics = t.whereType<String>().toList();
    } else if (t is String) {
      parsedTopics = t.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    // parse questions: each item is expected to be a Map<String,dynamic>
    final qs = <QuestionEntity>[];
    final rawQuestions = map['questions'];
    if (rawQuestions is List) {
      for (final item in rawQuestions) {
        if (item is Map<String, dynamic>) {
          // build QuestionEntity manually and convert answer maps to AnswerEntity
          final answersRaw = item['answers'];
          final answersList = <AnswerEntity>[];
          if (answersRaw is List) {
            for (final a in answersRaw) {
              if (a is Map<String, dynamic>) {
                answersList.add(AnswerEntity.fromMap(a));
              }
            }
          }

          final createdAtQuestion = item['created_at'] != null ? DateTime.tryParse(item['created_at'].toString()) ?? DateTime.now() : DateTime.now();
          final updatedAtQuestion = item['updated_at'] != null ? DateTime.tryParse(item['updated_at'].toString()) ?? createdAtQuestion : createdAtQuestion;

          qs.add(QuestionEntity(
            id: item['id']?.toString() ?? '',
            quizId: map['id']?.toString() ?? '', // FK para o quiz pai
            text: item['text']?.toString() ?? '',
            answers: answersList,
            order: (item['order'] is int) ? item['order'] as int : (item['order'] is num ? (item['order'] as num).toInt() : 0),
            createdAt: createdAtQuestion,
            updatedAt: updatedAtQuestion,
          ));
        }
      }
    }

    final createdAt = map['created_at'] != null ? DateTime.tryParse(map['created_at'].toString()) ?? DateTime.now() : DateTime.now();
    final updatedAt = map['updated_at'] != null ? DateTime.tryParse(map['updated_at'].toString()) ?? createdAt : createdAt;

    return QuizEntity(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description'] as String?,
      authorId: map['author_id'] as String?,
      topics: parsedTopics,
      questions: qs,
      isPublished: map['is_published'] as bool? ?? false,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'author_id': authorId,
      'topics': topics,
      'questions': questions.map((q) => q.toMap()).toList(),
      'is_published': isPublished,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
