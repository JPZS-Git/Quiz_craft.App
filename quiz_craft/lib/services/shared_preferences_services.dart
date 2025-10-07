// lib/data/services/shared_preferences_service.dart (Nome do Arquivo Ajustado)

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importa suas chaves centralizadas
import 'preferences_keys.dart'; 

/// Versão atual das políticas que o usuário deve ter aceito.
const double currentPolicyVersion = 1.0; 

// A classe foi renomeada para atender ao seu requisito de nomenclatura.
class SharedPreferencesService extends ChangeNotifier { 
  
  late SharedPreferences _prefs;
  bool _initialized = false;

  SharedPreferencesService() {
    init();
  }

  Future<void> init() async {
    if (_initialized) return;
    _prefs = await SharedPreferences.getInstance();
    _initialized = true;
  }

  // ------------------------------------------
  // LÓGICA DE ROTEAMENTO (usada pelo Splash)
  // ------------------------------------------

  /// @isPoliciesAccepted() é o método que o seu HomePage estava tentando chamar.
  /// Checa se o usuário aceitou a versão atual do fluxo legal. (RNF-5)
  Future<bool> isPoliciesAccepted() async { 
    await init();
    // Checa se a versão aceita é igual ou superior à versão atual
    final acceptedVersion = _prefs.getDouble(PreferencesKeys.acceptedFlowVersion) ?? 0.0;
    return acceptedVersion >= currentPolicyVersion;
  }

  /// Marca o fluxo inicial como completo com a versão atual.
  Future<void> completeInitialFlow({required double version}) async {
    await init();
    await _prefs.setDouble(PreferencesKeys.acceptedFlowVersion, currentPolicyVersion);
    await _prefs.setBool(PreferencesKeys.onboardingCompleted, true);
    notifyListeners(); 
  }


  // ------------------------------------------
  // CONSENTIMENTO DE MARKETING
  // ------------------------------------------

  Future<bool> getMarketingConsent() async {
    await init();
    return _prefs.getBool(PreferencesKeys.marketingConsent) ?? false;
  }

  Future<void> setMarketingConsent(bool value) async {
    await init();
    await _prefs.setBool(PreferencesKeys.marketingConsent, value);
    notifyListeners();
  }

  // ------------------------------------------
  // LEITURA OBRIGATÓRIA DE POLÍTICAS
  // ------------------------------------------

  Future<bool> getPrivacyPolicyReadStatus() async {
    await init();
    return _prefs.getBool(PreferencesKeys.privacyPolicyAllRead) ?? false;
  }

  Future<void> setPrivacyPolicyReadStatus(bool isRead) async {
    await init();
    await _prefs.setBool(PreferencesKeys.privacyPolicyAllRead, isRead);
  }

  Future<bool> getTermsOfUseReadStatus() async {
    await init();
    return _prefs.getBool(PreferencesKeys.termsOfUseAllRead) ?? false;
  }

  Future<void> setTermsOfUseReadStatus(bool isRead) async {
    await init();
    await _prefs.setBool(PreferencesKeys.termsOfUseAllRead, isRead);
  }
  
  // ------------------------------------------
  // MANUTENÇÃO E REVOGAÇÃO (RNF-114)
  // ------------------------------------------

  /// Revoga o aceite de consentimento, forçando o usuário a refazer o Onboarding legal.
  Future<void> revokeAllConsent() async {
    await init();
    
    await _prefs.setBool(PreferencesKeys.marketingConsent, false);
    await _prefs.setDouble(PreferencesKeys.acceptedFlowVersion, 0.0);
    await _prefs.setBool(PreferencesKeys.onboardingCompleted, false);
    await _prefs.setBool(PreferencesKeys.privacyPolicyAllRead, false);
    await _prefs.setBool(PreferencesKeys.termsOfUseAllRead, false);

    notifyListeners();
  }

  /// Remove TODAS as chaves de dados do app (Debug/Logout)
  Future<void> removeAll() async {
    await init();
    await _prefs.clear();
  }
}