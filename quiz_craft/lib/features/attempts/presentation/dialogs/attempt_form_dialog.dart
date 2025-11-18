import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../infrastructure/dtos/attempt_dto.dart';
import '../../infrastructure/local/attempts_local_dao_shared_prefs.dart';

/// Exibe um diálogo para criar ou editar uma tentativa de quiz.
///
/// Se [attempt] for fornecido, o formulário é pré-preenchido para edição.
/// Caso contrário, o formulário permite criar uma nova tentativa.
Future<void> showAttemptFormDialog(
  BuildContext context, {
  AttemptDto? attempt,
}) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => _AttemptFormDialog(attempt: attempt),
  );
}

class _AttemptFormDialog extends StatefulWidget {
  final AttemptDto? attempt;

  const _AttemptFormDialog({this.attempt});

  @override
  State<_AttemptFormDialog> createState() => _AttemptFormDialogState();
}

class _AttemptFormDialogState extends State<_AttemptFormDialog> {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final _formKey = GlobalKey<FormState>();
  final _correctCountController = TextEditingController();
  final _totalCountController = TextEditingController();
  final _finishedAtController = TextEditingController();
  final _dao = AttemptsLocalDaoSharedPrefs();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    if (widget.attempt != null) {
      _correctCountController.text = widget.attempt!.correctCount.toString();
      _totalCountController.text = widget.attempt!.totalCount.toString();
      if (widget.attempt!.finishedAt != null) {
        _finishedAtController.text = _formatDateTime(widget.attempt!.finishedAt!);
      }
    }
  }

  @override
  void dispose() {
    _correctCountController.dispose();
    _totalCountController.dispose();
    _finishedAtController.dispose();
    super.dispose();
  }

  String _formatDateTime(String isoDate) {
    final date = DateTime.tryParse(isoDate);
    if (date == null) return '';
    
    // Formato dd/MM/yyyy HH:mm
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year} '
           '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }

  String? _parseDateTime(String formatted) {
    if (formatted.trim().isEmpty) return null;
    
    // Tenta parsear dd/MM/yyyy HH:mm
    final regex = RegExp(r'^(\d{2})/(\d{2})/(\d{4})\s+(\d{2}):(\d{2})$');
    final match = regex.firstMatch(formatted.trim());
    
    if (match == null) return null;
    
    final day = int.tryParse(match.group(1)!);
    final month = int.tryParse(match.group(2)!);
    final year = int.tryParse(match.group(3)!);
    final hour = int.tryParse(match.group(4)!);
    final minute = int.tryParse(match.group(5)!);
    
    if (day == null || month == null || year == null || hour == null || minute == null) {
      return null;
    }
    
    try {
      final date = DateTime(year, month, day, hour, minute);
      return date.toIso8601String();
    } catch (e) {
      return null;
    }
  }

  double _calculateScore(int correct, int total) {
    if (total == 0) return 0.0;
    return (correct / total) * 100;
  }

  Color _getScoreColor(double score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.orange;
    return Colors.red;
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _saving = true);

    try {
      final correctCount = int.parse(_correctCountController.text.trim());
      final totalCount = int.parse(_totalCountController.text.trim());
      final score = _calculateScore(correctCount, totalCount);
      
      String? finishedAt;
      final finishedText = _finishedAtController.text.trim();
      if (finishedText.isNotEmpty) {
        finishedAt = _parseDateTime(finishedText);
        if (finishedAt == null) {
          throw Exception('Formato de data inválido');
        }
      }

      final attemptToSave = AttemptDto(
        id: widget.attempt?.id ?? DateTime.now().millisecondsSinceEpoch.toString(),
        quizId: widget.attempt?.quizId ?? '',
        userId: widget.attempt?.userId,
        correctCount: correctCount,
        totalCount: totalCount,
        score: score,
        startedAt: widget.attempt?.startedAt ?? DateTime.now().toIso8601String(),
        finishedAt: finishedAt,
      );

      await _dao.update(attemptToSave);

      if (!mounted) return;

      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tentativa atualizada com sucesso'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() => _saving = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao salvar tentativa: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.attempt != null;
    
    // Calcular score em tempo real
    double currentScore = 0;
    if (_correctCountController.text.isNotEmpty && _totalCountController.text.isNotEmpty) {
      final correct = int.tryParse(_correctCountController.text) ?? 0;
      final total = int.tryParse(_totalCountController.text) ?? 1;
      currentScore = _calculateScore(correct, total);
    }
    final scoreColor = _getScoreColor(currentScore);

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
            isEditing ? 'Editar Tentativa' : 'Nova Tentativa',
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
                      _buildReadOnlyField(
                        Icons.quiz,
                        'Quiz ID',
                        widget.attempt!.quizId.length > 20
                            ? '${widget.attempt!.quizId.substring(0, 20)}...'
                            : widget.attempt!.quizId,
                      ),
                      const SizedBox(height: 8),
                      _buildReadOnlyField(
                        Icons.calendar_today,
                        'Iniciado em',
                        _formatDateTime(widget.attempt!.startedAt),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Campo: Respostas corretas
              TextFormField(
                controller: _correctCountController,
                decoration: InputDecoration(
                  labelText: 'Respostas corretas',
                  hintText: '0',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.check_circle, color: Colors.green),
                ),
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (_) => setState(() {}), // Recalcular score
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 0) {
                    return 'Deve ser um número ≥ 0';
                  }
                  
                  // Validar contra totalCount
                  final totalText = _totalCountController.text.trim();
                  if (totalText.isNotEmpty) {
                    final total = int.tryParse(totalText);
                    if (total != null && number > total) {
                      return 'Não pode ser maior que o total';
                    }
                  }
                  
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Campo: Total de questões
              TextFormField(
                controller: _totalCountController,
                decoration: InputDecoration(
                  labelText: 'Total de questões',
                  hintText: '1',
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
                onChanged: (_) => setState(() {}), // Recalcular score
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Campo obrigatório';
                  }
                  final number = int.tryParse(value.trim());
                  if (number == null || number < 1) {
                    return 'Deve ser um número ≥ 1';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Score calculado (badge)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.grade, size: 20, color: scoreColor),
                    const SizedBox(width: 8),
                    Text(
                      'Score: ${currentScore.toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: 14,
                        color: scoreColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Campo: Data de conclusão (opcional)
              TextFormField(
                controller: _finishedAtController,
                decoration: InputDecoration(
                  labelText: 'Data de conclusão (opcional)',
                  hintText: 'dd/MM/yyyy HH:mm',
                  helperText: 'Deixe vazio se ainda não concluído',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryBlue, width: 2),
                  ),
                  prefixIcon: const Icon(Icons.event_available, color: _primaryBlue),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return null; // Opcional
                  }
                  
                  final parsed = _parseDateTime(value.trim());
                  if (parsed == null) {
                    return 'Formato inválido. Use: dd/MM/yyyy HH:mm';
                  }
                  
                  return null;
                },
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

  Widget _buildReadOnlyField(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
