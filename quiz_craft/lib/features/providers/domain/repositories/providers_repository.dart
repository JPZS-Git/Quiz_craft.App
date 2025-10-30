import '../entities/provider_entity.dart';

abstract class ProvidersRepository {
  /// Retorna a lista de providers disponíveis.
  Future<List<ProviderEntity>> fetchProviders();

  /// Retorna um provider pelo id ou null se não existir.
  Future<ProviderEntity?> getProviderById(String id);

  /// Adiciona um novo provider.
  Future<void> addProvider(ProviderEntity provider);

  /// Atualiza um provider existente.
  Future<void> updateProvider(ProviderEntity provider);

  /// Remove um provider pelo id.
  Future<void> deleteProvider(String id);
}
