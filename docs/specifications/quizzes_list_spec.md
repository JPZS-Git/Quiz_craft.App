# Especificação: Listagem de Quizzes (Quizzes)

## 1. Parâmetros de Query

A API/DAO de listagem de quizzes aceita os seguintes parâmetros:

| Parâmetro | Tipo | Obrigatório | Padrão | Descrição |
|-----------|------|-------------|--------|-----------|
| `page` | integer | Não | 1 | Número da página (≥ 1) |
| `pageSize` | integer | Não | 20 | Itens por página (1-100) |
| `sortBy` | string | Não | `createdAt` | Campo para ordenação: `title`, `createdAt`, `questionsCount` |
| `sortDir` | string | Não | `desc` | Direção: `asc` ou `desc` |
| `q` | string | Não | - | Busca por título do quiz |
| `authorId` | string | Não | - | Filtrar por ID do autor específico |
| `topic` | string | Não | - | Filtrar por tópico/categoria |
| `isPublished` | boolean | Não | - | Filtrar por quizzes publicados/não publicados |
| `minQuestions` | integer | Não | - | Filtrar por quantidade mínima de perguntas |
| `include` | array[string] | Não | `[]` | Relacionamentos a incluir: `["author", "questions"]` |

### Validações
- Se `page` < 1, usar 1
- Se `pageSize` < 1 ou > 100, truncar para [1, 100]
- Se `sortBy` inválido, usar `createdAt`
- Se `sortDir` não for `asc` ou `desc`, usar `desc`
- Se `minQuestions` < 0, ignorar filtro

## 2. Estrutura do DTO (QuizDto)

```dart
{
  "id": "string",              // UUID único do quiz
  "title": "string",           // Título do quiz
  "description": "string",     // Descrição (opcional)
  "authorId": "string",        // UUID do autor (opcional)
  "topics": ["string"],        // Lista de tópicos/categorias
  "questions": [QuestionDto],  // Lista de perguntas (array, carregado se include)
  "isPublished": boolean,      // Status de publicação
  "createdAt": "string"        // ISO8601 datetime
}
```

### Campo Derivado
- **questionsCount**: Calculado como `questions.length` ao carregar do DAO

## 3. Performance e Escalabilidade

### Recomendações
- **Paginação**: Implementada com offset/limit (adequado para volumes pequenos/médios)
- **Cursor-based**: Recomendado se a tabela de quizzes ultrapassar 10.000 registros
- **Índices**: Criar índices em `title`, `authorId`, `isPublished`, `createdAt` para otimizar filtros e ordenação
- **Limite de pageSize**: Máximo de 100 itens por página para evitar sobrecarga
- **Include questions**: Carregar perguntas completas apenas quando solicitado (include=["questions"])
  - Sem include: retornar apenas metadados do quiz
  - Com include: aumenta payload significativamente (cada pergunta tem respostas)
- **Busca textual**: Implementar índice full-text em `title` e `description`

### Considerações de Cache
- Quizzes publicados são relativamente estáveis
- Cache local via SharedPreferences é adequado
- TTL sugerido: 12 horas para quizzes publicados, 5 minutos para rascunhos
- Invalidar cache ao criar/editar/publicar quiz

## 4. Permissões e Privacidade

### Controle de Acesso
- **Quizzes publicados**: Visíveis para todos os usuários
- **Quizzes não publicados (rascunhos)**: Visíveis apenas para o próprio autor
- **Filtro por autor**: Qualquer usuário pode listar quizzes publicados de um autor específico
- **Administradores**: Podem ver todos os quizzes (publicados e não publicados)

### Regras de Exibição
- Lista pública: mostrar apenas `isPublished: true`
- Perfil do autor: mostrar seus próprios quizzes (publicados e rascunhos)
- Busca: indexar apenas quizzes publicados

### Auditoria
- Registrar acessos a quizzes (especialmente não publicados)
- Logs devem incluir: userId (quem acessou), quizId, timestamp
- Rate limiting: 200 requisições/minuto por usuário

## 5. Códigos de Resposta HTTP (para API futura)

| Código | Descrição |
|--------|-----------|
| 200 | Sucesso - Listagem retornada |
| 400 | Parâmetros inválidos (page, pageSize, minQuestions fora dos limites) |
| 401 | Não autenticado |
| 403 | Sem permissão para acessar quizzes não publicados |
| 429 | Rate limit excedido (200 requisições/min) |
| 500 | Erro interno do servidor |

## 6. Exemplo de Resposta

### Listagem básica (sem includes)

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

### Com include=["author"]

```json
{
  "meta": {
    "total": 156,
    "page": 1,
    "pageSize": 20,
    "totalPages": 8
  },
  "filtersApplied": {
    "include": ["author"]
  },
  "data": [
    {
      "id": "q1a2b3c4-5d6e-7f8g-9h0i-1j2k3l4m5n6o",
      "title": "História do Brasil - Período Colonial",
      "description": "Quiz sobre o período colonial brasileiro.",
      "authorId": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
      "topics": ["História", "Brasil"],
      "questionsCount": 20,
      "isPublished": true,
      "createdAt": "2024-11-10T14:30:00Z",
      "author": {
        "id": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
        "name": "João Silva",
        "email": "j***a@example.com"
      }
    }
  ]
}
```

