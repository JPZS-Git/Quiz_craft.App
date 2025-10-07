import 'package:flutter/material.dart';
import '../models/question.dart';
import '../models/answer.dart';

class QuestionCard extends StatefulWidget {
  final Question question;
  final ValueChanged<int> onAnswerSelected;

  const QuestionCard({
    super.key,
    required this.question,
    required this.onAnswerSelected,
  });

  @override
  State<QuestionCard> createState() => _QuestionCardState();
}

class _QuestionCardState extends State<QuestionCard> {
  int? _selectedIndex;

  // 🎨 Paleta de cores consistente
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _buttonBackground = Colors.white;
  static const Color _buttonSelected = _primaryBlue;
  static const Color _buttonText = Colors.black87;
  static const Color _buttonTextSelected = Colors.white;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(6), // retangular com cantos suaves
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24.0, horizontal: 20.0),
        child: Column(
          mainAxisSize: MainAxisSize.min, // ajusta altura conforme conteúdo
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pergunta
            Text(
              widget.question.text,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            // Respostas em largura total
            ...List.generate(
              widget.question.answers.length,
              (index) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: GestureDetector(
                  onTap: () {
                    setState(() => _selectedIndex = index);
                    widget.onAnswerSelected(index);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: double.infinity, // ocupa toda a largura
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: _selectedIndex == index
                          ? _buttonSelected
                          : _buttonBackground,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _selectedIndex == index
                            ? _primaryBlue
                            : Colors.grey.shade300,
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.question.answers[index].text,
                      style: TextStyle(
                        color: _selectedIndex == index
                            ? _buttonTextSelected
                            : _buttonText,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

