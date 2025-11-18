# Prompt: Implementar edição de questions (ícone lápis)

## Objetivo
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de questions (questões).

## Resumo do comportamento esperado
- Cada item da lista de questões deverá exibir um ícone de lápis (edit) visível e clicável
- Ao tocar no ícone de lápis, abrir um formulário em diálogo para edição preenchido com os dados atuais da questão
- O formulário deve permitir editar os campos da `QuestionDto`: text (texto da questão), order (ordem), e exibir informações sobre answers (respostas associadas)
- Ao confirmar a edição, chamar o DAO apropriado (`QuestionsLocalDaoSharedPrefs.upsert` ou similar) para persistir a alteração dentro de `try/catch`
- Exibir `SnackBar` de sucesso ou erro conforme o resultado
- Após salvar com sucesso, recarregar a lista de questões
- Não implementar remoção nem swipe neste prompt; apenas edição

## Entidade e estrutura
- **Entidade**: `QuestionDto` localizado em `lib/features/questions/infrastructure/dtos/question_dto.dart`
- **Propriedades**:
  - `id` (String): Identificador único da questão
  - `text` (String): Texto da questão
  - `answers` (List<AnswerDto>): Lista de respostas associadas
  - `order` (int): Ordem de exibição da questão

## Informações específicas para questions
- **Campo principal para edição**: `text` (texto da questão)
- **Campo secundário**: `order` (ordem numérica)
- **Informação read-only no diálogo**: Quantidade de respostas (`${question.answers.length} respostas`)
- **Validação obrigatória**: 
  - Text não pode estar vazio
  - Order deve ser um número inteiro positivo ou zero
- **Ícone**: `Icons.edit` para o botão de edição
- **Cor do ícone**: Azul (`Color(0xFF2563EB)`)

## Integração e convenções
- **Criar o diálogo de edição** em `lib/features/questions/presentation/dialogs/question_form_dialog.dart`
- O arquivo deve exportar uma função helper:
  ```dart
  Future<void> showQuestionFormDialog(
    BuildContext context, {
    QuestionDto? question, // null = criar nova, não-null = editar
  })
  ```
- Se `question` não for null, preencher os campos com os valores atuais para edição
- Se `question` for null, criar uma nova questão (modo criação - não é o foco deste prompt, mas deixar preparado)
- **Não implementar edição de respostas** neste diálogo - apenas mostrar a quantidade. A edição de respostas é responsabilidade da página de answers
- **DAO**: Usar `QuestionsLocalDaoSharedPrefs` com método `upsert(QuestionDto)` ou `upsertAll(List<QuestionDto>)`
- Labels e textos em **português**
- **Importante**: O diálogo não deve ser fechado ao tocar fora. Use `barrierDismissible: false` no `showDialog`
- Cores:
  - Botão Salvar: Azul (`Color(0xFF2563EB)`)
  - Botão Cancelar: Cinza (`Colors.grey`)
  - Campo de texto: Bordas azuis quando focado

## Integração na página de listagem
- **Arquivo**: `lib/features/questions/presentation/questions_page.dart`
- **Ação**: Adicionar ícone de edição (lápis) nos itens da lista
- **Implementação**:
  1. Importar o diálogo: `import 'dialogs/question_form_dialog.dart';`
  2. Atualizar o método `_handleEdit(QuestionDto question)` que atualmente é placeholder:
     - Remover o SnackBar placeholder
     - Chamar `await showQuestionFormDialog(context, question: question)`
     - Após retorno do diálogo, recarregar a lista com `await _loadQuestions()`
  3. Adicionar ícone de edição visível no `_QuestionListItem`:
     - Adicionar um `IconButton` com ícone de lápis no `trailing` do `ListTile`
     - Cor do ícone: `Color(0xFF2563EB)`
     - Ao clicar, chamar `_handleEdit(question)`
  4. Manter o comportamento de long-press para abrir o diálogo de ações (Editar/Remover/Fechar)

## Estrutura do diálogo de edição
- **Campos do formulário**:
  1. **Campo "Texto da questão"**: TextField multiline (minLines: 3, maxLines: 6)
     - Label: "Texto da questão"
     - Validação: Obrigatório, não pode estar vazio
  2. **Campo "Ordem"**: TextField numérico
     - Label: "Ordem de exibição"
     - Tipo: Teclado numérico
     - Validação: Deve ser número inteiro ≥ 0
  3. **Informação read-only**: Exibir quantidade de respostas
     - Formato: "X respostas associadas"
     - Ícone: `Icons.quiz`
     - Cor: Cinza

- **Botões**:
  - **Salvar**: Valida campos, persiste via DAO, fecha diálogo e retorna
  - **Cancelar**: Fecha diálogo sem salvar

## Layout visual esperado

```
┌─────────────────────────────────────────┐
│  ✏️ Editar Questão                      │
│                                         │
│  Texto da questão                       │
│  ┌───────────────────────────────────┐  │
│  │ Qual é a capital do Brasil?       │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Ordem de exibição                      │
│  ┌─────┐                                │
│  │  1  │                                │
│  └─────┘                                │
│                                         │
│  📝 3 respostas associadas              │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ 💾 Salvar│ ✕ Cancelar│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ O ícone de edição (lápis azul) aparece em cada item da lista de questões
2. ✅ Tocar no ícone de lápis abre o formulário de edição pré-preenchido
3. ✅ O formulário permite editar o texto da questão e a ordem
4. ✅ O formulário exibe a quantidade de respostas (read-only)
5. ✅ Validação impede salvar com texto vazio ou ordem inválida
6. ✅ Ao salvar, os dados são persistidos via DAO com `try/catch`
7. ✅ Usuário vê `SnackBar` de sucesso ("Questão atualizada com sucesso") ou erro
8. ✅ Após salvar com sucesso, a lista é recarregada automaticamente
9. ✅ O diálogo não pode ser fechado ao tocar fora (apenas pelos botões)
10. ✅ O método `_handleEdit` não exibe mais o SnackBar placeholder
11. ✅ O código não altera funcionalidades de remoção (isso é responsabilidade de outro prompt)

## Observações
- **Foco principal**: Edição do texto da questão e ordem
- **Não editar respostas**: As respostas associadas são gerenciadas na página de answers
- **Preparar para criação futura**: O diálogo deve suportar `question: null` para modo criação (mas não é prioridade agora)
- Manter consistência com os diálogos já implementados (questions selection, answers selection, etc.)
- Reutilizar o padrão de cores e espaçamentos estabelecido no projeto
