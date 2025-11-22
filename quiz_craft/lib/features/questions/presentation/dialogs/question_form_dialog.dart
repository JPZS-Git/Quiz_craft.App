import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../domain/entities/question_entity.dart';
import '../../services/question_sync_service.dart';
import '../../infrastructure/repositories/question_supabase_repository.dart';
import '../../infrastructure/local/questions_local_dao_shared_prefs.dart';

/// Exibe um diálogo para criar ou editar uma questão.
///
/// Se [question] for fornecido, o formulário é pré-preenchido para edição.
/// Caso contrário, o formulário permite criar uma nova questão.
/// [quizId] é obrigatório para criar novas questões.
Future<void> showQuestionFormDialog(
  BuildContext context, {
  QuestionEntity? question,
  String? quizId,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _QuestionFormDialog(
      question: question,
      quizId: quizId,
    ),
  );
}

class _QuestionFormDialog extends StatefulWidget {
  final QuestionEntity? question;
  final String? quizId;

  const _QuestionFormDialog({
    this.question,
    this.quizId,
  });

  @override
  State<_QuestionFormDialog> createState() => _QuestionFormDialogState();
}

class _QuestionFormDialogState extends State<_QuestionFormDialog> {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  final _orderController = TextEditingController();
  late final QuestionSyncService _syncService;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializa serviço de sincronização
    final localDao = QuestionsLocalDaoSharedPrefs();
    final repository = QuestionSupabaseRepository(localDao);
    _syncService = QuestionSyncService(repository);
    
    if (widget.question != null) {
      _textController.text = widget.question!.text;
      _orderController.text = widget.question!.order.toString();
    }
  }

  @override
  void dispose() {
    _syncService.dispose();
    _textController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      // Usa quizId da questão existente ou do parâmetro
      final effectiveQuizId = widget.question?.quizId ?? widget.quizId ?? '';
      
      if (effectiveQuizId.isEmpty) {
        throw Exception('Quiz ID é obrigatório para criar/editar questões');
      }

      final questionToSave = QuestionEntity(
        id: widget.question?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        quizId: effectiveQuizId,
        text: _textController.text.trim(),
        order: int.parse(_orderController.text.trim()),
        answers: widget.question?.answers ?? [],
      );

      if (widget.question != null) {
        await _syncService.updateQuestion(questionToSave);
      } else {
        await _syncService.createQuestion(questionToSave);
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.question != null 
            ? 'Questão atualizada com sucesso' 
            : 'Questão criada com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar questão: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.question != null;
    final answersCount = widget.question?.answers.length ?? 0;

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
          Text(
            isEditing ? 'Editar Questão' : 'Nova Questão',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              // Campo: Texto da questão
              TextFormField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Texto da questão',
                  hintText: 'Digite o texto da questão',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.quiz, color: _primaryBlue),
                ),
                minLines: 3,
                maxLines: 6,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O texto da questão é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Ordem
              TextFormField(
                controller: _orderController,
                decoration: InputDecoration(
                  labelText: 'Ordem de exibição',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.format_list_numbered, color: _primaryBlue),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'A ordem é obrigatória';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 0) {
                    return 'Ordem deve ser um número inteiro ≥ 0';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Informação: Quantidade de respostas (read-only)
              if (isEditing)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.quiz, size: 20, color: Colors.grey[700]),
                      const SizedBox(width: 8),
                      Text(
                        '$answersCount ${answersCount == 1 ? 'resposta associada' : 'respostas associadas'}',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
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
}
