import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/answer_entity.dart';
import '../dtos/answer_dto.dart';
import '../local/answers_local_dao_shared_prefs.dart';

/// Repository para gerenciar answers com Supabase e cache local.
/// Inclui lógica especial para unique constraint de is_correct (apenas uma resposta correta por questão).
class AnswerSupabaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AnswersLocalDaoSharedPrefs _localDao;
  static const String _lastSyncKey = 'answers_last_sync';

  AnswerSupabaseRepository(this._localDao);

  /// Valida se uma string é um UUID válido.
  bool _isValidUUID(String? value) {
    if (value == null || value.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(value);
  }

  /// Busca answers do Supabase, opcionalmente filtrando por question_id ou última sincronização.
  Future<List<AnswerEntity>> fetchAnswers({
    String? questionId,
    DateTime? lastSync,
  }) async {
    try {
      dynamic query = _supabase
          .from('answers')
          .select('id, question_id, text, is_correct, created_at, updated_at');

      if (questionId != null && questionId.isNotEmpty) {
        query = query.eq('question_id', questionId);
      }

      if (lastSync != null) {
        query = query.gte('updated_at', lastSync.toIso8601String());
      }

      final response = await query.order('created_at', ascending: true);
      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) {
        final dto = AnswerDto.fromMap(json as Map<String, dynamic>);
        return dto.toEntity();
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar answers do Supabase: $e');
      return [];
    }
  }

  /// Busca uma answer específica por ID.
  Future<AnswerEntity?> fetchAnswerById(String id) async {
    try {
      final response = await _supabase
          .from('answers')
          .select('id, question_id, text, is_correct, created_at, updated_at')
          .eq('id', id)
          .single();

      final dto = AnswerDto.fromMap(response);
      return dto.toEntity();
    } catch (e) {
      debugPrint('Erro ao buscar answer $id: $e');
      // Fallback para cache local
      final cached = await getLocalCache();
      return cached.firstWhere((a) => a.id == id, orElse: () => throw Exception('Answer não encontrada'));
    }
  }

  /// Obtém answers do cache local.
  Future<List<AnswerEntity>> getLocalCache() async {
    try {
      final dtos = await _localDao.listAll();
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      debugPrint('Erro ao ler cache local de answers: $e');
      return [];
    }
  }

  /// Salva answers no cache local.
  Future<void> saveLocalCache(List<AnswerEntity> answers) async {
    try {
      final dtos = answers.map((e) => AnswerDto.fromEntity(e)).toList();
      await _localDao.upsertAll(dtos);
    } catch (e) {
      debugPrint('Erro ao salvar cache local de answers: $e');
    }
  }

  /// Obtém a data da última sincronização.
  Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastSyncStr = prefs.getString(_lastSyncKey);
      return lastSyncStr != null ? DateTime.tryParse(lastSyncStr) : null;
    } catch (e) {
      debugPrint('Erro ao obter última sincronização: $e');
      return null;
    }
  }

  /// Salva a data da última sincronização.
  Future<void> saveLastSync(DateTime sync) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, sync.toIso8601String());
    } catch (e) {
      debugPrint('Erro ao salvar última sincronização: $e');
    }
  }

  /// Sincronização incremental: mescla dados do Supabase com cache local.
  Future<List<AnswerEntity>> syncIncremental() async {
    try {
      final lastSync = await getLastSync();
      final remoteAnswers = await fetchAnswers(lastSync: lastSync);
      final localAnswers = await getLocalCache();

      // Mescla: prefere dados remotos mais recentes
      final Map<String, AnswerEntity> merged = {};

      for (var local in localAnswers) {
        merged[local.id] = local;
      }

      for (var remote in remoteAnswers) {
        final existing = merged[remote.id];
        if (existing == null || remote.updatedAt.isAfter(existing.updatedAt)) {
          merged[remote.id] = remote;
        }
      }

      final result = merged.values.toList();
      await saveLocalCache(result);
      await saveLastSync(DateTime.now());

      return result;
    } catch (e) {
      debugPrint('Erro na sincronização incremental: $e');
      return await getLocalCache();
    }
  }

  /// Cria uma nova answer no Supabase e atualiza cache local.
  Future<AnswerEntity> createAnswer(AnswerEntity answer) async {
    try {
      // Valida question_id (deve ser UUID válido)
      if (!_isValidUUID(answer.questionId)) {
        throw Exception('question_id deve ser um UUID válido');
      }

      final dto = AnswerDto.fromEntity(answer);
      final map = dto.toMap();

      // Remove id (Supabase gera UUID automaticamente)
      map.remove('id');

      final response = await _supabase
          .from('answers')
          .insert(map)
          .select('id, question_id, text, is_correct, created_at, updated_at')
          .single();

      final createdDto = AnswerDto.fromMap(response);
      final createdEntity = createdDto.toEntity();

      // Atualiza cache local
      final cached = await getLocalCache();
      cached.add(createdEntity);
      await saveLocalCache(cached);

      return createdEntity;
    } catch (e) {
      debugPrint('Erro ao criar answer no Supabase: $e');
      rethrow;
    }
  }

  /// Atualiza uma answer existente no Supabase e no cache local.
  Future<AnswerEntity> updateAnswer(AnswerEntity answer) async {
    try {
      // Detecta IDs numéricos (answers locais legadas)
      if (int.tryParse(answer.id) != null) {
        debugPrint('Answer com ID numérico (${answer.id}), atualizando apenas cache local.');
        
        // Atualiza apenas o cache local
        final cached = await getLocalCache();
        final index = cached.indexWhere((a) => a.id == answer.id);
        if (index != -1) {
          cached[index] = answer;
          await saveLocalCache(cached);
        }
        return answer;
      }

      // Valida question_id
      if (!_isValidUUID(answer.questionId)) {
        throw Exception('question_id deve ser um UUID válido');
      }

      final dto = AnswerDto.fromEntity(answer);
      final map = dto.toMap();

      // Remove campos que não devem ser atualizados
      map.remove('id');
      map.remove('created_at');

      final response = await _supabase
          .from('answers')
          .update(map)
          .eq('id', answer.id)
          .select('id, question_id, text, is_correct, created_at, updated_at')
          .maybeSingle();

      if (response == null) {
        debugPrint('Answer ${answer.id} não encontrada no Supabase, atualizando apenas cache local.');
        
        // Fallback: atualiza apenas cache local
        final cached = await getLocalCache();
        final index = cached.indexWhere((a) => a.id == answer.id);
        if (index != -1) {
          cached[index] = answer;
          await saveLocalCache(cached);
        }
        return answer;
      }

      final updatedDto = AnswerDto.fromMap(response);
      final updatedEntity = updatedDto.toEntity();

      // Atualiza cache local
      final cached = await getLocalCache();
      final index = cached.indexWhere((a) => a.id == updatedEntity.id);
      if (index != -1) {
        cached[index] = updatedEntity;
      } else {
        cached.add(updatedEntity);
      }
      await saveLocalCache(cached);

      return updatedEntity;
    } catch (e) {
      debugPrint('Erro ao atualizar answer no Supabase: $e');
      rethrow;
    }
  }

  /// Marca uma answer como correta e automaticamente desmarca outras respostas da mesma questão.
  /// Este método lida com a constraint UNIQUE de is_correct por question_id.
  Future<AnswerEntity> markAsCorrect(String answerId) async {
    try {
      // Busca a answer atual
      final answer = await fetchAnswerById(answerId);
      if (answer == null) {
        throw Exception('Answer $answerId não encontrada');
      }

      // Se já está marcada como correta, não faz nada
      if (answer.isCorrect) {
        return answer;
      }

      // Atualiza para marcar como correta
      // O trigger validate_correct_answer() no Supabase automaticamente desmarca outras
      final updatedAnswer = AnswerEntity(
        id: answer.id,
        questionId: answer.questionId,
        text: answer.text,
        isCorrect: true,
        createdAt: answer.createdAt,
        updatedAt: DateTime.now(),
      );

      return await updateAnswer(updatedAnswer);
    } catch (e) {
      debugPrint('Erro ao marcar answer como correta: $e');
      rethrow;
    }
  }

  /// Deleta uma answer do Supabase e do cache local.
  Future<void> deleteAnswer(String id) async {
    try {
      // Detecta IDs numéricos (answers locais legadas)
      if (int.tryParse(id) != null) {
        debugPrint('Answer com ID numérico ($id), deletando apenas do cache local.');
        
        // Remove apenas do cache local
        final cached = await getLocalCache();
        cached.removeWhere((a) => a.id == id);
        await saveLocalCache(cached);
        return;
      }

      await _supabase
          .from('answers')
          .delete()
          .eq('id', id);

      // Remove do cache local
      final cached = await getLocalCache();
      cached.removeWhere((a) => a.id == id);
      await saveLocalCache(cached);
    } catch (e) {
      debugPrint('Erro ao deletar answer do Supabase: $e');
      rethrow;
    }
  }
}
