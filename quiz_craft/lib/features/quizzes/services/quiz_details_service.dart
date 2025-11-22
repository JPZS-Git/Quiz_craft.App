import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../domain/entities/quiz_entity.dart';
import '../../questions/domain/entities/question_entity.dart';
import '../../answers/domain/entities/answer_entity.dart';

/// Serviço para carregar detalhes completos de um quiz (com perguntas e respostas).
class QuizDetailsService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Carrega um quiz completo com todas suas perguntas e respostas do Supabase.
  Future<QuizEntity?> loadQuizWithDetails(String quizId) async {
    try {
      debugPrint('🔍 Carregando quiz $quizId com detalhes...');

      // 1. Buscar o quiz
      final quizResponse = await _supabase
          .from('quizzes')
          .select('*')
          .eq('id', quizId)
          .single();

      debugPrint('✅ Quiz encontrado: ${quizResponse['title']}');

      // 2. Buscar questions do quiz
      final questionsResponse = await _supabase
          .from('questions')
          .select('*')
          .eq('quiz_id', quizId)
          .order('order', ascending: true);

      final List<dynamic> questionsData = questionsResponse as List<dynamic>;
      debugPrint('✅ ${questionsData.length} questions encontradas');

      // 3. Para cada question, buscar suas answers
      final List<QuestionEntity> questions = [];
      
      for (final questionJson in questionsData) {
        final questionId = questionJson['id'] as String;
        
        final answersResponse = await _supabase
            .from('answers')
            .select('*')
            .eq('question_id', questionId);

        final List<dynamic> answersData = answersResponse as List<dynamic>;
        debugPrint('  📝 Question "${questionJson['text']}" tem ${answersData.length} answers');

        // Converter answers JSON para AnswerEntity
        final List<AnswerEntity> answers = answersData.map((answerJson) {
          return AnswerEntity(
            id: answerJson['id'] as String,
            questionId: answerJson['question_id'] as String,
            text: answerJson['text'] as String,
            isCorrect: answerJson['is_correct'] as bool,
            createdAt: DateTime.parse(answerJson['created_at'] as String),
            updatedAt: DateTime.parse(answerJson['updated_at'] as String),
          );
        }).toList();

        // Criar QuestionEntity com suas answers
        questions.add(QuestionEntity(
          id: questionJson['id'] as String,
          quizId: questionJson['quiz_id'] as String,
          text: questionJson['text'] as String,
          order: questionJson['order'] as int,
          answers: answers,
          createdAt: DateTime.parse(questionJson['created_at'] as String),
          updatedAt: DateTime.parse(questionJson['updated_at'] as String),
        ));
      }

      // 4. Criar QuizEntity completo
      final quiz = QuizEntity(
        id: quizResponse['id'] as String,
        title: quizResponse['title'] as String,
        description: quizResponse['description'] as String?,
        authorId: quizResponse['author_id'] as String?,
        topics: _parseTopics(quizResponse['topics']),
        isPublished: quizResponse['is_published'] as bool? ?? false,
        questions: questions,
        createdAt: DateTime.parse(quizResponse['created_at'] as String),
        updatedAt: DateTime.parse(quizResponse['updated_at'] as String),
      );

      debugPrint('✅ Quiz completo carregado: ${quiz.questions.length} questions');
      return quiz;
    } catch (e, stackTrace) {
      debugPrint('❌ Erro ao carregar quiz com detalhes: $e');
      debugPrint('Stack trace: $stackTrace');
      return null;
    }
  }

  /// Parse topics de String separada por vírgulas ou List<String>
  List<String> _parseTopics(dynamic topics) {
    if (topics == null) return [];
    if (topics is List) {
      return topics.whereType<String>().toList();
    }
    if (topics is String) {
      return topics
          .split(',')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();
    }
    return [];
  }
}
