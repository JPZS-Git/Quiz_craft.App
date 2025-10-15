import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; 

import '../../features/onboarding/onboarding_page.dart';
import '../../features/home/home_page.dart';
import '../../services/shared_preferences_services.dart';

class SplashScreenPage extends StatefulWidget {
  static const String routeName = '/';

  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _surfaceGray = Color(0xFF475569);

  @override
  void initState() {
    super.initState();

    // Garante que o Provider esteja disponível após o primeiro frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _decideAndNavigate();
    });
  }

  Future<void> _decideAndNavigate() async {
    final prefsService = Provider.of<SharedPreferencesService>(context, listen: false);

    // Verifica se o usuário já aceitou o fluxo de políticas (não apenas marketing)
    final isPoliciesAccepted = await prefsService.isPoliciesAccepted();

    // Aguarda 2-3 segundos para UX e inicialização visual
    await Future.delayed(const Duration(seconds: 2));

    // Remove splash nativa
    FlutterNativeSplash.remove();

    if (!mounted) return;

    // Define rota alvo: Home se já aceitou, Onboarding caso contrário
    final targetRoute = isPoliciesAccepted
        ? HomePage.routeName
        : OnboardingPage.routeName;

    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset('assets/logo_com_fundo.png', width: 200, height: 200),
            const SizedBox(height: 32),
            CircularProgressIndicator(
              strokeWidth: 4,
              valueColor: const AlwaysStoppedAnimation<Color>(_primaryBlue),
              backgroundColor: _primaryBlue.withOpacity(0.2),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 18.0),
              child: Text(
                'Preparando sua jornada de aprendizado...',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: _surfaceGray,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}