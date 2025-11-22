# Prompt: QuizCraft – Supabase + Flutter para Quizzes (Guia Completo Parametrizado)

## Parâmetros (defina no topo antes de executar)
- FEATURE_NAME: quizzes
- ENTITY: Quiz
- ENTITY_PLURAL: quizzes
- DTO_CLASS: QuizDto
- REPOSITORY_CLASS: QuizRepository
- LOCAL_CACHE_CLASS: QuizzesLocalCache
- SYNC_SERVICE_CLASS: QuizSyncService
- ENV_KEYS: [SUPABASE_URL, SUPABASE_ANON_KEY]
- TABLE_NAME: quizzes

---

## Contexto
Você é um agente especializado na geração de estruturas de software completas para o **QuizCraft**, seguindo arquitetura offline-first com Supabase.  
Seu objetivo é produzir **arquitetura, código, contratos, sincronização, cache offline**, configuração de ambiente, SQL e páginas Flutter para a entidade **Quizzes**.

O prompt abaixo foi desenhado para permitir gerar:
- SQL da tabela quizzes + RLS + índice.
- Setup do Supabase no Flutter com dotenv.
- Modelos (Entity, DTO, Mapper) para quizzes.
- Repository com cache e sync incremental.
- Serviço de sincronização incremental.
- Página de quizzes offline-first.
- README de setup completo.
- Arquivo `.env.example`.

---

## Objetivo
Gerar (conforme modo solicitado na invocação) um dos seguintes artefatos:

1. **SQL completo**: tabela quizzes, índice, RLS e policy.  
2. **Setup Flutter Supabase** (main.dart completo, dotenv, validação, warnings).  
3. **Models e camadas de dados**: QuizEntity, QuizDto, QuizMapper.  
4. **Repository offline-first**: cache local + sync incremental por updated_at.  
5. **Serviço de sincronização incremental** com fluxo completo.  
6. **Quizzes Page** renderizando cache + atualização silenciosa.  
7. **README.md completo** com boas práticas.  
8. **Arquivos de ambiente** `.env.example` e orientações CI/CD.  

Cada saída deve ser completa, funcional e sem omissões.

---

## Estrutura da Tabela Quizzes

### Campos da tabela `quizzes`
- `id` (uuid, PRIMARY KEY, DEFAULT gen_random_uuid())
- `title` (text, NOT NULL) - título do quiz
- `description` (text) - descrição detalhada (opcional)
- `author_id` (uuid, FOREIGN KEY → authors.id) - autor do quiz (opcional)
- `topics` (text[], DEFAULT '{}') - tópicos/tags do quiz
- `difficulty` (text) - valores: 'easy', 'medium', 'hard' (opcional)
- `estimated_duration_minutes` (integer) - duração estimada em minutos
- `is_published` (boolean, NOT NULL, DEFAULT false) - se está publicado/visível
- `questions_count` (integer, NOT NULL, DEFAULT 0) - contador de questões
- `attempts_count` (integer, NOT NULL, DEFAULT 0) - contador de tentativas
- `avg_score_percentage` (numeric(5,2)) - média de score das tentativas
- `thumbnail_url` (text) - URL da imagem de capa
- `created_at` (timestamptz, DEFAULT now())
- `updated_at` (timestamptz, DEFAULT now())

### Relacionamentos
- Pertence a um author (author_id → authors.id, opcional/nullable)
- Possui múltiplas questions (1:N)
- Possui múltiplas attempts (1:N)

### Índices necessários
- `quizzes_author_id_idx` em author_id (para queries por autor)
- `quizzes_updated_at_idx` em updated_at (para sync incremental)
- `quizzes_is_published_idx` em is_published (para filtrar publicados)
- `quizzes_difficulty_idx` em difficulty (para filtrar por dificuldade)
- `quizzes_created_at_idx` em created_at DESC (para ordenação temporal)
- Índice GIN em topics (para busca em array): `CREATE INDEX quizzes_topics_idx ON quizzes USING GIN (topics);`

### Constraints
- `quizzes_questions_count_check` CHECK (questions_count >= 0)
- `quizzes_attempts_count_check` CHECK (attempts_count >= 0)
- `quizzes_avg_score_check` CHECK (avg_score_percentage IS NULL OR (avg_score_percentage >= 0 AND avg_score_percentage <= 100))
- `quizzes_difficulty_check` CHECK (difficulty IS NULL OR difficulty IN ('easy', 'medium', 'hard'))
- `quizzes_duration_check` CHECK (estimated_duration_minutes IS NULL OR estimated_duration_minutes > 0)

