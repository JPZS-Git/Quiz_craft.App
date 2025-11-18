import 'package:flutter/material.dart';
import '../infrastructure/local/questions_local_dao_shared_prefs.dart';
import '../infrastructure/dtos/question_dto.dart';
import 'dialogs/question_actions_dialog.dart';
import 'dialogs/question_form_dialog.dart';
import 'widgets/question_list_item.dart';

/// Página de listagem de questões (Questions).
/// Exibe questões armazenadas localmente com suporte a expansão de respostas.
class QuestionsPage extends StatefulWidget {
  static const routeName = '/questions';

  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  // Paleta de cores (seguindo padrão da home_page.dart)
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  final _dao = QuestionsLocalDaoSharedPrefs();
  List<QuestionDto> _questions = [];
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final questions = await _dao.listAll();
      if (!mounted) return;
      
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar questões';
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

  /// Abre o diálogo de ações para a questão selecionada.
  void _showActionsDialog(QuestionDto question) {
    showQuestionActionsDialog(
      context,
      question,
      onEdit: () => _handleEdit(question),
      onRemove: () => _handleRemove(question),
    );
  }

  /// Handler para editar uma questão.
  Future<void> _handleEdit(QuestionDto question) async {
    await showQuestionFormDialog(context, question: question);
    await _loadQuestions();
  }

  /// Confirma a remoção de uma questão (usado pelo Dismissible e pelo diálogo de ações).
  Future<bool> _confirmRemove(QuestionDto question) async {
    final answersCount = question.answers.length;
    final answersText = answersCount == 1 ? '1 resposta associada' : '$answersCount respostas associadas';
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Remover questão?'),
        content: Text(
          'Deseja realmente remover esta questão?\n\n'
          '"${question.text}"\n\n'
          'Atenção: ${answersCount > 0 ? 'As $answersText também serão removidas.' : 'Esta questão não possui respostas.'}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Remover'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dao.removeById(question.id);
        if (!mounted) return false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Questão removida com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _loadQuestions();
        return true;
      } catch (e) {
        if (!mounted) return false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover questão: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    return false;
  }

  /// Handler para remover uma questão (usado pelo diálogo de ações).
  Future<void> _handleRemove(QuestionDto question) async {
    await _confirmRemove(question);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBackground,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 2,
        title: const Text(
          'Questões',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          Tooltip(
            message: 'Recarregar',
            waitDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Recarregar',
              icon: const Icon(Icons.refresh, color: Colors.white),
              splashRadius: 24,
              onPressed: _loadQuestions,
            ),
          ),
        ],
      ),
      body: _buildBody(),
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
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadQuestions,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      );
    }

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma questão encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadQuestions,
      child: ListView.builder(
        itemCount: _questions.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final question = _questions[index];
          return Dismissible(
            key: Key(question.id),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
                size: 32,
              ),
            ),
            confirmDismiss: (direction) => _confirmRemove(question),
            onDismissed: (direction) {
              // Item already removed in confirmDismiss
            },
            child: QuestionListItem(
              question: question,
              isExpanded: _expandedIds.contains(question.id),
              onTap: () => _toggleExpand(question.id),
              onLongPress: () => _showActionsDialog(question),
              onEdit: () => _handleEdit(question),
            ),
          );
        },
      ),
    );
  }
}
