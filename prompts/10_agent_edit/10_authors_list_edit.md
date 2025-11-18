# Prompt: Implementar edição de authors (ícone lápis)

## Objetivo
Gerar código Flutter/Dart que adicione a funcionalidade de edição a itens da listagem de authors (autores).

## Resumo do comportamento esperado
- Cada item da lista de autores deverá exibir um ícone de lápis (edit) visível e clicável
- Ao tocar no ícone de lápis, abrir um formulário em diálogo para edição preenchido com os dados atuais do autor
- O formulário deve permitir editar os campos da `AuthorDto`: `name`, `email`, `avatarUrl`, `bio`, `topics`, `rating`, e `isActive`
- Ao confirmar a edição, chamar o DAO apropriado (`AuthorsLocalDaoSharedPrefs.update` ou similar) para persistir a alteração dentro de `try/catch`
- Exibir `SnackBar` de sucesso ou erro conforme o resultado
- Após salvar com sucesso, recarregar a lista de autores
- Não implementar remoção nem swipe neste prompt; apenas edição

## Entidade e estrutura
- **Entidade**: `AuthorDto` localizado em `lib/features/authors/infrastructure/dtos/author_dto.dart`
- **Propriedades**:
  - `id` (String): Identificador único do autor - **READ-ONLY**
  - `name` (String): Nome do autor - **EDITÁVEL**
  - `email` (String?): Email do autor (opcional) - **EDITÁVEL**
  - `avatarUrl` (String?): URL da imagem de avatar (opcional) - **EDITÁVEL**
  - `bio` (String?): Biografia/descrição (opcional) - **EDITÁVEL**
  - `topics` (List<String>): Lista de tópicos de especialidade - **EDITÁVEL**
  - `quizzesCount` (int): Quantidade de quizzes criados - **READ-ONLY** (calculado)
  - `rating` (double): Avaliação do autor (0.0 - 5.0) - **EDITÁVEL**
  - `isActive` (bool): Status ativo/inativo - **EDITÁVEL**
  - `createdAt` (String): Data de criação (ISO 8601) - **READ-ONLY**

## Informações específicas para authors
- **Campos editáveis principais**:
  1. `name`: Nome completo (obrigatório)
  2. `email`: Email (opcional, validar formato se preenchido)
  3. `avatarUrl`: URL da imagem (opcional, validar formato URL se preenchido)
  4. `bio`: Biografia multiline (opcional)
  5. `topics`: Lista de tópicos separados por vírgula ou chips editáveis
  6. `rating`: Avaliação de 0.0 a 5.0 (slider ou campo numérico)
  7. `isActive`: Status ativo/inativo (switch ou checkbox)

- **Campos read-only** (exibir no diálogo mas não editar):
  - `id`: Identificador
  - `quizzesCount`: Quantidade de quizzes
  - `createdAt`: Data de criação formatada

- **Validações obrigatórias**: 
  - `name`: Não pode estar vazio
  - `email`: Formato válido se preenchido (regex)
  - `avatarUrl`: Formato URL válido se preenchido (http/https)
  - `rating`: Entre 0.0 e 5.0
  - `topics`: Pode ser vazio, mas se preenchido, separar por vírgula

- **Ícone**: `Icons.edit` para o botão de edição
- **Cor do ícone**: Azul (`Color(0xFF2563EB)`)

## Integração e convenções
- **Criar o diálogo de edição** em `lib/features/authors/presentation/dialogs/author_form_dialog.dart`
- O arquivo deve exportar uma função helper:
  ```dart
  Future<void> showAuthorFormDialog(
    BuildContext context, {
    AuthorDto? author, // null = criar novo, não-null = editar
  })
  ```
- Se `author` não for null, preencher os campos com os valores atuais para edição
- Se `author` for null, criar um novo autor (modo criação - não é o foco deste prompt, mas deixar preparado)
- **DAO**: Usar `AuthorsLocalDaoSharedPrefs` com método `update(AuthorDto)`
- Labels e textos em **português**
- **Importante**: O diálogo não deve ser fechado ao tocar fora. Use `barrierDismissible: false` no `showDialog`
- **Email masking**: Não aplicar no formulário de edição (permitir editar o email completo)
- Cores:
  - Botão Salvar: Azul (`Color(0xFF2563EB)`)
  - Botão Cancelar: Cinza (`Colors.grey`)
  - Switch ativo: Verde (`Colors.green`)
  - Rating: Amarelo/dourado (`Colors.amber`) para as estrelas

## Integração na página de listagem
- **Arquivo**: `lib/features/authors/presentation/authors_page.dart`
- **Ação**: Adicionar ícone de edição (lápis) nos itens da lista
- **Implementação**:
  1. Importar o diálogo: `import 'dialogs/author_form_dialog.dart';`
  2. Atualizar o método `_handleEdit(AuthorDto author)` que atualmente é placeholder:
     - Remover o SnackBar placeholder
     - Chamar `await showAuthorFormDialog(context, author: author)`
     - Após retorno do diálogo, recarregar a lista com `await _loadAuthors()`
  3. Adicionar ícone de edição visível no `_AuthorCard`:
     - Adicionar um `IconButton` com ícone de lápis no `trailing` do `ListTile`
     - Cor do ícone: `Color(0xFF2563EB)`
     - Ao clicar, chamar `_handleEdit(author)`
  4. Manter o comportamento de long-press para abrir o diálogo de ações (Editar/Remover/Fechar)

