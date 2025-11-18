# Prompt: Implementar remoção de answers por swipe (Dismissible)

## Objetivo
Adicionar a funcionalidade de remoção de answers via swipe-to-dismiss na listagem.

## Resumo do comportamento esperado
- Envolver cada item da lista de answers em um `Dismissible` com direção `DismissDirection.endToStart` (swipe da direita para esquerda)
- Ao detectar o gesto, chamar `confirmDismiss` que abre um `AlertDialog` de confirmação
- O diálogo deve perguntar: "Remover resposta?" e exibir o texto da resposta e seu status (correta/incorreta)
- Se o usuário confirmar, chamar o DAO para remover o item (`AnswersLocalDaoSharedPrefs.removeById(id)`) dentro de `try/catch`
- Em caso de sucesso, exibir `SnackBar` verde confirmando remoção ("Resposta removida com sucesso")
- Em caso de erro, reverter UI e exibir `SnackBar` vermelha com a mensagem de erro
- Após remoção bem-sucedida, recarregar a lista de answers

## Entidade e estrutura
- **Entidade**: `AnswerDto` localizado em `lib/features/answers/infrastructure/dtos/answer_dto.dart`
- **Propriedades principais**:
  - `id` (String): Identificador único da resposta
  - `text` (String): Texto da resposta
  - `isCorrect` (bool): Indica se a resposta é correta

## Informações específicas para answers
- **Confirmação**: O diálogo deve mostrar:
  - Título: "Remover resposta?"
  - Mensagem: "Deseja realmente remover esta resposta?\n\n'{answer.text}'\n\nStatus: {CORRETA/Incorreta}"
  - Botões: "Cancelar" (cinza) e "Remover" (vermelho)

- **Visual do Dismissible**:
  - Background: Vermelho com ícone de lixeira (Icons.delete) alinhado à direita
  - Direção: `DismissDirection.endToStart` (swipe esquerda)
  - Cor primária: `Color(0xFF2563EB)` (azul do app)

- **DAO**: Usar `AnswersLocalDaoSharedPrefs` com método `removeById(String id)`

## Integração e convenções
- **Arquivos**:
  - `lib/features/answers/presentation/answers_page.dart` - Página principal com Dismissible
  - `lib/features/answers/presentation/widgets/answer_list_item.dart` - Widget separado do card (OBRIGATÓRIO)
- **Estrutura obrigatória**: 
  - Criar widget público `AnswerListItem` em arquivo separado na pasta `widgets/`
  - O widget deve ser reutilizável e documentado
  - Incluir parâmetro `key` no construtor
  - Exportar callbacks para `onTap`, `onLongPress`, `onEdit`
- **Ação**: Envolver o `AnswerListItem` em um widget `Dismissible` no `ListView.builder`
- **Key**: Usar `Key(answer.id)` para identificar unicamente cada item
- **Importante**: 
  - O diálogo de confirmação deve usar `barrierDismissible: false` para evitar fechamento acidental
  - Usuário só pode confirmar/cancelar através dos botões
  - Manter o método `_handleRemove` existente mas adaptar para integrar com o Dismissible
  - A função `confirmDismiss` deve retornar `Future<bool?>` onde `true` = confirma remoção, `false/null` = cancela

## Layout visual do Dismissible

```
┌─────────────────────────────────────────┐
│  Card da resposta                       │  → Swipe para esquerda
│  "Brasília"                             │ 
│  ✅ CORRETA                              │
└─────────────────────────────────────────┘
         ↓ (ao fazer swipe)
┌─────────────────────────────────────────┐
│                        🗑️ DELETE         │ ← Background vermelho
└─────────────────────────────────────────┘
         ↓ (ao soltar)
┌─────────────────────────────────────────┐
│  ⚠️ Remover resposta?                    │
│                                         │
│  Deseja realmente remover esta resposta?│
│                                         │
│  "Brasília"                             │
│                                         │
│  Status: CORRETA                        │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ Cancelar│ 🗑️ Remover│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ Widget `AnswerListItem` criado em arquivo separado `widgets/answer_list_item.dart`
2. ✅ Widget é público, reutilizável e possui documentação adequada
3. ✅ Swipe para esquerda exibe background vermelho com ícone de lixeira
4. ✅ Ao soltar o swipe, abre diálogo de confirmação com texto da resposta e status (CORRETA/Incorreta)
5. ✅ Diálogo não pode ser fechado tocando fora (apenas pelos botões)
6. ✅ Ao confirmar, chama `removeById` do DAO dentro de `try/catch`
7. ✅ Em caso de sucesso, exibe SnackBar verde e recarrega a lista
8. ✅ Em caso de erro, exibe SnackBar vermelha com mensagem de erro
9. ✅ O swipe não interfere com outros gestos (tap, long-press)
10. ✅ Animação suave ao remover o item da lista
11. ✅ A remoção persiste (dados são excluídos do SharedPreferences)
12. ✅ Mensagem de confirmação mostra claramente o status da resposta (correta ou incorreta)

## Observações importantes
- **Status visual**: A confirmação deve exibir claramente se a resposta é CORRETA (verde) ou Incorreta (cinza) usando o mesmo padrão visual da listagem
- **Simplicidade**: Answers não têm dependências complexas como questions (que têm respostas associadas), então a remoção é direta
- **Integração com outros diálogos**: O swipe-to-dismiss convive com:
  - Tap para interação básica
  - Long-press para abrir diálogo de ações (Editar/Remover/Fechar)
  - Ícone de edição para abrir formulário
- **Confirmação dupla**: Como já existe `_handleRemove` no long-press, o swipe oferece um atalho rápido com a mesma confirmação
- **Não implementar edição**: Este prompt foca apenas em remoção. Edição já foi implementada em outro prompt.
- Manter consistência com os padrões já estabelecidos no projeto (cores, espaçamentos, feedback visual)
- Badge visual na confirmação: usar Container com padding e cor de fundo (verde para CORRETA, cinza para Incorreta)
