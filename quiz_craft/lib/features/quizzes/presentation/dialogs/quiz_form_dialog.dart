import 'package:flutter/material.dart';
import '../../infrastructure/dtos/quiz_dto.dart';
import '../../infrastructure/local/quizzes_local_dao_shared_prefs.dart';

Future<void> showQuizFormDialog(
  BuildContext context, {
  QuizDto? quiz,
}) async {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext context) {
      return _QuizFormDialog(quiz: quiz);
    },
  );
}

class _QuizFormDialog extends StatefulWidget {
  final QuizDto? quiz;

  const _QuizFormDialog({this.quiz});

  @override
  State<_QuizFormDialog> createState() => _QuizFormDialogState();
}

class _QuizFormDialogState extends State<_QuizFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _authorIdController = TextEditingController();
  final _topicsController = TextEditingController();
  
  bool _isPublished = false;
  bool _saving = false;

  static const _primaryBlue = Color(0xFF2563EB);

  @override
  void initState() {
    super.initState();
    if (widget.quiz != null) {
      _titleController.text = widget.quiz!.title;
      _descriptionController.text = widget.quiz!.description ?? '';
      _authorIdController.text = widget.quiz!.authorId ?? '';
      _topicsController.text = widget.quiz!.topics.join(', ');
      _isPublished = widget.quiz!.isPublished;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _authorIdController.dispose();
    _topicsController.dispose();
    super.dispose();
  }

  int get _topicsCount {
    final text = _topicsController.text.trim();
    if (text.isEmpty) return 0;
    return text.split(',').where((s) => s.trim().isNotEmpty).length;
  }

  String _formatDate(String isoDate) {
    try {
      final date = DateTime.parse(isoDate);
      final day = date.day.toString().padLeft(2, '0');
      final month = date.month.toString().padLeft(2, '0');
      final year = date.year.toString();
      return '$day/$month/$year';
    } catch (e) {
      return isoDate;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _saving = true;
    });

    try {
      final topicsText = _topicsController.text.trim();
      final topicsList = topicsText.isEmpty
          ? <String>[]
          : topicsText.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

      final dao = QuizzesLocalDaoSharedPrefs();

      if (widget.quiz != null) {
        // Atualizar quiz existente
        final updatedQuiz = QuizDto(
          id: widget.quiz!.id,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          authorId: _authorIdController.text.trim().isEmpty 
              ? null 
              : _authorIdController.text.trim(),
          topics: topicsList,
          questions: widget.quiz!.questions,
          isPublished: _isPublished,
          createdAt: widget.quiz!.createdAt,
        );

        await dao.update(updatedQuiz);

        if (!mounted) return;
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz atualizado com sucesso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        // Criar novo quiz
        final newQuiz = QuizDto(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim().isEmpty 
              ? null 
              : _descriptionController.text.trim(),
          authorId: _authorIdController.text.trim().isEmpty 
              ? null 
              : _authorIdController.text.trim(),
          topics: topicsList,
          questions: const [],
          isPublished: _isPublished,
        );

        await dao.add(newQuiz);

        if (!mounted) return;
        
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Quiz criado com sucesso'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar quiz: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.quiz != null;

    return AlertDialog(
      title: Row(
        children: [
          Icon(isEditing ? Icons.edit : Icons.add, color: _primaryBlue),
          const SizedBox(width: 8),
          Text(isEditing ? 'Editar Quiz' : 'Criar Quiz'),
        ],
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Read-only information section
              if (isEditing) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              'ID: ${widget.quiz!.id}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.quiz, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            '${widget.quiz!.questions.length} questões',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16, color: Colors.grey),
                          const SizedBox(width: 4),
                          Text(
                            'Criado: ${_formatDate(widget.quiz!.createdAt)}',
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Title field
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título do quiz',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Título é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Description field
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Descrição (opcional)',
                  border: OutlineInputBorder(),
                ),
                minLines: 3,
                maxLines: 6,
              ),
              const SizedBox(height: 16),

              // Author ID field
              TextFormField(
                controller: _authorIdController,
                decoration: const InputDecoration(
                  labelText: 'ID do autor (opcional)',
                  hintText: 'abc123...',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),

              // Topics field
              TextFormField(
                controller: _topicsController,
                decoration: InputDecoration(
                  labelText: 'Tópicos/Categorias (separados por vírgula)',
                  hintText: 'Dart, Flutter, Mobile',
                  border: const OutlineInputBorder(),
                  helperText: '$_topicsCount tópicos',
                ),
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 16),

              // Published status switch
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: SwitchListTile(
                  title: const Text('Quiz publicado'),
                  subtitle: Row(
                    children: [
                      Icon(
                        _isPublished ? Icons.check_circle : Icons.edit,
                        size: 16,
                        color: _isPublished ? Colors.green : Colors.orange,
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: _isPublished ? Colors.green : Colors.orange,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _isPublished ? 'PUBLICADO' : 'RASCUNHO',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  value: _isPublished,
                  activeThumbColor: Colors.green,
                  onChanged: (value) {
                    setState(() {
                      _isPublished = value;
                    });
                  },
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.of(context).pop(),
          child: const Text(
            'Cancelar',
            style: TextStyle(color: Colors.grey),
          ),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _handleSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryBlue,
            foregroundColor: Colors.white,
          ),
          child: _saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : const Text('Salvar'),
        ),
      ],
    );
  }
}
