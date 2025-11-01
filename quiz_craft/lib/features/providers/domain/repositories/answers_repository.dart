import '../entities/answer_entity.dart';

abstract class AnswersRepository {
  /// Fetch all answers for a given question.
  Future<List<AnswerEntity>> fetchAnswersByQuestion(String questionId);

  /// Get an answer by id.
  Future<AnswerEntity?> getAnswerById(String id);

  /// Add an answer to a question.
  Future<void> addAnswer(String questionId, AnswerEntity answer);

  /// Update an answer.
  Future<void> updateAnswer(AnswerEntity answer);

  /// Delete an answer by id.
  Future<void> deleteAnswer(String id);
}