### Triggers
- `update_updated_at_column` - atualizar updated_at automaticamente
- `sync_questions_count` - incrementar/decrementar quando question criada/deletada
- `sync_attempts_count` - incrementar quando attempt criada
- `update_avg_score` - recalcular avg_score_percentage quando attempt completado
- `increment_author_quizzes_count` - incrementar authors.quizzes_count ao criar quiz
- `decrement_author_quizzes_count` - decrementar authors.quizzes_count ao deletar quiz

---

## Entradas Esperadas (inputs)
- mode: `"sql" | "setup_flutter" | "entity" | "repository" | "sync" | "page" | "readme" | "env"`  
- Opcionalmente:
  - lastSync (DateTime)
  - shouldIncludeMapper (boolean)
  - offlineCacheEngine: `"shared_preferences" | "isar" | "sqflite" | "drift"`
  - authorId (String) - para filtrar quizzes por autor específico
  - isPublished (bool) - para filtrar por status de publicação
  - topics (List<String>) - para filtrar por tópicos
  - difficulty (String) - para filtrar por dificuldade

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
- Quizzes publicados são visíveis para todos (is_published = true).
- Quizzes não publicados só visíveis para o autor.

---

## Regras de Negócio Específicas

### Publicação de Quiz
- Quiz só pode ser publicado se tiver pelo menos 1 questão (questions_count > 0)
- Quiz não publicado (is_published = false) é visível apenas para o autor
- Quiz publicado (is_published = true) é visível para todos

### Contadores Automáticos
- `questions_count`: sincronizado via trigger quando questions são criadas/deletadas
- `attempts_count`: incrementado via trigger quando attempt é criada
- `avg_score_percentage`: recalculado via trigger quando attempt é completado

### Relacionamento com Author
- author_id é opcional (nullable) - permite quizzes sem autor
- Se author_id presente, incrementa/decrementa authors.quizzes_count via trigger
- Ao deletar author, pode-se fazer ON DELETE SET NULL ou CASCADE (definir política)

### Topics (Tags)
- Array de strings para categorização
- Busca usando operador `@>` (contains): `WHERE topics @> ARRAY['math']`
- Suporte a busca por múltiplos tópicos: `WHERE topics && ARRAY['math', 'science']` (overlap)

### Dificuldade
- Valores permitidos: 'easy', 'medium', 'hard'
- NULL = dificuldade não definida
- Badge visual na UI com cores distintas

---

## Escopo de Geração de Artefatos

### 1. **SQL (modo: sql)**
Gerar:
- Tabela quizzes completa.
- Foreign key para authors com ON DELETE SET NULL (ou CASCADE conforme política).
- Índices: author_id, updated_at, is_published, difficulty, created_at DESC, GIN em topics.
- Constraints para validação de questions_count, attempts_count, avg_score, difficulty, duration.
- Trigger para atualizar updated_at automaticamente.
- Trigger para sincronizar questions_count:
```sql
CREATE OR REPLACE FUNCTION sync_questions_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE quizzes SET questions_count = questions_count + 1 WHERE id = NEW.quiz_id;
    ELSIF TG_OP = 'DELETE' THEN
        UPDATE quizzes SET questions_count = questions_count - 1 WHERE id = OLD.quiz_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_questions_count_trigger
    AFTER INSERT OR DELETE ON questions
    FOR EACH ROW
    EXECUTE FUNCTION sync_questions_count();
```

- Trigger para sincronizar attempts_count:
```sql
CREATE OR REPLACE FUNCTION sync_attempts_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        UPDATE quizzes SET attempts_count = attempts_count + 1 WHERE id = NEW.quiz_id;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_attempts_count_trigger
    AFTER INSERT ON attempts
    FOR EACH ROW
    EXECUTE FUNCTION sync_attempts_count();
```

- Trigger para recalcular avg_score_percentage:
```sql
CREATE OR REPLACE FUNCTION update_avg_score()
RETURNS TRIGGER AS $$
BEGIN
    UPDATE quizzes 
    SET avg_score_percentage = (
        SELECT ROUND(AVG(percentage), 2)
        FROM attempts
        WHERE quiz_id = NEW.quiz_id
          AND status = 'completed'
    )
    WHERE id = NEW.quiz_id;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_avg_score_trigger
    AFTER INSERT OR UPDATE OF status, percentage ON attempts
    FOR EACH ROW
    WHEN (NEW.status = 'completed')
    EXECUTE FUNCTION update_avg_score();
```

