import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/attempt_entity.dart';
import '../dtos/attempt_dto.dart';
import '../local/attempts_local_dao_shared_prefs.dart';

/// Repository para gerenciar attempts com Supabase e cache local.
/// Inclui tratamento especial para JSONB answers_data e 5 triggers automáticos.
class AttemptSupabaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AttemptsLocalDaoSharedPrefs _localDao;
  static const String _lastSyncKey = 'attempts_last_sync';

  AttemptSupabaseRepository(this._localDao);

  /// Valida se uma string é um UUID válido.
  bool _isValidUUID(String? value) {
    if (value == null || value.isEmpty) return false;
    final uuidRegex = RegExp(
      r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
      caseSensitive: false,
    );
    return uuidRegex.hasMatch(value);
  }

  /// Busca attempts do Supabase, opcionalmente filtrando por quiz_id, user_id ou última sincronização.
  Future<List<AttemptEntity>> fetchAttempts({
    String? quizId,
    String? userId,
    DateTime? lastSync,
  }) async {
    try {
      dynamic query = _supabase
          .from('attempts')
          .select('id, quiz_id, user_id, status, answers_data, correct_count, total_count, score_percentage, duration_seconds, started_at, finished_at, created_at, updated_at');

      if (quizId != null && quizId.isNotEmpty) {
        query = query.eq('quiz_id', quizId);
      }

      if (userId != null && userId.isNotEmpty) {
        query = query.eq('user_id', userId);
      }

      if (lastSync != null) {
        query = query.gte('updated_at', lastSync.toIso8601String());
      }

      final response = await query.order('started_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      return data.map((json) {
        final dto = AttemptDto.fromMap(json as Map<String, dynamic>);
        return dto.toEntity();
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar attempts do Supabase: $e');
      return [];
    }
  }

  /// Busca um attempt específico por ID.
  Future<AttemptEntity?> fetchAttemptById(String id) async {
    try {
      final response = await _supabase
          .from('attempts')
          .select('id, quiz_id, user_id, status, answers_data, correct_count, total_count, score_percentage, duration_seconds, started_at, finished_at, created_at, updated_at')
          .eq('id', id)
          .single();

      final dto = AttemptDto.fromMap(response);
      return dto.toEntity();
    } catch (e) {
      debugPrint('Erro ao buscar attempt $id: $e');
      // Fallback para cache local
      final cached = await getLocalCache();
      return cached.firstWhere((a) => a.id == id, orElse: () => throw Exception('Attempt não encontrado'));
    }
  }

  /// Obtém attempts do cache local.
  Future<List<AttemptEntity>> getLocalCache() async {
    try {
      final dtos = await _localDao.listAll();
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      debugPrint('Erro ao ler cache local de attempts: $e');
      return [];
    }
  }

  /// Salva attempts no cache local.
  Future<void> saveLocalCache(List<AttemptEntity> attempts) async {
    try {
      final dtos = attempts.map((e) => AttemptDto.fromEntity(e)).toList();
      await _localDao.upsertAll(dtos);
    } catch (e) {
      debugPrint('Erro ao salvar cache local de attempts: $e');
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
  Future<List<AttemptEntity>> syncIncremental() async {
    try {
      final lastSync = await getLastSync();
      final remoteAttempts = await fetchAttempts(lastSync: lastSync);
      final localAttempts = await getLocalCache();

      // Mescla: prefere dados remotos mais recentes
      final Map<String, AttemptEntity> merged = {};

      for (var local in localAttempts) {
        merged[local.id] = local;
      }

      for (var remote in remoteAttempts) {
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

  /// Cria um novo attempt no Supabase e atualiza cache local.
  Future<AttemptEntity> createAttempt(AttemptEntity attempt) async {
    try {
      // Valida quiz_id (deve ser UUID válido)
      if (!_isValidUUID(attempt.quizId)) {
        throw Exception('quiz_id deve ser um UUID válido');
      }

      final dto = AttemptDto.fromEntity(attempt);
      final map = dto.toMap();

      // Remove id (Supabase gera UUID automaticamente)
      map.remove('id');

      final response = await _supabase
          .from('attempts')
          .insert(map)
          .select('id, quiz_id, user_id, status, answers_data, correct_count, total_count, score_percentage, duration_seconds, started_at, finished_at, created_at, updated_at')
          .single();

      final createdDto = AttemptDto.fromMap(response);
      final createdEntity = createdDto.toEntity();

      // Atualiza cache local
      final cached = await getLocalCache();
      cached.add(createdEntity);
      await saveLocalCache(cached);

      return createdEntity;
    } catch (e) {
      debugPrint('Erro ao criar attempt no Supabase: $e');
      rethrow;
    }
  }

  /// Atualiza um attempt existente no Supabase e no cache local.
  /// Triggers no Supabase calcularão automaticamente: percentage, duration, attempts_count, avg_score.
  Future<AttemptEntity> updateAttempt(AttemptEntity attempt) async {
    try {
      // Detecta IDs numéricos (attempts locais legados)
      if (int.tryParse(attempt.id) != null) {
        debugPrint('Attempt com ID numérico (${attempt.id}), atualizando apenas cache local.');
        
        // Atualiza apenas o cache local
        final cached = await getLocalCache();
        final index = cached.indexWhere((a) => a.id == attempt.id);
        if (index != -1) {
          cached[index] = attempt;
          await saveLocalCache(cached);
        }
        return attempt;
      }

      // Valida quiz_id
      if (!_isValidUUID(attempt.quizId)) {
        throw Exception('quiz_id deve ser um UUID válido');
      }

      final dto = AttemptDto.fromEntity(attempt);
      final map = dto.toMap();

      // Remove campos que não devem ser atualizados
      map.remove('id');
      map.remove('created_at');
      // Não remove score_percentage, duration_seconds - triggers calcularão se necessário

      final response = await _supabase
          .from('attempts')
          .update(map)
          .eq('id', attempt.id)
          .select('id, quiz_id, user_id, status, answers_data, correct_count, total_count, score_percentage, duration_seconds, started_at, finished_at, created_at, updated_at')
          .maybeSingle();

      if (response == null) {
        debugPrint('Attempt ${attempt.id} não encontrado no Supabase, atualizando apenas cache local.');
        
        // Fallback: atualiza apenas cache local
        final cached = await getLocalCache();
        final index = cached.indexWhere((a) => a.id == attempt.id);
        if (index != -1) {
          cached[index] = attempt;
          await saveLocalCache(cached);
        }
        return attempt;
      }

      final updatedDto = AttemptDto.fromMap(response);
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
      debugPrint('Erro ao atualizar attempt no Supabase: $e');
      rethrow;
    }
  }

  /// Marca um attempt como completed (automaticamente calcula duration e percentage via triggers).
  Future<AttemptEntity> completeAttempt(String attemptId) async {
    try {
      final attempt = await fetchAttemptById(attemptId);
      if (attempt == null) {
        throw Exception('Attempt $attemptId não encontrado');
      }

      if (attempt.status == 'completed') {
        return attempt; // Já completo
      }

      final completedAttempt = AttemptEntity(
        id: attempt.id,
        quizId: attempt.quizId,
        userId: attempt.userId,
        status: 'completed',
        answersData: attempt.answersData,
        correctCount: attempt.correctCount,
        totalCount: attempt.totalCount,
        scorePercentage: attempt.scorePercentage,
        durationSeconds: attempt.durationSeconds,
        startedAt: attempt.startedAt,
        finishedAt: DateTime.now(),
        createdAt: attempt.createdAt,
        updatedAt: DateTime.now(),
      );

      return await updateAttempt(completedAttempt);
    } catch (e) {
      debugPrint('Erro ao completar attempt: $e');
      rethrow;
    }
  }

  /// Marca um attempt como abandoned.
  Future<AttemptEntity> abandonAttempt(String attemptId) async {
    try {
      final attempt = await fetchAttemptById(attemptId);
      if (attempt == null) {
        throw Exception('Attempt $attemptId não encontrado');
      }

      final abandonedAttempt = AttemptEntity(
        id: attempt.id,
        quizId: attempt.quizId,
        userId: attempt.userId,
        status: 'abandoned',
        answersData: attempt.answersData,
        correctCount: attempt.correctCount,
        totalCount: attempt.totalCount,
        scorePercentage: attempt.scorePercentage,
        durationSeconds: attempt.durationSeconds,
        startedAt: attempt.startedAt,
        finishedAt: attempt.finishedAt,
        createdAt: attempt.createdAt,
        updatedAt: DateTime.now(),
      );

      return await updateAttempt(abandonedAttempt);
    } catch (e) {
      debugPrint('Erro ao abandonar attempt: $e');
      rethrow;
    }
  }

  /// Deleta um attempt do Supabase e do cache local.
  Future<void> deleteAttempt(String id) async {
    try {
      // Detecta IDs numéricos (attempts locais legados)
      if (int.tryParse(id) != null) {
        debugPrint('Attempt com ID numérico ($id), deletando apenas do cache local.');
        
        // Remove apenas do cache local
        final cached = await getLocalCache();
        cached.removeWhere((a) => a.id == id);
        await saveLocalCache(cached);
        return;
      }

      await _supabase
          .from('attempts')
          .delete()
          .eq('id', id);

      // Remove do cache local
      final cached = await getLocalCache();
      cached.removeWhere((a) => a.id == id);
      await saveLocalCache(cached);
    } catch (e) {
      debugPrint('Erro ao deletar attempt do Supabase: $e');
      rethrow;
    }
  }
}
