import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../dtos/author_dto.dart';

/// DAO local para authors usando SharedPreferences.
/// Armazena autores em JSON no storage local.
class AuthorsLocalDaoSharedPrefs {
  static const String _authorsKey = 'authors_cache';

  /// Lista todos os autores armazenados localmente.
  Future<List<AuthorDto>> listAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_authorsKey);
      
      if (jsonString == null || jsonString.isEmpty) {
        return [];
      }

      final List<dynamic> jsonList = jsonDecode(jsonString);
      return jsonList
          .map((json) => AuthorDto.fromMap(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }

  /// Insere ou atualiza múltiplos autores (upsert em lote).
  Future<void> upsertAll(List<AuthorDto> authors) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = authors.map((a) => a.toMap()).toList();
      await prefs.setString(_authorsKey, jsonEncode(jsonList));
    } catch (e) {
      // Silently fail
    }
  }

  /// Remove todos os autores do cache local.
  Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_authorsKey);
    } catch (e) {
      // Silently fail
    }
  }

  /// Adiciona um único autor ao cache.
  Future<void> add(AuthorDto author) async {
    final all = await listAll();
    all.add(author);
    await upsertAll(all);
  }

  /// Remove um autor por ID.
  Future<void> removeById(String id) async {
    final all = await listAll();
    all.removeWhere((a) => a.id == id);
    await upsertAll(all);
  }

  /// Atualiza um autor existente.
  Future<void> update(AuthorDto author) async {
    final all = await listAll();
    final index = all.indexWhere((a) => a.id == author.id);
    if (index != -1) {
      all[index] = author;
      await upsertAll(all);
    }
  }

  /// Filtra apenas autores ativos.
  Future<List<AuthorDto>> listActiveAuthors() async {
    final all = await listAll();
    return all.where((a) => a.isActive).toList();
  }

  /// Filtra apenas autores inativos.
  Future<List<AuthorDto>> listInactiveAuthors() async {
    final all = await listAll();
    return all.where((a) => !a.isActive).toList();
  }

  /// Filtra autores por tópico.
  Future<List<AuthorDto>> listByTopic(String topic) async {
    final all = await listAll();
    return all.where((a) => a.topics.contains(topic)).toList();
  }

  /// Filtra autores com avaliação mínima.
  Future<List<AuthorDto>> listByMinRating(double minRating) async {
    final all = await listAll();
    return all.where((a) => a.rating >= minRating).toList();
  }
}
