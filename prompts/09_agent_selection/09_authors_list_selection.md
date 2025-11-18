```markdown
## Prompt: Implementar seleção de autor com diálogo de ações (Editar / Remover / Fechar)

Objetivo
---
Adicionar um fluxo de seleção de item que, ao selecionar um autor (por exemplo long-press ou tap em área específica), exibe um diálogo com ações: Editar, Remover, Fechar.

Resumo do comportamento
---
- O diálogo de seleção contém três ações: Editar (abre o formulário de edição do autor), Remover (abre confirmação de remoção) e Fechar (fecha o diálogo).
- A ação Editar deve delegar ao prompt/handler de edição de `Author` (usar `showAuthorFormDialog` ou equivalente quando disponível).
- A ação Remover deve delegar ao prompt/handler de remoção (abrir `AlertDialog` de confirmação e remover via `AuthorsLocalDaoSharedPrefs` ou callback fornecido).
- O código deste prompt deve apenas adicionar o diálogo e as rotas de delegação — a lógica fina de edição/remoção permanece nos prompts/módulos especializados.

Integração e convenções
---
- Criar o diálogo em `lib/features/authors/presentation/dialogs/author_actions_dialog.dart` ou como helper reutilizável.
- Não implemente diretamente a persistência aqui — invoque os helpers já existentes ou as funções de callback fornecidas pelo widget de listagem.
- Labels e textos em português.
- Importante: o diálogo de ações deve ser não-dismissable ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões internos possam fechá-lo.

Exemplos de uso
---
- Em `authors_page.dart`, ao detectar um long-press em um card/ListTile de autor, chamar `showAuthorActionsDialog(context, author, onEdit: ..., onRemove: ...)`.
- `onEdit` deve abrir o formulário de edição, por exemplo: `showAuthorFormDialog(context, author: author)`.
- `onRemove` deve abrir um `AlertDialog` de confirmação e, se confirmado, chamar `AuthorsLocalDaoSharedPrefs().removeById(author.id)` ou o callback de remoção do widget pai.

Critérios de aceitação
---
1. Selecionar um autor (tap longo ou ação definida) exibe um diálogo com as três opções.
2. Cada opção delega corretamente: Editar -> abre formulário; Remover -> abre confirmação; Fechar -> fecha.
3. Este prompt não implementa a lógica de remoção por swipe nem altera os itens para mostrar ícones de edição; fica restrito ao diálogo de ações.

Observações para o implementador
---
- Use `AuthorDto` como DTO de transferência.
- Nome de arquivo sugerido: `author_actions_dialog.dart`.
- Mantenha testes unitários leves para verificar que o diálogo é construído com os botões corretos (ex.: `find.text('Editar')`, `find.text('Remover')`).
- O diálogo deve exibir informações contextuais do autor:
  - Avatar (CircleAvatar com imagem ou iniciais)
  - Nome completo
  - E-mail mascarado (ex.: `j***a@example.com`) para privacidade
  - Rating com estrelas (colorido: verde ≥4.5, laranja ≥3.5, vermelho <3.5)
  - Badge de status: "ATIVO" (verde) ou "INATIVO" (cinza)
  - Quantidade de quizzes publicados
- Considere ações opcionais para versões futuras:
  - `Ver quizzes` (abre lista de quizzes do autor)
  - `Ativar/Desativar` (toggle de `isActive`, somente para admins)
  - `Copiar e-mail` (com confirmação, revelar e-mail completo)
- Privacidade: nunca exibir e-mail completo sem confirmação explícita do usuário.
```