import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/author_entity.dart';
import '../infrastructure/local/authors_local_dao_shared_prefs.dart';
import '../infrastructure/repositories/author_supabase_repository.dart';

/// Serviço de sincronização incremental para Authors
/// Executa sync em background e notifica listeners sobre atualizações
class AuthorSyncService extends ChangeNotifier {
  final AuthorSupabaseRepository _repository;
  
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  String? _lastError;
  List<AuthorEntity> _cachedAuthors = [];

  AuthorSyncService(this._repository);

  /// Factory para criar instância com DAO local
  factory AuthorSyncService.create() {
    final localDao = AuthorsLocalDaoSharedPrefs();
    final repository = AuthorSupabaseRepository(localDao);
    return AuthorSyncService(repository);
  }

  // ============================================
  // GETTERS
  // ============================================

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  String? get lastError => _lastError;
  List<AuthorEntity> get cachedAuthors => List.unmodifiable(_cachedAuthors);

  // ============================================
  // SINCRONIZAÇÃO
  // ============================================

  /// Carrega cache local imediatamente (sem sync)
  Future<List<AuthorEntity>> loadCacheOnly() async {
    try {
      _cachedAuthors = await _repository.getLocalCache();
      notifyListeners();
      return _cachedAuthors;
    } catch (e) {
      _lastError = 'Erro ao carregar cache: $e';
      notifyListeners();
      return [];
    }
  }

  /// Sincroniza com Supabase em background (incremental)
  Future<List<AuthorEntity>> syncAuthors({bool onlyActive = false}) async {
    if (_isSyncing) {
      debugPrint('⚠️ Sync já em andamento, ignorando nova solicitação');
      return _cachedAuthors;
    }

    _isSyncing = true;
    _lastError = null;
    notifyListeners();

    try {
      debugPrint('🔄 Iniciando sync incremental de Authors...');
      
      // Sync incremental (busca apenas updated_at >= lastSync)
      final authors = await _repository.syncIncremental(onlyActive: onlyActive);
      
      _cachedAuthors = authors;
      _lastSyncTime = DateTime.now();
      _lastError = null;
      
      debugPrint('✅ Sync concluído: ${authors.length} authors');
      
      notifyListeners();
      return authors;
    } catch (e) {
      _lastError = 'Erro no sync: $e';
      debugPrint('❌ Erro no sync de Authors: $e');
      
      // Em caso de erro, tenta retornar cache local
      try {
        _cachedAuthors = await _repository.getLocalCache();
        debugPrint('📦 Retornando cache local após erro de sync');
      } catch (cacheError) {
        debugPrint('❌ Erro ao ler cache local: $cacheError');
      }
      
      notifyListeners();
      return _cachedAuthors;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Força sync completo (ignora lastSync, busca tudo)
  Future<List<AuthorEntity>> forceFullSync({bool onlyActive = false}) async {
    try {
      _isSyncing = true;
      notifyListeners();

      debugPrint('🔄 Forçando sync completo de Authors...');
      
      // Busca todos os authors do Supabase
      final authors = await _repository.fetchAuthors(onlyActive: onlyActive);
      
      // Salva no cache local
      await _repository.saveLocalCache(authors);
      
      // Atualiza lastSync
      await _repository.saveLastSync(DateTime.now());
      
      _cachedAuthors = authors;
      _lastSyncTime = DateTime.now();
      _lastError = null;
      
      debugPrint('✅ Sync completo concluído: ${authors.length} authors');
      
      notifyListeners();
      return authors;
    } catch (e) {
      _lastError = 'Erro no sync completo: $e';
      debugPrint('❌ Erro no sync completo: $e');
      notifyListeners();
      rethrow;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  // ============================================
  // SINCRONIZAÇÃO AUTOMÁTICA
  // ============================================

  Timer? _autoSyncTimer;

  /// Inicia sync automático em intervalo regular
  void startAutoSync({Duration interval = const Duration(minutes: 5)}) {
    stopAutoSync(); // Para timer anterior se existir
    
    debugPrint('🔁 Iniciando auto-sync a cada ${interval.inMinutes} minutos');
    
    _autoSyncTimer = Timer.periodic(interval, (_) async {
      debugPrint('⏰ Executando auto-sync agendado');
      await syncAuthors();
    });
  }

  /// Para sync automático
  void stopAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    debugPrint('⏸️ Auto-sync pausado');
  }

  // ============================================
  // CRUD COM SYNC
  // ============================================

  /// Cria novo autor e sincroniza
  Future<AuthorEntity> createAuthor(AuthorEntity author) async {
    try {
      final created = await _repository.createAuthor(author);
      
      // Recarrega cache
      await loadCacheOnly();
      
      return created;
    } catch (e) {
      debugPrint('❌ Erro ao criar author: $e');
      rethrow;
    }
  }

  /// Atualiza autor existente e sincroniza
  Future<void> updateAuthor(AuthorEntity author) async {
    try {
      await _repository.updateAuthor(author);
      
      // Recarrega cache
      await loadCacheOnly();
    } catch (e) {
      debugPrint('❌ Erro ao atualizar author: $e');
      rethrow;
    }
  }

  /// Deleta autor e sincroniza
  Future<void> deleteAuthor(String id) async {
    try {
      await _repository.deleteAuthor(id);
      
      // Recarrega cache
      await loadCacheOnly();
    } catch (e) {
      debugPrint('❌ Erro ao deletar author: $e');
      rethrow;
    }
  }

  // ============================================
  // CLEANUP
  // ============================================

  @override
  void dispose() {
    stopAutoSync();
    super.dispose();
  }
}
