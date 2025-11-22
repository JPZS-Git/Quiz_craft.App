import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/attempt_entity.dart';
import '../infrastructure/repositories/attempt_supabase_repository.dart';

/// Service para sincronização automática de attempts entre Supabase e cache local.
/// Gerencia estado de sincronização e dispara atualizações reativas para UI.
class AttemptSyncService extends ChangeNotifier {
  final AttemptSupabaseRepository _repository;
  List<AttemptEntity> _attempts = [];
  bool _isSyncing = false;
  DateTime? _lastSync;
  Timer? _autoSyncTimer;

  AttemptSyncService(this._repository);

  List<AttemptEntity> get attempts => _attempts;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSync => _lastSync;

  /// Inicializa sincronização com opção de auto-sync periódico.
  Future<void> initialize({Duration? autoSyncInterval}) async {
    await loadFromCache();
    await syncAttempts();

    if (autoSyncInterval != null) {
      _autoSyncTimer?.cancel();
      _autoSyncTimer = Timer.periodic(autoSyncInterval, (_) {
        syncAttempts();
      });
    }
  }

  /// Carrega attempts do cache local (útil para startup offline).
  Future<void> loadFromCache() async {
    try {
      _attempts = await _repository.getLocalCache();
      _lastSync = await _repository.getLastSync();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao carregar attempts do cache: $e');
    }
  }

  /// Sincroniza attempts com Supabase (incremental baseado em updated_at).
  Future<void> syncAttempts({String? quizId, String? userId}) async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Se quizId ou userId for especificado, busca diretamente (não incremental)
      if (quizId != null || userId != null) {
        final filtered = await _repository.fetchAttempts(quizId: quizId, userId: userId);
        _attempts = filtered;
      } else {
        _attempts = await _repository.syncIncremental();
      }

      _lastSync = DateTime.now();
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao sincronizar attempts: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Busca attempts por quiz_id.
  Future<List<AttemptEntity>> getAttemptsByQuiz(String quizId) async {
    try {
      return _attempts.where((a) => a.quizId == quizId).toList();
    } catch (e) {
      debugPrint('Erro ao buscar attempts por quiz: $e');
      return [];
    }
  }

  /// Busca attempts por user_id.
  Future<List<AttemptEntity>> getAttemptsByUser(String? userId) async {
    try {
      if (userId == null || userId.isEmpty) return [];
      return _attempts.where((a) => a.userId == userId).toList();
    } catch (e) {
      debugPrint('Erro ao buscar attempts por usuário: $e');
      return [];
    }
  }

  /// Busca um attempt específico por ID.
  Future<AttemptEntity?> getAttemptById(String id) async {
    try {
      return _attempts.firstWhere((a) => a.id == id, orElse: () => throw Exception('Attempt não encontrado'));
    } catch (e) {
      debugPrint('Attempt $id não encontrado no cache, buscando do Supabase...');
      try {
        final remote = await _repository.fetchAttemptById(id);
        if (remote != null) {
          _attempts.add(remote);
          notifyListeners();
        }
        return remote;
      } catch (e2) {
        debugPrint('Erro ao buscar attempt do Supabase: $e2');
        return null;
      }
    }
  }

  /// Cria um novo attempt e sincroniza.
  Future<AttemptEntity> createAttempt(AttemptEntity attempt) async {
    try {
      final created = await _repository.createAttempt(attempt);
      _attempts.add(created);
      notifyListeners();
      
      // Re-sincroniza para capturar mudanças nos triggers
      unawaited(syncAttempts());
      
      return created;
    } catch (e) {
      debugPrint('Erro ao criar attempt: $e');
      rethrow;
    }
  }

  /// Atualiza um attempt existente e sincroniza.
  Future<AttemptEntity> updateAttempt(AttemptEntity attempt) async {
    try {
      final updated = await _repository.updateAttempt(attempt);
      final index = _attempts.indexWhere((a) => a.id == updated.id);
      if (index != -1) {
        _attempts[index] = updated;
      } else {
        _attempts.add(updated);
      }
      notifyListeners();
      
      // Re-sincroniza para capturar mudanças nos triggers
      unawaited(syncAttempts());
      
      return updated;
    } catch (e) {
      debugPrint('Erro ao atualizar attempt: $e');
      rethrow;
    }
  }

  /// Marca um attempt como completed (dispara triggers para calcular duration e score).
  Future<AttemptEntity> completeAttempt(String attemptId) async {
    try {
      final completed = await _repository.completeAttempt(attemptId);
      final index = _attempts.indexWhere((a) => a.id == completed.id);
      if (index != -1) {
        _attempts[index] = completed;
      }
      notifyListeners();
      
      // Re-sincroniza para capturar mudanças nos triggers
      unawaited(syncAttempts());
      
      return completed;
    } catch (e) {
      debugPrint('Erro ao completar attempt: $e');
      rethrow;
    }
  }

  /// Marca um attempt como abandoned.
  Future<AttemptEntity> abandonAttempt(String attemptId) async {
    try {
      final abandoned = await _repository.abandonAttempt(attemptId);
      final index = _attempts.indexWhere((a) => a.id == abandoned.id);
      if (index != -1) {
        _attempts[index] = abandoned;
      }
      notifyListeners();
      
      // Re-sincroniza para capturar mudanças nos triggers
      unawaited(syncAttempts());
      
      return abandoned;
    } catch (e) {
      debugPrint('Erro ao abandonar attempt: $e');
      rethrow;
    }
  }

  /// Deleta um attempt e remove do cache.
  Future<void> deleteAttempt(String id) async {
    try {
      await _repository.deleteAttempt(id);
      _attempts.removeWhere((a) => a.id == id);
      notifyListeners();
    } catch (e) {
      debugPrint('Erro ao deletar attempt: $e');
      rethrow;
    }
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
