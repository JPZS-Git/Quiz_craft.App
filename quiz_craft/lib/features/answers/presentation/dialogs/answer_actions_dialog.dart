import 'package:flutter/material.dart';
import '../../infrastructure/dtos/answer_dto.dart';

/// Diálogo de ações para uma resposta selecionada.
/// Exibe opções: Editar, Remover e Fechar.
/// 
/// Exemplo de uso:
/// ```dart
/// showAnswerActionsDialog(
///   context,
///   answer,
///   onEdit: () => _handleEdit(answer),
///   onRemove: () => _handleRemove(answer),
/// );
/// ```
Future<void> showAnswerActionsDialog(
  BuildContext context,
  AnswerDto answer, {
  required VoidCallback onEdit,
  required VoidCallback onRemove,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false, // Não permite fechar clicando fora
    builder: (context) => _AnswerActionsDialog(
      answer: answer,
      onEdit: onEdit,
      onRemove: onRemove,
    ),
  );
}

class _AnswerActionsDialog extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AnswerDto answer;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _AnswerActionsDialog({
    required this.answer,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ações da Resposta'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                answer.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                color: answer.isCorrect ? Colors.green : Colors.grey,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer.text,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: (answer.isCorrect ? Colors.green : Colors.grey).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              answer.isCorrect ? 'CORRETA' : 'Incorreta',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 11,
                color: answer.isCorrect ? Colors.green : Colors.grey,
              ),
            ),
          ),
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
