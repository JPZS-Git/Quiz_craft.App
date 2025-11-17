import 'package:flutter/material.dart';
import 'package:quizcraft/features/onboarding/pages/consent_page.dart';
import 'package:quizcraft/features/quiz/pages/home_quiz_page.dart';
import 'package:quizcraft/features/home/profile_page.dart';
import 'package:quizcraft/services/shared_preferences_services.dart';

class HomePage extends StatefulWidget {
  static const String routeName = '/home';
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  // 🎨 Paleta de cores
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  bool _showConsentSnack = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConsent());
  }

  Future<void> _checkConsent() async {
    final prefsService = SharedPreferencesService();
    final accepted = await prefsService.isPoliciesAccepted();

    if (!accepted) {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => ConsentPageOBPage(
              onConsentGiven: () => _checkConsent(),
            ),
          ),
        );
      }
    } else if (!_showConsentSnack && mounted) {
      setState(() => _showConsentSnack = true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Você pode revogar seu consentimento a qualquer momento.',
          ),
          action: SnackBarAction(
            label: 'Revogar',
            onPressed: () => _revokeConsent(),
            textColor: const Color.fromARGB(255, 64, 118, 235),
          ),
          backgroundColor: const Color.fromARGB(255, 83, 96, 113),
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Future<void> _revokeConsent() async {
    final prefsService = SharedPreferencesService();
    await prefsService.revokeAllConsent();

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ConsentPageOBPage(
            onConsentGiven: () => _checkConsent(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cardBackground,
      appBar: AppBar(
        backgroundColor: _primaryBlue,
        elevation: 2,
        title: const Text(
          'QuizCraft',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),

        // ✅ Ícone branco com tooltip visível
        actions: [
          Tooltip(
            message: 'Perfil',
            waitDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Perfil', // redundante, mas mantém compatibilidade mobile
              icon: const Icon(Icons.person, color: Colors.white),
              splashRadius: 24,
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
          ),
        ],
      ),

      body: Center(
        child: Card(
          color: Colors.white,
          elevation: 6,
          shadowColor: Colors.black26,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Bem-vindo(a) à Home!',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Aqui você pode acessar todas as funcionalidades do QuizCraft.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HomeQuizPage()),
                    );
                  },
                  icon: const Icon(Icons.quiz),
                  label: const Text('Acessar Quizzes'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                    elevation: 4,
                  ),
                ),
                const SizedBox(height: 16),
                ElevatedButton.icon(
                  onPressed: _revokeConsent,
                  icon: const Icon(Icons.cancel_outlined),
                  label: const Text('Revogar Consentimento'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        vertical: 16, horizontal: 24),
                    textStyle: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(32)),
                    elevation: 4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
