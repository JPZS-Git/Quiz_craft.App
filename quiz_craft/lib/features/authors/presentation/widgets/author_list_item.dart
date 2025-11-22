import 'package:flutter/material.dart';
import '../../domain/entities/author_entity.dart';

/// Widget para renderizar um item de autor na lista.
/// 
/// Exibe um card com informações do autor incluindo:
/// - Avatar ou iniciais do nome em CircleAvatar
/// - Nome do autor
/// - Badge de status (ATIVO/INATIVO)
/// - Rating com cor baseada na avaliação
/// - Quantidade de quizzes criados
/// - Tópicos de especialidade (até 3 na visualização compacta)
/// - Botão de edição (opcional)
/// - Detalhes expandíveis com informações completas
class AuthorListItem extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AuthorEntity author;
  final bool isExpanded;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onEdit;
  final String initials;
  final String maskedEmail;

  const AuthorListItem({
    super.key,
    required this.author,
    required this.isExpanded,
    required this.onTap,
    this.onLongPress,
    this.onEdit,
    required this.initials,
    required this.maskedEmail,
  });

  @override
  Widget build(BuildContext context) {
    final ratingColor = author.rating >= 4.5 ? Colors.green : (author.rating >= 3.5 ? Colors.orange : Colors.red);
    
    return Card(
      color: Colors.white,
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: author.avatarUrl != null && author.avatarUrl!.isNotEmpty
                ? CircleAvatar(
                    radius: 28,
                    backgroundImage: NetworkImage(author.avatarUrl!),
                    backgroundColor: _primaryBlue.withValues(alpha: 0.2),
                  )
                : CircleAvatar(
                    radius: 28,
                    backgroundColor: _primaryBlue.withValues(alpha: 0.2),
                    child: Text(initials, style: const TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold)),
                  ),
            title: Row(
              children: [
                Expanded(
                  child: Text(author.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: (author.isActive ? Colors.green : Colors.grey).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    author.isActive ? 'ATIVO' : 'INATIVO',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                      color: author.isActive ? Colors.green : Colors.grey,
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
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: ratingColor),
                      const SizedBox(width: 4),
                      Text(author.rating.toStringAsFixed(1), style: TextStyle(fontWeight: FontWeight.bold, color: ratingColor)),
                      const SizedBox(width: 16),
                      Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
                      const SizedBox(width: 4),
                      Text('${author.quizzesCount} quizzes', style: TextStyle(color: Colors.grey[700], fontSize: 13)),
                    ],
                  ),
                  if (author.topics.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: author.topics.take(3).map((t) => _chip(t)).toList(),
                    ),
                  ],
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
                    tooltip: 'Editar autor',
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
          _row(Icons.fingerprint, 'ID', author.id),
          const SizedBox(height: 8),
          _row(Icons.email, 'Email', maskedEmail),
          if (author.bio != null && author.bio!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _row(Icons.info_outline, 'Biografia', author.bio!),
          ],
          const SizedBox(height: 8),
          _row(Icons.calendar_today, 'Cadastrado', _date(author.createdAt)),
          if (author.topics.length > 3) ...[
            const SizedBox(height: 12),
            Text('Todos os tópicos', style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
            const SizedBox(height: 8),
            Wrap(spacing: 6, runSpacing: 6, children: author.topics.map(_chip).toList()),
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

  String _date(DateTime d) {
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }
}
