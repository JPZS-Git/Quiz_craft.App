````markdown
## Prompt: Gerar listagem de quizzes (quizzes)

Parâmetros (defina estes valores no início do prompt antes de executar)
---------------------------------------------------------------
- ENTITY_SINGULAR: Quiz   # nome singular legível (ex.: 'Fornecedor')
- ENTITY_PLURAL: quizzes    # nome plural legível em minúsculas (ex.: 'fornecedores')
- DTO_CLASS: QuizDto        # nome da classe/DTO usada no projeto (ex.: 'ProviderDto')
- FEATURE_FOLDER: quizzes      # pasta/feature onde o código vive (ex.: 'providers')
- PAGE_DEFAULT: 1                # página padrão
- PAGE_SIZE_DEFAULT: 20          # tamanho de página padrão
- MAX_PAGE_SIZE: 100             # limite máximo recomendado para pageSize
- SORT_BY_DEFAULT: createdAt         # campo de ordenação padrão
- INCLUDE_HINT: author,questions # relacionamentos opcionais sugeridos

OBS: Substitua os tokens acima antes de enviar o prompt ao agente ou forneça esses valores na invocação.

Contexto
---
Você é um agente que ajuda a produzir tanto a especificação de dados quanto, quando solicitado, código Flutter/Dart que implemente a listagem de Quizzes (widget/fluxo) seguindo as convenções do repositório. O prompt abaixo está parametrizado para permitir gerar:

- uma especificação/contract (JSON) para a API/DAO que fornece a listagem;
- e opcionalmente, um widget Flutter muito semelhante ao `lib/features/questions/presentation/questions_page.dart`, com integração ao DAO local da feature.

Objetivo
---
Gerar (conforme modo solicitado na invocação) uma das seguintes saídas:

1. Especificação e exemplo de JSON (contrato de dados) para a listagem paginada e filtrável.
2. Código Flutter/Dart que implemente a página/listagem de quizzes (widget), integrando com o DAO local da feature, e obedecendo às convenções do projeto (idioma, nomes, patterns de persistência e handlers de UI).

Entradas esperadas (inputs)
---
- filters: objeto opcional com critérios de busca (por exemplo: {"q": "título", "authorId": "uuid", "topic": "História", "isPublished": true})
- page: número da página (inteiro, default 1)
- pageSize: itens por página (inteiro, default 20)
- sortBy: campo para ordenação (por exemplo: "title", "createdAt", "questionsCount")
- sortDir: direção da ordenação ("asc" ou "desc")
- include: lista opcional de relacionamentos a incluir (por exemplo: ["author", "questions"]) — o agente deve explicar resoluções possíveis.

Se o modo de execução pedir geração de código, o agente deve aceitar parâmetros adicionais (passe-os como tokens no topo):

- DAO_CLASS_HINT: QuizzesLocalDaoSharedPrefs  # sugestão de nome do DAO local a ser importado
- DAO_METHODS: [listAll, upsertAll, clear]     # métodos esperados no DAO (ajuste se diferente)

Regras e restrições
---
- Se o modo for "especificação", produza apenas a descrição/JSON (não gere código). Se o modo for "implementar_widget", gere código Flutter/Dart que implemente a página/listagem conforme as instruções abaixo.
- Campos sensíveis devem ser mascarados na saída de exemplo (se houver) e, no código gerado, aplicar máscaras quando exibir tais campos.
- A resposta deve considerar performance: indicar limites razoáveis de pageSize (por exemplo <= 100), sugerir cursor-based pagination para grandes volumes e limitar atributos carregados quando `include` não for solicitado.
- Permissões: o código gerado e a especificação devem mencionar que a listagem respeita permissões/escopo do usuário (exibir apenas quizzes publicados ou do próprio usuário).
- Ao gerar código, respeite os padrões do repositório: estrutura de pastas (`lib/features/{FEATURE_FOLDER}/presentation`), idioma (português nas labels), tratamento de erros (`try/catch`) e feedback via `SnackBar`.
 - Ao gerar código, respeite os padrões do repositório: estrutura de pastas (`lib/features/{FEATURE_FOLDER}/presentation`), idioma (português nas labels), tratamento de erros (`try/catch`) e feedback via `SnackBar`.
 - Importante: todos os diálogos gerados devem ser não-dismissable ao tocar fora (use `showDialog(..., barrierDismissible: false)` ou equivalente). O fechamento deve ocorrer somente pelos botões/ações explícitas do diálogo.

Escopo de geração de código (quando aplicável)
---
O agente deve gerar um widget Flutter que implemente apenas a listagem (modo "listing-only"). No modo listing-only o widget deve conter, no mínimo:

- Carregamento inicial via DAO (`listAll`) e indicação de loading (CircularProgressIndicator).
- `ListView.builder` para apresentar os itens com expansão inline para mostrar detalhes.
- Exibição de `title` (título do quiz), `topics` (chips/tags), `questionsCount` (quantidade de perguntas).
- Badge visual para indicar se o quiz está publicado (`isPublished`).
- Integração com DAO local da feature: identificar e importar o DAO (por exemplo `QuizzesLocalDaoSharedPrefs`) e usar os métodos de leitura (`listAll`) — operações de escrita/remoção/edição devem ser mantidas fora deste arquivo e implementadas separadamente.

