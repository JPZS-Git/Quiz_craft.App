import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../../domain/entities/quiz_entity.dart';
import '../dtos/quiz_dto.dart';
import '../local/quizzes_local_dao_shared_prefs.dart';

/// Repository para gerenciar quizzes com Supabase e cache local.
class QuizSupabaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final QuizzesLocalDaoSharedPrefs _localDao;
  static const String _lastSyncKey = 'quizzes_last_sync';

  QuizSupabaseRepository(this._localDao);

  /// Busca quizzes do Supabase, opcionalmente filtrando por última sincronização.
  Future<List<QuizEntity>> fetchQuizzes({
    DateTime? lastSync,
    bool onlyPublished = false,
  }) async {
    try {
      dynamic query = _supabase
          .from('quizzes')
          .select('id, title, description, author_id, topics, is_published, created_at, updated_at, questions_count, attempts_count, avg_score_percentage');

      if (lastSync != null) {
        query = query.gte('updated_at', lastSync.toIso8601String());
      }

      if (onlyPublished) {
        query = query.eq('is_published', true);
      }

      final response = await query.order('created_at', ascending: false);
      final List<dynamic> data = response as List<dynamic>;

      debugPrint('📊 Fetched ${data.length} quizzes from Supabase');
      
      return data.map((json) {
        debugPrint('  Quiz: ${json['title']} - questions_count: ${json['questions_count']}');
        
        // QuizDto.fromMap espera 'questions' como array vazio já que não vem do Supabase
        final jsonWithQuestions = Map<String, dynamic>.from(json as Map<String, dynamic>);
        jsonWithQuestions['questions'] = []; // Array vazio pois questions são entidade separada
        
        final dto = QuizDto.fromMap(jsonWithQuestions);
        return dto.toEntity();
      }).toList();
    } catch (e) {
      debugPrint('Erro ao buscar quizzes do Supabase: $e');
      return [];
    }
  }

  /// Busca um quiz específico por ID.
  Future<QuizEntity?> fetchQuizById(String id) async {
    try {
      final response = await _supabase
          .from('quizzes')
          .select('id, title, description, author_id, topics, is_published, created_at, updated_at, questions_count, attempts_count, avg_score_percentage')
          .eq('id', id)
          .single();

      final jsonWithQuestions = Map<String, dynamic>.from(response);
      jsonWithQuestions['questions'] = [];
      
      final dto = QuizDto.fromMap(jsonWithQuestions);
      return dto.toEntity();
    } catch (e) {
      debugPrint('Erro ao buscar quiz $id: $e');
      // Fallback para cache local
      final cached = await getLocalCache();
      return cached.firstWhere((q) => q.id == id, orElse: () => throw Exception('Quiz não encontrado'));
    }
  }

  /// Obtém quizzes do cache local.
  Future<List<QuizEntity>> getLocalCache() async {
    try {
      final dtos = await _localDao.listAll();
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      debugPrint('Erro ao ler cache local de quizzes: $e');
      return [];
    }
  }

  /// Salva quizzes no cache local.
  Future<void> saveLocalCache(List<QuizEntity> quizzes) async {
    try {
      final dtos = quizzes.map((e) => QuizDto.fromEntity(e)).toList();
      await _localDao.upsertAll(dtos);
    } catch (e) {
      debugPrint('Erro ao salvar cache local de quizzes: $e');
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

  /// Define a data da última sincronização.
  Future<void> setLastSync(DateTime dateTime) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, dateTime.toIso8601String());
    } catch (e) {
      debugPrint('Erro ao salvar última sincronização: $e');
    }
  }

  /// Sincronização incremental: busca apenas quizzes atualizados desde a última sincronização.
  Future<List<QuizEntity>> syncIncremental() async {
    try {
      final lastSync = await getLastSync();
      final remoteQuizzes = await fetchQuizzes(lastSync: lastSync);
      final localQuizzes = await getLocalCache();

      // Merge: combina remote e local, preferindo mais recente por updated_at
      final Map<String, QuizEntity> merged = {};

      for (final quiz in localQuizzes) {
        merged[quiz.id] = quiz;
      }

      for (final quiz in remoteQuizzes) {
        if (!merged.containsKey(quiz.id) ||
            quiz.updatedAt.isAfter(merged[quiz.id]!.updatedAt)) {
          merged[quiz.id] = quiz;
        }
      }

      final result = merged.values.toList();
      await saveLocalCache(result);
      await setLastSync(DateTime.now());

      return result;
    } catch (e) {
      debugPrint('Erro na sincronização incremental de quizzes: $e');
      return await getLocalCache();
    }
  }

  /// Cria um novo quiz no Supabase.
  Future<QuizEntity> createQuiz(QuizEntity entity) async {
    try {
      final dto = QuizDto.fromEntity(entity);
      final dataToInsert = dto.toMap();
      // Remove id e questions - Supabase gera UUID automaticamente
      dataToInsert.remove('id');
      dataToInsert.remove('questions');
      
      // Valida author_id: deve ser UUID válido ou null
      if (dataToInsert['author_id'] != null) {
        final authorId = dataToInsert['author_id'] as String?;
        // Se não for um UUID válido (formato: 8-4-4-4-12 chars), seta como null
        final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
        if (authorId == null || authorId.isEmpty || !uuidPattern.hasMatch(authorId)) {
          dataToInsert['author_id'] = null;
        }
      }
      
      final response = await _supabase
          .from('quizzes')
          .insert(dataToInsert)
          .select()
          .single();

      final jsonWithQuestions = Map<String, dynamic>.from(response);
      jsonWithQuestions['questions'] = [];
      
      final createdDto = QuizDto.fromMap(jsonWithQuestions);
      final createdEntity = createdDto.toEntity();

      // Atualiza cache local
      final cached = await getLocalCache();
      cached.add(createdEntity);
      await saveLocalCache(cached);

      return createdEntity;
    } catch (e) {
      debugPrint('Erro ao criar quiz: $e');
      rethrow;
    }
  }

  /// Atualiza um quiz existente no Supabase.
  Future<QuizEntity> updateQuiz(QuizEntity entity) async {
    try {
      // Verifica se o ID é numérico (formato antigo) - não existe no Supabase
      final isNumericId = int.tryParse(entity.id) != null;
      
      if (isNumericId) {
        debugPrint('Quiz ${entity.id} tem ID numérico (criado localmente), atualizando apenas cache');
        // Atualiza apenas cache local - quiz ainda não foi sincronizado com Supabase
        final cached = await getLocalCache();
        final index = cached.indexWhere((q) => q.id == entity.id);
        if (index != -1) {
          cached[index] = entity;
          await saveLocalCache(cached);
        }
        return entity;
      }
      
      final dto = QuizDto.fromEntity(entity);
      final dataToUpdate = dto.toMap();
      // Remove id e questions do update
      dataToUpdate.remove('id');
      dataToUpdate.remove('questions');
      
      // Valida author_id: deve ser UUID válido ou null
      if (dataToUpdate['author_id'] != null) {
        final authorId = dataToUpdate['author_id'] as String?;
        final uuidPattern = RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$', caseSensitive: false);
        if (authorId == null || authorId.isEmpty || !uuidPattern.hasMatch(authorId)) {
          dataToUpdate['author_id'] = null;
        }
      }
      
      final response = await _supabase
          .from('quizzes')
          .update(dataToUpdate)
          .eq('id', entity.id)
          .select()
          .maybeSingle();

      if (response == null) {
        debugPrint('Quiz ${entity.id} não encontrado no Supabase, atualizando apenas cache local');
        // Atualiza apenas cache local
        final cached = await getLocalCache();
        final index = cached.indexWhere((q) => q.id == entity.id);
        if (index != -1) {
          cached[index] = entity;
          await saveLocalCache(cached);
        }
        return entity;
      }

      final jsonWithQuestions = Map<String, dynamic>.from(response);
      jsonWithQuestions['questions'] = [];
      
      final updatedDto = QuizDto.fromMap(jsonWithQuestions);
      final updatedEntity = updatedDto.toEntity();

      // Atualiza cache local
      final cached = await getLocalCache();
      final index = cached.indexWhere((q) => q.id == entity.id);
      if (index != -1) {
        cached[index] = updatedEntity;
        await saveLocalCache(cached);
      }

      return updatedEntity;
    } catch (e) {
      debugPrint('Erro ao atualizar quiz: $e');
      rethrow;
    }
  }

  /// Remove um quiz do Supabase.
  Future<void> deleteQuiz(String id) async {
    try {
      // Verifica se o ID é numérico (formato antigo) - não existe no Supabase
      final isNumericId = int.tryParse(id) != null;
      
      if (!isNumericId) {
        // Só tenta deletar do Supabase se for UUID válido
        await _supabase.from('quizzes').delete().eq('id', id);
      } else {
        debugPrint('Quiz $id tem ID numérico, removendo apenas do cache local');
      }

      // Remove do cache local em ambos os casos
      final cached = await getLocalCache();
      cached.removeWhere((q) => q.id == id);
      await saveLocalCache(cached);
    } catch (e) {
      debugPrint('Erro ao deletar quiz: $e');
      rethrow;
    }
  }

  /// Incrementa o contador de tentativas de um quiz (via trigger no Supabase).
  Future<void> incrementAttemptsCount(String quizId) async {
    try {
      // O trigger handle_attempts_insert já incrementa automaticamente
      // Este método existe para casos onde precisamos forçar atualização
      await _supabase.rpc('increment_quiz_attempts', params: {'quiz_id': quizId});
    } catch (e) {
      debugPrint('Erro ao incrementar tentativas: $e');
    }
  }

  /// Decrementa o contador de tentativas de um quiz.
  Future<void> decrementAttemptsCount(String quizId) async {
    try {
      await _supabase.rpc('decrement_quiz_attempts', params: {'quiz_id': quizId});
    } catch (e) {
      debugPrint('Erro ao decrementar tentativas: $e');
    }
  }
}
