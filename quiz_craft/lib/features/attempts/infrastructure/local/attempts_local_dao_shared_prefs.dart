import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../dtos/attempt_dto.dart';

/// DAO local para attempts usando SharedPreferences.
/// Armazena tentativas de quiz em JSON no storage local.
class AttemptsLocalDaoSharedPrefs {
  static const String _attemptsKey = 'attempts_cache';

  /// Lista todas as tentativas armazenadas localmente.
  Future<List<AttemptDto>> listAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_attemptsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => AttemptDto.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Insere ou atualiza múltiplas tentativas (upsert em lote).
  Future<void> upsertAll(List<AttemptDto> attempts) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = attempts.map((a) => a.toMap()).toList();
      await prefs.setString(_attemptsKey, jsonEncode(jsonList));
    } catch (e) {
      // Silently fail
    }
  }

  /// Remove todas as tentativas do cache local.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_attemptsKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Adiciona uma única tentativa ao cache.
  Future<void> add(AttemptDto attempt) async {
    final all = await listAll();
    all.add(attempt);
    await upsertAll(all);
  }

  /// Remove uma tentativa por ID.
  Future<void> removeById(String id) async {
    final all = await listAll();
    all.removeWhere((a) => a.id == id);
    await upsertAll(all);
  }

  /// Atualiza uma tentativa existente.
  Future<void> update(AttemptDto attempt) async {
    final all = await listAll();
    final index = all.indexWhere((a) => a.id == attempt.id);
    if (index != -1) {
      all[index] = attempt;
      await upsertAll(all);
    }
  }

  /// Filtra tentativas por quizId.
  Future<List<AttemptDto>> listByQuizId(String quizId) async {
    final all = await listAll();
    return all.where((a) => a.quizId == quizId).toList();
  }

  /// Filtra tentativas por userId.
  Future<List<AttemptDto>> listByUserId(String userId) async {
    final all = await listAll();
    return all.where((a) => a.userId == userId).toList();
  }
}
