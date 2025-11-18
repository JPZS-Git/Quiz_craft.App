````markdown
## Prompt: Gerar listagem de respostas (answers)

Parâmetros (defina estes valores no início do prompt antes de executar)
---------------------------------------------------------------
- ENTITY_SINGULAR: Resposta   # nome singular legível (ex.: 'Fornecedor')
- ENTITY_PLURAL: respostas    # nome plural legível em minúsculas (ex.: 'fornecedores')
- DTO_CLASS: AnswerDto        # nome da classe/DTO usada no projeto (ex.: 'ProviderDto')
- FEATURE_FOLDER: answers      # pasta/feature onde o código vive (ex.: 'providers')
- PAGE_DEFAULT: 1                # página padrão
- PAGE_SIZE_DEFAULT: 20          # tamanho de página padrão
- MAX_PAGE_SIZE: 100             # limite máximo recomendado para pageSize
- SORT_BY_DEFAULT: createdAt         # campo de ordenação padrão
- INCLUDE_HINT: question # relacionamentos opcionais sugeridos

OBS: Substitua os tokens acima antes de enviar o prompt ao agente ou forneça esses valores na invocação.

Contexto
---
Você é um agente que ajuda a produzir tanto a especificação de dados quanto, quando solicitado, código Flutter/Dart que implemente a listagem de Respostas (widget/fluxo) seguindo as convenções do repositório. O prompt abaixo está parametrizado para permitir gerar:

- uma especificação/contract (JSON) para a API/DAO que fornece a listagem;
- e opcionalmente, um widget Flutter muito semelhante ao `lib/features/questions/presentation/questions_page.dart`, com integração ao DAO local da feature.

Objetivo
---
Gerar (conforme modo solicitado na invocação) uma das seguintes saídas:

1. Especificação e exemplo de JSON (contrato de dados) para a listagem paginada e filtrável.
2. Código Flutter/Dart que implemente a página/listagem de answers (widget), integrando com o DAO local da feature, e obedecendo às convenções do projeto (idioma, nomes, patterns de persistência e handlers de UI).

Entradas esperadas (inputs)
---
- filters: objeto opcional com critérios de busca (por exemplo: {"questionId": "uuid", "isCorrect": true})
- page: número da página (inteiro, default 1)
- pageSize: itens por página (inteiro, default 20)
- sortBy: campo para ordenação (por exemplo: "createdAt", "text")
- sortDir: direção da ordenação ("asc" ou "desc")
- include: lista opcional de relacionamentos a incluir (por exemplo: ["question"]) — o agente deve explicar resoluções possíveis.

Se o modo de execução pedir geração de código, o agente deve aceitar parâmetros adicionais (passe-os como tokens no topo):

- DAO_CLASS_HINT: AnswersLocalDaoSharedPrefs  # sugestão de nome do DAO local a ser importado
- DAO_METHODS: [listAll, upsertAll, clear]     # métodos esperados no DAO (ajuste se diferente)

Regras e restrições
---
- Se o modo for "especificação", produza apenas a descrição/JSON (não gere código). Se o modo for "implementar_widget", gere código Flutter/Dart que implemente a página/listagem conforme as instruções abaixo.
- Campos sensíveis devem ser mascarados na saída de exemplo (se houver) e, no código gerado, aplicar máscaras quando exibir tais campos.
- A resposta deve considerar performance: indicar limites razoáveis de pageSize (por exemplo <= 100), sugerir cursor-based pagination para grandes volumes e limitar atributos carregados quando `include` não for solicitado.
- Permissões: o código gerado e a especificação devem mencionar que a listagem respeita permissões/escopo do usuário (exibir apenas respostas que o usuário tem acesso).
- Ao gerar código, respeite os padrões do repositório: estrutura de pastas (`lib/features/{FEATURE_FOLDER}/presentation`), idioma (português nas labels), tratamento de erros (`try/catch`) e feedback via `SnackBar`.
 - Ao gerar código, respeite os padrões do repositório: estrutura de pastas (`lib/features/{FEATURE_FOLDER}/presentation`), idioma (português nas labels), tratamento de erros (`try/catch`) e feedback via `SnackBar`.
 - Importante: todos os diálogos gerados devem ser não-dismissable ao tocar fora (use `showDialog(..., barrierDismissible: false)` ou equivalente). O fechamento deve ocorrer somente pelos botões/ações explícitas do diálogo.

Escopo de geração de código (quando aplicável)
---
O agente deve gerar um widget Flutter que implemente apenas a listagem (modo "listing-only"). No modo listing-only o widget deve conter, no mínimo:

- Carregamento inicial via DAO (`listAll`) e indicação de loading (CircularProgressIndicator).
- `ListView.builder` para apresentar os itens com expansão inline para mostrar detalhes.
- Exibição de `text` (texto da resposta) e `isCorrect` (indicador visual se a resposta está correta).
- Integração com DAO local da feature: identificar e importar o DAO (por exemplo `AnswersLocalDaoSharedPrefs`) e usar os métodos de leitura (`listAll`) — operações de escrita/remoção/edição devem ser mantidas fora deste arquivo e implementadas separadamente.

