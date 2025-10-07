import 'package:flutter/material.dart';
import '../home/home_page.dart';
import '../onboarding/onboarding_page.dart';
import '../splashscreen/splashscreen_page.dart';

class QuizCraftApp extends StatelessWidget {
  const QuizCraftApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primaryBlue = Color(0xFF2563EB);
    const Color surfaceGray = Color(0xFF475569);

    return MaterialApp(
      title: 'QuizCraft',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        materialTapTargetSize: MaterialTapTargetSize.padded,
        visualDensity: VisualDensity.standard,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryBlue,
          primary: primaryBlue,
          surface: surfaceGray,
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(foregroundColor: primaryBlue),
        ),
      ),
      initialRoute: SplashScreenPage.routeName,
      routes: {
        SplashScreenPage.routeName: (context) => const SplashScreenPage(),
        OnboardingPage.routeName: (context) => const OnboardingPage(),
        HomePage.routeName: (context) => const HomePage(),
      },
    );
  }
}
