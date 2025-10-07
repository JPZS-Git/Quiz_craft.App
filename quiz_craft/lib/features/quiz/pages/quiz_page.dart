import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/answer.dart';
import '../widgets/question_card.dart';
import '../models/quiz.dart';

class QuizPage extends StatefulWidget {
  final Quiz quiz;

  const QuizPage({super.key, required this.quiz});

  @override
  State<QuizPage> createState() => _QuizPageState();
}

class _QuizPageState extends State<QuizPage> {
  int currentQuestionIndex = 0;
  int score = 0;

  // 🎨 Paleta de cores consistente
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  void _handleAnswer(int selectedIndex) {
    final question = widget.quiz.questions[currentQuestionIndex];
    final selectedAnswer = question.answers[selectedIndex];

    if (selectedAnswer.isCorrect) {
      score++;
    }

    if (currentQuestionIndex < widget.quiz.questions.length - 1) {
      setState(() => currentQuestionIndex++);
    } else {
      _showResult();
    }
  }

  void _showResult() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _cardBackground,
        title: Text(
          'Resultado',
          style: TextStyle(color: _primaryBlue, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Você acertou $score de ${widget.quiz.questions.length} perguntas!',
          style: const TextStyle(fontSize: 16),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(); // fecha o diálogo
              Navigator.of(context).pop(); // volta para a tela anterior
            },
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.quiz.questions[currentQuestionIndex];

    return Scaffold(
      backgroundColor: _cardBackground,
      appBar: AppBar(
        title: Text(widget.quiz.title),
        backgroundColor: _primaryBlue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            // Barra de progresso
            LinearProgressIndicator(
              value: (currentQuestionIndex + 1) / widget.quiz.questions.length,
              backgroundColor: Colors.grey[300],
              color: _primaryBlue,
              minHeight: 8,
            ),
            const SizedBox(height: 16),
            // Pergunta ocupando espaço proporcional
            Flexible(
              flex: 7, // ocupa 70% do espaço vertical disponível
              child: QuestionCard(
                question: question,
                onAnswerSelected: _handleAnswer,
              ),
            ),
            const SizedBox(height: 16),
            // Número da pergunta
            Flexible(
              flex: 1, // ocupa 10% do espaço vertical
              child: Center(
                child: Text(
                  'Pergunta ${currentQuestionIndex + 1} de ${widget.quiz.questions.length}',
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w500),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}


