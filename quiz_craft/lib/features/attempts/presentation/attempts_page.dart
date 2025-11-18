import 'package:flutter/material.dart';
import '../infrastructure/local/attempts_local_dao_shared_prefs.dart';
import '../infrastructure/dtos/attempt_dto.dart';
import 'dialogs/attempt_actions_dialog.dart';
import 'dialogs/attempt_form_dialog.dart';
import 'widgets/attempt_list_item.dart';

/// Página de listagem de tentativas (Attempts).
/// Exibe tentativas de quiz armazenadas localmente com detalhes de pontuação.
class AttemptsPage extends StatefulWidget {
  static const routeName = '/attempts';

  const AttemptsPage({super.key});

  @override
  State<AttemptsPage> createState() => _AttemptsPageState();
}

class _AttemptsPageState extends State<AttemptsPage> {
  // Paleta de cores
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  final _dao = AttemptsLocalDaoSharedPrefs();
  List<AttemptDto> _attempts = [];
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadAttempts();
  }

  Future<void> _loadAttempts() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final attempts = await _dao.listAll();
      if (!mounted) return;
      
      // Ordenar por data de início (mais recente primeiro)
      attempts.sort((a, b) {
        final dateA = DateTime.tryParse(a.startedAt) ?? DateTime.now();
        final dateB = DateTime.tryParse(b.startedAt) ?? DateTime.now();
        return dateB.compareTo(dateA);
      });

      setState(() {
        _attempts = attempts;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar tentativas';
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

  /// Abre o diálogo de ações para a tentativa selecionada.
  void _showActionsDialog(AttemptDto attempt) {
    showAttemptActionsDialog(
      context,
      attempt,
      onEdit: () => _handleEdit(attempt),
      onRemove: () => _handleRemove(attempt),
    );
  }

  /// Handler para editar uma tentativa.
  Future<void> _handleEdit(AttemptDto attempt) async {
    await showAttemptFormDialog(context, attempt: attempt);
    await _loadAttempts();
  }

  String _formatDateTime(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  /// Confirma a remoção de uma tentativa (usado pelo Dismissible e pelo diálogo de ações).
  Future<bool> _confirmRemove(AttemptDto attempt) async {
    final statusText = attempt.finishedAt != null ? 'Concluído' : 'Em andamento';
    
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Remover tentativa?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Deseja realmente remover esta tentativa?\n'),
            _buildInfoRow('Quiz ID:', attempt.quizId),
            const SizedBox(height: 8),
            _buildInfoRow(
              'Pontuação:',
              '${attempt.score.toStringAsFixed(0)}% (${attempt.correctCount}/${attempt.totalCount})',
            ),
            const SizedBox(height: 8),
            _buildInfoRow('Iniciado:', _formatDateTime(attempt.startedAt)),
            const SizedBox(height: 8),
            _buildInfoRow(
              attempt.finishedAt != null ? 'Concluído:' : 'Status:',
              attempt.finishedAt != null 
                  ? _formatDateTime(attempt.finishedAt!) 
                  : statusText,
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
        await _dao.removeById(attempt.id);
        if (!mounted) return false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tentativa removida com sucesso'),
            backgroundColor: Colors.green,
          ),
        );
        
        await _loadAttempts();
        return true;
      } catch (e) {
        if (!mounted) return false;
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao remover tentativa: $e'),
            backgroundColor: Colors.red,
          ),
        );
        return false;
      }
    }
    
    return false;
  }

  Widget _buildInfoRow(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 80,
          child: Text(
            label,
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontSize: 13),
          ),
        ),
      ],
    );
  }

  /// Handler para remover uma tentativa (usado pelo diálogo de ações).
  Future<void> _handleRemove(AttemptDto attempt) async {
    await _confirmRemove(attempt);
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
          'Tentativas de Quiz',
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
              onPressed: _loadAttempts,
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
              onPressed: _loadAttempts,
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

    if (_attempts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.assignment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma tentativa encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Complete um quiz para ver suas tentativas aqui',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadAttempts,
      child: ListView.builder(
        itemCount: _attempts.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final attempt = _attempts[index];
          return Dismissible(
            key: Key(attempt.id),
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
            confirmDismiss: (direction) => _confirmRemove(attempt),
            onDismissed: (direction) {
              // Item already removed in confirmDismiss
            },
            child: AttemptListItem(
              attempt: attempt,
              isExpanded: _expandedIds.contains(attempt.id),
              onTap: () => _toggleExpand(attempt.id),
              onLongPress: () => _showActionsDialog(attempt),
              onEdit: () => _handleEdit(attempt),
            ),
          );
        },
      ),
    );
  }
}
