# Prompt: Implementar seleção de quiz com diálogo de ações (Editar / Remover / Fechar)

## Objetivo
Adicionar um fluxo de seleção de quiz que, ao pressionar longamente (long-press) um item da lista, exibe um diálogo com as ações: **Editar**, **Remover** e **Fechar**.

## Resumo do comportamento
- O diálogo de seleção contém três ações:
  - **Editar**: Abre o formulário de edição do quiz (usar `showQuizFormDialog` ou equivalente quando disponível)
  - **Remover**: Abre um `AlertDialog` de confirmação e, se confirmado, remove o quiz via DAO
  - **Fechar**: Fecha o diálogo sem ações
- A ação **Editar** deve delegar ao prompt/handler de edição existente
- A ação **Remover** deve delegar ao prompt/handler de remoção (abrir confirmação e remover via DAO)
- O código deste prompt deve apenas adicionar o diálogo e as rotas de delegação — a lógica detalhada de edição/remoção permanece nos prompts especializados

## Entidade e estrutura
- **Entidade**: `QuizDto` localizado em `lib/features/quizzes/infrastructure/dtos/quiz_dto.dart`
- **Propriedades principais**:
  - `id` (String): Identificador único do quiz
  - `title` (String): Título do quiz
  - `description` (String?): Descrição opcional
  - `authorId` (String?): ID do autor
  - `topics` (List<String>): Lista de tópicos/categorias
  - `questions` (List<QuestionDto>): Lista de questões do quiz
  - `isPublished` (bool): Status de publicação
  - `createdAt` (String): Data de criação em ISO 8601

## Informações específicas para quizzes
- **Exibição no diálogo**: Mostrar o título do quiz (limitado a 2 linhas com ellipsis) e status de publicação
- **Badge de status**: Exibir badge "PUBLICADO" (verde) ou "RASCUNHO" (laranja) baseado em `isPublished`
- **Ícone**: Usar `Icons.quiz` para representar o quiz
- **Informações adicionais**: Mostrar quantidade de questões (`${quiz.questions.length} questões`)
- **Confirmação de remoção**: Avisar ao usuário que remover o quiz também removerá todas as questões associadas

## Integração e convenções
- Criar o diálogo em `lib/features/quizzes/presentation/dialogs/quiz_actions_dialog.dart`
- O arquivo deve exportar uma função helper:
  ```dart
  Future<void> showQuizActionsDialog(
    BuildContext context,
    QuizDto quiz, {
    required VoidCallback onEdit,
    required VoidCallback onRemove,
  })
  ```
- Não implementar diretamente a persistência no diálogo — invocar os callbacks fornecidos (`onEdit`, `onRemove`)
- Labels e textos em **português**
- **Importante**: O diálogo deve ser **não-dismissible** ao tocar fora. Use `barrierDismissible: false` no `showDialog`
- Cores:
  - Botão Editar: Azul (`Color(0xFF2563EB)`)
  - Botão Remover: Vermelho (`Colors.red`)
  - Botão Fechar: Cinza (`Colors.grey`)
  - Badge PUBLICADO: Verde (`Colors.green`)
  - Badge RASCUNHO: Laranja (`Colors.orange`)

## Integração na página de listagem
- **Arquivo**: `lib/features/quizzes/presentation/quizzes_page.dart`
- **Ação**: Adicionar handler `onLongPress` nos itens da lista (Card ou ListTile)
- **Implementação**:
  1. Importar o diálogo: `import 'dialogs/quiz_actions_dialog.dart';`
  2. Criar método `_showActionsDialog(QuizDto quiz)` que chama `showQuizActionsDialog`
  3. Criar método `_handleEdit(QuizDto quiz)` que exibe um SnackBar temporário (placeholder para futura implementação)
  4. Criar método `_handleRemove(QuizDto quiz)` que:
     - Abre um `AlertDialog` de confirmação perguntando se deseja realmente remover
     - Avisa que as questões associadas também serão removidas
     - Se confirmado, chama `_quizzesDao.removeById(quiz.id)`
     - Recarrega a lista após remoção
  5. Adicionar `onLongPress` ao widget de item da lista, chamando `_showActionsDialog(quiz)`

## Critérios de aceitação
1. ✅ Pressionar longamente um quiz exibe o diálogo com as três opções (Editar, Remover, Fechar)
2. ✅ O diálogo exibe corretamente:
   - Título do quiz (máximo 2 linhas)
   - Badge de status (PUBLICADO/RASCUNHO)
   - Quantidade de questões
   - Ícone de quiz
3. ✅ Botão "Editar" executa callback `onEdit` (atualmente exibe SnackBar placeholder)
4. ✅ Botão "Remover" abre confirmação e, se aceito, executa callback `onRemove` que remove via DAO
5. ✅ Botão "Fechar" fecha o diálogo sem ações
6. ✅ O diálogo só pode ser fechado pelos botões internos (não ao tocar fora)
7. ✅ Após remoção bem-sucedida, a lista é recarregada automaticamente
8. ✅ Mensagem de confirmação avisa sobre remoção das questões associadas
9. ✅ Este prompt não implementa remoção por swipe nem altera a visualização dos itens — apenas adiciona o diálogo de ações

## Exemplo de layout do diálogo

```
┌─────────────────────────────────────┐
│  🧩 Quiz sobre Dart                 │
│                                     │
│  PUBLICADO    📝 15 questões        │
│                                     │
│  ┌─────────┬─────────┬──────────┐  │
│  │ 🖊 Editar│ 🗑 Remover│ ✕ Fechar │  │
│  └─────────┴─────────┴──────────┘  │
└─────────────────────────────────────┘
```

## Observações
- Manter consistência com os diálogos já implementados (questions, answers, attempts, authors)
- Reutilizar o padrão de cores e espaçamentos estabelecido
- O handler de edição é placeholder por enquanto — será implementado em prompt futuro dedicado à edição de quizzes
