# Prompt: QuizCraft – Supabase + Flutter para Questions (Guia Completo Parametrizado)

## Parâmetros (defina no topo antes de executar)
- FEATURE_NAME: questions
- ENTITY: Question
- ENTITY_PLURAL: questions
- DTO_CLASS: QuestionDto
- REPOSITORY_CLASS: QuestionRepository
- LOCAL_CACHE_CLASS: QuestionsLocalCache
- SYNC_SERVICE_CLASS: QuestionSyncService
- ENV_KEYS: [SUPABASE_URL, SUPABASE_ANON_KEY]
- TABLE_NAME: questions

---

## Contexto
Você é um agente especializado na geração de estruturas de software completas para o **QuizCraft**, seguindo arquitetura offline-first com Supabase.  
Seu objetivo é produzir **arquitetura, código, contratos, sincronização, cache offline**, configuração de ambiente, SQL e páginas Flutter para a entidade **Questions**.

O prompt abaixo foi desenhado para permitir gerar:
- SQL da tabela questions + RLS + índice.
- Setup do Supabase no Flutter com dotenv.
- Modelos (Entity, DTO, Mapper) para questions.
- Repository com cache e sync incremental.
- Serviço de sincronização incremental.
- Página de questions offline-first.
- README de setup completo.
- Arquivo `.env.example`.

---

## Objetivo
Gerar (conforme modo solicitado na invocação) um dos seguintes artefatos:

1. **SQL completo**: tabela questions, índice, RLS e policy.  
2. **Setup Flutter Supabase** (main.dart completo, dotenv, validação, warnings).  
3. **Models e camadas de dados**: QuestionEntity, QuestionDto, QuestionMapper.  
4. **Repository offline-first**: cache local + sync incremental por updated_at.  
5. **Serviço de sincronização incremental** com fluxo completo.  
6. **Questions Page** renderizando cache + atualização silenciosa.  
7. **README.md completo** com boas práticas.  
8. **Arquivos de ambiente** `.env.example` e orientações CI/CD.  

Cada saída deve ser completa, funcional e sem omissões.

---

## Estrutura da Tabela Questions

### Campos da tabela `questions`
- `id` (uuid, PRIMARY KEY)
- `quiz_id` (uuid, FOREIGN KEY → quizzes.id, NOT NULL)
- `order` (integer, NOT NULL) - ordem da questão no quiz
- `text` (text, NOT NULL) - texto da pergunta
- `created_at` (timestamptz, DEFAULT now())
- `updated_at` (timestamptz, DEFAULT now())

### Relacionamentos
- Pertence a um quiz (quiz_id → quizzes.id)
- Possui múltiplas respostas (answers.question_id → questions.id)

### Índices necessários
- `questions_quiz_id_idx` em quiz_id (para queries por quiz)
- `questions_updated_at_idx` em updated_at (para sync incremental)
- `questions_quiz_id_order_idx` em (quiz_id, order) (para ordenação)

---

## Entradas Esperadas (inputs)
- mode: `"sql" | "setup_flutter" | "entity" | "repository" | "sync" | "page" | "readme" | "env"`  
- Opcionalmente:
  - lastSync (DateTime)
  - shouldIncludeMapper (boolean)
  - offlineCacheEngine: `"shared_preferences" | "isar" | "sqflite" | "drift"`
  - quizId (String) - para filtrar questions por quiz específico

---

## Regras Gerais
- Sempre seguir arquitetura offline-first.
- Nunca alterar nomes de campos da tabela.
- Nunca usar service role key no app Flutter.
- Sempre documentar RLS e políticas.
- Todo código deve ser completo, sem trechos omitidos.
- Sempre usar **updated_at >= lastSync** para sync incremental.
- Entity ≠ DTO (cada um em sua camada).
- Mapper obrigatório entre ambos.
- Repository deve orquestrar Supabase + cache local.
- Página deve exibir primeiro cache, depois sync silencioso.
- Usar FutureBuilder apenas na primeira carga; sync posterior deve atualizar a UI sem travar.
- README deve incluir instruções CI/CD e `--dart-define`.

---

## Regras de Segurança
- Nunca expor chaves reais.
- `.env` e `.env.production` devem estar no `.gitignore`.
- Warn se faltarem variáveis.
- Explicar por que **service role** não pode ser usada no app.
- Destacar RLS como proteção principal.
- Questions devem respeitar permissões do quiz pai.

---

## Escopo de Geração de Artefatos

### 1. **SQL (modo: sql)**
Gerar:
- Tabela questions completa.
- Foreign key para quizzes.
- Índices: updated_at, quiz_id, (quiz_id, order).
- Trigger para atualizar updated_at automaticamente.
- Ativar RLS.
- Criar policy de leitura (verificar acesso ao quiz).
- Comentários explicando relacionamentos e índices.

Exemplo de policy:
```sql
CREATE POLICY "Questions are viewable by everyone"
  ON questions FOR SELECT
  USING (true);
```

---

### 2. **Setup Flutter (modo: setup_flutter)**
Gerar:
- `main.dart` completo.
- Carregamento dotenv.
- Validação de variáveis SUPABASE_URL e SUPABASE_ANON_KEY.
- Supabase.initialize.
- Comentários explicativos.
- Aviso sobre ambientes dev/staging/prod.
- Suporte a `ENV_FILE` via `--dart-define`.

---

