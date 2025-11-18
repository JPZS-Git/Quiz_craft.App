# Prompt: Implementar edição de quizzes (ícone lápis)

## Objetivo
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de quizzes.

## Resumo do comportamento esperado
- Cada item da lista de quizzes deverá exibir um ícone de lápis (edit) visível e clicável
- Ao tocar no ícone de lápis, abrir um formulário em diálogo para edição preenchido com os dados atuais do quiz
- O formulário deve permitir editar os campos da `QuizDto`: `title`, `description`, `authorId`, `topics`, e `isPublished`
- Ao confirmar a edição, chamar o DAO apropriado (`QuizzesLocalDaoSharedPrefs.update` ou similar) para persistir a alteração dentro de `try/catch`
- Exibir `SnackBar` de sucesso ou erro conforme o resultado
- Após salvar com sucesso, recarregar a lista de quizzes
- Não implementar remoção nem swipe neste prompt; apenas edição

## Entidade e estrutura
- **Entidade**: `QuizDto` localizado em `lib/features/quizzes/infrastructure/dtos/quiz_dto.dart`
- **Propriedades**:
  - `id` (String): Identificador único do quiz - **READ-ONLY**
  - `title` (String): Título do quiz - **EDITÁVEL**
  - `description` (String?): Descrição do quiz (opcional) - **EDITÁVEL**
  - `authorId` (String?): ID do autor (opcional) - **EDITÁVEL**
  - `topics` (List<String>): Lista de tópicos/categorias - **EDITÁVEL**
  - `questions` (List<QuestionDto>): Lista de questões - **READ-ONLY** (quantidade exibida)
  - `isPublished` (bool): Status de publicação - **EDITÁVEL**
  - `createdAt` (String): Data de criação (ISO 8601) - **READ-ONLY**

## Informações específicas para quizzes
- **Campos editáveis principais**:
  1. `title`: Título do quiz (obrigatório)
  2. `description`: Descrição detalhada (opcional, multiline)
  3. `authorId`: ID do autor (opcional, campo texto)
  4. `topics`: Lista de tópicos separados por vírgula
  5. `isPublished`: Status de publicação (switch ou checkbox)

- **Campos read-only** (exibir no diálogo mas não editar):
  - `id`: Identificador
  - `questions.length`: Quantidade de questões associadas
  - `createdAt`: Data de criação formatada

- **Validações obrigatórias**: 
  - `title`: Não pode estar vazio
  - `topics`: Pode ser vazio, mas se preenchido, separar por vírgula
  - `authorId`: Opcional, formato livre (ID de autor)

- **Ícone**: `Icons.edit` para o botão de edição
- **Cor do ícone**: Azul (`Color(0xFF2563EB)`)

## Integração e convenções
- **Criar o diálogo de edição** em `lib/features/quizzes/presentation/dialogs/quiz_form_dialog.dart`
- O arquivo deve exportar uma função helper:
  ```dart
  Future<void> showQuizFormDialog(
    BuildContext context, {
    QuizDto? quiz, // null = criar novo, não-null = editar
  })
  ```
- Se `quiz` não for null, preencher os campos com os valores atuais para edição
- Se `quiz` for null, criar um novo quiz (modo criação - não é o foco deste prompt, mas deixar preparado)
- **Não implementar edição de questões** neste diálogo - apenas mostrar a quantidade. A edição de questões é responsabilidade da página de questions
- **DAO**: Usar `QuizzesLocalDaoSharedPrefs` com método `update(QuizDto)`
- Labels e textos em **português**
- **Importante**: O diálogo não deve ser fechado ao tocar fora. Use `barrierDismissible: false` no `showDialog`
- Cores:
  - Botão Salvar: Azul (`Color(0xFF2563EB)`)
  - Botão Cancelar: Cinza (`Colors.grey`)
  - Badge PUBLICADO: Verde (`Colors.green`)
  - Badge RASCUNHO: Laranja (`Colors.orange`)
  - Switch publicado: Verde (`Colors.green`)

## Integração na página de listagem
- **Arquivo**: `lib/features/quizzes/presentation/quizzes_page.dart`
- **Ação**: Adicionar ícone de edição (lápis) nos itens da lista
- **Implementação**:
  1. Importar o diálogo: `import 'dialogs/quiz_form_dialog.dart';`
  2. Atualizar o método `_handleEdit(QuizDto quiz)` que atualmente é placeholder:
     - Remover o SnackBar placeholder
     - Chamar `await showQuizFormDialog(context, quiz: quiz)`
     - Após retorno do diálogo, recarregar a lista com `await _loadQuizzes()`
  3. Adicionar ícone de edição visível no `_QuizCard`:
     - Adicionar um `IconButton` com ícone de lápis no `trailing` do `ListTile`
     - Cor do ícone: `Color(0xFF2563EB)`
     - Ao clicar, chamar `_handleEdit(quiz)`
  4. Manter o comportamento de long-press para abrir o diálogo de ações (Editar/Remover/Fechar)

