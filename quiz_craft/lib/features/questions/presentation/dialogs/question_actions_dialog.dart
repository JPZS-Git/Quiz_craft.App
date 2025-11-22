import 'package:flutter/material.dart';
import '../../domain/entities/question_entity.dart';

/// Diálogo de ações para uma questão selecionada.
/// Exibe opções: Editar, Remover e Fechar.
/// 
/// Exemplo de uso:
/// ```dart
/// showQuestionActionsDialog(
///   context,
///   question,
///   onEdit: () => _handleEdit(question),
///   onRemove: () => _handleRemove(question),
/// );
/// ```
Future<void> showQuestionActionsDialog(
  BuildContext context,
  QuestionEntity question, {
  required VoidCallback onEdit,
  required VoidCallback onRemove,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false, // Não permite fechar clicando fora
    builder: (context) => _QuestionActionsDialog(
      question: question,
      onEdit: onEdit,
      onRemove: onRemove,
    ),
  );
}

class _QuestionActionsDialog extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final QuestionEntity question;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _QuestionActionsDialog({
    required this.question,
    required this.onEdit,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Ações da Questão'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            question.text,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
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
