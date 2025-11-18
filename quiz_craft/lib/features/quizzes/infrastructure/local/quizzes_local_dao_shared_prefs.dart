import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../dtos/quiz_dto.dart';

/// DAO local para quizzes usando SharedPreferences.
/// Armazena quizzes em JSON no storage local.
class QuizzesLocalDaoSharedPrefs {
  static const String _quizzesKey = 'quizzes_cache';

  /// Lista todos os quizzes armazenados localmente.
  Future<List<QuizDto>> listAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_quizzesKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => QuizDto.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Insere ou atualiza múltiplos quizzes (upsert em lote).
  Future<void> upsertAll(List<QuizDto> quizzes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = quizzes.map((q) => q.toMap()).toList();
      await prefs.setString(_quizzesKey, jsonEncode(jsonList));
    } catch (e) {
      // Silently fail
    }
  }

  /// Remove todos os quizzes do cache local.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_quizzesKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Adiciona um único quiz ao cache.
  Future<void> add(QuizDto quiz) async {
    final all = await listAll();
    all.add(quiz);
    await upsertAll(all);
  }

  /// Remove um quiz por ID.
  Future<void> removeById(String id) async {
    final all = await listAll();
    all.removeWhere((q) => q.id == id);
    await upsertAll(all);
  }

  /// Atualiza um quiz existente.
  Future<void> update(QuizDto quiz) async {
    final all = await listAll();
    final index = all.indexWhere((q) => q.id == quiz.id);
    if (index != -1) {
      all[index] = quiz;
      await upsertAll(all);
    }
  }

  /// Filtra apenas quizzes publicados.
  Future<List<QuizDto>> listPublishedQuizzes() async {
    final all = await listAll();
    return all.where((q) => q.isPublished).toList();
  }

  /// Filtra apenas quizzes não publicados (rascunhos).
  Future<List<QuizDto>> listDraftQuizzes() async {
    final all = await listAll();
    return all.where((q) => !q.isPublished).toList();
  }

  /// Filtra quizzes por tópico.
  Future<List<QuizDto>> listByTopic(String topic) async {
    final all = await listAll();
    return all.where((q) => q.topics.contains(topic)).toList();
  }

  /// Filtra quizzes por authorId.
  Future<List<QuizDto>> listByAuthorId(String authorId) async {
    final all = await listAll();
    return all.where((q) => q.authorId == authorId).toList();
  }

  /// Filtra quizzes com quantidade mínima de perguntas.
  Future<List<QuizDto>> listByMinQuestions(int minQuestions) async {
    final all = await listAll();
    return all.where((q) => q.questions.length >= minQuestions).toList();
  }
}
