import 'dart:async';

import '../domain/entities/provider_entity.dart';
import '../domain/repositories/providers_repository.dart';

/// Simples implementação em memória para desenvolvimento e testes.
class InMemoryProvidersRepository implements ProvidersRepository {
  final List<ProviderEntity> _store = [];

  @override
  Future<void> addProvider(ProviderEntity provider) async {
    // simulate latency
    await Future.delayed(const Duration(milliseconds: 150));
    _store.add(provider);
  }

  @override
  Future<void> deleteProvider(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    _store.removeWhere((p) => p.id == id);
  }

  @override
  Future<ProviderEntity?> getProviderById(String id) async {
    await Future.delayed(const Duration(milliseconds: 100));
    try {
      return _store.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ProviderEntity>> fetchProviders() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.unmodifiable(_store);
  }

  @override
  Future<void> updateProvider(ProviderEntity provider) async {
    await Future.delayed(const Duration(milliseconds: 150));
    final idx = _store.indexWhere((p) => p.id == provider.id);
    if (idx >= 0) {
      _store[idx] = provider;
    } else {
      throw StateError('Provider not found: ${provider.id}');
    }
  }
}
