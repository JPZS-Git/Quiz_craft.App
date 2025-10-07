import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart'; 
// Gerenciamento do splash nativo

import '../../services/shared_preferences_services.dart';
import '../onboarding/onboarding_page.dart'; 
// Certifique-se de que o caminho de importação esteja correto

class SplashScreenPage extends StatefulWidget {
  // Define a rota raiz do aplicativo
  static const String routeName = '/'; 

  const SplashScreenPage({super.key});

  @override
  State<SplashScreenPage> createState() => _SplashScreenPageState();
}

class _SplashScreenPageState extends State<SplashScreenPage> {
  // Cores do QuizCraft
  static const Color _primaryBlue = Color(0xFF2563EB);
  static const Color _surfaceGray = Color(0xFF475569);

  @override
void initState() {
  super.initState();
  // Executa após o primeiro frame para garantir que o Provider esteja disponível
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _decideAndNavigate();
  });

  }

  // --- Lógica de Carregamento e Roteamento (A CHAVE DO FLUXO) ---
  void _decideAndNavigate() async {
    // 1. Obtém a INSTÂNCIA do serviço via Provider (Correção do erro de acesso estático)
    final prefsService = Provider.of<SharedPreferencesService>(context, listen: false);

    // 2. Inicia as operações assíncronas
    final dataFuture = prefsService.getMarketingConsent(); 
    final delayFuture = Future.delayed(const Duration(seconds: 3)); // Tempo mínimo de UX
    
    // 3. Espera que AMBOS (leitura de dados e 3 segundos) terminem
    final marketingConsent = await dataFuture;
    await delayFuture;
    
    // 4. Remove a tela de Splash Nativa (transiciona para a UI Flutter)
    FlutterNativeSplash.remove(); 

    // 5. Navegação ÚNICA e Final
    if (!mounted) return;
    
    // Decide a rota: se consentiu (true) ou se não há consentimento (1ª execução)
    final String targetRoute = (marketingConsent == true)
        ? '/home'
        : OnboardingPage.routeName;

    // Executa a substituição de rota
    Navigator.of(context).pushReplacementNamed(targetRoute);
  }

  // --- Construção Visual (BUILD) ---
  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white, // Fundo branco
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo principal do QuizCraft
            Image.asset('assets/logo_com_fundo.png', width: 200, height: 200),
            const SizedBox(height: 32),
            // Indicador de progresso com a cor primária
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