## Estrutura do diálogo de edição
- **Campos do formulário** (ordem sugerida):
  1. **Informações read-only** (container cinza no topo):
     - ID do quiz (truncado se necessário)
     - Quantidade de questões
     - Data de criação formatada (dd/MM/yyyy)
  
  2. **Campo "Título do quiz"**: TextField single-line
     - Label: "Título do quiz"
     - Validação: Obrigatório, não pode estar vazio
  
  3. **Campo "Descrição"**: TextField multiline
     - Label: "Descrição (opcional)"
     - Linhas: minLines: 3, maxLines: 6
  
  4. **Campo "ID do Autor"**: TextField single-line
     - Label: "ID do autor (opcional)"
     - Hint: "abc123..."
  
  5. **Campo "Tópicos"**: TextField single-line
     - Label: "Tópicos/Categorias (separados por vírgula)"
     - Hint: "Dart, Flutter, Mobile"
     - Exibir count de tópicos atual
  
  6. **Campo "Status de publicação"**: SwitchListTile
     - Label: "Quiz publicado"
     - Badge visual: "PUBLICADO" (verde) quando true, "RASCUNHO" (laranja) quando false
     - Ícone: `Icons.check_circle` (verde) quando true, `Icons.edit` (laranja) quando false

- **Botões**:
  - **Salvar**: Valida campos, persiste via DAO, fecha diálogo e retorna
  - **Cancelar**: Fecha diálogo sem salvar

## Layout visual esperado

```
┌─────────────────────────────────────────┐
│  ✏️ Editar Quiz                         │
│                                         │
│  📋 ID: abc123... | 15 questões         │
│  📅 Criado: 18/11/2025                  │
│                                         │
│  Título do quiz                         │
│  ┌───────────────────────────────────┐  │
│  │ Quiz sobre Dart Básico            │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Descrição (opcional)                   │
│  ┌───────────────────────────────────┐  │
│  │ Este quiz testa conhecimentos     │  │
│  │ básicos de Dart...                │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ID do autor (opcional)                 │
│  ┌───────────────────────────────────┐  │
│  │ author123                         │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Tópicos (3 tópicos)                    │
│  ┌───────────────────────────────────┐  │
│  │ Dart, Flutter, Programação        │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ☑️ Quiz publicado  ✅ PUBLICADO        │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ 💾 Salvar│ ✕ Cancelar│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ O ícone de edição (lápis azul) aparece em cada item da lista de quizzes
2. ✅ Tocar no ícone de lápis abre o formulário de edição pré-preenchido
3. ✅ O formulário permite editar title, description, authorId, topics e isPublished
4. ✅ O formulário exibe campos read-only: id, quantidade de questões, createdAt
5. ✅ Validação impede salvar com título vazio
6. ✅ Switch de isPublished atualiza badge visual (PUBLICADO/RASCUNHO)
7. ✅ Campo topics exibe contador dinâmico de tópicos
8. ✅ Ao salvar, os dados são persistidos via DAO com `try/catch`
9. ✅ Usuário vê `SnackBar` de sucesso ("Quiz atualizado com sucesso") ou erro
10. ✅ Após salvar com sucesso, a lista é recarregada automaticamente
11. ✅ O diálogo não pode ser fechado ao tocar fora (apenas pelos botões)
12. ✅ O método `_handleEdit` não exibe mais o SnackBar placeholder
13. ✅ O código não altera funcionalidades de remoção (isso é responsabilidade de outro prompt)
14. ✅ A lista de questões (questions) não é editável neste diálogo - apenas a quantidade é exibida

## Observações
- **Foco principal**: Edição de metadados do quiz (título, descrição, autor, tópicos, status)
- **Questões não editáveis**: As questões associadas são gerenciadas na página de questions
- **Tópicos**: Aceitar string separada por vírgula, converter para List<String> ao salvar
- **Status de publicação**: Switch com feedback visual imediato (PUBLICADO/RASCUNHO)
- **Author ID**: Campo livre para ID do autor - não fazer lookup ou validação de existência
- **Preservar questões**: Ao salvar, manter a lista de questões existente (não modificar)
- Manter consistência com os diálogos já implementados (questions, answers, attempts, authors)
- Reutilizar o padrão de cores e espaçamentos estabelecido no projeto
