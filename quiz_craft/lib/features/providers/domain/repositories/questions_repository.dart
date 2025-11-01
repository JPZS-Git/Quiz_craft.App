import '../entities/question_entity.dart';

abstract class QuestionsRepository {
  /// Fetch all questions for a given quiz.
  Future<List<QuestionEntity>> fetchQuestionsByQuiz(String quizId);

  /// Get a question by id.
  Future<QuestionEntity?> getQuestionById(String id);

  /// Add a question to a quiz.
  Future<void> addQuestion(String quizId, QuestionEntity question);

  /// Update a question.
  Future<void> updateQuestion(QuestionEntity question);

  /// Delete a question by id.
  Future<void> deleteQuestion(String id);
}
