import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/question_entity.dart';
import '../infrastructure/repositories/question_supabase_repository.dart';

/// Serviço de sincronização para questions com Supabase.
/// Gerencia a sincronização incremental e operações CRUD.
class QuestionSyncService extends ChangeNotifier {
  final QuestionSupabaseRepository _repository;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;

  QuestionSyncService(this._repository);

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Sincroniza questions do Supabase com cache local.
  Future<List<QuestionEntity>> syncQuestions({String? quizId}) async {
    if (_isSyncing) {
      debugPrint('Sincronização já em andamento, aguarde...');
      return await _repository.getLocalCache();
    }

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('Iniciando sincronização de questions...');
      final questions = await _repository.syncIncremental();
      _lastSyncTime = DateTime.now();
      debugPrint('Sincronização concluída: ${questions.length} questions.');
      
      // Se quizId foi fornecido, filtra apenas questions desse quiz
      if (quizId != null && quizId.isNotEmpty) {
        // Nota: precisamos adicionar quiz_id ao QuestionEntity para filtrar
        // Por enquanto, retorna todas
        return questions;
      }
      
      return questions;
    } catch (e) {
      debugPrint('Erro na sincronização: $e');
      // Fallback: retorna cache local
      return await _repository.getLocalCache();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Obtém questions do cache local.
  Future<List<QuestionEntity>> getLocalQuestions() async {
    return await _repository.getLocalCache();
  }

  /// Cria uma nova question.
  Future<QuestionEntity> createQuestion(QuestionEntity question) async {
    try {
      debugPrint('Criando question: ${question.text}');
      final created = await _repository.createQuestion(question);
      
      // Re-sincroniza após criação
      await syncQuestions();
      
      return created;
    } catch (e) {
      debugPrint('Erro ao criar question: $e');
      rethrow;
    }
  }

  /// Atualiza uma question existente.
  Future<QuestionEntity> updateQuestion(QuestionEntity question) async {
    try {
      debugPrint('Atualizando question: ${question.id}');
      final updated = await _repository.updateQuestion(question);
      
      // Re-sincroniza após atualização
      await syncQuestions();
      
      return updated;
    } catch (e) {
      debugPrint('Erro ao atualizar question: $e');
      rethrow;
    }
  }

  /// Deleta uma question.
  Future<void> deleteQuestion(String id) async {
    try {
      debugPrint('Deletando question: $id');
      await _repository.deleteQuestion(id);
      
      // Re-sincroniza após exclusão
      await syncQuestions();
    } catch (e) {
      debugPrint('Erro ao deletar question: $e');
      rethrow;
    }
  }

  /// Habilita sincronização automática em intervalos regulares.
  void enableAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) {
      syncQuestions();
    });
    debugPrint('Auto-sincronização habilitada (intervalo: ${interval.inMinutes}min)');
  }

  /// Desabilita sincronização automática.
  void disableAutoSync() {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = null;
    debugPrint('Auto-sincronização desabilitada');
  }

  @override
  void dispose() {
    _autoSyncTimer?.cancel();
    super.dispose();
  }
}
