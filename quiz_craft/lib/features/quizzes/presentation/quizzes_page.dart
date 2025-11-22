import 'package:flutter/material.dart';
import '../domain/entities/quiz_entity.dart';
import '../services/quiz_sync_service.dart';
import 'dialogs/quiz_actions_dialog.dart';
import 'dialogs/quiz_form_dialog.dart';
import 'widgets/quiz_list_item.dart';

/// Página de listagem de quizzes.
class QuizzesPage extends StatefulWidget {
  static const routeName = '/quizzes';

  const QuizzesPage({super.key});

  @override
  State<QuizzesPage> createState() => _QuizzesPageState();
}

class _QuizzesPageState extends State<QuizzesPage> {
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  late final QuizSyncService _syncService;
  List<QuizEntity> _quizzes = [];
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _syncService = QuizSyncService.create();
    _syncService.addListener(_onSyncUpdate);
    _loadQuizzes();
  }

  @override
  void dispose() {
    _syncService.removeListener(_onSyncUpdate);
    _syncService.dispose();
    super.dispose();
  }

  void _onSyncUpdate() {
    if (mounted) {
      setState(() {
        if (!_syncService.isSyncing) {
          _quizzes = _syncService.cachedQuizzes;
        }
      });
    }
  }

  Future<void> _loadQuizzes() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final quizzes = await _syncService.syncQuizzes();
      if (!mounted) return;
      
      quizzes.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      setState(() {
        _quizzes = quizzes;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar quizzes';
        _loading = false;
      });
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  int _estimatedTime(int questionsCount) {
    return (questionsCount * 0.5).ceil();
  }

  void _showActionsDialog(QuizEntity quiz) {
    showQuizActionsDialog(
      context,
      quiz,
      onEdit: () => _handleEdit(quiz),
      onRemove: () => _handleRemove(quiz),
    );
  }

  Future<void> _handleCreate() async {
    await showQuizFormDialog(context);
    await _loadQuizzes();
  }

  Future<void> _handleEdit(QuizEntity quiz) async {
    await showQuizFormDialog(context, quiz: quiz);
    await _loadQuizzes();
  }

  Future<bool> _confirmRemove(QuizEntity quiz) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover Quiz?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow('Título', quiz.title),
            const SizedBox(height: 8),
            _buildInfoRow('Autor', quiz.authorId ?? 'N/A'),
            const SizedBox(height: 8),
            _buildInfoRow('Status', quiz.isPublished ? 'PUBLICADO' : 'RASCUNHO'),
            const SizedBox(height: 8),
            _buildInfoRow('Questões', '${quiz.questions.length}'),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.red, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Atenção: As ${quiz.questions.length} questões associadas também serão removidas',
                      style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Remover', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm != true) return false;

    try {
      await _syncService.deleteQuiz(quiz.id);
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Quiz removido com sucesso'), backgroundColor: Colors.green),
      );
      await _loadQuizzes();
      return true;
    } catch (e) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao remover quiz: $e'), backgroundColor: Colors.red),
      );
      return false;
    }
  }

  Future<void> _handleRemove(QuizEntity quiz) async {
    await _confirmRemove(quiz);
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
        ),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBackground,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Quizzes',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadQuizzes,
          ),
        ],
      ),
      body: _buildBody(),
      floatingActionButton: FloatingActionButton(
        onPressed: _handleCreate,
        backgroundColor: _primaryBlue,
        tooltip: 'Criar novo quiz',
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 16)),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadQuizzes,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      );
    }

    if (_quizzes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.quiz_outlined, size: 64, color: Colors.grey[400]),
            const SizedBox(height: 16),
            const Text('Nenhum quiz encontrado', style: TextStyle(fontSize: 16, color: Colors.grey)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadQuizzes,
      child: ListView.builder(
        itemCount: _quizzes.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final quiz = _quizzes[index];
          return Dismissible(
            key: Key(quiz.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete, color: Colors.white, size: 32),
            ),
            confirmDismiss: (direction) => _confirmRemove(quiz),
            onDismissed: (direction) {
              // Removal is already handled in confirmDismiss
            },
            child: QuizListItem(
              quiz: quiz,
              isExpanded: _expandedIds.contains(quiz.id),
              onTap: () => _toggleExpand(quiz.id),
              onLongPress: () => _showActionsDialog(quiz),
              onEdit: () => _handleEdit(quiz),
              estimatedTime: _estimatedTime(quiz.questions.length),
            ),
          );
        },
      ),
    );
  }
}
