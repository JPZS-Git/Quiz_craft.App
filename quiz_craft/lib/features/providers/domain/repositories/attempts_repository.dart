import '../entities/attempt_entity.dart';

abstract class AttemptsRepository {
  /// Fetch attempts for a given quiz (or all attempts if quizId is null).
  Future<List<AttemptEntity>> fetchAttemptsByQuiz(String quizId);

  /// Get an attempt by id.
  Future<AttemptEntity?> getAttemptById(String id);

  /// Add a new attempt record.
  Future<void> addAttempt(AttemptEntity attempt);

  /// Update an existing attempt.
  Future<void> updateAttempt(AttemptEntity attempt);

  /// Delete an attempt by id.
  Future<void> deleteAttempt(String id);
}