Observação: funcionalidades adicionais (editar, remover por swipe, seleção com diálogo de ações) devem ser implementadas em arquivos/pedidos separados. Veja os prompts complementares criados ao lado para cada uma dessas responsabilidades.

Contrato de DTO / Campos esperados
---
O agente deve mapear o DTO aos campos usados no código existente. Campos normalmente presentes no projeto e no `quiz_entity.dart`:

- id: string (UUID)
- title: string
- description: string (opcional, descrição do quiz)
- authorId: string (opcional, UUID do autor)
- topics: array[string] (lista de tópicos/categorias)
- questions: array[QuestionDto] (lista de perguntas, carregada quando include=["questions"])
- isPublished: boolean (indica se o quiz está publicado)
- createdAt: ISO8601 datetime

O agente deve preferir a classe `{DTO_CLASS}` quando existir e gerar import/uso desta classe no código produzido.

Formato de saída desejado (modo: especificação)
---
Quando em modo de especificação, o agente deve apresentar um exemplo JSON com os seguintes elementos:

- meta: { total: inteiro, page: inteiro, pageSize: inteiro, totalPages: inteiro }
- filtersApplied: objeto descrevendo os filtros usados
- data: lista de objetos de quiz, cada um contendo ao menos os campos abaixo

Campos de cada quiz (exemplo mínimo)
---
- id: string (UUID ou identificador)
- title: string
- description: string (opcional)
- authorId: string (UUID do autor)
- topics: array[string] (ex: ["História", "Brasil Colônia"])
- questionsCount: integer (quantidade de perguntas, derivado de questions.length)
- isPublished: boolean (ex: true)
- createdAt: ISO8601 datetime
- author: objeto opcional com { id, name, email } (quando include=["author"])
- questions: array opcional de perguntas (quando include=["questions"])

Exemplo de saída (JSON)
---
```json
{
  "meta": {
    "total": 156,
    "page": 1,
    "pageSize": 20,
    "totalPages": 8
  },
  "filtersApplied": {
    "isPublished": true,
    "topic": "História",
    "sortBy": "createdAt",
    "sortDir": "desc"
  },
  "data": [
    {
      "id": "q1a2b3c4-5d6e-7f8g-9h0i-1j2k3l4m5n6o",
      "title": "História do Brasil - Período Colonial",
      "description": "Quiz sobre o período colonial brasileiro, abordando economia, sociedade e política.",
      "authorId": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
      "topics": ["História", "Brasil", "Período Colonial"],
      "questionsCount": 20,
      "isPublished": true,
      "createdAt": "2024-11-10T14:30:00Z"
    },
    {
      "id": "q2b3c4d5-6e7f-8g9h-0i1j-2k3l4m5n6o7p",
      "title": "Matemática Básica - Frações",
      "description": "Exercícios práticos sobre operações com frações.",
      "authorId": "b2c3d4e5-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
      "topics": ["Matemática", "Ensino Fundamental"],
      "questionsCount": 15,
      "isPublished": true,
      "createdAt": "2024-11-12T09:15:00Z"
    },
    {
      "id": "q3c4d5e6-7f8g-9h0i-1j2k-3l4m5n6o7p8q",
      "title": "Geografia Física - Relevo Mundial",
      "description": null,
      "authorId": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
      "topics": ["Geografia", "Relevo"],
      "questionsCount": 12,
      "isPublished": false,
      "createdAt": "2024-11-15T16:45:00Z"
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
- Sugira campos opcionais que podem ser incluídos se solicitado (ex.: lista completa de perguntas com respostas, informações do autor) e como isso impacta performance.
- Indique tratamentos de erro/validação (por exemplo: page inválida => retornar página 1, pageSize fora do intervalo => truncar para limites permitidos).
- Campo derivado `questionsCount`: calcular como `questions.length` ao carregar do DAO.

Geração de código e limitações
---
Quando o modo for `implementar_widget`, o agente pode gerar código Dart/Flutter que modifica ou cria arquivos dentro de `lib/features/{FEATURE_FOLDER}/presentation` e `lib/features/{FEATURE_FOLDER}/infrastructure` (se necessário). Sempre:

- prefira reutilizar componentes existentes quando detectados no repositório;
- adicione apenas os arquivos mínimos necessários (ex.: `quizzes_page.dart`) e siga as convenções de nomes e pastas;
- não faça alterações em arquivos não relacionados sem justificativa.

Se não houver DAO detectada automaticamente, o agente deve instruir o desenvolvedor sobre a API esperada do DAO (métodos: `listAll`, `upsertAll`, `clear`) e fornecer um stub simples comentado para implementação posterior.

Resumo
---
Este prompt agora é parametrizável e suporta dois modos: gerar especificação (JSON/contract) ou gerar implementação Flutter/Dart de uma página de listagem compatível com `questions_page.dart`. Configure os tokens no topo (`ENTITY_SINGULAR`, `DTO_CLASS`, `FEATURE_FOLDER`, `DAO_CLASS_HINT`, etc.) antes de executar o prompt com o agente.

````
