# Prompt: Implementar edição de attempts (ícone lápis)

## Objetivo
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de attempts (tentativas de quiz).

## Resumo do comportamento esperado
- Cada item da lista de tentativas deverá exibir um ícone de lápis (edit) visível e clicável
- Ao tocar no ícone de lápis, abrir um formulário em diálogo para edição preenchido com os dados atuais da tentativa
- O formulário deve permitir editar os campos editáveis da `AttemptDto`: `correctCount` (respostas corretas), `totalCount` (total de questões), e `finishedAt` (data de conclusão)
- O score será recalculado automaticamente com base em correctCount/totalCount
- Ao confirmar a edição, chamar o DAO apropriado (`AttemptsLocalDaoSharedPrefs.update` ou similar) para persistir a alteração dentro de `try/catch`
- Exibir `SnackBar` de sucesso ou erro conforme o resultado
- Após salvar com sucesso, recarregar a lista de tentativas
- Não implementar remoção nem swipe neste prompt; apenas edição

## Entidade e estrutura
- **Entidade**: `AttemptDto` localizado em `lib/features/attempts/infrastructure/dtos/attempt_dto.dart`
- **Propriedades**:
  - `id` (String): Identificador único da tentativa
  - `quizId` (String): ID do quiz associado
  - `userId` (String?): ID do usuário (opcional)
  - `correctCount` (int): Quantidade de respostas corretas - **EDITÁVEL**
  - `totalCount` (int): Total de questões - **EDITÁVEL**
  - `score` (double): Pontuação percentual (calculada automaticamente)
  - `startedAt` (String): Data/hora de início (ISO 8601) - **READ-ONLY**
  - `finishedAt` (String?): Data/hora de conclusão (ISO 8601) - **EDITÁVEL**

## Informações específicas para attempts
- **Campos editáveis**:
  1. `correctCount`: Número de respostas corretas (inteiro ≥ 0)
  2. `totalCount`: Total de questões (inteiro ≥ 1)
  3. `finishedAt`: Data/hora de conclusão (opcional, pode ser null para tentativas em andamento)
- **Campos read-only**:
  - `id`: Identificador (exibir para referência)
  - `quizId`: ID do quiz (exibir truncado)
  - `startedAt`: Data de início (exibir formatada)
  - `score`: Calculado automaticamente como `(correctCount / totalCount) * 100`
- **Validações obrigatórias**: 
  - `correctCount` ≥ 0
  - `totalCount` ≥ 1
  - `correctCount` ≤ `totalCount`
- **Ícone**: `Icons.edit` para o botão de edição
- **Cor do ícone**: Azul (`Color(0xFF2563EB)`)

## Integração e convenções
- **Criar o diálogo de edição** em `lib/features/attempts/presentation/dialogs/attempt_form_dialog.dart`
- O arquivo deve exportar uma função helper:
  ```dart
  Future<void> showAttemptFormDialog(
    BuildContext context, {
    AttemptDto? attempt, // null = criar nova, não-null = editar
  })
  ```
- Se `attempt` não for null, preencher os campos com os valores atuais para edição
- Se `attempt` for null, criar uma nova tentativa (modo criação - não é o foco deste prompt, mas deixar preparado)
- **Recalcular score**: Ao salvar, calcular `score = (correctCount / totalCount) * 100`
- **DAO**: Usar `AttemptsLocalDaoSharedPrefs` com método `update(AttemptDto)`
- Labels e textos em **português**
- **Importante**: O diálogo não deve ser fechado ao tocar fora. Use `barrierDismissible: false` no `showDialog`
- **Data/hora**: Usar `DateFormat` para formatar datas no formato brasileiro (dd/MM/yyyy HH:mm)
- Cores:
  - Botão Salvar: Azul (`Color(0xFF2563EB)`)
  - Botão Cancelar: Cinza (`Colors.grey`)
  - Score badge: Verde (≥80%), Laranja (≥60%), Vermelho (<60%)

