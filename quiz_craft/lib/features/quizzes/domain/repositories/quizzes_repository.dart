import '../entities/quiz_entity.dart';

abstract class QuizzesRepository {
  /// Returns the list of quizzes (optionally could support pagination/filters later).
  Future<List<QuizEntity>> fetchQuizzes();

  /// Returns a quiz by id or null if not found.
  Future<QuizEntity?> getQuizById(String id);

  /// Adds a quiz to the data source.
  Future<void> addQuiz(QuizEntity quiz);

  /// Updates an existing quiz.
  Future<void> updateQuiz(QuizEntity quiz);

  /// Deletes a quiz by id.
  Future<void> deleteQuiz(String id);
}
