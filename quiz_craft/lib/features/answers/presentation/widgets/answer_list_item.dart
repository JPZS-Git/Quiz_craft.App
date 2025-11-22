import 'package:flutter/material.dart';
import '../../domain/entities/answer_entity.dart';

/// Widget para renderizar um item de resposta na lista.
/// 
/// Exibe um card com informações da resposta incluindo:
/// - Avatar com ícone de status (correta/incorreta)
/// - Texto da resposta
/// - Badge de status (CORRETA/Incorreta)
/// - Botão de edição (opcional)
/// - Detalhes expandíveis com ID e informações completas
class AnswerListItem extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AnswerEntity answer;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;

  const AnswerListItem({
    super.key,
    required this.answer,
    required this.isExpanded,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
  });

  Color _getStatusColor(bool isCorrect) {
    return isCorrect ? Colors.green : Colors.grey;
  }

  IconData _getStatusIcon(bool isCorrect) {
    return isCorrect ? Icons.check_circle : Icons.radio_button_unchecked;
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(answer.isCorrect);
    final statusIcon = _getStatusIcon(answer.isCorrect);
    
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
              backgroundColor: statusColor.withValues(alpha: 0.2),
              child: Icon(
                statusIcon,
                color: statusColor,
                size: 28,
              ),
            ),
            title: Text(
              answer.text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
              maxLines: isExpanded ? null : 2,
              overflow: isExpanded ? null : TextOverflow.ellipsis,
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      answer.isCorrect ? 'CORRETA' : 'Incorreta',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (onEdit != null)
                  IconButton(
                    icon: const Icon(Icons.edit, color: _primaryBlue),
                    onPressed: onEdit,
                    splashRadius: 20,
                    tooltip: 'Editar resposta',
                  ),
                Icon(
                  isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: _primaryBlue,
                ),
              ],
            ),
            onTap: onTap,
            onLongPress: onLongPress,
          ),
          if (isExpanded) _buildDetails(),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.fingerprint,
            'ID',
            answer.id,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.text_fields,
            'Texto da Resposta',
            answer.text,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            answer.isCorrect ? Icons.check_circle : Icons.cancel,
            'Status',
            answer.isCorrect ? 'Resposta Correta' : 'Resposta Incorreta',
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
