# Especificação: Listagem de Autores (Authors)

## 1. Parâmetros de Query

A API/DAO de listagem de autores aceita os seguintes parâmetros:

| Parâmetro | Tipo | Obrigatório | Padrão | Descrição |
|-----------|------|-------------|--------|-----------|
| `page` | integer | Não | 1 | Número da página (≥ 1) |
| `pageSize` | integer | Não | 20 | Itens por página (1-100) |
| `sortBy` | string | Não | `name` | Campo para ordenação: `name`, `rating`, `quizzesCount`, `createdAt` |
| `sortDir` | string | Não | `asc` | Direção: `asc` ou `desc` |
| `q` | string | Não | - | Busca por nome do autor |
| `isActive` | boolean | Não | - | Filtrar por autores ativos/inativos |
| `topic` | string | Não | - | Filtrar por tópico específico |
| `minRating` | number | Não | - | Filtrar por avaliação mínima (0-5) |
| `include` | array[string] | Não | `[]` | Relacionamentos a incluir: `["quizzes"]` |

### Validações
- Se `page` < 1, usar 1
- Se `pageSize` < 1 ou > 100, truncar para [1, 100]
- Se `sortBy` inválido, usar `name`
- Se `sortDir` não for `asc` ou `desc`, usar `asc`
- Se `minRating` fora do intervalo [0, 5], ignorar filtro

## 2. Estrutura do DTO (AuthorDto)

```dart
{
  "id": "string",              // UUID único do autor
  "name": "string",            // Nome completo
  "email": "string",           // Email (opcional, mascarado na resposta)
  "avatarUrl": "string",       // URL do avatar (opcional)
  "bio": "string",             // Biografia/descrição (opcional)
  "topics": ["string"],        // Lista de tópicos/especialidades
  "quizzesCount": integer,     // Quantidade de quizzes criados
  "rating": number,            // Avaliação média (0-5)
  "isActive": boolean,         // Status ativo/inativo
  "createdAt": "string"        // ISO8601 datetime
}
```

## 3. Performance e Escalabilidade

### Recomendações
- **Paginação**: Implementada com offset/limit (adequado para volumes pequenos/médios)
- **Cursor-based**: Recomendado se a tabela de autores ultrapassar 10.000 registros
- **Índices**: Criar índices em `name`, `rating`, `isActive`, `createdAt` para otimizar filtros e ordenação
- **Limite de pageSize**: Máximo de 100 itens por página para evitar sobrecarga
- **Include**: Carregar relacionamento `quizzes` apenas quando solicitado (include=["quizzes"])
- **Busca textual**: Implementar índice full-text em `name` e `bio` para pesquisas eficientes

### Considerações de Cache
- Dados de autores mudam com menos frequência que tentativas/respostas
- Cache local via SharedPreferences é adequado
- TTL sugerido: 24 horas ou até refresh manual
- Invalidar cache ao criar/editar autor

## 4. Permissões e Privacidade

### Controle de Acesso
- Listagem pública: todos os usuários podem ver autores ativos
- Autores inativos: visíveis apenas para administradores
- Email mascarado: exibir apenas primeiros 1-2 caracteres + "***" + caractere antes do @ + domínio
  - Exemplo: "joao.silva@example.com" → "j***a@example.com"
- Bio e topics: públicos, sem restrições

### Mascaramento de Email
```
Regra: 
- Pegar primeiro caractere
- Adicionar "***"
- Pegar último caractere antes do @
- Manter domínio completo

Exemplos:
- "maria@gmail.com" → "m***a@gmail.com"
- "pedro.costa@empresa.com.br" → "p***a@empresa.com.br"
- "a@test.com" → "a***@test.com" (nome muito curto)
```

### Auditoria
- Registrar acessos a perfis de autores
- Logs devem incluir: userId (quem acessou), authorId, timestamp
- Rate limiting: 200 requisições/minuto por usuário

## 5. Códigos de Resposta HTTP (para API futura)

| Código | Descrição |
|--------|-----------|
| 200 | Sucesso - Listagem retornada |
| 400 | Parâmetros inválidos (page, pageSize, minRating fora dos limites) |
| 401 | Não autenticado |
| 403 | Sem permissão para acessar autores inativos |
| 429 | Rate limit excedido (200 requisições/min) |
| 500 | Erro interno do servidor |

## 6. Exemplo de Resposta

### Listagem básica

```json
{
  "meta": {
    "total": 78,
    "page": 1,
    "pageSize": 20,
    "totalPages": 4
  },
  "filtersApplied": {
    "q": "João",
    "isActive": true,
    "sortBy": "rating",
    "sortDir": "desc"
  },
  "data": [
    {
      "id": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
      "name": "João Silva",
      "email": "j***a@example.com",
      "avatarUrl": "https://cdn.example.com/avatars/joao.png",
      "bio": "Professor de História com 15 anos de experiência em educação.",
      "topics": ["História", "Geografia", "Atualidades"],
      "quizzesCount": 42,
      "rating": 4.8,
      "isActive": true,
      "createdAt": "2023-01-15T10:30:00Z"
    },
    {
      "id": "b2c3d4e5-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
      "name": "Maria Santos",
      "email": "m***a@example.com",
      "avatarUrl": null,
      "bio": "Especialista em Matemática e Física para ensino médio.",
      "topics": ["Matemática", "Física"],
      "quizzesCount": 28,
      "rating": 4.6,
      "isActive": true,
      "createdAt": "2023-03-22T14:20:00Z"
    },
    {
      "id": "c3d4e5f6-7g8h-9i0j-1k2l-3m4n5o6p7q8r",
      "name": "Pedro Costa",
      "email": "p***o@example.com",
      "avatarUrl": "https://cdn.example.com/avatars/pedro.png",
      "bio": null,
      "topics": ["Biologia", "Química"],
      "quizzesCount": 15,
      "rating": 4.3,
      "isActive": false,
      "createdAt": "2024-06-10T09:45:00Z"
    }
  ]
}
```

