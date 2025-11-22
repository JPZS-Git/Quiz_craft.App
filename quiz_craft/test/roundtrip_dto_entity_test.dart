import 'package:flutter_test/flutter_test.dart';

import 'package:quizcraft/features/authors/domain/entities/author_entity.dart';
import 'package:quizcraft/features/authors/infrastructure/dtos/author_dto.dart';
import 'package:quizcraft/features/authors/infrastructure/mappers/author_mapper.dart';

import 'package:quizcraft/features/quizzes/domain/entities/quiz_entity.dart';
import 'package:quizcraft/features/questions/domain/entities/question_entity.dart';
import 'package:quizcraft/features/answers/domain/entities/answer_entity.dart';
import 'package:quizcraft/features/quizzes/infrastructure/dtos/quiz_dto.dart';
import 'package:quizcraft/features/quizzes/infrastructure/mappers/quiz_mapper.dart';

import 'package:quizcraft/features/attempts/domain/entities/attempt_entity.dart';
import 'package:quizcraft/features/attempts/infrastructure/dtos/attempt_dto.dart';
import 'package:quizcraft/features/attempts/infrastructure/mappers/attempt_mapper.dart';

void main() {
  test('Author DTO round-trip (Entity -> DTO -> Map -> DTO -> Entity)', () {
    final created = DateTime.utc(2025, 11, 1);
    final author = AuthorEntity(
      id: 'author-1',
      name: 'João',
      email: 'joao@example.com',
      avatarUrl: 'https://example.com/avatar.png',
      bio: 'Bio',
      topics: ['dart', 'flutter'],
      quizzesCount: 5,
      rating: 4.2,
      isActive: true,
      createdAt: created,
    );

    final dto = AuthorMapper.toDto(author);
    final map = dto.toMap();
    final dto2 = AuthorDto.fromMap(map);
    final entity2 = dto2.toEntity();

    expect(entity2.id, author.id);
    expect(entity2.name, author.name);
    expect(entity2.email, author.email);
    expect(entity2.avatarUrl, author.avatarUrl);
    expect(entity2.bio, author.bio);
    expect(entity2.topics, author.topics);
    expect(entity2.quizzesCount, author.quizzesCount);
    expect(entity2.rating, author.rating);
    expect(entity2.isActive, author.isActive);
    expect(entity2.createdAt.toUtc(), author.createdAt.toUtc());
  });

  test('Quiz DTO round-trip with nested questions and answers', () {
    final created = DateTime.utc(2025, 11, 1);

    final answers = [
      AnswerEntity(id: 'a1', questionId: 'q1', text: 'Yes', isCorrect: true),
      AnswerEntity(id: 'a2', questionId: 'q1', text: 'No', isCorrect: false),
    ];

    final questions = [
      QuestionEntity(id: 'q1', text: 'Is this a test?', answers: answers, order: 0, quizId: 'quiz-1'),
    ];

    final quiz = QuizEntity(
      id: 'quiz-1',
      title: 'Sample Quiz',
      description: 'Desc',
      authorId: 'author-1',
      topics: ['sample', 'test'],
      questions: questions,
      isPublished: true,
      createdAt: created,
    );

    final dto = QuizMapper.toDto(quiz);
    final map = dto.toMap();
    final dto2 = QuizDto.fromMap(map);
    final entity2 = dto2.toEntity();

    expect(entity2.id, quiz.id);
    expect(entity2.title, quiz.title);
    expect(entity2.description, quiz.description);
    expect(entity2.authorId, quiz.authorId);
    expect(entity2.topics, quiz.topics);
    expect(entity2.isPublished, quiz.isPublished);
    expect(entity2.createdAt.toUtc(), quiz.createdAt.toUtc());

    expect(entity2.questions.length, quiz.questions.length);
    for (var i = 0; i < quiz.questions.length; i++) {
      final q = quiz.questions[i];
      final q2 = entity2.questions[i];
      expect(q2.id, q.id);
      expect(q2.text, q.text);
      expect(q2.order, q.order);
      expect(q2.answers.length, q.answers.length);
      for (var j = 0; j < q.answers.length; j++) {
        final a = q.answers[j];
        final a2 = q2.answers[j];
        expect(a2.id, a.id);
        expect(a2.text, a.text);
        expect(a2.isCorrect, a.isCorrect);
      }
    }
  });

  test('Attempt DTO round-trip', () {
    final started = DateTime.utc(2025, 11, 1, 12, 0, 0);
    final finished = DateTime.utc(2025, 11, 1, 12, 30, 0);

    final attempt = AttemptEntity(
      id: 'att-1',
      quizId: 'quiz-1',
      userId: 'user-1',
      status: 'completed',
      answersData: {'q1': 'a1', 'q2': 'a2'},
      correctCount: 8,
      totalCount: 10,
      scorePercentage: 80.0,
      durationSeconds: 1800,
      startedAt: started,
      finishedAt: finished,
      createdAt: started,
      updatedAt: finished,
    );

    final dto = AttemptMapper.toDto(attempt);
    final map = dto.toMap();
    final dto2 = AttemptDto.fromMap(map);
    final entity2 = dto2.toEntity();

    expect(entity2.id, attempt.id);
    expect(entity2.quizId, attempt.quizId);
    expect(entity2.userId, attempt.userId);
    expect(entity2.status, attempt.status);
    expect(entity2.answersData, attempt.answersData);
    expect(entity2.correctCount, attempt.correctCount);
    expect(entity2.totalCount, attempt.totalCount);
    expect(entity2.scorePercentage, attempt.scorePercentage);
    expect(entity2.durationSeconds, attempt.durationSeconds);
    expect(entity2.startedAt.toUtc(), attempt.startedAt.toUtc());
    expect(entity2.finishedAt?.toUtc(), attempt.finishedAt?.toUtc());
    expect(entity2.createdAt.toUtc(), attempt.createdAt.toUtc());
    expect(entity2.updatedAt.toUtc(), attempt.updatedAt.toUtc());
  });
}
