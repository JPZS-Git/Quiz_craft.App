import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../dtos/question_dto.dart';

/// DAO local para questões usando SharedPreferences.
/// Armazena questões em JSON no storage local.
class QuestionsLocalDaoSharedPrefs {
  static const String _questionsKey = 'questions_cache';

  /// Lista todas as questões armazenadas localmente.
  Future<List<QuestionDto>> listAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_questionsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => QuestionDto.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Insere ou atualiza múltiplas questões (upsert em lote).
  Future<void> upsertAll(List<QuestionDto> questions) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = questions.map((q) => q.toMap()).toList();
      await prefs.setString(_questionsKey, jsonEncode(jsonList));
    } catch (e) {
      // Silently fail
    }
  }

  /// Remove todas as questões do cache local.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_questionsKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Adiciona uma única questão ao cache.
  Future<void> add(QuestionDto question) async {
    final all = await listAll();
    all.add(question);
    await upsertAll(all);
  }

  /// Remove uma questão por ID.
  Future<void> removeById(String id) async {
    final all = await listAll();
    all.removeWhere((q) => q.id == id);
    await upsertAll(all);
  }

  /// Atualiza uma questão existente.
  Future<void> update(QuestionDto question) async {
    final all = await listAll();
    final index = all.indexWhere((q) => q.id == question.id);
    if (index != -1) {
      all[index] = question;
      await upsertAll(all);
    }
  }
}
