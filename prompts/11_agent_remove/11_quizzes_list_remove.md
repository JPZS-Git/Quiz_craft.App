## Prompt: Implementar remoção por swipe (Dismissible) para Quizzes

Objetivo
---
Adicionar a funcionalidade de remoção de quizzes via swipe-to-dismiss na listagem.

Requisito obrigatório
---
**O widget de item da lista DEVE ser separado em arquivo próprio** em `lib/features/quizzes/presentation/widgets/quiz_list_item.dart` como classe pública `QuizListItem` com documentação completa.

Resumo do comportamento
---
- Envolver cada item da lista em um `Dismissible` com direção `DismissDirection.endToStart` (swipe para esquerda).
- Ao detectar o gesto, chamar `confirmDismiss` que abre um `AlertDialog` de confirmação detalhada.
- **Diálogo de confirmação** deve mostrar:
  - Título do quiz
  - Autor ID
  - Status (PUBLICADO/RASCUNHO)
  - Quantidade de questões
  - **Aviso importante destacado**: "Atenção: As X questões associadas também serão removidas" (container vermelho com ícone de aviso)
- Se o usuário confirmar, chamar o DAO para remover o item (`QuizzesLocalDaoSharedPrefs.removeById(id)`) dentro de `try/catch`.
- Em caso de sucesso, exibir `SnackBar` verde confirmando remoção e recarregar lista.
- Em caso de erro, exibir `SnackBar` vermelho com mensagem de erro.
- Background do Dismissible: container vermelho com ícone `Icons.delete` alinhado à direita, borderRadius 12.

Integração e convenções
---
- **Widget separado obrigatório**: Extrair widget de item para `lib/features/quizzes/presentation/widgets/quiz_list_item.dart`
  - Classe pública `QuizListItem` com `super.key` parameter
  - Incluir documentação descrevendo funcionalidade
  - Exportar callbacks: `onTap`, `onLongPress`, `onEdit`
- Implementar em `lib/features/quizzes/presentation/quizzes_page.dart`
- Usar DAO local existente: `QuizzesLocalDaoSharedPrefs`
- Refatorar `_handleRemove` para `_confirmRemove` que retorna `Future<bool>`:
  - Retorna `true` se removido com sucesso
  - Retorna `false` se cancelado ou erro
  - Chama `await _loadQuizzes()` após remoção bem-sucedida
- Criar `_handleRemove` wrapper: `Future<void> _handleRemove(QuizDto quiz) async { await _confirmRemove(quiz); }`
- Adicionar helper `_buildInfoRow(String label, String value)` para formatação consistente do diálogo
- Diálogo de confirmação com `barrierDismissible: false` (usuário deve usar botões)
- Remover classe privada `_QuizCard` ou equivalente após extração do widget

Padrão de Dismissible
---
```dart
Dismissible(
  key: Key(quiz.id),
  direction: DismissDirection.endToStart,
  background: Container(
    alignment: Alignment.centerRight,
    padding: const EdgeInsets.only(right: 20),
    decoration: BoxDecoration(
      color: Colors.red,
      borderRadius: BorderRadius.circular(12),
    ),
    child: const Icon(Icons.delete, color: Colors.white, size: 32),
  ),
  confirmDismiss: (direction) => _confirmRemove(quiz),
  onDismissed: (direction) {
    // Removal is already handled in confirmDismiss
  },
  child: QuizListItem(...),
)
```

Padrão de confirmação
---
```dart
Future<bool> _confirmRemove(QuizDto quiz) async {
  final confirm = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: const Text('Remover Quiz?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow('Título', quiz.title),
          const SizedBox(height: 8),
          _buildInfoRow('Autor', quiz.authorId),
          const SizedBox(height: 8),
          _buildInfoRow('Status', quiz.isPublished ? 'PUBLICADO' : 'RASCUNHO'),
          const SizedBox(height: 8),
          _buildInfoRow('Questões', '${quiz.questions.length}'),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning, color: Colors.red, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Atenção: As ${quiz.questions.length} questões associadas também serão removidas',
                    style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(false),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Remover', style: TextStyle(color: Colors.white)),
        ),
      ],
    ),
  );

  if (confirm != true) return false;

  try {
    await _dao.removeById(quiz.id);
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Quiz removido com sucesso'), backgroundColor: Colors.green),
    );
    await _loadQuizzes();
    return true;
  } catch (e) {
    if (!mounted) return false;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Erro ao remover quiz: $e'), backgroundColor: Colors.red),
    );
    return false;
  }
}

Widget _buildInfoRow(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 120,
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey[700])),
      ),
      Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600))),
    ],
  );
}
```

Critérios de aceitação
---
1. Widget `QuizListItem` separado em arquivo próprio com documentação
2. Swipe para esquerda exibe confirmação detalhada com aviso de remoção de questões
3. Confirmação mostra: título, autor, status, quantidade de questões, aviso destacado
4. Remoção persiste via DAO e lista é recarregada após sucesso
5. Erros são tratados com `SnackBar` vermelho
6. Diálogo não-dismissable (apenas botões funcionam)
7. Validar com `flutter analyze` esperando 0 erros
8. Não introduz comportamento de edição ou seleção — somente remoção
