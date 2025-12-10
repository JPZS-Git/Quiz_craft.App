import 'package:flutter/material.dart';

/// Cor semente do QuizCraft (baseada na identidade visual)
const Color _seedColor = Color(0xFF2563EB); // Azul primário do app

/// ColorScheme claro gerado automaticamente a partir da cor semente
final ColorScheme lightColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.light,
);

/// ColorScheme escuro gerado automaticamente a partir da cor semente
final ColorScheme darkColorScheme = ColorScheme.fromSeed(
  seedColor: _seedColor,
  brightness: Brightness.dark,
);
