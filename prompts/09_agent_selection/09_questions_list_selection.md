```markdown
## Prompt: Implementar seleção de questão com diálogo de ações (Editar / Remover / Fechar)

Objetivo
---
Adicionar um fluxo de seleção de item que, ao selecionar uma questão (por exemplo long-press ou tap em área específica), exibe um diálogo com ações: Editar, Remover, Fechar.

Resumo do comportamento
---
- O diálogo de seleção contém três ações: Editar (abre o formulário de edição da questão), Remover (abre confirmação de remoção) e Fechar (fecha o diálogo).
- A ação Editar deve delegar ao prompt/handler de edição de `Question` (usar `showProviderFormDialog` ou equivalente quando disponível).
- A ação Remover deve delegar ao prompt/handler de remoção (abrir `AlertDialog` de confirmação e remover via `QuestionsLocalDaoSharedPrefs` ou callback fornecido).
- O código deste prompt deve apenas adicionar o diálogo e as rotas de delegação — a lógica fina de edição/remoção permanece nos prompts/módulos especializados.

Integração e convenções
---
- Criar o diálogo em `lib/features/questions/presentation/dialogs/question_actions_dialog.dart` ou como helper reutilizável.
- Não implemente diretamente a persistência aqui — invoque os helpers já existentes ou as funções de callback fornecidas pelo widget de listagem.
- Labels e textos em português.
- Importante: o diálogo de ações deve ser não-dismissable ao tocar fora. Use `showDialog(..., barrierDismissible: false)` para garantir que apenas os botões internos possam fechá-lo.

Exemplos de uso
---
- Em `questions_page.dart`, ao detectar um long-press em um `ListTile` de questão, chamar `showQuestionActionsDialog(context, question, onEdit: ..., onRemove: ...)`.
- `onEdit` deve abrir o formulário de edição, por exemplo: `showQuestionFormDialog(context, question: question)`.
- `onRemove` deve abrir um `AlertDialog` de confirmação e, se confirmado, chamar `QuestionsLocalDaoSharedPrefs().removeById(question.id)` ou o callback de remoção do widget pai.

Critérios de aceitação
---
1. Selecionar uma questão (tap longo ou ação definida) exibe um diálogo com as três opções.
2. Cada opção delega corretamente: Editar -> abre formulário; Remover -> abre confirmação; Fechar -> fecha.
3. Este prompt não implementa a lógica de remoção por swipe nem altera os itens para mostrar ícones de edição; fica restrito ao diálogo de ações.

Observações para o implementador
---
- Use `QuestionDto` como DTO de transferência.
- Nome de arquivo sugerido: `question_actions_dialog.dart`.
- Mantenha testes unitários leves para verificar que o diálogo é construído com os botões corretos (ex.: `find.text('Editar')`, `find.text('Remover')`).
```