### 3. **Entity / DTO / Mapper (modo: entity)**
Gerar:
- `QuestionEntity` em `lib/features/questions/domain/entities/question_entity.dart`
  - Campos: id, quizId, order, text, createdAt, updatedAt
  - Método toMap() e fromMap()
- `QuestionDto` em `lib/features/questions/infrastructure/dtos/question_dto.dart`
  - Mesmos campos com snake_case para Supabase
  - toMap() e fromMap()
- `QuestionMapper` em `lib/features/questions/infrastructure/mappers/question_mapper.dart`
  - toEntity(QuestionDto) → QuestionEntity
  - toDto(QuestionEntity) → QuestionDto
- Comentários sobre conversão de nomes (order vs order, quiz_id vs quizId)

---

### 4. **Repository Offline-First (modo: repository)**
Gerar:
- `QuestionRepository` em `lib/features/questions/infrastructure/repositories/question_repository.dart`
- Métodos:
  - `Future<List<QuestionEntity>> fetchQuestionsByQuiz(String quizId, {DateTime? lastSync})`
  - `Future<List<QuestionEntity>> getLocalCache(String quizId)`
  - `Future<void> saveLocalCache(List<QuestionEntity> questions)`
  - `Future<List<QuestionEntity>> syncIncremental(String quizId)`
- Regras:
  - Não bloquear UI.
  - Sincronização incremental por updated_at.
  - Persistência local usando SharedPreferences ou cache escolhido.
  - Filtrar por quiz_id.
  - Ordenar por order ASC.
  - Aviso sobre paginação futura se necessário.

---

### 5. **Sync Service (modo: sync)**
Gerar:
- `QuestionSyncService` em `lib/features/questions/services/question_sync_service.dart`
- Fluxo:
  1. Ler lastSync para o quiz específico.
  2. Buscar questions atualizadas no Supabase (WHERE quiz_id = ? AND updated_at >= ?).
  3. Mesclar com cache local.
  4. Ordenar por order.
  5. Atualizar lastSync.
  6. Salvar no cache.
  7. Retornar lista final.
- Garantir que UI receba resultados sem lag.
- Método: `Future<List<QuestionEntity>> syncQuestions(String quizId)`

---

### 6. **Questions Page (modo: page)**
Gerar:
- `QuestionsPage` completa em `lib/features/questions/presentation/questions_page.dart`
- Recebe quizId como parâmetro.
- Carrega cache local primeiro.
- Renderização imediata das questions ordenadas.
- Atualização silenciosa em background.
- Indicador discreto de atualização (CircularProgressIndicator no AppBar).
- Sem travar UI.
- Sem refresh manual obrigatório.
- Exibir ordem, texto da questão.
- Botão para adicionar nova questão (abre diálogo).
- Cards expansíveis mostrando respostas (se disponível).
- FloatingActionButton para criar nova question.

---

### 7. **README (modo: readme)**
Gerar:
- Instalação completa do Supabase
- Setup Flutter para questions
- Como rodar com `.env`
- Como rodar com `--dart-define`
- Segurança e RLS
- Estrutura de pastas para questions
- Fluxo de sync incremental
- Relacionamento questions → quizzes
- Checklist final:
  - [ ] Tabela questions criada
  - [ ] RLS ativado
  - [ ] Índices criados
  - [ ] Repository implementado
  - [ ] Sync service implementado
  - [ ] QuestionsPage funcionando offline
  - [ ] .env configurado

---

### 8. **Arquivos .env (modo: env)**
Gerar:
- `.env.example`
```env
SUPABASE_URL=https://<your-project>.supabase.co
SUPABASE_ANON_KEY=<your-anon-key-here>
```
- `.env.production` (placeholder)
- Instruções CI/CD
- Instruções para assets no Flutter
- Como definir via --dart-define em CI:
```bash
flutter build apk --dart-define=ENV_FILE=.env.production
```

---

## Estrutura de Arquivos Esperada

```
lib/
  features/
    questions/
      domain/
        entities/
          question_entity.dart
      infrastructure/
        dtos/
          question_dto.dart
        mappers/
          question_mapper.dart
        repositories/
          question_repository.dart
        local/
          questions_local_dao_shared_prefs.dart
      presentation/
        questions_page.dart
        widgets/
          question_list_item.dart
        dialogs/
          question_form_dialog.dart
      services/
        question_sync_service.dart
```

---

## Critérios de Aceitação
1. Saída deve ser completa (sem "…" ou código omitido).
2. Seguir arquitetura offline-first.
3. Linguagem clara, técnica e didática.
4. Estrutura organizada por seções.
5. Código válido e pronto para uso.
6. Integrar todas as peças corretamente.
7. Explicar decisões arquiteturais.
8. Manter consistência com padrões do QuizCraft.
9. Questions ordenadas corretamente por order.
10. Foreign key para quizzes respeitada.

---

## Exemplo de Query Incremental

```sql
SELECT * FROM questions 
WHERE quiz_id = $1 
  AND updated_at >= $2
ORDER BY "order" ASC;
```

---

## Observações Importantes
- O agente deve assumir que este prompt controla todo o fluxo de Questions no QuizCraft.
- Manter consistência entre backend (Supabase) e frontend (Flutter).
- Todos os trechos gerados devem ser prontos para copiar/colar.
- Questions dependem de Quizzes - verificar relacionamento.
- Order é palavra reservada SQL - sempre usar "order" entre aspas ou order como alias.
- Cache local deve ser específico por quiz_id.
- Sync incremental deve filtrar por quiz_id E updated_at.
