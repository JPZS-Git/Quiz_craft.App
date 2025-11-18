import 'package:flutter/material.dart';
import '../../infrastructure/dtos/author_dto.dart';

/// Diálogo de ações para um autor selecionado.
/// Exibe opções: Editar, Remover e Fechar.
/// 
/// Exemplo de uso:
/// ```dart
/// showAuthorActionsDialog(
///   context,
///   author,
///   onEdit: () => _handleEdit(author),
///   onRemove: () => _handleRemove(author),
/// );
/// ```
Future<void> showAuthorActionsDialog(
  BuildContext context,
  AuthorDto author, {
  required VoidCallback onEdit,
  required VoidCallback onRemove,
}) async {
  await showDialog<void>(
    context: context,
    barrierDismissible: false, // Não permite fechar clicando fora
    builder: (context) => _AuthorActionsDialog(
      author: author,
      onEdit: onEdit,
      onRemove: onRemove,
    ),
  );
}

class _AuthorActionsDialog extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AuthorDto author;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  const _AuthorActionsDialog({
    required this.author,
    required this.onEdit,
    required this.onRemove,
  });

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '';
    if (parts.length == 1) {
      return parts[0].substring(0, parts[0].length >= 2 ? 2 : 1).toUpperCase();
    }
    final first = parts[0].characters.first;
    final last = parts[parts.length - 1].characters.first;
    return (first + last).toUpperCase();
  }

  String _maskEmail(String? email) {
    if (email == null || email.isEmpty) return 'Email não informado';
    
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return email;
    
    final localPart = email.substring(0, atIndex);
    final domain = email.substring(atIndex);
    
    if (localPart.length <= 2) {
      return '${localPart[0]}***$domain';
    }
    
    return '${localPart[0]}***${localPart[localPart.length - 1]}$domain';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.5) return Colors.green;
    if (rating >= 3.5) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final ratingColor = _getRatingColor(author.rating);
    final statusColor = author.isActive ? Colors.green : Colors.grey;
    
    return AlertDialog(
      title: const Text('Ações do Autor'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 28,
                backgroundColor: _primaryBlue.withValues(alpha: 0.2),
                backgroundImage: author.avatarUrl != null && author.avatarUrl!.isNotEmpty
                    ? NetworkImage(author.avatarUrl!)
                    : null,
                child: author.avatarUrl == null || author.avatarUrl!.isEmpty
                    ? Text(
                        _getInitials(author.name),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: _primaryBlue,
                        ),
                      )
                    : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      author.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _maskEmail(author.email),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.star, size: 16, color: ratingColor),
              const SizedBox(width: 4),
              Text(
                author.rating.toStringAsFixed(1),
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: ratingColor,
                ),
              ),
              const SizedBox(width: 12),
              Icon(Icons.quiz, size: 16, color: Colors.grey[600]),
              const SizedBox(width: 4),
              Text(
                '${author.quizzesCount} quizzes',
                style: TextStyle(fontSize: 13, color: Colors.grey[700]),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  author.isActive ? 'ATIVO' : 'INATIVO',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 10,
                    color: statusColor,
                  ),
                ),
              ),
            ],
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
