import 'package:flutter/material.dart';

class HowItWorksOBPage extends StatelessWidget {
  final VoidCallback onNext; // <-- recebe a função de avanço da OnboardingPage

  const HowItWorksOBPage({super.key, required this.onNext});

  // Paleta de cores do QuizCraft
  static const Color _primaryBlue = Color(0xFF2563EB);
  //static const Color _accentAmber = Color(0xFFF59E0B);
  static const Color _surfaceGray = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16),
          child: Column(
            children: [
              // Conteúdo principal rolável
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.asset(
                          'assets/images/02.png',
                          height: 180,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(height: 32),

                      // Título
                      Text(
                        'Como Funciona o QuizCraft',
                        style: textTheme.headlineMedium?.copyWith(
                          color: _surfaceGray,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),

                      // Texto descritivo
                      Text(
                        'Domine seus estudos e gerencie seu progresso através de nossos quizzes interativos e focados em unidades.',
                        style: textTheme.bodyMedium?.copyWith(
                          color: const Color.fromRGBO(71, 85, 105, 0.85),
                          fontSize: 16,
                          height: 1.4,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Botão fixo na parte inferior
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: onNext, // <-- usa o callback passado pela OnboardingPage
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Próximo'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

