import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/quiz_entity.dart';
import '../infrastructure/repositories/quiz_supabase_repository.dart';
import '../infrastructure/local/quizzes_local_dao_shared_prefs.dart';

/// Serviço de sincronização de quizzes com notificação de mudanças.
class QuizSyncService extends ChangeNotifier {
  final QuizSupabaseRepository _repository;
  List<QuizEntity> _quizzes = [];
  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;
  bool _autoSyncEnabled = false;

  QuizSyncService(this._repository);

  /// Factory para criar instância com dependências injetadas.
  factory QuizSyncService.create() {
    final repository = QuizSupabaseRepository(QuizzesLocalDaoSharedPrefs());
    return QuizSyncService(repository);
  }

  // Getters
  List<QuizEntity> get quizzes => _quizzes;
  List<QuizEntity> get cachedQuizzes => _quizzes;
  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;
  bool get autoSyncEnabled => _autoSyncEnabled;

  /// Sincroniza quizzes do Supabase (incremental).
  Future<List<QuizEntity>> syncQuizzes({bool onlyPublished = false}) async {
    if (_isSyncing) return _quizzes;

    _isSyncing = true;
    notifyListeners();

    try {
      _quizzes = await _repository.syncIncremental();
      _lastSyncTime = DateTime.now();

      if (onlyPublished) {
        _quizzes = _quizzes.where((q) => q.isPublished).toList();
      }

      return _quizzes;
    } catch (e) {
      debugPrint('Erro ao sincronizar quizzes: $e');
      // Retorna cache em caso de erro
      _quizzes = await _repository.getLocalCache();
      return _quizzes;
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Habilita sincronização automática em intervalos definidos.
  void enableAutoSync(Duration interval) {
    if (_autoSyncEnabled) return;

    _autoSyncEnabled = true;
    _autoSyncTimer = Timer.periodic(interval, (_) {
      syncQuizzes();
    });
    notifyListeners();
  }

  /// Desabilita sincronização automática.
  void disableAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    _autoSyncEnabled = false;
    notifyListeners();
  }

  /// Retorna a lista de quizzes em cache.
  List<QuizEntity> getQuizzes({bool onlyPublished = false}) {
    if (onlyPublished) {
      return _quizzes.where((q) => q.isPublished).toList();
    }
    return _quizzes;
  }

  /// Busca um quiz específico por ID.
  QuizEntity? getQuizById(String id) {
    try {
      return _quizzes.firstWhere((q) => q.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Cria um novo quiz.
  Future<QuizEntity> createQuiz(QuizEntity entity) async {
    try {
      final created = await _repository.createQuiz(entity);
      await syncQuizzes();
      return created;
    } catch (e) {
      debugPrint('Erro ao criar quiz: $e');
      rethrow;
    }
  }

  /// Atualiza um quiz existente.
  Future<QuizEntity> updateQuiz(QuizEntity entity) async {
    try {
      final updated = await _repository.updateQuiz(entity);
      await syncQuizzes();
      return updated;
    } catch (e) {
      debugPrint('Erro ao atualizar quiz: $e');
      rethrow;
    }
  }

  /// Remove um quiz.
  Future<void> deleteQuiz(String id) async {
    try {
      await _repository.deleteQuiz(id);
      await syncQuizzes();
    } catch (e) {
      debugPrint('Erro ao deletar quiz: $e');
      rethrow;
    }
  }

  /// Incrementa contador de tentativas.
  Future<void> incrementAttemptsCount(String quizId) async {
    try {
      await _repository.incrementAttemptsCount(quizId);
      await syncQuizzes();
    } catch (e) {
      debugPrint('Erro ao incrementar tentativas: $e');
    }
  }

  /// Decrementa contador de tentativas.
  Future<void> decrementAttemptsCount(String quizId) async {
    try {
      await _repository.decrementAttemptsCount(quizId);
      await syncQuizzes();
    } catch (e) {
      debugPrint('Erro ao decrementar tentativas: $e');
    }
  }

  @override
  void dispose() {
    disableAutoSync();
    super.dispose();
  }
}
