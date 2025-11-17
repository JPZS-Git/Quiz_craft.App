# Especificação: API de Listagem de Questões (Questions)

## Parâmetros Configurados
- **ENTITY_SINGULAR**: Question
- **ENTITY_PLURAL**: questions
- **DTO_CLASS**: QuestionDto
- **FEATURE_FOLDER**: questions
- **PAGE_DEFAULT**: 1
- **PAGE_SIZE_DEFAULT**: 20
- **MAX_PAGE_SIZE**: 100
- **SORT_BY_DEFAULT**: order
- **INCLUDE_HINT**: answers, attempt

---

## 1. Entradas (Query Parameters)

| Parâmetro | Tipo | Obrigatório | Default | Descrição |
|-----------|------|-------------|---------|-----------|
| `page` | integer | Não | 1 | Número da página (mín: 1) |
| `pageSize` | integer | Não | 20 | Itens por página (máx: 100) |
| `sortBy` | string | Não | "order" | Campo de ordenação: `order`, `text`, `createdAt` |
| `sortDir` | string | Não | "asc" | Direção: `asc` ou `desc` |
| `q` | string | Não | - | Busca textual no campo `text` |
| `topic` | string | Não | - | Filtro por tópico (ex: "Biologia", "Matemática") |
| `include` | string[] | Não | [] | Relacionamentos: `["answers"]`, `["attempt"]` |

**Validações:**
- `page < 1` → retorna página 1
- `pageSize > 100` → trunca para 100
- `sortBy` inválido → usa default "order"
- `sortDir` diferente de "asc"/"desc" → usa "asc"

---

## 2. Estrutura do DTO (QuestionDto)

**Campos obrigatórios:**
- `id`: string (UUID)
- `text`: string (texto da pergunta)
- `order`: integer (ordem de exibição)

**Campos opcionais:**
- `answers`: AnswerDto[] (incluído se `include=["answers"]`)
- `topic`: string (categoria/assunto)
- `createdAt`: ISO8601 datetime
- `updatedAt`: ISO8601 datetime

**Estrutura do AnswerDto (quando incluído):**
```json
{
  "id": "string",
  "text": "string",
  "is_correct": boolean
}
```

---

## 3. Considerações de Performance

**Paginação:**
- **Offset-based** (atual): adequada para até ~10k registros
- **Cursor-based** (recomendada para >10k): usar `id` ou `order` como cursor
  - Exemplo: `?cursor=550e8400&pageSize=20`
  - Retorna `nextCursor` no meta para próxima página

**Include:**
- Sem `include`: retorna apenas Question sem `answers` (mais rápido)
- Com `include=["answers"]`: carrega relacionamentos (+ ~30-50% tempo)
- Evitar múltiplos `include` em produção para listas longas

**Limites:**
- `pageSize` máximo: 100 (protege contra DoS)
- Timeout recomendado: 5s no backend

---

## 4. Permissões e Privacidade

- **Escopo de usuário**: retorna apenas questões do quiz que o usuário tem acesso
- **Dados sensíveis**: não aplicável (questões são conteúdo educacional)
- **Rate limiting**: recomendado 100 req/min por usuário

---

## 5. Códigos de Resposta HTTP

| Código | Cenário |
|--------|---------|
| 200 | Sucesso |
| 400 | Parâmetros inválidos (ex: `page=-1`) |
| 401 | Não autenticado |
| 403 | Sem permissão para acessar o quiz |
| 429 | Rate limit excedido |
| 500 | Erro interno do servidor |

---

## 6. Exemplo de Uso

**Requisição:**
```http
GET /api/questions?page=1&pageSize=20&topic=Biologia&include=answers&sortBy=order&sortDir=asc
```

**Resposta:** Ver `contracts/questions_list_response.json`
