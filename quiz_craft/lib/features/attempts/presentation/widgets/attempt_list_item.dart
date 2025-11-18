import 'package:flutter/material.dart';
import '../../infrastructure/dtos/attempt_dto.dart';

/// Widget para renderizar um item de tentativa na lista.
/// 
/// Exibe um card com informações da tentativa incluindo:
/// - Avatar com ícone de pontuação (baseado no score)
/// - Quiz ID truncado
/// - Badge de pontuação com cor baseada no desempenho
/// - Quantidade de acertos (corretas/total)
/// - Data/hora de início formatada
/// - Botão de edição (opcional)
/// - Detalhes expandíveis com informações completas e barra de progresso
class AttemptListItem extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AttemptDto attempt;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;

  const AttemptListItem({
    super.key,
    required this.attempt,
    required this.isExpanded,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
  });

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Color _withAlpha(Color color, double alpha) {
    return color.withValues(alpha: alpha);
  }

  IconData _getScoreIcon(double score) {
    if (score >= 80) return Icons.stars;
    if (score >= 60) return Icons.check_circle;
    return Icons.cancel;
  }

  String _formatDateTime(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return isoDate;
    
    // Formato dd/MM/yyyy HH:mm sem intl package
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String _calculateDuration() {
    final started = DateTime.tryParse(attempt.startedAt);
    final finished = attempt.finishedAt != null 
        ? DateTime.tryParse(attempt.finishedAt!) 
        : null;
    
    if (started == null) return 'Duração desconhecida';
    if (finished == null) return 'Em andamento';
    
    final duration = finished.difference(started);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    
    if (minutes > 0) {
      return '$minutes min ${seconds}s';
    }
    return '${seconds}s';
  }

  @override
  Widget build(BuildContext context) {
    final scoreColor = _getScoreColor(attempt.score);
    final scoreIcon = _getScoreIcon(attempt.score);
    final isFinished = attempt.finishedAt != null;
    
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
              backgroundColor: _withAlpha(scoreColor, 0.2),
              child: Icon(
                scoreIcon,
                color: scoreColor,
                size: 28,
              ),
            ),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    'Quiz ${attempt.quizId.substring(0, 8)}...',
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 15,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _withAlpha(scoreColor, 0.2),
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
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${attempt.correctCount}/${attempt.totalCount} corretas',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.access_time, size: 12, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        _formatDateTime(attempt.startedAt),
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
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
                    tooltip: 'Editar tentativa',
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
          if (isExpanded) _buildDetails(isFinished),
        ],
      ),
    );
  }

  Widget _buildDetails(bool isFinished) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.assignment,
            'ID da Tentativa',
            attempt.id,
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.quiz,
            'ID do Quiz',
            attempt.quizId,
          ),
          if (attempt.userId != null) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.person,
              'Usuário',
              _maskUserId(attempt.userId!),
            ),
          ],
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.timer,
            'Duração',
            _calculateDuration(),
          ),
          const SizedBox(height: 8),
          _buildDetailRow(
            Icons.calendar_today,
            'Iniciado em',
            _formatDateTime(attempt.startedAt),
          ),
          if (isFinished) ...[
            const SizedBox(height: 8),
            _buildDetailRow(
              Icons.check_circle_outline,
              'Finalizado em',
              _formatDateTime(attempt.finishedAt!),
            ),
          ],
          const SizedBox(height: 12),
          _buildProgressBar(),
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

  Widget _buildProgressBar() {
    final percentage = attempt.score / 100;
    final scoreColor = _getScoreColor(attempt.score);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Progresso',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage,
            minHeight: 12,
            backgroundColor: Colors.grey[300],
            valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
          ),
        ),
      ],
    );
  }

  String _maskUserId(String userId) {
    if (userId.length <= 8) return 'user-***';
    return '${userId.substring(0, 4)}***${userId.substring(userId.length - 4)}';
  }
}