- Trigger para sincronizar authors.quizzes_count:
```sql
CREATE OR REPLACE FUNCTION sync_author_quizzes_count()
RETURNS TRIGGER AS $$
BEGIN
    IF TG_OP = 'INSERT' AND NEW.author_id IS NOT NULL THEN
        UPDATE authors SET quizzes_count = quizzes_count + 1 WHERE id = NEW.author_id;
    ELSIF TG_OP = 'DELETE' AND OLD.author_id IS NOT NULL THEN
        UPDATE authors SET quizzes_count = quizzes_count - 1 WHERE id = OLD.author_id;
    ELSIF TG_OP = 'UPDATE' AND OLD.author_id IS DISTINCT FROM NEW.author_id THEN
        IF OLD.author_id IS NOT NULL THEN
            UPDATE authors SET quizzes_count = quizzes_count - 1 WHERE id = OLD.author_id;
        END IF;
        IF NEW.author_id IS NOT NULL THEN
            UPDATE authors SET quizzes_count = quizzes_count + 1 WHERE id = NEW.author_id;
        END IF;
    END IF;
    RETURN NULL;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER sync_author_quizzes_count_trigger
    AFTER INSERT OR UPDATE OR DELETE ON quizzes
    FOR EACH ROW
    EXECUTE FUNCTION sync_author_quizzes_count();
```

- Ativar RLS.
- Criar policies:
```sql
-- Todos podem ver quizzes publicados
CREATE POLICY "Published quizzes are viewable by everyone"
  ON quizzes FOR SELECT
  USING (is_published = true);

-- Autores podem ver seus próprios quizzes (publicados ou não)
CREATE POLICY "Authors can view own quizzes"
  ON quizzes FOR SELECT
  USING (author_id::text = current_setting('app.user_id', true));

-- Autores podem criar quizzes
CREATE POLICY "Authors can create quizzes"
  ON quizzes FOR INSERT
  WITH CHECK (author_id::text = current_setting('app.user_id', true));

-- Autores podem atualizar próprios quizzes
CREATE POLICY "Authors can update own quizzes"
  ON quizzes FOR UPDATE
  USING (author_id::text = current_setting('app.user_id', true));

-- Autores podem deletar próprios quizzes
CREATE POLICY "Authors can delete own quizzes"
  ON quizzes FOR DELETE
  USING (author_id::text = current_setting('app.user_id', true));
```

- Comentários explicando relacionamentos, triggers, constraints e policies.

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
- `QuizEntity` em `lib/features/quizzes/domain/entities/quiz_entity.dart`
  - Campos: id, title, description, authorId, topics, difficulty, estimatedDurationMinutes, isPublished, questionsCount, attemptsCount, avgScorePercentage, thumbnailUrl, createdAt, updatedAt
  - Método toMap() e fromMap()
  - Getters computados: canBePublished (questionsCount > 0), difficultyLabel, formattedDuration
- `QuizDto` em `lib/features/quizzes/infrastructure/dtos/quiz_dto.dart`
  - Mesmos campos com snake_case para Supabase
  - toMap() e fromMap()
  - Conversão de topics (text[] vs List<String>)
- `QuizMapper` em `lib/features/quizzes/infrastructure/mappers/quiz_mapper.dart`
  - toEntity(QuizDto) → QuizEntity
  - toDto(QuizEntity) → QuizDto
- Comentários sobre conversão de nomes e tipos (text[] vs List<String>)

---

