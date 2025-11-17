
import 'package:flutter/material.dart';
import 'package:quizcraft/features/onboarding/pages/consent_page.dart';
import '../../home/home_page.dart'; // Substitua pelo caminho correto da sua tela inicial


class GoToAccessPageOBpage extends StatelessWidget {
  const GoToAccessPageOBpage({super.key});

  // Paleta de cores do QuizCraft
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _surfaceGray = Color.fromARGB(255, 61, 76, 97);

  static const String routeName = '/onboarding/access-policies';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Center(
            child: Card(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(32),
              ),
              elevation: 8,
              shadowColor: Colors.black26,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Ícone moderno
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: const BoxDecoration(
                        color: Color.fromRGBO(37, 99, 235, 0.25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.gavel_outlined,
                        size: 64,
                        color: _primaryBlue,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Título
                    const Text(
                      'Aceite Necessário',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: _surfaceGray,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),

                    // Texto explicativo
                    Text(
                      'Para continuar no QuizCraft, precisamos que você aceite nossos Termos de Uso e Política de Privacidade.',
                      style: TextStyle(
                        fontSize: 16,
                        color: _surfaceGray.withOpacity(0.95),
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 32),

                    // Botão para abrir a página de consentimento
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pushReplacement(
                            MaterialPageRoute(
                              builder: (context) => ConsentPageOBPage(
                                onConsentGiven: () {
                                  // Só vai para a Home depois que o usuário aceitar
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const HomePage(),
                                    ),
                                  );
                                },
                              ),
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 18),
                          textStyle: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(32),
                          ),
                          elevation: 4,
                        ),
                        child: const Text('Revisar Consentimento'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}