### Com include=["questions"] (primeiras perguntas)

```json
{
  "meta": {
    "total": 1,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  },
  "filtersApplied": {
    "include": ["questions"]
  },
  "data": [
    {
      "id": "q1a2b3c4-5d6e-7f8g-9h0i-1j2k3l4m5n6o",
      "title": "História do Brasil - Período Colonial",
      "description": "Quiz sobre o período colonial brasileiro.",
      "authorId": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
      "topics": ["História", "Brasil"],
      "questionsCount": 2,
      "isPublished": true,
      "createdAt": "2024-11-10T14:30:00Z",
      "questions": [
        {
          "id": "quest1",
          "text": "Qual foi o primeiro produto de exportação do Brasil colonial?",
          "category": "História",
          "difficulty": "medium"
        },
        {
          "id": "quest2",
          "text": "Em que século teve início o período colonial brasileiro?",
          "category": "História",
          "difficulty": "easy"
        }
      ]
    }
  ]
}
```

## 7. Casos de Uso Comuns

### Listar quizzes publicados mais recentes
```
GET /quizzes?isPublished=true&sortBy=createdAt&sortDir=desc
```

### Buscar quizzes por título
```
GET /quizzes?q=Matemática&isPublished=true
```

### Filtrar quizzes por tópico
```
GET /quizzes?topic=História&isPublished=true&sortBy=questionsCount&sortDir=desc
```

### Listar quizzes de um autor específico
```
GET /quizzes?authorId=a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p&isPublished=true
```

### Obter quizzes com perguntas incluídas
```
GET /quizzes?include=["questions"]&pageSize=5
```

### Filtrar por quantidade mínima de perguntas
```
GET /quizzes?minQuestions=10&isPublished=true
```

## 8. Tratamento de Erros no Widget Flutter

### Cenários de Erro
1. **DAO vazio**: Exibir mensagem "Nenhum quiz encontrado" com ícone e sugestão
2. **Erro ao carregar**: Exibir mensagem de erro com botão "Tentar novamente"
3. **Timeout**: Após 10s, cancelar operação e informar usuário
4. **Quiz sem perguntas**: Exibir badge "Vazio" e desabilitar ação de iniciar

### Feedback Visual
- **Loading**: CircularProgressIndicator centralizado
- **Empty State**: Ícone de quiz + texto explicativo
- **Error State**: Ícone de erro + mensagem + botão de retry
- **Success**: Transição suave para lista com animação

## 9. Considerações de UX

### Display de Quizzes
- **Título**: Texto principal em negrito
- **Descrição**: Texto secundário (truncado se muito longo)
- **Topics**: Chips/tags coloridos
- **Status**: Badge "PUBLICADO" (verde) ou "RASCUNHO" (amarelo)
- **Contagem**: Ícone de pergunta + número (ex: "📝 20 perguntas")
- **Data**: Formatada como "10/11/2024"

### Cards Expansíveis
- **Compacto**: Título, topics, questionsCount, status
- **Expandido**: + Descrição completa, author info, data de criação, botão "Iniciar Quiz"

### Interação
- Pull-to-refresh para recarregar lista
- Tap no card para expandir/colapsar detalhes
- Botão "Iniciar Quiz" para quizzes publicados com perguntas
- Filtro rápido: "Todos", "Meus Quizzes", "Favoritos"

### Filtros e Ordenação
- Dropdown para ordenação (Mais Recentes, Título A-Z, Mais Perguntas)
- Filtro por tópico (chips selecionáveis)
- Toggle "Apenas Publicados"
- Busca por título no AppBar

### Acessibilidade
- Labels semânticos para screen readers
- Contrast ratio adequado para badges
- Tamanho mínimo de toque: 48x48 dp
- Descrição textual do status e contagem

## 10. Campos Derivados e Calculados

### questionsCount
- Calculado como `questions.length`
- Usado para ordenação e filtros
- Exibido como badge no card

### Tempo Estimado
- Calcular baseado em `questionsCount * 30 segundos` (média por pergunta)
- Exibir como "~10 min" no card
- Fórmula: `Math.ceil(questionsCount * 0.5)` minutos

### Dificuldade Média
- Agregado das dificuldades das perguntas (easy=1, medium=2, hard=3)
- Exibir como badge: "Fácil", "Médio", "Difícil"
- Apenas se include=["questions"]

### Status Badge
- Verde "PUBLICADO" se `isPublished == true`
- Amarelo "RASCUNHO" se `isPublished == false`
- Posicionado no canto superior direito do card

### Topics Display
- Mostrar até 3 chips no modo compacto
- Exibir "+N mais" se houver mais tópicos
- No modo expandido, mostrar todos os tópicos
