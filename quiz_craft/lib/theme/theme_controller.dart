import 'package:flutter/material.dart';
import '../services/shared_preferences_services.dart';
//import '../services/preferences_keys.dart';

/// Controlador de tema que gerencia o ThemeMode do aplicativo.
/// 
/// Usa ChangeNotifier para notificar widgets quando o tema muda.
/// Persiste a preferência do usuário em SharedPreferences.
class ThemeController extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;
  final SharedPreferencesService _prefsService;

  ThemeController(this._prefsService);

  /// ThemeMode atual (system, light ou dark)
  ThemeMode get themeMode => _themeMode;

  /// Retorna true se o modo escuro está ativo (considerando o ThemeMode)
  bool get isDarkMode => _themeMode == ThemeMode.dark;

  /// Retorna true se está seguindo o tema do sistema
  bool get isSystemMode => _themeMode == ThemeMode.system;

  /// Inicializa o controller carregando a preferência salva
  Future<void> init() async {
    final savedTheme = await _prefsService.getThemeMode();
    _themeMode = _parseThemeMode(savedTheme);
    debugPrint('[ThemeController] 🚀 Iniciado com tema: ${_themeMode.toString()} (salvo como: "$savedTheme")');
    notifyListeners();
  }

  /// Alterna entre os modos de tema: system → light → dark → system
  Future<void> toggleTheme() async {
    switch (_themeMode) {
      case ThemeMode.system:
        _themeMode = ThemeMode.light;
        break;
      case ThemeMode.light:
        _themeMode = ThemeMode.dark;
        break;
      case ThemeMode.dark:
        _themeMode = ThemeMode.system;
        break;
    }
    await _saveThemeMode();
    notifyListeners();
  }

  /// Define o tema explicitamente
  Future<void> setThemeMode(ThemeMode mode) async {
    if (_themeMode == mode) return;
    debugPrint('[ThemeController] 🎨 Alterando tema: ${_themeMode.toString()} → ${mode.toString()}');
    _themeMode = mode;
    await _saveThemeMode();
    debugPrint('[ThemeController] ✅ Tema salvo como: ${mode.toString()}');
    notifyListeners();
  }

  /// Salva o ThemeMode atual no SharedPreferences
  Future<void> _saveThemeMode() async {
    final themeString = _themeMode.toString().split('.').last;
    await _prefsService.saveThemeMode(themeString);
  }

  /// Converte string para ThemeMode
  ThemeMode _parseThemeMode(String? value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  /// Retorna um texto descritivo do modo atual
  String get themeModeLabel {
    switch (_themeMode) {
      case ThemeMode.system:
        return 'Acompanhar sistema';
      case ThemeMode.light:
        return 'Tema claro';
      case ThemeMode.dark:
        return 'Tema escuro';
    }
  }
}
