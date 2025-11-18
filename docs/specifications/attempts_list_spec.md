# Especificação: API de Listagem de Tentativas (Attempts)

## Parâmetros Configurados
- **ENTITY_SINGULAR**: Attempt
- **ENTITY_PLURAL**: attempts
- **DTO_CLASS**: AttemptDto
- **FEATURE_FOLDER**: attempts
- **PAGE_DEFAULT**: 1
- **PAGE_SIZE_DEFAULT**: 20
- **MAX_PAGE_SIZE**: 100
- **SORT_BY_DEFAULT**: startedAt
- **INCLUDE_HINT**: quiz, user

---

## 1. Entradas (Query Parameters)

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|-------------|---------|-----------|
| `page` | integer | Não | 1 | Número da página (mín: 1) |
| `pageSize` | integer | Não | 20 | Itens por página (máx: 100) |
| `sortBy` | string | Não | "startedAt" | Campo de ordenação: `startedAt`, `score`, `finishedAt` |
| `sortDir` | string | Não | "desc" | Direção: `asc` ou `desc` |
| `quizId` | string | Não | - | Filtro por ID do quiz |
| `userId` | string | Não | - | Filtro por ID do usuário |
| `minScore` | number | Não | - | Score mínimo (0-100) |
| `include` | string[] | Não | [] | Relacionamentos: `["quiz"]`, `["user"]` |

**Validações:**
- `page < 1` → retorna página 1
- `pageSize > 100` → trunca para 100
- `sortBy` inválido → usa default "startedAt"
- `sortDir` diferente de "asc"/"desc" → usa "desc"
- `minScore` fora do range 0-100 → ignora filtro

---

## 2. Estrutura do DTO (AttemptDto)

**Campos obrigatórios:**
- `id`: string (UUID)
- `quizId`: string (ID do quiz)
- `correctCount`: integer (respostas corretas)
- `totalCount`: integer (total de questões)
- `score`: number (pontuação 0-100)
- `startedAt`: ISO8601 datetime

**Campos opcionais:**
- `userId`: string (ID do usuário - mascarado quando exibido)
- `finishedAt`: ISO8601 datetime (null se não finalizado)

**Campos incluíveis (via `include`):**
- `quiz`: objeto QuizDto (quando `include=["quiz"]`)
- `user`: objeto UserDto (quando `include=["user"]`)

---

## 3. Considerações de Performance

**Paginação:**
- **Offset-based** (atual): adequada para até ~10k registros
- **Cursor-based** (recomendada para >10k): usar `startedAt` + `id` como cursor
  - Exemplo: `?cursor=2025-10-01T12:00:00Z_a1b2c3d4&pageSize=20`
  - Retorna `nextCursor` no meta para próxima página

**Include:**
- Sem `include`: retorna apenas Attempt sem relacionamentos (mais rápido)
- Com `include=["quiz"]`: carrega dados do quiz (+ ~20-30% tempo)
- Com `include=["user"]`: carrega dados do usuário (+ ~20-30% tempo)
- Evitar múltiplos `include` em produção para listas longas

**Limites:**
- `pageSize` máximo: 100 (protege contra DoS)
- Timeout recomendado: 5s no backend
- Cache sugerido: 1 minuto para listagens sem filtros específicos

---

## 4. Permissões e Privacidade

- **Escopo de usuário**: por padrão, retorna apenas attempts do usuário autenticado
- **Admin**: pode filtrar por `userId` para ver attempts de outros usuários
- **Dados sensíveis**: 
  - `userId` deve ser mascarado na exibição: `"joao***@exemplo.com"` ou `"user-***456"`
  - `user.email` (quando incluído) deve ser parcialmente oculto
- **Rate limiting**: recomendado 200 req/min por usuário

---

## 5. Códigos de Resposta HTTP

| Código | Cenário |
|--------|---------|
| 200 | Sucesso |
| 400 | Parâmetros inválidos (ex: `page=-1`, `minScore=150`) |
| 401 | Não autenticado |
| 403 | Sem permissão para acessar attempts de outro usuário |
| 429 | Rate limit excedido |
| 500 | Erro interno do servidor |

---

## 6. Exemplo de Uso

**Requisição:**
```http
GET /api/attempts?page=1&pageSize=20&quizId=quiz-123&sortBy=startedAt&sortDir=desc&include=quiz
```

**Resposta:** Ver `contracts/attempts_list_response.json`

---

## 7. Cálculos Derivados

- **duration**: `finishedAt - startedAt` (em segundos)
- **accuracy**: `(correctCount / totalCount) * 100`
- **isPassed**: `score >= 60` (critério padrão de aprovação)

Esses campos podem ser calculados no frontend ou incluídos no backend dependendo da necessidade.
