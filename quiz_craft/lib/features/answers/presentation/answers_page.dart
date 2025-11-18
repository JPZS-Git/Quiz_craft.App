import 'package:flutter/material.dart';
import '../infrastructure/local/answers_local_dao_shared_prefs.dart';
import '../infrastructure/dtos/answer_dto.dart';
import 'dialogs/answer_actions_dialog.dart';
import 'dialogs/answer_form_dialog.dart';
import 'widgets/answer_list_item.dart';

/// Página de listagem de respostas (Answers).
/// Exibe respostas armazenadas localmente com indicação de correção.
class AnswersPage extends StatefulWidget {
  static const routeName = '/answers';

  const AnswersPage({super.key});

  @override
  State<AnswersPage> createState() => _AnswersPageState();
}

class _AnswersPageState extends State<AnswersPage> {
  // Paleta de cores
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  final _dao = AnswersLocalDaoSharedPrefs();
  List<AnswerDto> _answers = [];
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final answers = await _dao.listAll();
      if (!mounted) return;
      
      // Ordenar alfabeticamente por texto
      answers.sort((a, b) => a.text.compareTo(b.text));

      setState(() {
        _answers = answers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar respostas';
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

  /// Abre o diálogo de ações para a resposta selecionada.
  void _showActionsDialog(AnswerDto answer) {
    showAnswerActionsDialog(
      context,
      answer,
      onEdit: () => _handleEdit(answer),
      onRemove: () => _handleRemove(answer),
    );
  }

  /// Handler para editar uma resposta.
  Future<void> _handleEdit(AnswerDto answer) async {
    await showAnswerFormDialog(context, answer: answer);
    await _loadAnswers();
  }

  /// Confirma a remoção de uma resposta (usado pelo Dismissible e pelo diálogo de ações).
  Future<bool> _confirmRemove(AnswerDto answer) async {
    final statusText = answer.isCorrect ? 'CORRETA' : 'Incorreta';
    final statusColor = answer.isCorrect ? Colors.green : Colors.grey;
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Remover resposta?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deseja realmente remover esta resposta?\n'),
            Text(
              '"${answer.text}"',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Text('Status: '),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    statusText,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                      color: statusColor,
                    ),
                  ),
                ),
              ],
            ),
          ],
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
        await _dao.removeById(answer.id);
        if (!mounted) return false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Resposta removida com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _loadAnswers();
        return true;
      } catch (e) {
        if (!mounted) return false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover resposta: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    return false;
  }

  /// Handler para remover uma resposta (usado pelo diálogo de ações).
  Future<void> _handleRemove(AnswerDto answer) async {
    await _confirmRemove(answer);
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
          'Respostas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
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
              onPressed: _loadAnswers,
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
              onPressed: _loadAnswers,
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

    if (_answers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma resposta encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione respostas para visualizá-las aqui',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadAnswers,
      child: ListView.builder(
        itemCount: _answers.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final answer = _answers[index];
          return Dismissible(
            key: Key(answer.id),
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
            confirmDismiss: (direction) => _confirmRemove(answer),
            onDismissed: (direction) {
              // Item already removed in confirmDismiss
            },
            child: AnswerListItem(
              answer: answer,
              isExpanded: _expandedIds.contains(answer.id),
              onTap: () => _toggleExpand(answer.id),
              onLongPress: () => _showActionsDialog(answer),
              onEdit: () => _handleEdit(answer),
            ),
          );
        },
      ),
    );
  }
}