### Com include=["quizzes"] (primeiros quizzes do autor)

```json
{
  "meta": {
    "total": 78,
    "page": 1,
    "pageSize": 20,
    "totalPages": 4
  },
  "filtersApplied": {
    "include": ["quizzes"]
  },
  "data": [
    {
      "id": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
      "name": "João Silva",
      "email": "j***a@example.com",
      "avatarUrl": "https://cdn.example.com/avatars/joao.png",
      "bio": "Professor de História com 15 anos de experiência.",
      "topics": ["História", "Geografia"],
      "quizzesCount": 42,
      "rating": 4.8,
      "isActive": true,
      "createdAt": "2023-01-15T10:30:00Z",
      "quizzes": [
        {
          "id": "q1",
          "title": "História do Brasil - Período Colonial",
          "category": "História",
          "difficulty": "medium",
          "questionsCount": 20
        },
        {
          "id": "q2",
          "title": "Geografia Física - Relevo Brasileiro",
          "category": "Geografia",
          "difficulty": "easy",
          "questionsCount": 15
        }
      ]
    }
  ]
}
```

## 7. Casos de Uso Comuns

### Listar autores ativos ordenados por avaliação
```
GET /authors?isActive=true&sortBy=rating&sortDir=desc
```

### Buscar autores por nome
```
GET /authors?q=João&pageSize=10
```

### Filtrar autores por tópico
```
GET /authors?topic=História&sortBy=quizzesCount&sortDir=desc
```

### Listar top autores com alta avaliação
```
GET /authors?minRating=4.5&sortBy=rating&sortDir=desc&pageSize=10
```

### Obter autores com seus quizzes
```
GET /authors?include=["quizzes"]&pageSize=5
```

## 8. Tratamento de Erros no Widget Flutter

### Cenários de Erro
1. **DAO vazio**: Exibir mensagem "Nenhum autor encontrado" com ícone e sugestão
2. **Erro ao carregar**: Exibir mensagem de erro com botão "Tentar novamente"
3. **Timeout**: Após 10s, cancelar operação e informar usuário
4. **Avatar inválido**: Usar fallback com iniciais do nome em CircleAvatar

### Feedback Visual
- **Loading**: CircularProgressIndicator centralizado
- **Empty State**: Ícone de pessoa + texto explicativo
- **Error State**: Ícone de erro + mensagem + botão de retry
- **Success**: Transição suave para lista com animação

## 9. Considerações de UX

### Display de Autores
- **Avatar**: CircleAvatar com imagem ou iniciais (primeiras letras do nome)
- **Rating**: Exibir estrelas visuais (⭐) ou número formatado (ex: "4.8 ★")
- **Topics**: Chips/tags coloridos para cada tópico
- **Status**: Badge "ATIVO" (verde) ou "INATIVO" (cinza)
- **Quizzes Count**: Ícone + número (ex: "📝 42 quizzes")

### Cards Expansíveis
- **Compacto**: Nome, avatar, rating, topics (como chips)
- **Expandido**: + Bio completa, email mascarado, data de criação, quizzesCount detalhado

### Interação
- Pull-to-refresh para recarregar lista
- Scroll suave com lazy loading (se implementar paginação incremental)
- Tap no card para expandir/colapsar detalhes
- Tap no avatar para visualizar perfil completo (futura feature)

### Filtros Rápidos
- Botão "Apenas Ativos" (toggle)
- Dropdown para ordenação (Nome, Avaliação, Quizzes)
- Busca por nome no AppBar

### Acessibilidade
- Labels semânticos para screen readers
- Contrast ratio adequado para badges e chips
- Tamanho mínimo de toque: 48x48 dp
- Descrição textual do rating para leitores de tela

## 10. Campos Derivados e Calculados

### Rating Médio
- Calculado a partir das avaliações dos quizzes do autor
- Atualizado automaticamente quando um quiz recebe nova avaliação
- Exibir com uma casa decimal (ex: 4.7)

### Quizzes Count
- Contador de quizzes criados pelo autor
- Inclui apenas quizzes ativos (não deletados)
- Atualizar ao criar/deletar quiz

### Iniciais para Avatar
- Extrair primeiras letras do nome
- Regra: primeira letra do primeiro nome + primeira letra do último nome
- Exemplos:
  - "João Silva" → "JS"
  - "Maria" → "MA" (usar primeiras 2 letras se nome único)
  - "Pedro da Costa" → "PC" (ignorar conectivos)

### Status Badge
- Verde com texto "ATIVO" se `isActive == true`
- Cinza com texto "INATIVO" se `isActive == false`
- Posicionado no canto superior direito do card