Observação: funcionalidades adicionais (editar, remover por swipe, seleção com diálogo de ações) devem ser implementadas em arquivos/pedidos separados. Veja os prompts complementares criados ao lado para cada uma dessas responsabilidades.

Contrato de DTO / Campos esperados
---
O agente deve mapear o DTO aos campos usados no código existente. Campos normalmente presentes no projeto e no `answer_entity.dart`:

- id: string
- questionId: string
- text: string
- isCorrect: boolean
- createdAt / updatedAt: ISO8601 datetimes (opcional)

O agente deve preferir a classe `{DTO_CLASS}` quando existir e gerar import/uso desta classe no código produzido.

Formato de saída desejado (modo: especificação)
---
Quando em modo de especificação, o agente deve apresentar um exemplo JSON com os seguintes elementos:

- meta: { total: inteiro, page: inteiro, pageSize: inteiro, totalPages: inteiro }
- filtersApplied: objeto descrevendo os filtros usados
- data: lista de objetos de answer, cada um contendo ao menos os campos abaixo

Campos de cada answer (exemplo mínimo)
---
- id: string (UUID ou identificador)
- questionId: string (UUID da pergunta associada)
- text: string (texto da resposta)
- isCorrect: boolean (indica se é a resposta correta)
- createdAt: ISO8601 datetime (opcional)
- updatedAt: ISO8601 datetime (opcional)
- question: objeto opcional com { id, text, category } (quando include=["question"])

Exemplo de saída (JSON)
---
```json
{
  "meta": {
    "total": 45,
    "page": 1,
    "pageSize": 20,
    "totalPages": 3
  },
  "filtersApplied": {
    "questionId": "b6f8c1f2-3d2a-4a9e-9f6b-1a2b3c4d5e6f",
    "sortBy": "createdAt",
    "sortDir": "asc"
  },
  "data": [
    {
      "id": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
      "questionId": "b6f8c1f2-3d2a-4a9e-9f6b-1a2b3c4d5e6f",
      "text": "Rio de Janeiro",
      "isCorrect": false,
      "createdAt": "2024-03-12T10:15:30Z",
      "updatedAt": "2025-07-02T08:12:00Z"
    },
    {
      "id": "b2c3d4e5-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
      "questionId": "b6f8c1f2-3d2a-4a9e-9f6b-1a2b3c4d5e6f",
      "text": "Brasília",
      "isCorrect": true,
      "createdAt": "2024-03-12T10:16:00Z",
      "updatedAt": "2025-07-02T08:13:00Z"
    }
  ]
}
```

Critérios de aceitação
---
Modo: especificação
1. O agente descreve claramente quais inputs aceita e como eles afetam a listagem.
2. Fornece o formato de saída (meta + data) e um exemplo JSON válido.
3. Informa restrições (pageSize máximo, ordenação padrão) e considerações sobre permissões e privacidade.

Modo: implementar_widget
1. O agente gera um widget Flutter/Dart que implementa a página de listagem com comportamento compatível com `questions_page.dart` (loading, refresh, list, expansion inline).
2. O widget integra com o DAO local da feature — identifica o DAO existente, importa e usa os métodos padrão (ex.: `listAll`, `upsertAll`, `clear`) ou adapta conforme encontrado.
3. Operações de persistência são envolvidas em `try/catch` e o UX apresenta `SnackBar`s de sucesso/erro. O código respeita nomes/pastas do projeto.
4. Ao finalizar, o agente fornece instruções de teste manual (passos rápidos) e um breve resumo das alterações/arquivos propostos.

Notas adicionais para o agente
---
- Explique brevemente alternativas de paginação (offset/limit vs cursor-based) e recomende cursor-based para grandes volumes de dados.
- Sugira campos opcionais que podem ser incluídos se solicitado (ex.: feedback do usuário sobre a resposta) e como isso impacta performance.
- Indique tratamentos de erro/validação (por exemplo: page inválida => retornar página 1, pageSize fora do intervalo => truncar para limites permitidos).

Geração de código e limitações
---
Quando o modo for `implementar_widget`, o agente pode gerar código Dart/Flutter que modifica ou cria arquivos dentro de `lib/features/{FEATURE_FOLDER}/presentation` e `lib/features/{FEATURE_FOLDER}/infrastructure` (se necessário). Sempre:

- prefira reutilizar componentes existentes quando detectados no repositório;
- adicione apenas os arquivos mínimos necessários (ex.: `answers_page.dart`) e siga as convenções de nomes e pastas;
- não faça alterações em arquivos não relacionados sem justificativa.

Se não houver DAO detectada automaticamente, o agente deve instruir o desenvolvedor sobre a API esperada do DAO (métodos: `listAll`, `upsertAll`, `clear`) e fornecer um stub simples comentado para implementação posterior.

Resumo
---
Este prompt agora é parametrizável e suporta dois modos: gerar especificação (JSON/contract) ou gerar implementação Flutter/Dart de uma página de listagem compatível com `questions_page.dart`. Configure os tokens no topo (`ENTITY_SINGULAR`, `DTO_CLASS`, `FEATURE_FOLDER`, `DAO_CLASS_HINT`, etc.) antes de executar o prompt com o agente.

````
