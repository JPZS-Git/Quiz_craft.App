import 'package:flutter/material.dart';
import '../../infrastructure/dtos/quiz_dto.dart';

/// Exibe um diálogo de ações para um quiz selecionado.
///
/// O diálogo apresenta informações do quiz e oferece três opções:
/// - Editar: Chama o callback [onEdit]
/// - Remover: Chama o callback [onRemove]
/// - Fechar: Fecha o diálogo sem ações
///
/// O diálogo não pode ser fechado ao tocar fora (barrierDismissible: false).
Future<void> showQuizActionsDialog(
  BuildContext context,
  QuizDto quiz, {
  required VoidCallback onEdit,
  required VoidCallback onRemove,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _QuizActionsDialog(
      quiz: quiz,
      onEdit: onEdit,
      onRemove: onRemove,
    ),
  );
}

class _QuizActionsDialog extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final QuizDto quiz;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _QuizActionsDialog({
    required this.quiz,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Ícone e título
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: _primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.quiz, color: _primaryBlue, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  quiz.title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Status e quantidade de questões
          Row(
            children: [
              // Badge de status
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (quiz.isPublished ? Colors.green : Colors.orange).withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      quiz.isPublished ? Icons.check_circle : Icons.edit,
                      size: 14,
                      color: quiz.isPublished ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      quiz.isPublished ? 'PUBLICADO' : 'RASCUNHO',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: quiz.isPublished ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Quantidade de questões
              Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${quiz.questions.length} ${quiz.questions.length == 1 ? 'questão' : 'questões'}',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        // Botão Editar
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onEdit();
          },
          icon: const Icon(Icons.edit, size: 20),
          label: const Text('Editar'),
          style: TextButton.styleFrom(
            foregroundColor: _primaryBlue,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        // Botão Remover
        TextButton.icon(
          onPressed: () {
            Navigator.of(context).pop();
            onRemove();
          },
          icon: const Icon(Icons.delete, size: 20),
          label: const Text('Remover'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.red,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
        
        // Botão Fechar
        TextButton.icon(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Fechar'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }
}
