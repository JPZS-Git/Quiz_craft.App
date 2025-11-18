# Prompt: Implementar remoção de authors por swipe (Dismissible)

## Objetivo
Adicionar a funcionalidade de remoção de authors via swipe-to-dismiss na listagem.

## Resumo do comportamento esperado
- Envolver cada item da lista de authors em um `Dismissible` com direção `DismissDirection.endToStart` (swipe da direita para esquerda)
- Ao detectar o gesto, chamar `confirmDismiss` que abre um `AlertDialog` de confirmação
- O diálogo deve perguntar: "Remover autor?" e exibir informações do author (nome, email, quizzes, status)
- Se o usuário confirmar, chamar o DAO para remover o item (`AuthorsLocalDaoSharedPrefs.removeById(id)`) dentro de `try/catch`
- Em caso de sucesso, exibir `SnackBar` verde confirmando remoção ("Autor removido com sucesso")
- Em caso de erro, reverter UI e exibir `SnackBar` vermelha com a mensagem de erro
- Após remoção bem-sucedida, recarregar a lista de authors

## Entidade e estrutura
- **Entidade**: `AuthorDto` localizado em `lib/features/authors/infrastructure/dtos/author_dto.dart`
- **Propriedades principais**:
  - `id` (String): Identificador único do autor
  - `name` (String): Nome do autor
  - `email` (String?): Email do autor (opcional)
  - `avatarUrl` (String?): URL do avatar (opcional)
  - `bio` (String?): Biografia (opcional)
  - `topics` (List<String>): Lista de tópicos de especialidade
  - `quizzesCount` (int): Quantidade de quizzes criados
  - `rating` (double): Avaliação (0.0-5.0)
  - `isActive` (bool): Status de atividade
  - `createdAt` (String): Data de criação (ISO 8601)

## Informações específicas para authors
- **Confirmação**: O diálogo deve mostrar:
  - Título: "Remover autor?"
  - Mensagem: "Deseja realmente remover este autor?\n\nNome: {name}\nEmail: {email mascarado}\nQuizzes criados: {quizzesCount}\nStatus: {ATIVO/INATIVO}\n\nAtenção: Os {quizzesCount} quizzes associados também serão removidos."
  - Botões: "Cancelar" (cinza) e "Remover" (vermelho)

- **Visual do Dismissible**:
  - Background: Vermelho com ícone de lixeira (Icons.delete) alinhado à direita
  - Direção: `DismissDirection.endToStart` (swipe esquerda)
  - Cor primária: `Color(0xFF2563EB)` (azul do app)

- **DAO**: Usar `AuthorsLocalDaoSharedPrefs` com método `removeById(String id)`

## Integração e convenções
- **Arquivos**:
  - `lib/features/authors/presentation/authors_page.dart` - Página principal com Dismissible
  - `lib/features/authors/presentation/widgets/author_list_item.dart` - Widget separado do card (OBRIGATÓRIO)
- **Estrutura obrigatória**: 
  - Criar widget público `AuthorListItem` em arquivo separado na pasta `widgets/`
  - O widget deve ser reutilizável e documentado
  - Incluir parâmetro `key` no construtor
  - Exportar callbacks para `onTap`, `onLongPress`, `onEdit`
- **Ação**: Envolver o `AuthorListItem` em um widget `Dismissible` no `ListView.builder`
- **Key**: Usar `Key(author.id)` para identificar unicamente cada item
- **Importante**: 
  - O diálogo de confirmação deve usar `barrierDismissible: false` para evitar fechamento acidental
  - Usuário só pode confirmar/cancelar através dos botões
  - Manter o método `_handleRemove` existente mas adaptar para integrar com o Dismissible
  - A função `confirmDismiss` deve retornar `Future<bool?>` onde `true` = confirma remoção, `false/null` = cancela
  - Email deve ser mascarado (ex: jo***@ex***.com)

## Layout visual do Dismissible

```
┌─────────────────────────────────────────┐
│  Card do autor                          │  → Swipe para esquerda
│  [Avatar] João Silva                    │ 
│  jo***@ex***.com | ⭐ 4.5 | 15 quizzes  │
│  ✅ ATIVO                                │
└─────────────────────────────────────────┘
         ↓ (ao fazer swipe)
┌─────────────────────────────────────────┐
│                        🗑️ DELETE         │ ← Background vermelho
└─────────────────────────────────────────┘
         ↓ (ao soltar)
┌─────────────────────────────────────────┐
│  ⚠️ Remover autor?                       │
│                                         │
│  Deseja realmente remover este autor?   │
│                                         │
│  Nome: João Silva                       │
│  Email: jo***@ex***.com                 │
│  Quizzes criados: 15                    │
│  Status: ATIVO                          │
│                                         │
│  Atenção: Os 15 quizzes associados      │
│  também serão removidos.                │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ Cancelar│ 🗑️ Remover│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ Widget `AuthorListItem` criado em arquivo separado `widgets/author_list_item.dart`
2. ✅ Widget é público, reutilizável e possui documentação adequada
3. ✅ Swipe para esquerda exibe background vermelho com ícone de lixeira
4. ✅ Ao soltar o swipe, abre diálogo de confirmação com informações completas do autor
5. ✅ Diálogo mostra: nome, email mascarado, quantidade de quizzes, status (ATIVO/INATIVO)
6. ✅ Diálogo alerta claramente sobre remoção dos quizzes associados
7. ✅ Diálogo não pode ser fechado tocando fora (apenas pelos botões)
8. ✅ Ao confirmar, chama `removeById` do DAO dentro de `try/catch`
9. ✅ Em caso de sucesso, exibe SnackBar verde e recarrega a lista
10. ✅ Em caso de erro, exibe SnackBar vermelha com mensagem de erro
11. ✅ O swipe não interfere com outros gestos (tap, long-press)
12. ✅ Animação suave ao remover o item da lista
13. ✅ A remoção persiste (dados são excluídos do SharedPreferences)

## Observações importantes
- **Impacto da remoção**: Authors têm quizzes associados. A confirmação deve deixar bem claro que remover o autor também remove seus quizzes.
- **Email mascarado**: Por privacidade, exibir email parcialmente oculto (ex: jo***@ex***.com) no diálogo de confirmação.
- **Status visual**: Mostrar claramente se o autor está ATIVO (verde) ou INATIVO (cinza/vermelho).
- **Rating**: Exibir avaliação com estrelas (0.0-5.0) se relevante para o contexto.
- **Topics**: Lista de especialidades do autor pode ser mostrada de forma resumida.
- **Integração com outros diálogos**: O swipe-to-dismiss convive com:
  - Tap para expandir/colapsar detalhes
  - Long-press para abrir diálogo de ações (Editar/Remover/Fechar)
  - Ícone de edição para abrir formulário
- **Confirmação dupla**: Como já existe `_handleRemove` no long-press, o swipe oferece um atalho rápido com a mesma confirmação
- **Não implementar edição**: Este prompt foca apenas em remoção. Edição já foi implementada em outro prompt.
- Manter consistência com os padrões já estabelecidos no projeto (cores, espaçamentos, feedback visual)
- Badge de status: ATIVO (verde) / INATIVO (cinza ou vermelho)
- Contagem de quizzes deve aparecer em destaque para enfatizar o impacto da remoção
