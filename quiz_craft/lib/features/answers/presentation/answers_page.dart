import 'package:flutter/material.dart';
import '../infrastructure/local/answers_local_dao_shared_prefs.dart';
import '../infrastructure/dtos/answer_dto.dart';

/// Página de listagem de respostas (Answers).
/// Exibe respostas armazenadas localmente com indicação de correção.
class AnswersPage extends StatefulWidget {
  static const routeName = '/answers';

  const AnswersPage({super.key});

  @override
  State<AnswersPage> createState() => _AnswersPageState();
}

class _AnswersPageState extends State<AnswersPage> {
  // Paleta de cores
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  final _dao = AnswersLocalDaoSharedPrefs();
  List<AnswerDto> _answers = [];
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadAnswers();
  }

  Future<void> _loadAnswers() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final answers = await _dao.listAll();
      if (!mounted) return;
      
      // Ordenar alfabeticamente por texto
      answers.sort((a, b) => a.text.compareTo(b.text));

      setState(() {
        _answers = answers;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar respostas';
        _loading = false;
      });
    }
  }

  void _toggleExpand(String id) {
    setState(() {
      if (_expandedIds.contains(id)) {
        _expandedIds.remove(id);
      } else {
        _expandedIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBackground,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 2,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Respostas',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Tooltip(
            message: 'Recarregar',
            waitDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Recarregar',
              icon: const Icon(Icons.refresh, color: Colors.white),
              splashRadius: 24,
              onPressed: _loadAnswers,
            ),
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(_primaryBlue),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _loadAnswers,
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32),
                ),
                elevation: 4,
              ),
            ),
          ],
        ),
      );
    }

    if (_answers.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.question_answer_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma resposta encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Adicione respostas para visualizá-las aqui',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadAnswers,
      child: ListView.builder(
        itemCount: _answers.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final answer = _answers[index];
          return _AnswerListItem(
            answer: answer,
            isExpanded: _expandedIds.contains(answer.id),
            onTap: () => _toggleExpand(answer.id),
          );
        },
      ),
    );
  }
}

/// Widget para renderizar um item de resposta na lista.
class _AnswerListItem extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final AnswerDto answer;
  final bool isExpanded;
  final VoidCallback onTap;

  const _AnswerListItem({
    required this.answer,
    required this.isExpanded,
    required this.onTap,
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
            trailing: Icon(
              isExpanded ? Icons.expand_less : Icons.expand_more,
              color: _primaryBlue,
            ),
            onTap: onTap,
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
