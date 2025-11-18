import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../dtos/answer_dto.dart';

/// DAO local para answers usando SharedPreferences.
/// Armazena respostas em JSON no storage local.
class AnswersLocalDaoSharedPrefs {
  static const String _answersKey = 'answers_cache';

  /// Lista todas as respostas armazenadas localmente.
  Future<List<AnswerDto>> listAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_answersKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => AnswerDto.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Insere ou atualiza múltiplas respostas (upsert em lote).
  Future<void> upsertAll(List<AnswerDto> answers) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = answers.map((a) => a.toMap()).toList();
      await prefs.setString(_answersKey, jsonEncode(jsonList));
    } catch (e) {
      // Silently fail
    }
  }

  /// Remove todas as respostas do cache local.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_answersKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Adiciona uma única resposta ao cache.
  Future<void> add(AnswerDto answer) async {
    final all = await listAll();
    all.add(answer);
    await upsertAll(all);
  }

  /// Remove uma resposta por ID.
  Future<void> removeById(String id) async {
    final all = await listAll();
    all.removeWhere((a) => a.id == id);
    await upsertAll(all);
  }

  /// Atualiza uma resposta existente.
  Future<void> update(AnswerDto answer) async {
    final all = await listAll();
    final index = all.indexWhere((a) => a.id == answer.id);
    if (index != -1) {
      all[index] = answer;
      await upsertAll(all);
    }
  }

  /// Filtra respostas por questionId (se o DTO incluir esse campo futuramente).
  Future<List<AnswerDto>> listByQuestionId(String questionId) async {
    // Nota: AnswerDto atual não tem questionId
    // Esta função está preparada para quando o campo for adicionado
    final all = await listAll();
    // return all.where((a) => a.questionId == questionId).toList();
    return all; // Retorna todas por enquanto
  }

  /// Filtra apenas respostas corretas.
  Future<List<AnswerDto>> listCorrectAnswers() async {
    final all = await listAll();
    return all.where((a) => a.isCorrect).toList();
  }

  /// Filtra apenas respostas incorretas.
  Future<List<AnswerDto>> listIncorrectAnswers() async {
    final all = await listAll();
    return all.where((a) => !a.isCorrect).toList();
  }
}
