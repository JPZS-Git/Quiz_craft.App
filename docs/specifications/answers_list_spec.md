# Especificação: Listagem de Respostas (Answers)

## 1. Parâmetros de Query

A API/DAO de listagem de respostas aceita os seguintes parâmetros:

| Parâmetro | Tipo | Obrigatório | Padrão | Descrição |
|-----------|------|-------------|--------|-----------|
| `page` | integer | Não | 1 | Número da página (≥ 1) |
| `pageSize` | integer | Não | 20 | Itens por página (1-100) |
| `sortBy` | string | Não | `createdAt` | Campo para ordenação: `id`, `text`, `createdAt` |
| `sortDir` | string | Não | `asc` | Direção: `asc` ou `desc` |
| `questionId` | string | Não | - | Filtrar por ID da pergunta específica |
| `isCorrect` | boolean | Não | - | Filtrar por respostas corretas (true) ou incorretas (false) |
| `include` | array[string] | Não | `[]` | Relacionamentos a incluir: `["question"]` |

### Validações
- Se `page` < 1, usar 1
- Se `pageSize` < 1 ou > 100, truncar para [1, 100]
- Se `sortBy` inválido, usar `createdAt`
- Se `sortDir` não for `asc` ou `desc`, usar `asc`

## 2. Estrutura do DTO (AnswerDto)

```dart
{
  "id": "string",              // UUID único da resposta
  "text": "string",            // Texto da resposta
  "isCorrect": boolean,        // true se é a resposta correta
  "questionId": "string"       // UUID da pergunta (se necessário no futuro)
}
```

**Nota**: O DTO atual não inclui `questionId`, mas pode ser adicionado se houver necessidade de associação explícita.

## 3. Performance e Escalabilidade

### Recomendações
- **Paginação**: Implementada com offset/limit (adequado para volumes pequenos/médios)
- **Cursor-based**: Recomendado se a tabela de respostas ultrapassar 10.000 registros
- **Índices**: Criar índices em `questionId`, `isCorrect`, `createdAt` para otimizar filtros e ordenação
- **Limite de pageSize**: Máximo de 100 itens por página para evitar sobrecarga
- **Include**: Carregar relacionamento `question` apenas quando solicitado (include=["question"])

### Considerações de Cache
- Respostas são relativamente estáticas (não mudam com frequência após criação)
- Cache local via SharedPreferences é adequado para este caso de uso
- TTL sugerido: 24 horas ou até refresh manual

## 4. Permissões e Privacidade

### Controle de Acesso
- Respostas são geralmente públicas dentro do contexto de um quiz
- Se houver restrição por usuário, filtrar apenas respostas associadas a perguntas acessíveis pelo usuário
- Não há campos sensíveis em respostas (apenas texto e flag de correção)

### Auditoria
- Registrar tentativas de acesso a respostas corretas durante realização de quiz (anti-fraude)
- Logs devem incluir: userId, questionId, timestamp

## 5. Códigos de Resposta HTTP (para API futura)

| Código | Descrição |
|--------|-----------|
| 200 | Sucesso - Listagem retornada |
| 400 | Parâmetros inválidos (page, pageSize fora dos limites) |
| 401 | Não autenticado |
| 403 | Sem permissão para acessar respostas |
| 429 | Rate limit excedido (sugestão: 200 requisições/min) |
| 500 | Erro interno do servidor |

## 6. Exemplo de Resposta

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
      "text": "Rio de Janeiro",
      "isCorrect": false
    },
    {
      "id": "b2c3d4e5-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
      "text": "Brasília",
      "isCorrect": true
    },
    {
      "id": "c3d4e5f6-7g8h-9i0j-1k2l-3m4n5o6p7q8r",
      "text": "São Paulo",
      "isCorrect": false
    },
    {
      "id": "d4e5f6g7-8h9i-0j1k-2l3m-4n5o6p7q8r9s",
      "text": "Salvador",
      "isCorrect": false
    }
  ]
}
```

### Com include=["question"]

```json
{
  "meta": {
    "total": 4,
    "page": 1,
    "pageSize": 20,
    "totalPages": 1
  },
  "filtersApplied": {
    "questionId": "b6f8c1f2-3d2a-4a9e-9f6b-1a2b3c4d5e6f",
    "include": ["question"]
  },
  "data": [
    {
      "id": "a1b2c3d4-5e6f-7g8h-9i0j-1k2l3m4n5o6p",
      "text": "Rio de Janeiro",
      "isCorrect": false,
      "question": {
        "id": "b6f8c1f2-3d2a-4a9e-9f6b-1a2b3c4d5e6f",
        "text": "Qual é a capital do Brasil?",
        "category": "Geografia"
      }
    },
    {
      "id": "b2c3d4e5-6f7g-8h9i-0j1k-2l3m4n5o6p7q",
      "text": "Brasília",
      "isCorrect": true,
      "question": {
        "id": "b6f8c1f2-3d2a-4a9e-9f6b-1a2b3c4d5e6f",
        "text": "Qual é a capital do Brasil?",
        "category": "Geografia"
      }
    }
  ]
}
```

## 7. Casos de Uso Comuns

### Listar todas as respostas de uma pergunta
```
GET /answers?questionId=b6f8c1f2-3d2a-4a9e-9f6b-1a2b3c4d5e6f&pageSize=100
```

### Obter apenas respostas corretas
```
GET /answers?isCorrect=true
```

### Listar respostas com informações da pergunta
```
GET /answers?questionId=xxx&include=["question"]
```

### Ordenar por texto alfabeticamente
```
GET /answers?sortBy=text&sortDir=asc
```

## 8. Tratamento de Erros no Widget Flutter

### Cenários de Erro
1. **DAO vazio**: Exibir mensagem "Nenhuma resposta encontrada" com ícone e sugestão de ação
2. **Erro ao carregar**: Exibir mensagem de erro com botão "Tentar novamente"
3. **Timeout**: Após 10s, cancelar operação e informar usuário

### Feedback Visual
- **Loading**: CircularProgressIndicator centralizado
- **Empty State**: Ícone + texto explicativo + ação sugerida
- **Error State**: Ícone de erro + mensagem + botão de retry
- **Success**: Transição suave para lista com animação

## 9. Considerações de UX

### Display de Respostas
- Marcar visualmente a resposta correta (ícone de check verde)
- Respostas incorretas com ícone neutro ou X vermelho
- Permitir expansão inline para mostrar mais detalhes (se houver campos adicionais futuramente)

### Interação
- Pull-to-refresh para recarregar lista
- Scroll suave com lazy loading (se implementar paginação incremental)
- Busca/filtro rápido por texto da resposta

### Acessibilidade
- Labels semânticos para screen readers
- Contrast ratio adequado para textos
- Tamanho mínimo de toque: 48x48 dp
