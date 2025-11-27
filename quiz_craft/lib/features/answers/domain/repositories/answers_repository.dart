import '../entities/answer_entity.dart';

/// Interface de repositório para a entidade Answer.
///
/// O repositório define as operações de acesso e sincronização de dados,
/// separando a lógica de persistência da lógica de negócio.
/// Utilizar interfaces facilita a troca de implementações (ex.: local, remota)
/// e torna o código mais testável e modular.
///
/// ⚠️ Dicas práticas para evitar erros comuns:
/// - Certifique-se de que a entidade AnswerEntity possui métodos de conversão robustos (ex: aceitar id como int ou string, datas como DateTime ou String).
/// - Ao implementar esta interface, adicione prints/logs (usando kDebugMode) nos métodos principais para facilitar o diagnóstico de problemas de cache, conversão e sync.
/// - Em métodos assíncronos usados na UI, sempre verifique se o widget está "mounted" antes de chamar setState, evitando exceções de widget desmontado.
/// - Consulte os arquivos de debug do projeto (ex: answers_cache_debug_prompt.md, supabase_init_debug_prompt.md, supabase_rls_remediation.md) para exemplos de logs, prints e soluções de problemas reais.
abstract class AnswersRepository {
  // Método para renderização inicial rápida.
  // Carrega dados do cache local sem fazer chamadas de rede.
  // Use este método na inicialização da tela para mostrar dados imediatamente,
  // mesmo que estejam desatualizados. Depois, chame syncFromServer() para atualizar.
  /// Render inicial rápido a partir do cache local.
  Future<List<AnswerEntity>> loadFromCache();

  // Sincronização incremental com o servidor.
  // Busca apenas registros modificados desde a última sincronização (>= lastSync).
  // Retorna o número de registros que foram alterados (inseridos, atualizados ou removidos).
  // Chame este método após loadFromCache() para garantir que os dados estão atualizados.
  /// Sincronização incremental (>= lastSync). Retorna quantos registros mudaram.
  Future<int> syncFromServer();

  // Listagem completa de todas as respostas disponíveis.
  // Normalmente retorna dados do cache local após a sincronização.
  // Use este método quando precisar de todas as respostas, por exemplo,
  // para exibir em uma lista ou fazer filtragens locais.
  /// Listagem completa (normalmente do cache após sync).
  Future<List<AnswerEntity>> listAll();

  // Listagem de respostas em destaque (featured).
  // Filtra do cache local apenas as respostas marcadas como `featured`.
  // Útil para exibir respostas especiais ou recomendadas na interface.
  /// Destaques (filtrados do cache por `featured`).
  Future<List<AnswerEntity>> listFeatured();

  // Busca direta de uma resposta por ID.
  // Procura no cache local e retorna null se não encontrada.
  // Use quando precisar carregar uma resposta específica, por exemplo,
  // ao navegar para uma tela de detalhes ou edição.
  /// Opcional: busca direta por ID no cache.
  Future<AnswerEntity?> getById(int id);
}

/*
// Exemplo de uso:
final repo = MinhaImplementacaoDeAnswersRepository();
final lista = await repo.listAll();

// Dica: implemente esta interface usando um DAO local e um datasource remoto.
// Para testes, crie um mock que retorna dados fixos.

// Checklist de erros comuns e como evitar:
// - Erro de conversão de tipos (ex: id como string): ajuste o fromMap/toMap da entidade/DTO para aceitar múltiplos formatos.
// - Falha ao atualizar UI após sync: verifique se o widget está mounted antes de chamar setState.
// - Dados não aparecem após sync: adicione prints/logs para inspecionar o conteúdo do cache e o fluxo de conversão.
// - Problemas com Supabase (RLS, inicialização): consulte supabase_rls_remediation.md e supabase_init_debug_prompt.md.

// Referências úteis:
// - answers_cache_debug_prompt.md
// - supabase_init_debug_prompt.md
// - supabase_rls_remediation.md
*/