### 4. **Repository Offline-First (modo: repository)**
Gerar:
- `QuizRepository` em `lib/features/quizzes/infrastructure/repositories/quiz_repository.dart`
- Métodos:
  - `Future<List<QuizEntity>> fetchQuizzes({DateTime? lastSync, bool? isPublished})`
  - `Future<List<QuizEntity>> fetchQuizzesByAuthor(String authorId, {DateTime? lastSync})`
  - `Future<List<QuizEntity>> fetchQuizzesByTopics(List<String> topics, {DateTime? lastSync})`
  - `Future<List<QuizEntity>> fetchQuizzesByDifficulty(String difficulty, {DateTime? lastSync})`
  - `Future<QuizEntity?> fetchQuizById(String quizId)`
  - `Future<List<QuizEntity>> getLocalCache({bool? isPublished})`
  - `Future<void> saveLocalCache(List<QuizEntity> quizzes)`
  - `Future<List<QuizEntity>> syncIncremental({bool? isPublished})`
  - `Future<QuizEntity> createQuiz(QuizEntity quiz)`
  - `Future<void> updateQuiz(QuizEntity quiz)`
  - `Future<void> deleteQuiz(String quizId)`
  - `Future<void> publishQuiz(String quizId)` - marca is_published = true
  - `Future<void> unpublishQuiz(String quizId)` - marca is_published = false
  - `Future<List<QuizEntity>> searchQuizzes(String query)` - busca por title/description
- Regras:
  - Não bloquear UI.
  - Sincronização incremental por updated_at.
  - Persistência local usando SharedPreferences ou cache escolhido.
  - Filtros: por author_id, topics (usando @> ou &&), difficulty, is_published.
  - Ordenação padrão: created_at DESC (mais recente primeiro).
  - Validação: quiz só pode ser publicado se questionsCount > 0.
  - Busca: case-insensitive em title e description.
  - Aviso sobre paginação futura se necessário.

---

### 5. **Sync Service (modo: sync)**
Gerar:
- `QuizSyncService` em `lib/features/quizzes/services/quiz_sync_service.dart`
- Fluxo:
  1. Ler lastSync para o contexto específico.
  2. Buscar quizzes atualizados no Supabase (WHERE updated_at >= ? AND is_published = ? se filtrado).
  3. Buscar dados de authors relacionados (JOIN ou query separada).
  4. Mesclar com cache local.
  5. Atualizar lastSync.
  6. Salvar no cache.
  7. Retornar lista final ordenada.
- Garantir que UI receba resultados sem lag.
- Métodos:
  - `Future<List<QuizEntity>> syncAllQuizzes()`
  - `Future<List<QuizEntity>> syncPublishedQuizzes()`
  - `Future<List<QuizEntity>> syncQuizzesByAuthor(String authorId)`
  - `Future<QuizEntity> syncQuizById(String quizId)`

---

### 6. **Quizzes Page (modo: page)**
Gerar:
- `QuizzesPage` completa em `lib/features/quizzes/presentation/quizzes_page.dart`
- Carrega cache local primeiro (apenas publicados por padrão).
- Renderização imediata dos quizzes.
- Atualização silenciosa em background.
- Indicador discreto de atualização (CircularProgressIndicator no AppBar).
- Sem travar UI.
- Sem refresh manual obrigatório.
- Cards de quiz exibindo:
  - Título
  - Descrição (truncada)
  - Author name (authorId → buscar nome do autor)
  - Topics como chips/badges
  - Difficulty badge com cores (easy - verde, medium - amarelo, hard - vermelho)
  - Questions count: "X questões"
  - Estimated duration: "~X min"
  - Attempts count e avg score: "Y tentativas • Média: Z%"
  - Thumbnail se disponível
  - Status badge: PUBLICADO (verde) / RASCUNHO (cinza)
- Tap no card: navega para QuizDetailsPage ou inicia quiz.
- FloatingActionButton: "Criar Quiz" (se usuário é autor).
- Filtros no AppBar:
  - Por dificuldade (chips: easy, medium, hard, all)
  - Por tópico (dropdown multi-select)
  - Toggle: "Meus Quizzes" (filtra por author_id)
- Busca: TextField no AppBar para buscar por title/description.
- Ordenação: dropdown (mais recente, mais popular, melhor avaliado).
- Widget para estatísticas gerais: total de quizzes, média geral de score.

---

