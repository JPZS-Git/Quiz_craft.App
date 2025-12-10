import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../theme/theme_controller.dart';
import '../../theme/color_schemes.dart';
import '../home/home_page.dart';
import '../onboarding/onboarding_page.dart';
import '../splashscreen/splashscreen_page.dart';
import '../quizzes/presentation/quizzes_page.dart';

class QuizCraftApp extends StatelessWidget {
  const QuizCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeController>(
      builder: (context, themeController, _) {
        return MaterialApp(
          title: 'QuizCraft',
          debugShowCheckedModeBanner: false,
          
          // Tema claro usando ColorScheme gerado
          theme: ThemeData(
            useMaterial3: true,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
            colorScheme: lightColorScheme,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: lightColorScheme.primary,
              ),
            ),
          ),
          
          // Tema escuro usando ColorScheme gerado
          darkTheme: ThemeData(
            useMaterial3: true,
            materialTapTargetSize: MaterialTapTargetSize.padded,
            visualDensity: VisualDensity.standard,
            colorScheme: darkColorScheme,
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: darkColorScheme.primary,
              ),
            ),
          ),
          
          // ThemeMode controlado pelo ThemeController
          themeMode: themeController.themeMode,
          
          initialRoute: SplashScreenPage.routeName,
          routes: {
            SplashScreenPage.routeName: (context) => const SplashScreenPage(),
            OnboardingPage.routeName: (context) => const OnboardingPage(),
            HomePage.routeName: (context) => const HomePage(),
            QuizzesPage.routeName: (context) => const QuizzesPage(),
          },
        );
      },
    );
  }
}
