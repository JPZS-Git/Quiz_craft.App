import '../../domain/entities/quiz_entity.dart';
import 'package:quizcraft/features/questions/infrastructure/dtos/question_dto.dart';

class QuizDto {
  final String id;
  final String title;
  final String? description;
  final String? authorId;
  final List<String> topics;
  final List<QuestionDto> questions;
  final bool isPublished;
  final String createdAt;
  final String updatedAt;

  QuizDto({
    required this.id,
    required this.title,
    this.description,
    this.authorId,
    this.topics = const [],
    this.questions = const [],
    this.isPublished = false,
    String? createdAt,
    String? updatedAt,
  }) : createdAt = createdAt ?? DateTime.now().toIso8601String(),
       updatedAt = updatedAt ?? createdAt ?? DateTime.now().toIso8601String();

  factory QuizDto.fromMap(Map<String, dynamic> map) {
    final parsedTopics = <String>[];
    final t = map['topics'];
    if (t is List) {
      parsedTopics.addAll(t.whereType<String>());
    } else if (t is String) {
      parsedTopics.addAll(
        t.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty),
      );
    }

    final qs = <QuestionDto>[];
    if (map['questions'] is List) {
      for (final q in map['questions']) {
        if (q is Map<String, dynamic>) {
          qs.add(QuestionDto.fromMap(q));
        }
      }
    }

    return QuizDto(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description'] as String?,
      authorId: map['author_id'] as String?,
      topics: parsedTopics,
      questions: qs,
      isPublished: map['is_published'] as bool? ?? false,
      createdAt: map['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: map['updated_at']?.toString() ?? DateTime.now().toIso8601String(),
    );
  }

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'description': description,
        'author_id': authorId,
        'topics': topics,
        'questions': questions.map((q) => q.toMap()).toList(),
        'is_published': isPublished,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  QuizEntity toEntity() {
    return QuizEntity(
      id: id,
      title: title,
      description: description,
      authorId: authorId,
      topics: List<String>.from(topics),
      questions: questions.map((q) => q.toEntity()).toList(),
      isPublished: isPublished,
      createdAt: DateTime.tryParse(createdAt) ?? DateTime.now(),
      updatedAt: DateTime.tryParse(updatedAt) ?? DateTime.now(),
    );
  }

  factory QuizDto.fromEntity(QuizEntity e) => QuizDto(
        id: e.id,
        title: e.title,
        description: e.description,
        authorId: e.authorId,
        topics: e.topics,
        questions: e.questions.map((q) => QuestionDto.fromMap(q.toMap())).toList(),
        isPublished: e.isPublished,
        createdAt: e.createdAt.toIso8601String(),
        updatedAt: e.updatedAt.toIso8601String(),
      );
}
