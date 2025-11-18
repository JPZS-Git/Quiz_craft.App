# Prompt: Implementar edição de answers (ícone lápis)

## Objetivo
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de answers (respostas).

## Resumo do comportamento esperado
- Cada item da lista de respostas deverá exibir um ícone de lápis (edit) visível e clicável
- Ao tocar no ícone de lápis, abrir um formulário em diálogo para edição preenchido com os dados atuais da resposta
- O formulário deve permitir editar os campos da `AnswerDto`: `text` (texto da resposta) e `isCorrect` (se é a resposta correta)
- Ao confirmar a edição, chamar o DAO apropriado (`AnswersLocalDaoSharedPrefs.update` ou similar) para persistir a alteração dentro de `try/catch`
- Exibir `SnackBar` de sucesso ou erro conforme o resultado
- Após salvar com sucesso, recarregar a lista de respostas
- Não implementar remoção nem swipe neste prompt; apenas edição

## Entidade e estrutura
- **Entidade**: `AnswerDto` localizado em `lib/features/answers/infrastructure/dtos/answer_dto.dart`
- **Propriedades**:
  - `id` (String): Identificador único da resposta
  - `text` (String): Texto da resposta
  - `isCorrect` (bool): Indica se é a resposta correta (true/false)

## Informações específicas para answers
- **Campo principal para edição**: `text` (texto da resposta)
- **Campo booleano**: `isCorrect` (checkbox ou switch para marcar como correta)
- **Validação obrigatória**: 
  - Text não pode estar vazio
- **Ícone**: `Icons.edit` para o botão de edição
- **Cor do ícone**: Azul (`Color(0xFF2563EB)`)
- **Badge visual**: Exibir indicador visual "CORRETA" (verde) ou "Incorreta" (cinza) baseado em `isCorrect`

## Integração e convenções
- **Criar o diálogo de edição** em `lib/features/answers/presentation/dialogs/answer_form_dialog.dart`
- O arquivo deve exportar uma função helper:
  ```dart
  Future<void> showAnswerFormDialog(
    BuildContext context, {
    AnswerDto? answer, // null = criar nova, não-null = editar
  })
  ```
- Se `answer` não for null, preencher os campos com os valores atuais para edição
- Se `answer` for null, criar uma nova resposta (modo criação - não é o foco deste prompt, mas deixar preparado)
- **DAO**: Usar `AnswersLocalDaoSharedPrefs` com método `update(AnswerDto)`
- Labels e textos em **português**
- **Importante**: O diálogo não deve ser fechado ao tocar fora. Use `barrierDismissible: false` no `showDialog`
- Cores:
  - Botão Salvar: Azul (`Color(0xFF2563EB)`)
  - Botão Cancelar: Cinza (`Colors.grey`)
  - Badge "CORRETA": Verde (`Colors.green`)
  - Badge "Incorreta": Cinza (`Colors.grey`)
  - Ícone check (correta): Verde (`Colors.green`)
  - Ícone radio (incorreta): Cinza (`Colors.grey`)

## Integração na página de listagem
- **Arquivo**: `lib/features/answers/presentation/answers_page.dart`
- **Ação**: Adicionar ícone de edição (lápis) nos itens da lista
- **Implementação**:
  1. Importar o diálogo: `import 'dialogs/answer_form_dialog.dart';`
  2. Atualizar o método `_handleEdit(AnswerDto answer)` que atualmente é placeholder:
     - Remover o SnackBar placeholder
     - Chamar `await showAnswerFormDialog(context, answer: answer)`
     - Após retorno do diálogo, recarregar a lista com `await _loadAnswers()`
  3. Adicionar ícone de edição visível no `_AnswerListItem`:
     - Adicionar um `IconButton` com ícone de lápis no `trailing` do `ListTile`
     - Cor do ícone: `Color(0xFF2563EB)`
     - Ao clicar, chamar `_handleEdit(answer)`
  4. Manter o comportamento de long-press para abrir o diálogo de ações (Editar/Remover/Fechar)

## Estrutura do diálogo de edição
- **Campos do formulário**:
  1. **Campo "Texto da resposta"**: TextField multiline (minLines: 2, maxLines: 5)
     - Label: "Texto da resposta"
     - Validação: Obrigatório, não pode estar vazio
  2. **Campo "É a resposta correta?"**: CheckboxListTile ou SwitchListTile
     - Label: "Marcar como resposta correta"
     - Valor inicial: `answer.isCorrect`
     - Exibir badge visual ao lado: "CORRETA" (verde) quando true, "Incorreta" (cinza) quando false
     - Ícone: `Icons.check_circle` (verde) quando true, `Icons.radio_button_unchecked` (cinza) quando false

- **Botões**:
  - **Salvar**: Valida campos, persiste via DAO, fecha diálogo e retorna
  - **Cancelar**: Fecha diálogo sem salvar

## Layout visual esperado

```
┌─────────────────────────────────────────┐
│  ✏️ Editar Resposta                     │
│                                         │
│  Texto da resposta                      │
│  ┌───────────────────────────────────┐  │
│  │ Brasília                          │  │
│  │                                   │  │
│  └───────────────────────────────────┘  │
│                                         │
│  ☑️ Marcar como resposta correta        │
│  ✅ CORRETA                             │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ 💾 Salvar│ ✕ Cancelar│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ O ícone de edição (lápis azul) aparece em cada item da lista de respostas
2. ✅ Tocar no ícone de lápis abre o formulário de edição pré-preenchido
3. ✅ O formulário permite editar o texto da resposta e o status isCorrect
4. ✅ O formulário exibe badge visual (CORRETA/Incorreta) baseado no checkbox/switch
5. ✅ Validação impede salvar com texto vazio
6. ✅ Ao salvar, os dados são persistidos via DAO com `try/catch`
7. ✅ Usuário vê `SnackBar` de sucesso ("Resposta atualizada com sucesso") ou erro
8. ✅ Após salvar com sucesso, a lista é recarregada automaticamente
9. ✅ O diálogo não pode ser fechado ao tocar fora (apenas pelos botões)
10. ✅ O método `_handleEdit` não exibe mais o SnackBar placeholder
11. ✅ O código não altera funcionalidades de remoção (isso é responsabilidade de outro prompt)

## Observações
- **Foco principal**: Edição do texto da resposta e do status isCorrect
- **Badge visual**: Importante para feedback visual imediato do status da resposta
- **Checkbox vs Switch**: Pode usar qualquer um dos dois componentes, mas recomenda-se CheckboxListTile por ser mais visual
- **Preparar para criação futura**: O diálogo deve suportar `answer: null` para modo criação (mas não é prioridade agora)
- Manter consistência com os diálogos já implementados (questions, attempts, etc.)
- Reutilizar o padrão de cores e espaçamentos estabelecido no projeto
