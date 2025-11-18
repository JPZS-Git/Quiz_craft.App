# Prompt: Implementar remoção de attempts por swipe (Dismissible)

## Objetivo
Adicionar a funcionalidade de remoção de attempts via swipe-to-dismiss na listagem.

## Resumo do comportamento esperado
- Envolver cada item da lista de attempts em um `Dismissible` com direção `DismissDirection.endToStart` (swipe da direita para esquerda)
- Ao detectar o gesto, chamar `confirmDismiss` que abre um `AlertDialog` de confirmação
- O diálogo deve perguntar: "Remover tentativa?" e exibir informações do attempt (quiz ID, score, data)
- Se o usuário confirmar, chamar o DAO para remover o item (`AttemptsLocalDaoSharedPrefs.removeById(id)`) dentro de `try/catch`
- Em caso de sucesso, exibir `SnackBar` verde confirmando remoção ("Tentativa removida com sucesso")
- Em caso de erro, reverter UI e exibir `SnackBar` vermelha com a mensagem de erro
- Após remoção bem-sucedida, recarregar a lista de attempts

## Entidade e estrutura
- **Entidade**: `AttemptDto` localizado em `lib/features/attempts/infrastructure/dtos/attempt_dto.dart`
- **Propriedades principais**:
  - `id` (String): Identificador único da tentativa
  - `quizId` (String): ID do quiz associado
  - `userId` (String?): ID do usuário (opcional)
  - `correctCount` (int): Quantidade de respostas corretas
  - `totalCount` (int): Total de questões
  - `score` (double): Pontuação (0-100%)
  - `startedAt` (String): Data/hora de início (ISO 8601)
  - `finishedAt` (String?): Data/hora de conclusão (ISO 8601, opcional)

## Informações específicas para attempts
- **Confirmação**: O diálogo deve mostrar:
  - Título: "Remover tentativa?"
  - Mensagem: "Deseja realmente remover esta tentativa?\n\nQuiz ID: {quizId}\nPontuação: {score}% ({correctCount}/{totalCount})\nIniciado: {formatado}\n{Concluído/Em andamento}"
  - Botões: "Cancelar" (cinza) e "Remover" (vermelho)

- **Visual do Dismissible**:
  - Background: Vermelho com ícone de lixeira (Icons.delete) alinhado à direita
  - Direção: `DismissDirection.endToStart` (swipe esquerda)
  - Cor primária: `Color(0xFF2563EB)` (azul do app)

- **DAO**: Usar `AttemptsLocalDaoSharedPrefs` com método `removeById(String id)`

## Integração e convenções
- **Arquivos**:
  - `lib/features/attempts/presentation/attempts_page.dart` - Página principal com Dismissible
  - `lib/features/attempts/presentation/widgets/attempt_list_item.dart` - Widget separado do card (OBRIGATÓRIO)
- **Estrutura obrigatória**: 
  - Criar widget público `AttemptListItem` em arquivo separado na pasta `widgets/`
  - O widget deve ser reutilizável e documentado
  - Incluir parâmetro `key` no construtor
  - Exportar callbacks para `onTap`, `onLongPress`, `onEdit`
- **Ação**: Envolver o `AttemptListItem` em um widget `Dismissible` no `ListView.builder`
- **Key**: Usar `Key(attempt.id)` para identificar unicamente cada item
- **Importante**: 
  - O diálogo de confirmação deve usar `barrierDismissible: false` para evitar fechamento acidental
  - Usuário só pode confirmar/cancelar através dos botões
  - Manter o método `_handleRemove` existente mas adaptar para integrar com o Dismissible
  - A função `confirmDismiss` deve retornar `Future<bool?>` onde `true` = confirma remoção, `false/null` = cancela
  - Formatar datas de forma legível (dd/MM/yyyy HH:mm)

## Layout visual do Dismissible

```
┌─────────────────────────────────────────┐
│  Card da tentativa                      │  → Swipe para esquerda
│  Quiz: abc123                           │ 
│  📊 75% (15/20) | 18/11/2025 14:30      │
│  ✅ Concluída                            │
└─────────────────────────────────────────┘
         ↓ (ao fazer swipe)
┌─────────────────────────────────────────┐
│                        🗑️ DELETE         │ ← Background vermelho
└─────────────────────────────────────────┘
         ↓ (ao soltar)
┌─────────────────────────────────────────┐
│  ⚠️ Remover tentativa?                   │
│                                         │
│  Deseja realmente remover esta tentativa?│
│                                         │
│  Quiz ID: abc123                        │
│  Pontuação: 75% (15/20)                 │
│  Iniciado: 18/11/2025 14:30             │
│  Concluído: 18/11/2025 14:45            │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ Cancelar│ 🗑️ Remover│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ Widget `AttemptListItem` criado em arquivo separado `widgets/attempt_list_item.dart`
2. ✅ Widget é público, reutilizável e possui documentação adequada
3. ✅ Swipe para esquerda exibe background vermelho com ícone de lixeira
4. ✅ Ao soltar o swipe, abre diálogo de confirmação com informações detalhadas da tentativa
5. ✅ Diálogo mostra: quiz ID, pontuação (% e fração), datas formatadas, status (concluída/em andamento)
6. ✅ Diálogo não pode ser fechado tocando fora (apenas pelos botões)
7. ✅ Ao confirmar, chama `removeById` do DAO dentro de `try/catch`
8. ✅ Em caso de sucesso, exibe SnackBar verde e recarrega a lista
9. ✅ Em caso de erro, exibe SnackBar vermelha com mensagem de erro
10. ✅ O swipe não interfere com outros gestos (tap, long-press)
11. ✅ Animação suave ao remover o item da lista
12. ✅ A remoção persiste (dados são excluídos do SharedPreferences)

## Observações importantes
- **Formatação de datas**: Usar formato brasileiro dd/MM/yyyy HH:mm para exibição no diálogo
- **Status visual**: Indicar claramente se a tentativa foi concluída (finishedAt != null) ou está em andamento
- **Pontuação**: Mostrar tanto a porcentagem quanto a fração (ex: "75% (15/20)")
- **Quiz ID**: Como attempts têm referência a quiz, exibir o quizId truncado se necessário
- **Integração com outros diálogos**: O swipe-to-dismiss convive com:
  - Tap para expandir/colapsar detalhes
  - Long-press para abrir diálogo de ações (Editar/Remover/Fechar)
  - Ícone de edição para abrir formulário
- **Confirmação dupla**: Como já existe `_handleRemove` no long-press, o swipe oferece um atalho rápido com a mesma confirmação
- **Não implementar edição**: Este prompt foca apenas em remoção. Edição já foi implementada em outro prompt.
- Manter consistência com os padrões já estabelecidos no projeto (cores, espaçamentos, feedback visual)
- Badge de pontuação com cores: verde (≥70%), laranja (40-69%), vermelho (<40%)
