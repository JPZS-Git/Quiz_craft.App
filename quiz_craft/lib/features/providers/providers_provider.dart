import 'package:flutter/foundation.dart';

import 'domain/entities/provider_entity.dart';
import 'domain/repositories/providers_repository.dart';

class ProvidersProvider extends ChangeNotifier {
  final ProvidersRepository repository;

  ProvidersProvider({required this.repository});

  List<ProviderEntity> _providers = [];
  bool _loading = false;
  String? _error;

  List<ProviderEntity> get providers => List.unmodifiable(_providers);
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loadProviders() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final list = await repository.fetchProviders();
      _providers = list;
    } catch (e, st) {
      _error = e.toString();
      // keep previous list if any
      debugPrint('Failed loading providers: $e\n$st');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  ProviderEntity? getById(String id) {
    try {
      return _providers.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> addProvider(ProviderEntity provider) async {
    _loading = true;
    notifyListeners();
    try {
      await repository.addProvider(provider);
      _providers = [..._providers, provider];
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateProvider(ProviderEntity provider) async {
    _loading = true;
    notifyListeners();
    try {
      await repository.updateProvider(provider);
      _providers = _providers.map((p) => p.id == provider.id ? provider : p).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteProvider(String id) async {
    _loading = true;
    notifyListeners();
    try {
      await repository.deleteProvider(id);
      _providers = _providers.where((p) => p.id != id).toList();
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}
