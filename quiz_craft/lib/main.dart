import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'features/app/quizcraft_app.dart';
import 'services/shared_preferences_services.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  // Mantém a splash nativa até carregarmos dependências
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Inicializa SharedPreferencesService antes de rodar o app
  final sharedPrefsService = SharedPreferencesService();
  await sharedPrefsService.init(); // garante que _prefs está pronto

  runApp(
    ChangeNotifierProvider<SharedPreferencesService>.value(
  value: sharedPrefsService,
  child: const QuizCraftApp(),
)
  );

  // Remove a splash nativa depois do runApp
  FlutterNativeSplash.remove();
}
