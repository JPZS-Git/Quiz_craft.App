import 'package:flutter/material.dart';

class WellcomeOBPage extends StatelessWidget {
  final VoidCallback onNext; // 👈 Recebe o callback do OnboardingPage

  const WellcomeOBPage({super.key, required this.onNext});

  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _surfaceGray = Color(0xFF475569);

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ClipOval(
                  child: Image.asset(
                    'assets/images/01.png',
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                  ),
                ),
                const SizedBox(height: 32),

                Text(
                  'Bem-vindo(a) ao QuizCraft!',
                  style: textTheme.headlineMedium?.copyWith(
                    color: _surfaceGray,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),

                Text(
                  'Seu guia para o domínio de unidades e testes.',
                  style: textTheme.bodyLarge?.copyWith(
                    color: _surfaceGray.withOpacity(0.8),
                    fontSize: 16,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),

                const SizedBox(height: 24),

                ElevatedButton(
                  onPressed: onNext, // 👈 Agora chama o método de navegação
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                    textStyle: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Começar'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
