import 'dart:async';
import 'package:flutter/foundation.dart';
import '../domain/entities/answer_entity.dart';
import '../infrastructure/repositories/answer_supabase_repository.dart';

/// Serviço de sincronização para answers com Supabase.
/// Gerencia a sincronização incremental e operações CRUD.
class AnswerSyncService extends ChangeNotifier {
  final AnswerSupabaseRepository _repository;

  bool _isSyncing = false;
  DateTime? _lastSyncTime;
  Timer? _autoSyncTimer;

  AnswerSyncService(this._repository);

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  /// Sincroniza answers do Supabase com cache local.
  Future<List<AnswerEntity>> syncAnswers({String? questionId}) async {
    if (_isSyncing) {
      debugPrint('Sincronização já em andamento, aguarde...');
      return await _repository.getLocalCache();
    }

    _isSyncing = true;
    notifyListeners();

    try {
      debugPrint('Iniciando sincronização de answers...');
      final answers = await _repository.syncIncremental();
      _lastSyncTime = DateTime.now();
      debugPrint('Sincronização concluída: ${answers.length} answers.');
      
      // Se questionId foi fornecido, filtra apenas answers dessa question
      if (questionId != null && questionId.isNotEmpty) {
        return answers.where((a) => a.questionId == questionId).toList();
      }
      
      return answers;
    } catch (e) {
      debugPrint('Erro na sincronização: $e');
      // Fallback: retorna cache local
      return await _repository.getLocalCache();
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Obtém answers do cache local, opcionalmente filtradas por questionId.
  Future<List<AnswerEntity>> getLocalAnswers({String? questionId}) async {
    final allAnswers = await _repository.getLocalCache();
    
    if (questionId != null && questionId.isNotEmpty) {
      return allAnswers.where((a) => a.questionId == questionId).toList();
    }
    
    return allAnswers;
  }

  /// Cria uma nova answer.
  Future<AnswerEntity> createAnswer(AnswerEntity answer) async {
    try {
      debugPrint('Criando answer: ${answer.text}');
      final created = await _repository.createAnswer(answer);
      
      // Re-sincroniza após criação
      await syncAnswers();
      
      return created;
    } catch (e) {
      debugPrint('Erro ao criar answer: $e');
      rethrow;
    }
  }

  /// Atualiza uma answer existente.
  Future<AnswerEntity> updateAnswer(AnswerEntity answer) async {
    try {
      debugPrint('Atualizando answer: ${answer.id}');
      final updated = await _repository.updateAnswer(answer);
      
      // Re-sincroniza após atualização
      await syncAnswers();
      
      return updated;
    } catch (e) {
      debugPrint('Erro ao atualizar answer: $e');
      rethrow;
    }
  }

  /// Marca uma answer como correta (automaticamente desmarca outras da mesma question).
  Future<AnswerEntity> markAsCorrect(String answerId) async {
    try {
      debugPrint('Marcando answer $answerId como correta');
      final marked = await _repository.markAsCorrect(answerId);
      
      // Re-sincroniza após marcar
      await syncAnswers();
      
      return marked;
    } catch (e) {
      debugPrint('Erro ao marcar answer como correta: $e');
      rethrow;
    }
  }

  /// Deleta uma answer.
  Future<void> deleteAnswer(String id) async {
    try {
      debugPrint('Deletando answer: $id');
      await _repository.deleteAnswer(id);
      
      // Re-sincroniza após exclusão
      await syncAnswers();
    } catch (e) {
      debugPrint('Erro ao deletar answer: $e');
      rethrow;
    }
  }

  /// Habilita sincronização automática em intervalos regulares.
  void enableAutoSync({Duration interval = const Duration(minutes: 5)}) {
    _autoSyncTimer?.cancel();
    _autoSyncTimer = Timer.periodic(interval, (_) {
      syncAnswers();
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
