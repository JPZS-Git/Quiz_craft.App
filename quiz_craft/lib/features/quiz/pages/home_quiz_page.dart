import 'package:flutter/material.dart';
import '../models/quiz.dart';
import 'quiz_page.dart';
import 'create_quiz_page.dart';

class HomeQuizPage extends StatefulWidget {
  const HomeQuizPage({super.key});

  @override
  State<HomeQuizPage> createState() => _HomeQuizPageState();
}

class _HomeQuizPageState extends State<HomeQuizPage> {
  // Lista de quizzes
  List<Quiz> quizzes = [];

  @override
  void initState() {
    super.initState();
    _loadQuizzes();
  }

  void _loadQuizzes() {
    // Aqui você carregaria do storage real. Exemplo inicial vazio:
    setState(() {
      quizzes = [];
    });
  }

  void _addQuiz(Quiz quiz) {
    setState(() {
      quizzes.add(quiz);
    });
  }

  void _navigateToCreateQuiz() async {
    final newQuiz = await Navigator.push<Quiz>(
      context,
      MaterialPageRoute(
        builder: (_) => const CreateQuizPage(),
      ),
    );

    if (newQuiz != null) {
      _addQuiz(newQuiz);
    }
  }

  void _startQuiz(Quiz quiz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => QuizPage(quiz: quiz),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Meus Quizzes'),
        backgroundColor: const Color(0xFF2563EB),
      ),
      body: quizzes.isEmpty
          ? const Center(
              child: Text(
                'Nenhum quiz criado ainda.\nClique no botão + para criar um.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16),
              itemCount: quizzes.length,
              itemBuilder: (context, index) {
                final quiz = quizzes[index];
                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  child: ListTile(
                    title: Text(
                      quiz.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    subtitle: Text('Tema: ${quiz.theme}'),
                    trailing: const Icon(Icons.play_arrow),
                    onTap: () => _startQuiz(quiz),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateQuiz,
        backgroundColor: const Color(0xFF2563EB),
        child: const Icon(Icons.add),
      ),
    );
  }
}
