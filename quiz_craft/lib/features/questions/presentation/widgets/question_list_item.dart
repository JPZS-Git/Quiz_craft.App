import 'package:flutter/material.dart';
import '../../infrastructure/dtos/question_dto.dart';

/// Widget para renderizar um item de questão na lista.
/// 
/// Exibe um card com informações da questão incluindo:
/// - Avatar com número de ordem
/// - Texto da questão
/// - Quantidade de respostas
/// - Botão de edição (opcional)
/// - Lista expansível de respostas quando expandido
class QuestionListItem extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final QuestionDto question;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;

  const QuestionListItem({
    super.key,
    required this.question,
    required this.isExpanded,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswers = question.answers.isNotEmpty;
    
    return Card(
      color: Colors.white,
      elevation: 3,
      shadowColor: Colors.black26,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      margin: const EdgeInsets.only(bottom: 12),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: CircleAvatar(
              backgroundColor: _primaryBlue,
              child: Text(
                '${question.order}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              question.text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: hasAnswers
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${question.answers.length} resposta${question.answers.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : null,
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: _primaryBlue),
                    onPressed: onEdit,
                    splashRadius: 20,
                    tooltip: 'Editar questão',
                  ),
                if (hasAnswers)
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _primaryBlue,
                  ),
              ],
            ),
            onTap: hasAnswers ? onTap : null,
            onLongPress: onLongPress,
          ),
          if (isExpanded && hasAnswers) _buildAnswersList(),
        ],
      ),
    );
  }

  Widget _buildAnswersList() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text(
            'Respostas:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...question.answers.map((answer) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    answer.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: answer.isCorrect ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      answer.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: answer.isCorrect ? Colors.green[800] : Colors.black87,
                        fontWeight: answer.isCorrect ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