## Integração na página de listagem
- **Arquivo**: `lib/features/attempts/presentation/attempts_page.dart`
- **Ação**: Adicionar ícone de edição (lápis) nos itens da lista
- **Implementação**:
  1. Importar o diálogo: `import 'dialogs/attempt_form_dialog.dart';`
  2. Atualizar o método `_handleEdit(AttemptDto attempt)` que atualmente é placeholder:
     - Remover o SnackBar placeholder
     - Chamar `await showAttemptFormDialog(context, attempt: attempt)`
     - Após retorno do diálogo, recarregar a lista com `await _loadAttempts()`
  3. Adicionar ícone de edição visível no `_AttemptListItem`:
     - Adicionar um `IconButton` com ícone de lápis no `trailing` do `ListTile`
     - Cor do ícone: `Color(0xFF2563EB)`
     - Ao clicar, chamar `_handleEdit(attempt)`
  4. Manter o comportamento de long-press para abrir o diálogo de ações (Editar/Remover/Fechar)

## Estrutura do diálogo de edição
- **Campos do formulário**:
  1. **Campo "Respostas corretas"**: TextField numérico
     - Label: "Respostas corretas"
     - Tipo: Teclado numérico
     - Validação: Obrigatório, ≥ 0, ≤ totalCount
  2. **Campo "Total de questões"**: TextField numérico
     - Label: "Total de questões"
     - Tipo: Teclado numérico
     - Validação: Obrigatório, ≥ 1
  3. **Campo "Data de conclusão"**: TextField de data/hora
     - Label: "Data de conclusão (opcional)"
     - Formato: dd/MM/yyyy HH:mm
     - Placeholder: "Deixe vazio se ainda não concluído"
     - Validação: Opcional, formato válido se preenchido
  4. **Informações read-only**:
     - Quiz ID (truncado se muito longo)
     - Data de início formatada
     - Score calculado automaticamente (exibir badge colorido)

- **Botões**:
  - **Salvar**: Valida campos, recalcula score, persiste via DAO, fecha diálogo e retorna
  - **Cancelar**: Fecha diálogo sem salvar

## Layout visual esperado

```
┌─────────────────────────────────────────┐
│  ✏️ Editar Tentativa                    │
│                                         │
│  Quiz: abc123... (read-only)            │
│  Iniciado: 18/11/2025 14:30 (read-only)│
│                                         │
│  Respostas corretas                     │
│  ┌─────┐                                │
│  │  8  │                                │
│  └─────┘                                │
│                                         │
│  Total de questões                      │
│  ┌─────┐                                │
│  │ 10  │                                │
│  └─────┘                                │
│                                         │
│  Score: 80% ✅                          │
│                                         │
│  Data de conclusão (opcional)           │
│  ┌──────────────────────────┐           │
│  │ 18/11/2025 15:00         │           │
│  └──────────────────────────┘           │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ 💾 Salvar│ ✕ Cancelar│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ O ícone de edição (lápis azul) aparece em cada item da lista de tentativas
2. ✅ Tocar no ícone de lápis abre o formulário de edição pré-preenchido
3. ✅ O formulário permite editar correctCount, totalCount e finishedAt
4. ✅ O formulário exibe informações read-only: quizId, startedAt
5. ✅ Score é calculado automaticamente e exibido com badge colorido
6. ✅ Validação impede salvar com valores inválidos (correctCount > totalCount, totalCount < 1, etc.)
7. ✅ Ao salvar, os dados são persistidos via DAO com `try/catch`
8. ✅ Usuário vê `SnackBar` de sucesso ("Tentativa atualizada com sucesso") ou erro
9. ✅ Após salvar com sucesso, a lista é recarregada automaticamente
10. ✅ O diálogo não pode ser fechado ao tocar fora (apenas pelos botões)
11. ✅ O método `_handleEdit` não exibe mais o SnackBar placeholder
12. ✅ O código não altera funcionalidades de remoção (isso é responsabilidade de outro prompt)

## Observações
- **Foco principal**: Edição de correctCount, totalCount e finishedAt
- **Score automático**: Sempre recalcular ao salvar
- **Data de conclusão opcional**: Campo finishedAt pode ser null (tentativa em andamento)
- **Formatação de datas**: Usar formato brasileiro dd/MM/yyyy HH:mm
- Manter consistência com os diálogos já implementados (questions, answers, etc.)
- Reutilizar o padrão de cores e espaçamentos estabelecido no projeto
