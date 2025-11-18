import 'package:flutter/material.dart';
import '../../infrastructure/dtos/attempt_dto.dart';

/// Diálogo de ações para uma tentativa selecionada.
/// Exibe opções: Editar, Remover e Fechar.
/// 
/// Exemplo de uso:
/// ```dart
/// showAttemptActionsDialog(
///   context,
///   attempt,
///   onEdit: () => _handleEdit(attempt),
///   onRemove: () => _handleRemove(attempt),
/// );
/// ```
Future<void> showAttemptActionsDialog(
  BuildContext context,
  AttemptDto attempt, {
  required VoidCallback onEdit,
  required VoidCallback onRemove,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false, // Não permite fechar clicando fora
    builder: (context) => _AttemptActionsDialog(
      attempt: attempt,
      onEdit: onEdit,
      onRemove: onRemove,
    ),
  );
}

class _AttemptActionsDialog extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AttemptDto attempt;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _AttemptActionsDialog({
    required this.attempt,
    required this.onEdit,
    required this.onRemove,
  });

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.stars;
    if (score >= 60) return Icons.check_circle;
    return Icons.cancel;
  }

  String _formatDateTime(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(attempt.score);
    final scoreIcon = _getScoreIcon(attempt.score);
    
    return AlertDialog(
      title: const Text('Ações da Tentativa'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                scoreIcon,
                color: scoreColor,
                size: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Quiz ${attempt.quizId.substring(0, 8)}...',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${attempt.correctCount}/${attempt.totalCount} corretas',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${attempt.score.toStringAsFixed(0)}%',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: scoreColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.access_time, size: 14, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  _formatDateTime(attempt.startedAt),
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
              ),
            ],
          ),
          if (attempt.finishedAt != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.check_circle_outline, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    'Finalizado: ${_formatDateTime(attempt.finishedAt!)}',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          const Text(
            'O que deseja fazer?',
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
        ],
      ),
      actions: [
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onEdit();
          },
          icon: const Icon(Icons.edit, size: 20),
          label: const Text('Editar'),
          style: TextButton.styleFrom(
            foregroundColor: _primaryBlue,
          ),
        ),
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onRemove();
          },
          icon: const Icon(Icons.delete, size: 20),
          label: const Text('Remover'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
          ),
        ),
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Fechar'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
          ),
        ),
      ],
    );
  }
}
