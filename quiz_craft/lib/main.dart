import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'features/app/quizcraft_app.dart';
import 'services/shared_preferences_services.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // ============================================
  // CARREGAR VARIÁVEIS DE AMBIENTE
  // ============================================
  try {
    await dotenv.load(fileName: ".env");
    debugPrint('✅ Arquivo .env carregado com sucesso');
  } catch (e) {
    debugPrint('⚠️  Erro ao carregar .env: $e');
    debugPrint('⚠️  Certifique-se de que o arquivo .env existe e está no pubspec.yaml');
  }

  // ============================================
  // VALIDAR VARIÁVEIS OBRIGATÓRIAS
  // ============================================
  final supabaseUrl = dotenv.env['SUPABASE_URL'];
  final supabaseAnonKey = dotenv.env['SUPABASE_ANON_KEY'];

  if (supabaseUrl == null || supabaseUrl.isEmpty) {
    throw Exception('❌ SUPABASE_URL não encontrada no .env');
  }
  if (supabaseAnonKey == null || supabaseAnonKey.isEmpty) {
    throw Exception('❌ SUPABASE_ANON_KEY não encontrada no .env');
  }

  // ============================================
  // INICIALIZAR SUPABASE
  // ============================================
  try {
    await Supabase.initialize(
      url: supabaseUrl,
      anonKey: supabaseAnonKey,
      debug: true, // Desabilitar em produção
    );
    debugPrint('✅ Supabase inicializado com sucesso');
    debugPrint('🔗 URL: $supabaseUrl');
  } catch (e) {
    debugPrint('❌ Erro ao inicializar Supabase: $e');
    rethrow;
  }

  // ============================================
  // INICIALIZAR SHARED PREFERENCES (mantido)
  // ============================================
  final sharedPrefsService = SharedPreferencesService();
  await sharedPrefsService.init();

  runApp(
    ChangeNotifierProvider<SharedPreferencesService>.value(
      value: sharedPrefsService,
      child: const QuizCraftApp(),
    ),
  );

  FlutterNativeSplash.remove();
}
