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
  // Paleta de cores
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _cardBackground = Color(0xFFF9FAFB);

  String? _userName;
  String? _userEmail;
  bool _showConsentSnack = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkConsent());
  }

  Future<void> _loadUser() async {
    final prefs = SharedPreferencesService();
    final name = await prefs.getUserName();
    final email = await prefs.getUserEmail();
    if (!mounted) return;
    setState(() {
      _userName = name;
      _userEmail = email;
    });
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
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'QuizCraft',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        actions: [
          Tooltip(
            message: 'Ajuda',
            waitDuration: const Duration(milliseconds: 300),
            textStyle: const TextStyle(color: Colors.white),
            decoration: BoxDecoration(
              color: const Color.fromRGBO(0, 0, 0, 0.7),
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              tooltip: 'Ajuda',
              icon: const Icon(Icons.help_outline, color: Colors.white),
              splashRadius: 24,
              onPressed: () {
                showDialog(
                  context: context,
                  barrierDismissible: false,
                  builder: (context) => AlertDialog(
                    title: const Text('Como começar?'),
                    content: const Text(
                      'Use o menu lateral para acessar seu perfil, políticas e outras configurações.',
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Entendi'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: _primaryBlue),
              accountName: Text(_userName ?? 'Usuário não registrado'),
              accountEmail: Text(_userEmail ?? ''),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                child: Text(
                  _userName != null && _userName!.isNotEmpty
                      ? _userName!
                            .trim()
                            .split(' ')
                            .map((e) => e.isNotEmpty ? e[0] : '')
                            .take(2)
                            .join()
                      : '?',
                  style: const TextStyle(fontSize: 20, color: _primaryBlue),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.person),
              title: const Text('Editar perfil'),
              onTap: () async {
                Navigator.of(context).pop();
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
                if (result == true) {
                  _loadUser();
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.privacy_tip),
              title: const Text('Privacidade & consentimentos'),
              onTap: () {
                Navigator.of(context).pop();
                _openPrivacyDialog();
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.info_outline),
              title: const Text('Política de Privacidade'),
              onTap: () {
                Navigator.of(context).pop();
                Navigator.of(context).pushNamed('/policies');
              },
            ),
          ],
        ),
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

  void _openPrivacyDialog() {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return AlertDialog(
          title: const Text('Privacidade & Consentimentos'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Deletar nome e e-mail locais'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  onPressed: () async {
                    Navigator.of(context).pop();
                    final messenger = ScaffoldMessenger.of(context);
                    final confirm = await showDialog<bool>(
                      context: context,
                      barrierDismissible: false,
                      builder: (context) => AlertDialog(
                        title: const Text('Confirmar remoção de dados'),
                        content: const Text(
                          'Deseja realmente remover seu nome e e-mail armazenados localmente?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: const Text('Cancelar'),
                          ),
                          ElevatedButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: const Text('Remover'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      final prefs = SharedPreferencesService();
                      await prefs.setUserName('');
                      await prefs.setUserEmail('');
                      if (!mounted) return;
                      
                      setState(() {
                        _userName = null;
                        _userEmail = null;
                      });
                      
                      messenger.showSnackBar(
                        const SnackBar(
                          content: Text('Dados locais removidos.'),
                        ),
                      );
                    }
                  },
                  child: const Text('Deletar'),
                ),
              ),
              const SizedBox(height: 8),
              ListTile(
                title: const Text('Revogar consentimento'),
                trailing: ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  onPressed: () {
                    Navigator.of(context).pop();
                    _revokeConsent();
                  },
                  child: const Text('Revogar'),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Fechar'),
            ),
          ],
        );
      },
    );
  }
}
