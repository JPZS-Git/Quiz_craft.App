import 'package:flutter/material.dart';
import '../infrastructure/local/questions_local_dao_shared_prefs.dart';
import '../infrastructure/dtos/question_dto.dart';

/// Página de listagem de questões (Questions).
/// Exibe questões armazenadas localmente com suporte a expansão de respostas.
class QuestionsPage extends StatefulWidget {
  static const routeName = '/questions';

  const QuestionsPage({super.key});

  @override
  State<QuestionsPage> createState() => _QuestionsPageState();
}

class _QuestionsPageState extends State<QuestionsPage> {
  // Paleta de cores (seguindo padrão da home_page.dart)
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  final _dao = QuestionsLocalDaoSharedPrefs();
  List<QuestionDto> _questions = [];
  bool _loading = true;
  String? _errorMessage;
  final Set<String> _expandedIds = {};

  @override
  void initState() {
    super.initState();
    _loadQuestions();
  }

  Future<void> _loadQuestions() async {
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      final questions = await _dao.listAll();
      if (!mounted) return;
      
      setState(() {
        _questions = questions;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      
      setState(() {
        _errorMessage = 'Erro ao carregar questões';
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
        title: const Text(
          'Questões',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
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
              onPressed: _loadQuestions,
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
              onPressed: _loadQuestions,
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

    if (_questions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.quiz_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'Nenhuma questão encontrada',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: _primaryBlue,
      onRefresh: _loadQuestions,
      child: ListView.builder(
        itemCount: _questions.length,
        padding: const EdgeInsets.all(16),
        itemBuilder: (context, index) {
          final question = _questions[index];
          return _QuestionListItem(
            question: question,
            isExpanded: _expandedIds.contains(question.id),
            onTap: () => _toggleExpand(question.id),
          );
        },
      ),
    );
  }
}

/// Widget para renderizar um item de questão na lista.
class _QuestionListItem extends StatelessWidget {
  static const Color _primaryBlue = Color(0xFF2563EB);

  final QuestionDto question;
  final bool isExpanded;
  final VoidCallback onTap;

  const _QuestionListItem({
    required this.question,
    required this.isExpanded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAnswers = question.answers.isNotEmpty;
    
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
              backgroundColor: _primaryBlue,
              child: Text(
                '${question.order}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              question.text,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            subtitle: hasAnswers
                ? Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      '${question.answers.length} resposta${question.answers.length != 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  )
                : null,
            trailing: hasAnswers
                ? Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: _primaryBlue,
                  )
                : null,
            onTap: hasAnswers ? onTap : null,
          ),
          if (isExpanded && hasAnswers) _buildAnswersList(),
        ],
      ),
    );
  }

  Widget _buildAnswersList() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Divider(),
          const Text(
            'Respostas:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 8),
          ...question.answers.map((answer) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    answer.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 20,
                    color: answer.isCorrect ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      answer.text,
                      style: TextStyle(
                        fontSize: 14,
                        color: answer.isCorrect ? Colors.green[800] : Colors.black87,
                        fontWeight: answer.isCorrect ? FontWeight.w500 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
