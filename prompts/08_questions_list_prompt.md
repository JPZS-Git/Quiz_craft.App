`````markdown
````markdown
## Prompt: Gerar listagem de questões (questions)

Parâmetros (defina estes valores no início do prompt antes de executar)
---------------------------------------------------------------
- ENTITY_SINGULAR: Question    # nome singular legível (ex.: 'Question')
- ENTITY_PLURAL: questions     # nome plural legível em minúsculas (ex.: 'questions')
- DTO_CLASS: QuestionDto      # nome da classe/DTO usada no projeto
- FEATURE_FOLDER: questions   # pasta/feature onde o código vive
- PAGE_DEFAULT: 1             # página padrão
- PAGE_SIZE_DEFAULT: 20       # tamanho de página padrão
- MAX_PAGE_SIZE: 100          # limite máximo recomendado para pageSize
- SORT_BY_DEFAULT: createdAt  # campo de ordenação padrão
- INCLUDE_HINT: answers,attempt # relacionamentos opcionais sugeridos

OBS: Substitua os tokens acima antes de enviar o prompt ao agente ou forneça esses valores na invocação.

Contexto
---
Você é um agente que ajuda a produzir tanto a especificação de dados quanto, quando solicitado, código Flutter/Dart que implemente a listagem de questões (widget/fluxo) seguindo as convenções do repositório. O prompt abaixo está parametrizado para permitir gerar:

- uma especificação/contract (JSON) para a API/DAO que fornece a listagem;
- e opcionalmente, um widget Flutter/Dart muito semelhante ao `lib/features/questions/presentation/questions_page.dart`, com integração ao DAO local da feature.

Objetivo
---
Gerar (conforme modo solicitado na invocação) uma das seguintes saídas:

1. Especificação e exemplo de JSON (contrato de dados) para a listagem paginada e filtrável de `Question`;
2. Código Flutter/Dart que implemente a página/listagem de `questions` (widget), integrando com o DAO local da feature, e obedecendo às convenções do projeto (idioma, nomes, patterns de persistência e handlers de UI).

Entradas esperadas (inputs)
---
- filters: objeto opcional com critérios de busca (por exemplo: {"q": "texto", "topic": "Biologia"})
- page: número da página (inteiro, default 1)
- pageSize: itens por página (inteiro, default 20)
- sortBy: campo para ordenação (por exemplo: "createdAt", "order")
- sortDir: direção da ordenação ("asc" ou "desc")
- include: lista opcional de relacionamentos a incluir (por exemplo: ["answers","attempt"]) — o agente deve explicar resoluções possíveis.

Se o modo de execução pedir geração de código, o agente deve aceitar parâmetros adicionais (passe-os como tokens no topo):

- DAO_CLASS_HINT: QuestionsLocalDaoSharedPrefs  # sugestão de nome do DAO local a ser importado
- DAO_METHODS: [listAll, upsertAll, clear]     # métodos esperados no DAO (ajuste se diferente)

Regras e restrições
---
- Se o modo for "especificação", produza apenas a descrição/JSON (não gere código). Se o modo for "implementar_widget", gere código Flutter/Dart que implemente a página/listagem conforme as instruções abaixo.
- Campos sensíveis devem ser mascarados na saída de exemplo (por exemplo: CPF/CNPJ parcialmente ocultos) e, no código gerado, aplicar máscaras quando exibir tais campos. Para `Question` normalmente não há dados sensíveis, mantenha a nota para casos futuros.
- A resposta deve considerar performance: indicar limites razoáveis de pageSize (por exemplo <= 100), sugerir cursor-based pagination para grandes volumes e limitar atributos carregados quando `include` não for solicitado.
- Permissões: o código gerado e a especificação devem mencionar que a listagem respeita permissões/escopo do usuário (exibir apenas questões que o usuário tem acesso).
- Ao gerar código, respeite os padrões do repositório: estrutura de pastas (`lib/features/{FEATURE_FOLDER}/presentation`), idioma (português nas labels), tratamento de erros (`try/catch`) e feedback via `SnackBar`.
- Todos os diálogos gerados devem ser não-dismissable ao tocar fora (use `showDialog(..., barrierDismissible: false)`).

Escopo de geração de código (quando aplicável)
---
O agente deve gerar um widget Flutter que implemente apenas a listagem (modo "listing-only"). No modo listing-only o widget deve conter, no mínimo:

- Carregamento inicial via DAO (`listAll`) e indicação de loading (CircularProgressIndicator).
- `ListView.builder` para apresentar os itens.
- Renderização resumida de cada `Question` (ex.: `text`, `order`, número de `answers` quando presente).
- Renderização condicional de `answers` quando `include` for solicitado — implementar como expansão inline opcional (opcional para listing-only), mas o widget deve sempre suportar a presença do campo `answers` no DTO.
- Integração com DAO local da feature: identificar e importar o DAO (por exemplo `QuestionsLocalDaoSharedPrefs`) e usar os métodos de leitura (`listAll`) — operações de escrita/remoção/edição devem ser mantidas fora deste arquivo e implementadas separadamente.

Observação: funcionalidades adicionais (editar, remover por swipe, seleção com diálogo de ações) devem ser implementadas em arquivos/pedidos separados.

Contrato de DTO / Campos esperados
---
O agente deve mapear o DTO aos campos usados no código existente. Campos normalmente presentes no projeto e em `QuestionDto`:

- id: string
- text: string
- answers: list of AnswerDto (opcional)
- order: int
- createdAt / updatedAt: ISO8601 datetimes
- topic: string (opcional)

O agente deve preferir a classe `{DTO_CLASS}` quando existir e gerar import/uso desta classe no código produzido.

Formato de saída desejado (modo: especificação)
---
Quando em modo de especificação, o agente deve apresentar um exemplo JSON com os seguintes elementos:

- meta: { total: inteiro, page: inteiro, pageSize: inteiro, totalPages: inteiro }
- filtersApplied: objeto descrevendo os filtros usados
- data: lista de objetos de question, cada um contendo ao menos os campos abaixo

Campos de cada question (exemplo mínimo)
---
- id: string (UUID ou identificador)
- text: string
- order: integer
- answers: array opcional de objetos Answer (cada um com id,text,isCorrect,index)
- topic: string (opcional)
- createdAt: ISO8601 datetime
- updatedAt: ISO8601 datetime

Exemplo de saída (JSON)
---
```json
{
  "meta": {
    "total": 124,
    "page": 1,
    "pageSize": 20,
    "totalPages": 7
  },
  "filtersApplied": {
    "q": "fotossintese",
    "topic": "Biologia",
    "sortBy": "createdAt",
    "sortDir": "asc"
  },
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440010",
      "text": "O que é fotossíntese?",
      "order": 1,
      "topic": "Biologia",
      "answers": [
        { "id": "a1", "text": "Processo de ...", "isCorrect": true, "index": 0 }
      ],
      "createdAt": "2024-03-15T14:30:00Z",
      "updatedAt": "2024-08-22T10:12:45Z"
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
1. O agente gera um widget Flutter/Dart que implementa a página de listagem com comportamento compatível (loading, list, image handling se aplicável, FAB opcional).
2. O widget integra com o DAO local da feature — identifica o DAO existente, importa e usa os métodos padrão (ex.: `listAll`) ou adapta conforme encontrado.
3. Operações de persistência são envolvidas em `try/catch` e o UX apresenta `SnackBar`s de sucesso/erro. O código respeita nomes/pastas do projeto.
4. Ao finalizar, o agente fornece instruções de teste manual (passos rápidos) e um breve resumo das alterações/arquivos propostos.

Notas adicionais para o agente
---
- Explique brevemente alternativas de paginação (offset/limit vs cursor-based) e recomende cursor-based para grandes volumes de dados.
- Sugira campos opcionais que podem ser incluídos se solicitado (ex.: tags, difficultyLevel, lastSeenAt) e como isso impacta performance.
- Indique tratamentos de erro/validação (por exemplo: page inválida => retornar página 1, pageSize fora do intervalo => truncar para limites permitidos).

Geração de código e limitações
---
Quando o modo for `implementar_widget`, o agente pode gerar código Dart/Flutter que modifica ou cria arquivos dentro de `lib/features/{FEATURE_FOLDER}/presentation` e `lib/features/{FEATURE_FOLDER}/infrastructure` (se necessário). Sempre:

- prefira reutilizar componentes existentes (por exemplo componentes compartilhados já presentes no projeto);
- adicione apenas os arquivos mínimos necessários (ex.: `questions_page.dart`, `question_list_widget.dart`, `question_list_item.dart`) e siga as convenções de nomes e pastas;
- não faça alterações em arquivos não relacionados sem justificativa.

Se não houver DAO detectada automaticamente, o agente deve instruir o desenvolvedor sobre a API esperada do DAO (métodos: `listAll`, `upsertAll`, `clear`) e fornecer um stub simples comentado para implementação posterior.

Resumo
---
Este prompt agora está parametrizável e adaptado à feature `questions`. Configure os tokens no topo (`ENTITY_SINGULAR`, `DTO_CLASS`, `FEATURE_FOLDER`, `DAO_CLASS_HINT`, etc.) antes de executar o prompt com o agente.

````

`````
