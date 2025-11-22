import 'package:flutter/material.dart';
import '../../quizzes/domain/entities/quiz_entity.dart';
import '../../quizzes/services/quiz_sync_service.dart';
import '../../quizzes/infrastructure/repositories/quiz_supabase_repository.dart';
import '../../quizzes/infrastructure/local/quizzes_local_dao_shared_prefs.dart';
import '../../questions/domain/entities/question_entity.dart';
import '../../questions/services/question_sync_service.dart';
import '../../questions/infrastructure/repositories/question_supabase_repository.dart';
import '../../questions/infrastructure/local/questions_local_dao_shared_prefs.dart';
import '../../answers/domain/entities/answer_entity.dart';
import '../../answers/services/answer_sync_service.dart';
import '../../answers/infrastructure/repositories/answer_supabase_repository.dart';
import '../../answers/infrastructure/local/answers_local_dao_shared_prefs.dart';

class CreateQuizPage extends StatefulWidget {
  const CreateQuizPage({super.key});

  @override
  State<CreateQuizPage> createState() => _CreateQuizPageState();
}

class _CreateQuizPageState extends State<CreateQuizPage> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  late final QuizSyncService _quizSyncService;
  late final QuestionSyncService _questionSyncService;
  late final AnswerSyncService _answerSyncService;
  
  bool _isSaving = false;
  
  // Store temporary question data before quiz is created
  final List<_TempQuestion> _tempQuestions = [];

  // 🎨 Paleta de cores consistente
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  @override
  void initState() {
    super.initState();
    
    // Initialize services
    final quizDao = QuizzesLocalDaoSharedPrefs();
    final quizRepo = QuizSupabaseRepository(quizDao);
    _quizSyncService = QuizSyncService(quizRepo);
    
    final questionDao = QuestionsLocalDaoSharedPrefs();
    final questionRepo = QuestionSupabaseRepository(questionDao);
    _questionSyncService = QuestionSyncService(questionRepo);
    
    final answerDao = AnswersLocalDaoSharedPrefs();
    final answerRepo = AnswerSupabaseRepository(answerDao);
    _answerSyncService = AnswerSyncService(answerRepo);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _themeController.dispose();
    super.dispose();
  }

  void _addQuestion() async {
    final question = await showDialog<Question>(
      context: context,
      builder: (context) => const AddQuestionDialog(),
    );

    if (question != null) {
      setState(() => _questions.add(question));
    }
  }

  void _saveQuiz() {
    if (_titleController.text.isEmpty ||
        _themeController.text.isEmpty ||
        _questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Preencha título, tema e pelo menos 1 pergunta!'),
        ),
      );
      return;
    }

    final newQuiz = Quiz(
      title: _titleController.text,
      theme: _themeController.text,
      questions: _questions,
    );

    Navigator.of(context).pop(newQuiz); // retorna para HomeQuizPage
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBackground,
      resizeToAvoidBottomInset: true, // garante teclado visível
      appBar: AppBar(
        title: const Text('Criar Quiz'),
        backgroundColor: _primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Título do Quiz',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _themeController,
              decoration: const InputDecoration(
                labelText: 'Tema do Quiz',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _addQuestion,
              icon: const Icon(Icons.add),
              label: const Text('Adicionar Pergunta'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  final q = _questions[index];
                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    child: ListTile(
                      title: Text(q.text),
                      subtitle: Text('${q.answers.length} respostas'),
                    ),
                  );
                },
              ),
            ),
            ElevatedButton(
              onPressed: _saveQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
              child: const Text('Salvar Quiz'),
            ),
          ],
        ),
      ),
    );
  }
}

// ----------------- Dialog para adicionar pergunta -----------------
class AddQuestionDialog extends StatefulWidget {
  const AddQuestionDialog({super.key});

  @override
  State<AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _questionController = TextEditingController();
  final List<Answer> _answers = [];
  final _answerController = TextEditingController();
  int? _correctIndex;

  static const Color _primaryBlue = Color(0xFF2563EB);

  void _addAnswer() {
    if (_answerController.text.isEmpty) return;
    setState(() {
      _answers.add(Answer(text: _answerController.text, isCorrect: false));
      _answerController.clear();
    });
  }

  void _saveQuestion() {
    if (_questionController.text.isEmpty ||
        _answers.isEmpty ||
        _correctIndex == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Preencha a pergunta, adicione respostas e marque a correta!'),
        ),
      );
      return;
    }

    for (int i = 0; i < _answers.length; i++) {
      _answers[i] =
          Answer(text: _answers[i].text, isCorrect: i == _correctIndex);
    }

    final question = Question(text: _questionController.text, answers: _answers);
    Navigator.of(context).pop(question);
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Adicionar Pergunta',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      TextField(
                        controller: _questionController,
                        autofocus: true,
                        decoration: const InputDecoration(
                          labelText: 'Texto da Pergunta',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _answerController,
                              autofocus: true,
                              decoration: const InputDecoration(
                                labelText: 'Resposta',
                                border: OutlineInputBorder(),
                              ),
                              textInputAction: TextInputAction.done,
                              onSubmitted: (_) => _addAnswer(),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add, color: _primaryBlue),
                            onPressed: _addAnswer,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      RadioGroup<int>(
                        groupValue: _correctIndex,
                        onChanged: (val) => setState(() => _correctIndex = val),
                        child: Column(
                          children: _answers.asMap().entries.map(
                                (entry) => ListTile(
                                  leading: Radio<int>(
                                    value: entry.key,
                                  ),
                                  title: Text(entry.value.text),
                                  onTap: () => setState(() => _correctIndex = entry.key),
                                ),
                              ).toList(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: _saveQuestion,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryBlue,
                    ),
                    child: const Text('Salvar Pergunta'),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}


