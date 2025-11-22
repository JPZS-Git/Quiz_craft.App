import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/question_entity.dart';
import '../dtos/question_dto.dart';
import '../local/questions_local_dao_shared_prefs.dart';

/// Repository para gerenciar questions com Supabase e cache local.
class QuestionSupabaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final QuestionsLocalDaoSharedPrefs _localDao;
  static const String _lastSyncKey = 'questions_last_sync';

  QuestionSupabaseRepository(this._localDao);

  /// Valida se uma string é um UUID válido.
  bool _isValidUUID(String? value) {
    if (value == null || value.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(value);
  }

  /// Busca questions do Supabase, opcionalmente filtrando por quiz_id ou última sincronização.
  Future<List<QuestionEntity>> fetchQuestions({
    String? quizId,
    DateTime? lastSync,
  }) async {
    try {
      dynamic query = _supabase
          .from('questions')
          .select('id, quiz_id, text, "order", created_at, updated_at');

      if (quizId != null && quizId.isNotEmpty) {
        query = query.eq('quiz_id', quizId);
      }

      if (lastSync != null) {
        query = query.gte('updated_at', lastSync.toIso8601String());
      }

      final response = await query.order('"order"', ascending: true);
      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) {
        // QuestionDto.fromMap espera 'answers' como array vazio já que não vem do Supabase
        final jsonWithAnswers = Map<String, dynamic>.from(json as Map<String, dynamic>);
        jsonWithAnswers['answers'] = []; // Array vazio pois answers são entidade separada
        
        final dto = QuestionDto.fromMap(jsonWithAnswers);
        return dto.toEntity();
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar questions do Supabase: $e');
      return [];
    }
  }

  /// Busca uma question específica por ID.
  Future<QuestionEntity?> fetchQuestionById(String id) async {
    try {
      final response = await _supabase
          .from('questions')
          .select('id, quiz_id, text, "order", created_at, updated_at')
          .eq('id', id)
          .single();

      final jsonWithAnswers = Map<String, dynamic>.from(response);
      jsonWithAnswers['answers'] = [];
      
      final dto = QuestionDto.fromMap(jsonWithAnswers);
      return dto.toEntity();
    } catch (e) {
      debugPrint('Erro ao buscar question $id: $e');
      // Fallback para cache local
      final cached = await getLocalCache();
      return cached.firstWhere((q) => q.id == id, orElse: () => throw Exception('Question não encontrada'));
    }
  }

  /// Obtém questions do cache local.
  Future<List<QuestionEntity>> getLocalCache() async {
    try {
      final dtos = await _localDao.listAll();
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      debugPrint('Erro ao ler cache local de questions: $e');
      return [];
    }
  }

  /// Salva questions no cache local.
  Future<void> saveLocalCache(List<QuestionEntity> questions) async {
    try {
      final dtos = questions.map((e) => QuestionDto.fromEntity(e)).toList();
      await _localDao.upsertAll(dtos);
    } catch (e) {
      debugPrint('Erro ao salvar cache local de questions: $e');
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
  Future<List<QuestionEntity>> syncIncremental() async {
    try {
      final lastSync = await getLastSync();
      final remoteQuestions = await fetchQuestions(lastSync: lastSync);
      final localQuestions = await getLocalCache();

      // Mescla: prefere dados remotos mais recentes
      final Map<String, QuestionEntity> merged = {};

      for (var local in localQuestions) {
        merged[local.id] = local;
      }

      for (var remote in remoteQuestions) {
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

  /// Cria uma nova question no Supabase e atualiza cache local.
  Future<QuestionEntity> createQuestion(QuestionEntity question) async {
    try {
      // Valida quiz_id (deve ser UUID válido)
      if (!_isValidUUID(question.quizId)) {
        throw Exception('quiz_id deve ser um UUID válido');
      }

      final dto = QuestionDto.fromEntity(question);
      final map = dto.toMap();

      // Remove id (Supabase gera UUID automaticamente)
      map.remove('id');
      // Remove answers (entidade separada no Supabase)
      map.remove('answers');

      final response = await _supabase
          .from('questions')
          .insert(map)
          .select('id, quiz_id, text, "order", created_at, updated_at')
          .single();

      final jsonWithAnswers = Map<String, dynamic>.from(response);
      jsonWithAnswers['answers'] = [];

      final createdDto = QuestionDto.fromMap(jsonWithAnswers);
      final createdEntity = createdDto.toEntity();

      // Atualiza cache local
      final cached = await getLocalCache();
      cached.add(createdEntity);
      await saveLocalCache(cached);

      return createdEntity;
    } catch (e) {
      debugPrint('Erro ao criar question no Supabase: $e');
      rethrow;
    }
  }

  /// Atualiza uma question existente no Supabase e no cache local.
  Future<QuestionEntity> updateQuestion(QuestionEntity question) async {
    try {
      // Detecta IDs numéricos (questions locais legadas)
      if (int.tryParse(question.id) != null) {
        debugPrint('Question com ID numérico (${question.id}), atualizando apenas cache local.');
        
        // Atualiza apenas o cache local
        final cached = await getLocalCache();
        final index = cached.indexWhere((q) => q.id == question.id);
        if (index != -1) {
          cached[index] = question;
          await saveLocalCache(cached);
        }
        return question;
      }

      // Valida quiz_id
      if (!_isValidUUID(question.quizId)) {
        throw Exception('quiz_id deve ser um UUID válido');
      }

      final dto = QuestionDto.fromEntity(question);
      final map = dto.toMap();

      // Remove campos que não devem ser atualizados
      map.remove('id');
      map.remove('created_at');
      map.remove('answers');

      final response = await _supabase
          .from('questions')
          .update(map)
          .eq('id', question.id)
          .select('id, quiz_id, text, "order", created_at, updated_at')
          .maybeSingle();

      if (response == null) {
        debugPrint('Question ${question.id} não encontrada no Supabase, atualizando apenas cache local.');
        
        // Fallback: atualiza apenas cache local
        final cached = await getLocalCache();
        final index = cached.indexWhere((q) => q.id == question.id);
        if (index != -1) {
          cached[index] = question;
          await saveLocalCache(cached);
        }
        return question;
      }

      final jsonWithAnswers = Map<String, dynamic>.from(response);
      jsonWithAnswers['answers'] = [];

      final updatedDto = QuestionDto.fromMap(jsonWithAnswers);
      final updatedEntity = updatedDto.toEntity();

      // Atualiza cache local
      final cached = await getLocalCache();
      final index = cached.indexWhere((q) => q.id == updatedEntity.id);
      if (index != -1) {
        cached[index] = updatedEntity;
      } else {
        cached.add(updatedEntity);
      }
      await saveLocalCache(cached);

      return updatedEntity;
    } catch (e) {
      debugPrint('Erro ao atualizar question no Supabase: $e');
      rethrow;
    }
  }

  /// Deleta uma question do Supabase e do cache local.
  Future<void> deleteQuestion(String id) async {
    try {
      // Detecta IDs numéricos (questions locais legadas)
      if (int.tryParse(id) != null) {
        debugPrint('Question com ID numérico ($id), deletando apenas do cache local.');
        
        // Remove apenas do cache local
        final cached = await getLocalCache();
        cached.removeWhere((q) => q.id == id);
        await saveLocalCache(cached);
        return;
      }

      await _supabase
          .from('questions')
          .delete()
          .eq('id', id);

      // Remove do cache local
      final cached = await getLocalCache();
      cached.removeWhere((q) => q.id == id);
      await saveLocalCache(cached);
    } catch (e) {
      debugPrint('Erro ao deletar question do Supabase: $e');
      rethrow;
    }
  }
}
