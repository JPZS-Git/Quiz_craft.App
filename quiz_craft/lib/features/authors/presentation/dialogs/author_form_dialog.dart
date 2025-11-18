import 'package:flutter/material.dart';
import '../../infrastructure/dtos/author_dto.dart';
import '../../infrastructure/local/authors_local_dao_shared_prefs.dart';

/// Exibe um diálogo para criar ou editar um autor.
///
/// Se [author] for fornecido, o formulário é pré-preenchido para edição.
/// Caso contrário, o formulário permite criar um novo autor.
Future<void> showAuthorFormDialog(
  BuildContext context, {
  AuthorDto? author,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AuthorFormDialog(author: author),
  );
}

class _AuthorFormDialog extends StatefulWidget {
  final AuthorDto? author;

  const _AuthorFormDialog({this.author});

  @override
  State<_AuthorFormDialog> createState() => _AuthorFormDialogState();
}

class _AuthorFormDialogState extends State<_AuthorFormDialog> {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _avatarUrlController = TextEditingController();
  final _bioController = TextEditingController();
  final _topicsController = TextEditingController();
  final _dao = AuthorsLocalDaoSharedPrefs();
  
  double _rating = 0.0;
  bool _isActive = true;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.author != null) {
      _nameController.text = widget.author!.name;
      _emailController.text = widget.author!.email ?? '';
      _avatarUrlController.text = widget.author!.avatarUrl ?? '';
      _bioController.text = widget.author!.bio ?? '';
      _topicsController.text = widget.author!.topics.join(', ');
      _rating = widget.author!.rating;
      _isActive = widget.author!.isActive;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _avatarUrlController.dispose();
    _bioController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  String _formatDateTime(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Color _getRatingColor(double rating) {
    if (rating >= 4.0) return Colors.amber;
    if (rating >= 3.0) return Colors.orange;
    return Colors.red;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      // Processar tópicos
      final topicsText = _topicsController.text.trim();
      final topicsList = topicsText.isEmpty
          ? <String>[]
          : topicsText.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

      final authorToSave = AuthorDto(
        id: widget.author?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        email: _emailController.text.trim().isEmpty ? null : _emailController.text.trim(),
        avatarUrl: _avatarUrlController.text.trim().isEmpty ? null : _avatarUrlController.text.trim(),
        bio: _bioController.text.trim().isEmpty ? null : _bioController.text.trim(),
        topics: topicsList,
        quizzesCount: widget.author?.quizzesCount ?? 0,
        rating: _rating,
        isActive: _isActive,
        createdAt: widget.author?.createdAt ?? DateTime.now().toIso8601String(),
      );

      await _dao.update(authorToSave);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Autor atualizado com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar autor: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.author != null;
    final statusColor = _isActive ? Colors.green : Colors.grey;
    final ratingColor = _getRatingColor(_rating);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryBlue.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isEditing ? Icons.edit : Icons.add,
              color: _primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              isEditing ? 'Editar Autor' : 'Novo Autor',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Informações read-only
              if (isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildReadOnlyRow(Icons.fingerprint, 'ID', widget.author!.id.length > 20 ? '${widget.author!.id.substring(0, 20)}...' : widget.author!.id),
                      const SizedBox(height: 6),
                      _buildReadOnlyRow(Icons.quiz, 'Quizzes criados', '${widget.author!.quizzesCount} quizzes'),
                      const SizedBox(height: 6),
                      _buildReadOnlyRow(Icons.calendar_today, 'Criado em', _formatDateTime(widget.author!.createdAt)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Campo: Nome completo
              TextFormField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Nome completo',
                  hintText: 'Digite o nome completo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.person, color: _primaryBlue),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O nome é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Campo: Email
              TextFormField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email (opcional)',
                  hintText: 'exemplo@dominio.com',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.email, color: _primaryBlue),
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Opcional
                  }
                  final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
                  if (!emailRegex.hasMatch(value.trim())) {
                    return 'Email inválido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Campo: URL do Avatar
              TextFormField(
                controller: _avatarUrlController,
                decoration: InputDecoration(
                  labelText: 'URL da imagem do avatar (opcional)',
                  hintText: 'https://example.com/avatar.jpg',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.image, color: _primaryBlue),
                ),
                keyboardType: TextInputType.url,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Opcional
                  }
                  final urlRegex = RegExp(r'^https?://');
                  if (!urlRegex.hasMatch(value.trim())) {
                    return 'URL deve começar com http:// ou https://';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Campo: Biografia
              TextFormField(
                controller: _bioController,
                decoration: InputDecoration(
                  labelText: 'Biografia (opcional)',
                  hintText: 'Descreva o autor',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.description, color: _primaryBlue),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 14),

              // Campo: Tópicos
              TextFormField(
                controller: _topicsController,
                decoration: InputDecoration(
                  labelText: 'Tópicos de especialidade (separados por vírgula)',
                  hintText: 'Dart, Flutter, Mobile',
                  helperText: _topicsController.text.trim().isEmpty 
                      ? '0 tópicos' 
                      : '${_topicsController.text.split(',').where((t) => t.trim().isNotEmpty).length} tópicos',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.label, color: _primaryBlue),
                ),
                onChanged: (_) => setState(() {}), // Atualizar contador
              ),
              const SizedBox(height: 16),

              // Campo: Avaliação (Slider)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Avaliação', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: ratingColor.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: ratingColor,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(Icons.star, color: ratingColor, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Slider(
                    value: _rating,
                    min: 0.0,
                    max: 5.0,
                    divisions: 10,
                    thumbColor: ratingColor,
                    label: _rating.toStringAsFixed(1),
                    onChanged: (value) {
                      setState(() => _rating = value);
                    },
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('0.0', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                      Text('5.0', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Campo: Status ativo (Switch)
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SwitchListTile(
                  title: const Text('Autor ativo', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500)),
                  value: _isActive,
                  onChanged: (value) {
                    setState(() => _isActive = value);
                  },
                  activeTrackColor: Colors.green.withValues(alpha: 0.5),
                  activeThumbColor: Colors.green,
                  secondary: Icon(
                    _isActive ? Icons.check_circle : Icons.cancel,
                    color: statusColor,
                    size: 28,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Badge visual do status
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: statusColor.withValues(alpha: 0.4)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(_isActive ? Icons.check_circle : Icons.cancel, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isActive ? 'ATIVO' : 'INATIVO',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: statusColor,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      actions: [
        // Botão Cancelar
        TextButton.icon(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close, size: 20),
          label: const Text('Cancelar'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),

        // Botão Salvar
        ElevatedButton.icon(
          onPressed: _saving ? null : _handleSave,
          icon: _saving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Icon(Icons.save, size: 20),
          label: Text(_saving ? 'Salvando...' : 'Salvar'),
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildReadOnlyRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: Colors.grey[700]),
        const SizedBox(width: 6),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(color: Colors.grey[800], fontSize: 12),
              children: [
                TextSpan(text: '$label: ', style: const TextStyle(fontWeight: FontWeight.w600)),
                TextSpan(text: value),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
