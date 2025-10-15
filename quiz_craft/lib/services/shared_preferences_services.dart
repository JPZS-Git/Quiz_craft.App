import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'preferences_keys.dart'; 

/// Versão atual do fluxo legal que o usuário deve ter aceitado.
/// (Se você atualizar termos/políticas futuramente, aumente esse número)
const double currentPolicyVersion = 1.0;

/// Serviço central de persistência usando SharedPreferences.
/// Responsável por armazenar e recuperar dados locais do app.
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

  // ============================================================
  // ===============   CONTROLE DE FLUXO INICIAL   ===============
  // ============================================================

  /// Retorna `true` se o usuário já aceitou a versão atual das políticas.
  Future<bool> isPoliciesAccepted() async {
    await init();
    final acceptedVersion = _prefs.getDouble(PreferencesKeys.acceptedFlowVersion) ?? 0.0;
    return acceptedVersion >= currentPolicyVersion;
  }

  /// Marca o fluxo inicial (onboarding + aceite de políticas) como concluído.
  Future<void> completeInitialFlow() async {
    await init();
    await _prefs.setDouble(PreferencesKeys.acceptedFlowVersion, currentPolicyVersion);
    await _prefs.setBool(PreferencesKeys.onboardingCompleted, true);
    notifyListeners();
  }

  // ============================================================
  // ===============     CONSENTIMENTO DE MARKETING   ============
  // ============================================================

  Future<bool> getMarketingConsent() async {
    await init();
    return _prefs.getBool(PreferencesKeys.marketingConsent) ?? false;
  }

  Future<void> setMarketingConsent(bool value) async {
    await init();
    await _prefs.setBool(PreferencesKeys.marketingConsent, value);
    notifyListeners();
  }

  // ============================================================
  // ===============     STATUS DE LEITURA DE POLÍTICAS   ========
  // ============================================================

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

  // ============================================================
  // ===============     MANUTENÇÃO E REVOGAÇÃO   ================
  // ============================================================

  /// Revoga todos os consentimentos e reinicia o fluxo inicial.
  Future<void> revokeAllConsent() async {
    await init();
    await _prefs.setBool(PreferencesKeys.marketingConsent, false);
    await _prefs.setDouble(PreferencesKeys.acceptedFlowVersion, 0.0);
    await _prefs.setBool(PreferencesKeys.onboardingCompleted, false);
    await _prefs.setBool(PreferencesKeys.privacyPolicyAllRead, false);
    await _prefs.setBool(PreferencesKeys.termsOfUseAllRead, false);
    notifyListeners();
  }

  /// Remove todas as chaves de dados (modo debug ou logout).
  Future<void> removeAll() async {
    await init();
    await _prefs.clear();
  }
}