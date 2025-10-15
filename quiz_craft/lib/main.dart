import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:provider/provider.dart';

import 'features/app/quizcraft_app.dart';
import 'services/shared_preferences_services.dart';

Future<void> main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();

  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  final sharedPrefsService = SharedPreferencesService();
  await sharedPrefsService.init(); 

  runApp(
    ChangeNotifierProvider<SharedPreferencesService>.value(
  value: sharedPrefsService,
  child: const QuizCraftApp(),
)
  );


  FlutterNativeSplash.remove();
}
