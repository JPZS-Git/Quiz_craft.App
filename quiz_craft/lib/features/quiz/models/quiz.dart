import 'question.dart';

/// Representa um quiz completo
class Quiz {
  final String title;
  final String theme; // tema do quiz
  final List<Question> questions;

  Quiz({
    required this.title,
    required this.theme,
    required this.questions,
  });
}
