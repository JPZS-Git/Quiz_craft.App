import 'package:flutter/material.dart';
import '../../infrastructure/dtos/quiz_dto.dart';

/// Widget para renderizar um item de quiz na lista.
/// 
/// Exibe um card com informações do quiz incluindo:
/// - Título do quiz
/// - Badge de status (PUBLICADO/RASCUNHO)
/// - Descrição (se disponível)
/// - Botão de edição (opcional)
/// - Quantidade de perguntas
/// - Tempo estimado de conclusão
/// - Tópicos do quiz (até 3 na visualização compacta)
/// - Detalhes expandíveis com informações completas
class QuizListItem extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final QuizDto quiz;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final int estimatedTime;

  const QuizListItem({
    super.key,
    required this.quiz,
    required this.isExpanded,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
    required this.estimatedTime,
  });

  @override
  Widget build(BuildContext context) {
    final questionsCount = quiz.questions.length;
    
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    quiz.title,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (quiz.isPublished ? Colors.green : Colors.orange).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    quiz.isPublished ? 'PUBLICADO' : 'RASCUNHO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: quiz.isPublished ? Colors.green : Colors.orange,
                    ),
                  ),
                ),
              ],
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (quiz.description != null && quiz.description!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        quiz.description!,
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        maxLines: isExpanded ? null : 2,
                        overflow: isExpanded ? null : TextOverflow.ellipsis,
                      ),
                    ),
                  Row(
                    children: [
                      if (onEdit != null) ...[
                        IconButton(
                          icon: const Icon(Icons.edit, color: _primaryBlue),
                          iconSize: 20,
                          splashRadius: 20,
                          tooltip: 'Editar quiz',
                          onPressed: onEdit,
                        ),
                        const SizedBox(width: 4),
                      ],
                      Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '$questionsCount perguntas',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                      const SizedBox(width: 16),
                      Icon(Icons.access_time, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text(
                        '~$estimatedTime min',
                        style: TextStyle(color: Colors.grey[700], fontSize: 13),
                      ),
                    ],
                  ),
                  if (quiz.topics.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: quiz.topics.take(isExpanded ? quiz.topics.length : 3).map((t) => _chip(t)).toList(),
                    ),
                  ],
                ],
              ),
            ),
            trailing: Icon(isExpanded ? Icons.expand_less : Icons.expand_more, color: _primaryBlue),
            onTap: onTap,
            onLongPress: onLongPress,
          ),
          if (isExpanded) _details(),
        ],
      ),
    );
  }

  Widget _chip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: _primaryBlue.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _primaryBlue.withValues(alpha: 0.3)),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, color: _primaryBlue, fontWeight: FontWeight.w500)),
    );
  }

  Widget _details() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const SizedBox(height: 8),
          _row(Icons.fingerprint, 'ID', quiz.id),
          if (quiz.authorId != null) ...[
            const SizedBox(height: 8),
            _row(Icons.person, 'Autor ID', quiz.authorId!),
          ],
          const SizedBox(height: 8),
          _row(Icons.calendar_today, 'Criado em', _date(quiz.createdAt)),
          const SizedBox(height: 8),
          _row(
            quiz.isPublished ? Icons.check_circle : Icons.edit,
            'Status',
            quiz.isPublished ? 'Publicado e disponível' : 'Rascunho (não público)',
          ),
          if (quiz.questions.isEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Este quiz ainda não possui perguntas',
                      style: TextStyle(color: Colors.orange[800], fontSize: 13),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.grey[600]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 2),
              Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }

  String _date(String iso) {
    final d = DateTime.tryParse(iso);
    if (d == null) return iso;
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
