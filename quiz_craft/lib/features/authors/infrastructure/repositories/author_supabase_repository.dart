import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../domain/entities/author_entity.dart';
import '../dtos/author_dto.dart';
import '../local/authors_local_dao_shared_prefs.dart';

/// Repository offline-first para Authors com Supabase + cache local
class AuthorSupabaseRepository {
  final SupabaseClient _supabase = Supabase.instance.client;
  final AuthorsLocalDaoSharedPrefs _localDao;
  
  static const String _tableName = 'authors';
  static const String _lastSyncKey = 'authors_last_sync';

  AuthorSupabaseRepository(this._localDao);

  // ============================================
  // BUSCAR DADOS DO SUPABASE
  // ============================================

  /// Busca todos os autores do Supabase (ou incrementalmente se lastSync fornecido)
  Future<List<AuthorEntity>> fetchAuthors({
    DateTime? lastSync,
    bool onlyActive = false,
  }) async {
    try {
      var query = _supabase.from(_tableName).select();

      // Filtro incremental por updated_at
      if (lastSync != null) {
        query = query.gte('updated_at', lastSync.toIso8601String());
      }

      // Filtro por status ativo
      if (onlyActive) {
        query = query.eq('is_active', true);
      }

      // Ordenação padrão: rating DESC, name ASC
      final response = await query.order('rating', ascending: false).order('name', ascending: true);
      
      return (response as List).map((json) => AuthorDto.fromMap(json).toEntity()).toList();
    } catch (e) {
      throw Exception('Erro ao buscar authors do Supabase: $e');
    }
  }

  /// Busca um autor específico por ID
  Future<AuthorEntity?> fetchAuthorById(String id) async {
    try {
      final response = await _supabase
          .from(_tableName)
          .select()
          .eq('id', id)
          .maybeSingle();

      if (response == null) return null;

      return AuthorDto.fromMap(response).toEntity();
    } catch (e) {
      throw Exception('Erro ao buscar author $id: $e');
    }
  }

  // ============================================
  // CACHE LOCAL
  // ============================================

  /// Retorna autores do cache local
  Future<List<AuthorEntity>> getLocalCache() async {
    try {
      final dtos = await _localDao.listAll();
      return dtos.map((dto) => dto.toEntity()).toList();
    } catch (e) {
      throw Exception('Erro ao ler cache local de authors: $e');
    }
  }

  /// Salva autores no cache local
  Future<void> saveLocalCache(List<AuthorEntity> authors) async {
    try {
      final dtos = authors.map((e) => AuthorDto.fromEntity(e)).toList();
      await _localDao.upsertAll(dtos);
    } catch (e) {
      throw Exception('Erro ao salvar cache local de authors: $e');
    }
  }

  /// Lê timestamp do último sync
  Future<DateTime?> getLastSync() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = prefs.getString(_lastSyncKey);
      if (timestamp == null) return null;
      return DateTime.tryParse(timestamp);
    } catch (e) {
      return null;
    }
  }

  /// Salva timestamp do último sync
  Future<void> saveLastSync(DateTime timestamp) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_lastSyncKey, timestamp.toIso8601String());
    } catch (e) {
      throw Exception('Erro ao salvar lastSync: $e');
    }
  }

  // ============================================
  // SINCRONIZAÇÃO INCREMENTAL
  // ============================================

  /// Sincroniza authors: busca atualizações do Supabase e mescla com cache local
  Future<List<AuthorEntity>> syncIncremental({bool onlyActive = false}) async {
    try {
      // 1. Ler lastSync
      final lastSync = await getLastSync();

      // 2. Buscar atualizações do Supabase
      final updatedAuthors = await fetchAuthors(
        lastSync: lastSync,
        onlyActive: onlyActive,
      );

      // 3. Se não há atualizações, retorna cache
      if (updatedAuthors.isEmpty && lastSync != null) {
        return await getLocalCache();
      }

      // 4. Mesclar com cache local
      final cachedAuthors = await getLocalCache();
      final mergedMap = <String, AuthorEntity>{};

      // Adiciona cache existente
      for (final author in cachedAuthors) {
        mergedMap[author.id] = author;
      }

      // Sobrescreve com dados atualizados
      for (final author in updatedAuthors) {
        mergedMap[author.id] = author;
      }

      // 5. Ordenar por rating DESC
      final merged = mergedMap.values.toList()
        ..sort((a, b) {
          final ratingCmp = b.rating.compareTo(a.rating);
          if (ratingCmp != 0) return ratingCmp;
          return a.name.compareTo(b.name);
        });

      // 6. Salvar cache atualizado
      await saveLocalCache(merged);

      // 7. Atualizar lastSync
      await saveLastSync(DateTime.now());

      return merged;
    } catch (e) {
      // Se falhar sync, retorna cache local (offline-first)
      try {
        return await getLocalCache();
      } catch (_) {
        rethrow;
      }
    }
  }

  // ============================================
  // CRUD NO SUPABASE
  // ============================================

  /// Cria novo autor no Supabase
  Future<AuthorEntity> createAuthor(AuthorEntity author) async {
    try {
      final dto = AuthorDto.fromEntity(author);
      final response = await _supabase
          .from(_tableName)
          .insert(dto.toMap())
          .select()
          .single();

      final created = AuthorDto.fromMap(response).toEntity();

      // Atualiza cache local
      await _localDao.add(AuthorDto.fromEntity(created));

      return created;
    } catch (e) {
      throw Exception('Erro ao criar author: $e');
    }
  }

  /// Atualiza autor existente no Supabase
  Future<void> updateAuthor(AuthorEntity author) async {
    try {
      final dto = AuthorDto.fromEntity(author);
      await _supabase
          .from(_tableName)
          .update(dto.toMap())
          .eq('id', author.id);

      // Atualiza cache local
      await _localDao.update(AuthorDto.fromEntity(author));
    } catch (e) {
      throw Exception('Erro ao atualizar author: $e');
    }
  }

  /// Deleta autor do Supabase
  Future<void> deleteAuthor(String id) async {
    try {
      await _supabase.from(_tableName).delete().eq('id', id);

      // Remove do cache local
      await _localDao.removeById(id);
    } catch (e) {
      throw Exception('Erro ao deletar author: $e');
    }
  }

  // ============================================
  // MÉTODOS AUXILIARES
  // ============================================

  /// Incrementa contador de quizzes do autor
  Future<void> incrementQuizzesCount(String authorId) async {
    try {
      await _supabase.rpc('increment_author_quizzes', params: {'author_id': authorId});
      
      // Atualiza cache local
      final cached = await getLocalCache();
      final author = cached.firstWhere((a) => a.id == authorId, orElse: () => throw Exception('Author not found'));
      await _localDao.update(AuthorDto.fromEntity(author.copyWith(quizzesCount: author.quizzesCount + 1)));
    } catch (e) {
      throw Exception('Erro ao incrementar quizzes_count: $e');
    }
  }

  /// Decrementa contador de quizzes do autor
  Future<void> decrementQuizzesCount(String authorId) async {
    try {
      await _supabase.rpc('decrement_author_quizzes', params: {'author_id': authorId});
      
      // Atualiza cache local
      final cached = await getLocalCache();
      final author = cached.firstWhere((a) => a.id == authorId, orElse: () => throw Exception('Author not found'));
      final newCount = author.quizzesCount > 0 ? author.quizzesCount - 1 : 0;
      await _localDao.update(AuthorDto.fromEntity(author.copyWith(quizzesCount: newCount)));
    } catch (e) {
      throw Exception('Erro ao decrementar quizzes_count: $e');
    }
  }
}