## Estrutura do diálogo de edição
- **Campos do formulário** (ordem sugerida):
  1. **Informações read-only** (container cinza no topo):
     - ID do autor (truncado se necessário)
     - Quantidade de quizzes criados
     - Data de criação formatada (dd/MM/yyyy)
  
  2. **Campo "Nome completo"**: TextField single-line
     - Label: "Nome completo"
     - Validação: Obrigatório, não pode estar vazio
  
  3. **Campo "Email"**: TextField single-line
     - Label: "Email (opcional)"
     - Validação: Formato válido se preenchido
     - Tipo de teclado: email
  
  4. **Campo "URL do Avatar"**: TextField single-line
     - Label: "URL da imagem do avatar (opcional)"
     - Validação: URL válida (http/https) se preenchido
     - Tipo de teclado: url
  
  5. **Campo "Biografia"**: TextField multiline
     - Label: "Biografia (opcional)"
     - Linhas: minLines: 3, maxLines: 6
  
  6. **Campo "Tópicos"**: TextField single-line
     - Label: "Tópicos de especialidade (separados por vírgula)"
     - Hint: "Dart, Flutter, Mobile"
     - Exibir count de tópicos atual
  
  7. **Campo "Avaliação"**: Slider + display do valor
     - Label: "Avaliação"
     - Range: 0.0 - 5.0
     - Divisões: 10 (incrementos de 0.5)
     - Display: X.X ⭐
     - Cor: Amarelo (amber) para rating ≥ 4.0, laranja ≥ 3.0, vermelho < 3.0
  
  8. **Campo "Status ativo"**: SwitchListTile
     - Label: "Autor ativo"
     - Badge visual: "ATIVO" (verde) quando true, "INATIVO" (cinza) quando false

- **Botões**:
  - **Salvar**: Valida campos, persiste via DAO, fecha diálogo e retorna
  - **Cancelar**: Fecha diálogo sem salvar

## Layout visual esperado

```
┌─────────────────────────────────────────┐
│  ✏️ Editar Autor                        │
│                                         │
│  📋 ID: abc123... | 15 quizzes          │
│  📅 Criado: 18/11/2025                  │
│                                         │
│  Nome completo                          │
│  ┌───────────────────────────────────┐  │
│  │ João Pedro Silva                  │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Email (opcional)                       │
│  ┌───────────────────────────────────┐  │
│  │ joao@example.com                  │  │
│  └───────────────────────────────────┘  │
│                                         │
│  URL do Avatar (opcional)               │
│  ┌───────────────────────────────────┐  │
│  │ https://example.com/avatar.jpg    │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Biografia (opcional)                   │
│  ┌───────────────────────────────────┐  │
│  │ Desenvolvedor Flutter com 5 anos │  │
│  │ de experiência...                 │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Tópicos (3 tópicos)                    │
│  ┌───────────────────────────────────┐  │
│  │ Dart, Flutter, Mobile             │  │
│  └───────────────────────────────────┘  │
│                                         │
│  Avaliação: 4.5 ⭐                      │
│  ├─────────●─────────────────────────┤  │
│  0.0                              5.0   │
│                                         │
│  ☑️ Autor ativo  ✅ ATIVO               │
│                                         │
│  ┌─────────┬──────────┐                │
│  │ 💾 Salvar│ ✕ Cancelar│                │
│  └─────────┴──────────┘                │
└─────────────────────────────────────────┘
```

## Critérios de aceitação
1. ✅ O ícone de edição (lápis azul) aparece em cada item da lista de autores
2. ✅ Tocar no ícone de lápis abre o formulário de edição pré-preenchido
3. ✅ O formulário permite editar todos os campos editáveis (name, email, avatarUrl, bio, topics, rating, isActive)
4. ✅ O formulário exibe campos read-only: id, quizzesCount, createdAt
5. ✅ Validações funcionam corretamente (name obrigatório, email formato válido, avatarUrl formato URL)
6. ✅ Slider de rating funciona com incrementos de 0.5 (0.0 - 5.0)
7. ✅ Switch de isActive atualiza badge visual (ATIVO/INATIVO)
8. ✅ Ao salvar, os dados são persistidos via DAO com `try/catch`
9. ✅ Usuário vê `SnackBar` de sucesso ("Autor atualizado com sucesso") ou erro
10. ✅ Após salvar com sucesso, a lista é recarregada automaticamente
11. ✅ O diálogo não pode ser fechado ao tocar fora (apenas pelos botões)
12. ✅ O método `_handleEdit` não exibe mais o SnackBar placeholder
13. ✅ O código não altera funcionalidades de remoção (isso é responsabilidade de outro prompt)

## Observações
- **Foco principal**: Edição completa do perfil do autor
- **Campos complexos**: 
  - `topics`: Aceitar string separada por vírgula, converter para List<String> ao salvar
  - `rating`: Usar Slider com divisões para facilitar seleção
  - `isActive`: Switch com feedback visual imediato
- **Email não mascarado**: Diferente do diálogo de visualização, aqui o email completo deve ser editável
- **Avatar preview**: Considerar adicionar preview da imagem se avatarUrl for válida (opcional, não obrigatório)
- **Validação de URL**: Regex simples para validar http:// ou https://
- Manter consistência com os diálogos já implementados (questions, answers, attempts)
- Reutilizar o padrão de cores e espaçamentos estabelecido no projeto
