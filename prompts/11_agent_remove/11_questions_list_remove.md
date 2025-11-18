# Prompt: Implementar remoção de questions por swipe (Dismissible)

## Objetivo
Adicionar a funcionalidade de remoção de questions via swipe-to-dismiss na listagem.

## Resumo do comportamento esperado
- Envolver cada item da lista de questions em um `Dismissible` com direção `DismissDirection.endToStart` (swipe da direita para esquerda)
- Ao detectar o gesto, chamar `confirmDismiss` que abre um `AlertDialog` de confirmação
- O diálogo deve perguntar: "Remover questão?" e exibir o texto da questão e quantidade de respostas associadas
- Se o usuário confirmar, chamar o DAO para remover o item (`QuestionsLocalDaoSharedPrefs.removeById(id)`) dentro de `try/catch`
- Em caso de sucesso, exibir `SnackBar` verde confirmando remoção ("Questão removida com sucesso")
- Em caso de erro, reverter UI e exibir `SnackBar` vermelha com a mensagem de erro
- Após remoção bem-sucedida, recarregar a lista de questions

## Entidade e estrutura
- **Entidade**: `QuestionDto` localizado em `lib/features/questions/infrastructure/dtos/question_dto.dart`
- **Propriedades principais**:
  - `id` (String): Identificador único da questão
  - `text` (String): Texto da questão
  - `answers` (List<AnswerDto>): Lista de respostas associadas
  - `order` (int): Ordem da questão

## Informações específicas para questions
- **Confirmação**: O diálogo deve mostrar:
  - Título: "Remover questão?"
  - Mensagem: "Deseja realmente remover esta questão?\n\n'{question.text}'\n\nAtenção: As {answers.length} respostas associadas também serão removidas."
  - Botões: "Cancelar" (cinza) e "Remover" (vermelho)

- **Visual do Dismissible**:
  - Background: Vermelho com ícone de lixeira (Icons.delete) alinhado à direita
  - Direção: `DismissDirection.endToStart` (swipe esquerda)
  - Cor primária: `Color(0xFF2563EB)` (azul do app)

- **DAO**: Usar `QuestionsLocalDaoSharedPrefs` com método `removeById(String id)`

## Integração e convenções
- **Arquivo**: `lib/features/questions/presentation/questions_page.dart`
- **Ação**: Envolver o Card de cada question em um widget `Dismissible`
- **Key**: Usar `Key(question.id)` para identificar unicamente cada item
- **Importante**: 
  - O diálogo de confirmação deve usar `barrierDismissible: false` para evitar fechamento acidental
  - Usuário só pode confirmar/cancelar através dos botões
  - Manter o método `_handleRemove` existente mas adaptar para integrar com o Dismissible
  - A função `confirmDismiss` deve retornar `Future<bool?>` onde `true` = confirma remoção, `false/null` = cancela

## Layout visual do Dismissible

```
┌─────────────────────────────────────────┐
│  Card da questão                        │  → Swipe para esquerda
│  "Qual é a capital do Brasil?"          │ 
│  📝 5 respostas | Ordem: 1               │
└─────────────────────────────────────────┘
         ↓ (ao fazer swipe)
┌─────────────────────────────────────────┐
│                        🗑️ DELETE         │ ← Background vermelho
└─────────────────────────────────────────┘
         ↓ (ao soltar)
┌─────────────────────────────────────────┐
│  ⚠️ Remover questão?                     │
│                                         │
│  Deseja realmente remover esta questão? │
│                                         │
│  "Qual é a capital do Brasil?"          │
│                                         │
│  Atenção: As 5 respostas associadas     │
│  também serão removidas.                │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ Cancelar│ 🗑️ Remover│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ Swipe para esquerda exibe background vermelho com ícone de lixeira
2. ✅ Ao soltar o swipe, abre diálogo de confirmação com texto da questão e quantidade de respostas
3. ✅ Diálogo não pode ser fechado tocando fora (apenas pelos botões)
4. ✅ Ao confirmar, chama `removeById` do DAO dentro de `try/catch`
5. ✅ Em caso de sucesso, exibe SnackBar verde e recarrega a lista
6. ✅ Em caso de erro, exibe SnackBar vermelha com mensagem de erro
7. ✅ O swipe não interfere com outros gestos (tap, long-press)
8. ✅ Animação suave ao remover o item da lista
9. ✅ A remoção persiste (dados são excluídos do SharedPreferences)
10. ✅ Mensagem de confirmação alerta sobre remoção das respostas associadas

## Observações importantes
- **Respostas associadas**: Ao remover uma questão, todas as respostas associadas também são removidas. O diálogo deve deixar isso claro para o usuário.
- **Ordem das questões**: Após remover uma questão, a lista será reordenada automaticamente ao recarregar.
- **Integração com outros diálogos**: O swipe-to-dismiss convive com:
  - Tap para expandir/colapsar detalhes
  - Long-press para abrir diálogo de ações (Editar/Remover/Fechar)
  - Ícone de edição para abrir formulário
- **Confirmação dupla**: Como já existe `_handleRemove` no long-press, o swipe oferece um atalho rápido com a mesma confirmação
- **Não implementar edição**: Este prompt foca apenas em remoção. Edição já foi implementada em outro prompt.
- Manter consistência com os padrões já estabelecidos no projeto (cores, espaçamentos, feedback visual)