### 7. **README (modo: readme)**
Gerar:
- Instalação completa do Supabase
- Setup Flutter para quizzes
- Como rodar com `.env`
- Como rodar com `--dart-define`
- Segurança e RLS (policies detalhadas)
- Estrutura de pastas para quizzes
- Fluxo de sync incremental
- Relacionamentos: quizzes → authors, quizzes → questions, quizzes → attempts
- Regras de negócio: publicação, contadores automáticos, dificuldade
- Triggers automáticos (questions_count, attempts_count, avg_score, author sync)
- Busca por topics (operadores @> e &&)
- Checklist final:
  - [ ] Tabela quizzes criada
  - [ ] RLS ativado com policies (public read para publicados, author CRUD para próprios)
  - [ ] Índices criados (incluindo GIN para topics)
  - [ ] Constraints validados
  - [ ] Triggers configurados (5 triggers)
  - [ ] Repository implementado
  - [ ] Sync service implementado
  - [ ] QuizzesPage funcionando offline
  - [ ] Filtros e busca funcionando
  - [ ] Relacionamento com authors sincronizado
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
    quizzes/
      domain/
        entities/
          quiz_entity.dart
      infrastructure/
        dtos/
          quiz_dto.dart
        mappers/
          quiz_mapper.dart
        repositories/
          quiz_repository.dart
        local/
          quizzes_local_dao_shared_prefs.dart
      presentation/
        quizzes_page.dart
        quiz_details_page.dart
        widgets/
          quiz_list_item.dart
          quiz_statistics_card.dart
        dialogs/
          quiz_form_dialog.dart
      services/
        quiz_sync_service.dart
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
9. Contadores sincronizados via triggers (questions_count, attempts_count, avg_score).
10. Foreign key para authors respeitada (ON DELETE SET NULL ou CASCADE).
11. RLS com policies adequadas (public read para publicados, author CRUD).
12. Busca por topics usando operadores PostgreSQL array (@>, &&).
13. Validação de publicação (questionsCount > 0).
14. Filtros e ordenação implementados.

---

## Exemplo de Query Incremental

```sql
-- Todos os quizzes publicados atualizados
SELECT * FROM quizzes 
WHERE is_published = true
  AND updated_at >= $1
ORDER BY created_at DESC;

-- Quizzes de um autor específico
SELECT * FROM quizzes 
WHERE author_id = $1 
  AND updated_at >= $2
ORDER BY created_at DESC;

-- Quizzes por tópicos (overlap)
SELECT * FROM quizzes 
WHERE topics && ARRAY[$1, $2]
  AND is_published = true
  AND updated_at >= $3
ORDER BY created_at DESC;

-- Quizzes por dificuldade
SELECT * FROM quizzes 
WHERE difficulty = $1
  AND is_published = true
  AND updated_at >= $2
ORDER BY created_at DESC;
```

---

## Exemplo de Query para Busca

```sql
-- Busca case-insensitive em title e description
SELECT * FROM quizzes 
WHERE (
    LOWER(title) LIKE LOWER($1)
    OR LOWER(description) LIKE LOWER($1)
  )
  AND is_published = true
ORDER BY created_at DESC;
```

---

## Exemplo de Query com Author Name (JOIN)

```sql
SELECT 
  q.*,
  a.name as author_name,
  a.email as author_email
FROM quizzes q
LEFT JOIN authors a ON q.author_id = a.id
WHERE q.is_published = true
  AND q.updated_at >= $1
ORDER BY q.created_at DESC;
```

---

## Observações Importantes
- O agente deve assumir que este prompt controla todo o fluxo de Quizzes no QuizCraft.
- Manter consistência entre backend (Supabase) e frontend (Flutter).
- Todos os trechos gerados devem ser prontos para copiar/colar.
- Quizzes é a entidade central: relaciona authors, questions, attempts.
- author_id é opcional (nullable) - permite quizzes anônimos.
- ON DELETE para author: usar SET NULL (quiz continua existindo) ou CASCADE (definir política).
- ON DELETE para quiz: CASCADE para questions e attempts (remover tudo).
- Cache local deve incluir author name (desnormalizar ou query separada).
- Sync incremental deve trazer author data junto (JOIN ou fetch separado).
- Triggers mantêm contadores sincronizados - não atualizar manualmente.
- topics (text[]): usar operador `@>` (contains) ou `&&` (overlap) para busca.
- Índice GIN em topics é crucial para performance de busca.
- RLS: quizzes publicados são públicos, não publicados só para autor.
- Validação de publicação: questionsCount > 0 (frontend e backend).
- avg_score_percentage: calculado automaticamente via trigger, não atualizar manualmente.
- Filtros e busca: essenciais para UX (descobrir quizzes relevantes).
- Ordenação: por data (padrão), por popularidade (attempts_count), por qualidade (avg_score).
- Thumbnail: URL externa ou Supabase Storage (considerar implementação futura).
- Difficulty: usar enum no Dart ('easy', 'medium', 'hard') com validação.
- estimated_duration_minutes: calculado com base no número de questões ou definido pelo autor.
