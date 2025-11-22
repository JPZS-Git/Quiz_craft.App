import 'package:flutter/material.dart';
import '../../domain/entities/answer_entity.dart';
import '../../services/answer_sync_service.dart';
import '../../infrastructure/repositories/answer_supabase_repository.dart';
import '../../infrastructure/local/answers_local_dao_shared_prefs.dart';

/// Exibe um diálogo para criar ou editar uma resposta.
///
/// Se [answer] for fornecido, o formulário é pré-preenchido para edição.
/// Caso contrário, o formulário permite criar uma nova resposta.
/// [questionId] é obrigatório para criar novas respostas.
Future<void> showAnswerFormDialog(
  BuildContext context, {
  AnswerEntity? answer,
  String? questionId,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AnswerFormDialog(
      answer: answer,
      questionId: questionId,
    ),
  );
}

class _AnswerFormDialog extends StatefulWidget {
  final AnswerEntity? answer;
  final String? questionId;

  const _AnswerFormDialog({
    this.answer,
    this.questionId,
  });

  @override
  State<_AnswerFormDialog> createState() => _AnswerFormDialogState();
}

class _AnswerFormDialogState extends State<_AnswerFormDialog> {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _textController = TextEditingController();
  late final AnswerSyncService _syncService;
  bool _isCorrect = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    
    // Inicializa serviço de sincronização
    final localDao = AnswersLocalDaoSharedPrefs();
    final repository = AnswerSupabaseRepository(localDao);
    _syncService = AnswerSyncService(repository);
    
    if (widget.answer != null) {
      _textController.text = widget.answer!.text;
      _isCorrect = widget.answer!.isCorrect;
    }
  }

  @override
  void dispose() {
    _syncService.dispose();
    _textController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      // Usa questionId da resposta existente ou do parâmetro
      final effectiveQuestionId = widget.answer?.questionId ?? widget.questionId ?? '';
      
      if (effectiveQuestionId.isEmpty) {
        throw Exception('Question ID é obrigatório para criar/editar respostas');
      }

      final answerToSave = AnswerEntity(
        id: widget.answer?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        questionId: effectiveQuestionId,
        text: _textController.text.trim(),
        isCorrect: _isCorrect,
      );

      if (widget.answer != null) {
        await _syncService.updateAnswer(answerToSave);
      } else {
        await _syncService.createAnswer(answerToSave);
      }

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(widget.answer != null 
            ? 'Resposta atualizada com sucesso' 
            : 'Resposta criada com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar resposta: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.answer != null;
    final statusColor = _isCorrect ? Colors.green : Colors.grey;
    final statusIcon = _isCorrect ? Icons.check_circle : Icons.radio_button_unchecked;

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
            isEditing ? 'Editar Resposta' : 'Nova Resposta',
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
              // Campo: Texto da resposta
              TextFormField(
                controller: _textController,
                decoration: InputDecoration(
                  labelText: 'Texto da resposta',
                  hintText: 'Digite o texto da resposta',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.question_answer, color: _primaryBlue),
                ),
                minLines: 2,
                maxLines: 5,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'O texto da resposta é obrigatório';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // CheckboxListTile: É a resposta correta?
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: CheckboxListTile(
                  title: const Text(
                    'Marcar como resposta correta',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                  value: _isCorrect,
                  onChanged: (value) {
                    setState(() {
                      _isCorrect = value ?? false;
                    });
                  },
                  activeColor: Colors.green,
                  checkColor: Colors.white,
                  secondary: Icon(
                    statusIcon,
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
                      Icon(statusIcon, color: statusColor, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        _isCorrect ? 'CORRETA' : 'Incorreta',
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
}
