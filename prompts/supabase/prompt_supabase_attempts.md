# Prompt: QuizCraft – Supabase + Flutter para Attempts (Guia Completo Parametrizado)

## Parâmetros (defina no topo antes de executar)
- FEATURE_NAME: attempts
- ENTITY: Attempt
- ENTITY_PLURAL: attempts
- DTO_CLASS: AttemptDto
- REPOSITORY_CLASS: AttemptRepository
- LOCAL_CACHE_CLASS: AttemptsLocalCache
- SYNC_SERVICE_CLASS: AttemptSyncService
- ENV_KEYS: [SUPABASE_URL, SUPABASE_ANON_KEY]
- TABLE_NAME: attempts

---

## Contexto
Você é um agente especializado na geração de estruturas de software completas para o **QuizCraft**, seguindo arquitetura offline-first com Supabase.  
Seu objetivo é produzir **arquitetura, código, contratos, sincronização, cache offline**, configuração de ambiente, SQL e páginas Flutter para a entidade **Attempts**.

O prompt abaixo foi desenhado para permitir gerar:
- SQL da tabela attempts + RLS + índice.
- Setup do Supabase no Flutter com dotenv.
- Modelos (Entity, DTO, Mapper) para attempts.
- Repository com cache e sync incremental.
- Serviço de sincronização incremental.
- Página de attempts offline-first.
- README de setup completo.
- Arquivo `.env.example`.

---

## Objetivo
Gerar (conforme modo solicitado na invocação) um dos seguintes artefatos:

1. **SQL completo**: tabela attempts, índice, RLS e policy.  
2. **Setup Flutter Supabase** (main.dart completo, dotenv, validação, warnings).  
3. **Models e camadas de dados**: AttemptEntity, AttemptDto, AttemptMapper.  
4. **Repository offline-first**: cache local + sync incremental por updated_at.  
5. **Serviço de sincronização incremental** com fluxo completo.  
6. **Attempts Page** renderizando cache + atualização silenciosa.  
7. **README.md completo** com boas práticas.  
8. **Arquivos de ambiente** `.env.example` e orientações CI/CD.  

Cada saída deve ser completa, funcional e sem omissões.

---

## Estrutura da Tabela Attempts

### Campos da tabela `attempts`
- `id` (uuid, PRIMARY KEY, DEFAULT gen_random_uuid())
- `quiz_id` (uuid, FOREIGN KEY → quizzes.id, NOT NULL)
- `user_id` (text) - identificador do usuário (pode ser device_id ou auth_id)
- `score` (integer, NOT NULL, DEFAULT 0) - pontuação obtida
- `max_score` (integer, NOT NULL) - pontuação máxima possível
- `percentage` (numeric(5,2)) - percentual de acerto (score/max_score * 100)
- `started_at` (timestamptz, NOT NULL) - quando o quiz foi iniciado
- `finished_at` (timestamptz) - quando o quiz foi finalizado (NULL se em andamento)
- `duration_seconds` (integer) - duração em segundos (finished_at - started_at)
- `status` (text, NOT NULL, DEFAULT 'in_progress') - valores: 'in_progress', 'completed', 'abandoned'
- `answers_data` (jsonb) - armazena respostas do usuário { "question_id": "answer_id" }
- `created_at` (timestamptz, DEFAULT now())
- `updated_at` (timestamptz, DEFAULT now())

### Relacionamentos
- Pertence a um quiz (quiz_id → quizzes.id)
- Quiz possui múltiplas attempts (1:N)
- User pode ter múltiplas attempts (identificado por user_id)

### Índices necessários
- `attempts_quiz_id_idx` em quiz_id (para queries por quiz)
- `attempts_user_id_idx` em user_id (para histórico do usuário)
- `attempts_updated_at_idx` em updated_at (para sync incremental)
- `attempts_status_idx` em status (para filtrar por status)
- `attempts_started_at_idx` em started_at DESC (para ordenação temporal)
- Índice composto: `(user_id, quiz_id, started_at DESC)` para histórico ordenado

### Constraints
- `attempts_score_check` CHECK (score >= 0 AND score <= max_score)
- `attempts_max_score_check` CHECK (max_score > 0)
- `attempts_percentage_check` CHECK (percentage >= 0 AND percentage <= 100)
- `attempts_duration_check` CHECK (duration_seconds IS NULL OR duration_seconds >= 0)
- `attempts_finished_check` CHECK (
    (status = 'in_progress' AND finished_at IS NULL) OR
    (status IN ('completed', 'abandoned') AND finished_at IS NOT NULL)
  )

### Triggers
- `update_updated_at_column` - atualizar updated_at automaticamente
- `calculate_percentage_on_insert_or_update` - calcular percentage automaticamente
- `calculate_duration_on_finish` - calcular duration_seconds quando finished_at é definido

---

## Entradas Esperadas (inputs)
- mode: `"sql" | "setup_flutter" | "entity" | "repository" | "sync" | "page" | "readme" | "env"`  
- Opcionalmente:
  - lastSync (DateTime)
  - shouldIncludeMapper (boolean)
  - offlineCacheEngine: `"shared_preferences" | "isar" | "sqflite" | "drift"`
  - quizId (String) - para filtrar attempts por quiz específico
  - userId (String) - para filtrar attempts por usuário específico
  - status (String) - para filtrar por status ('in_progress', 'completed', 'abandoned')

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
- Attempts devem respeitar permissões: usuário só vê suas próprias tentativas.
- Policy RLS: `user_id = current_setting('app.user_id')` ou similar para isolar dados.

---

## Regras de Negócio Específicas

### Status do Attempt
- **in_progress**: Quiz iniciado mas não finalizado (finished_at = NULL)
- **completed**: Quiz finalizado normalmente
- **abandoned**: Quiz iniciado mas não finalizado após timeout ou abandono explícito

### Cálculo de Score
- score: soma dos pontos das respostas corretas
- max_score: número total de questões * pontos por questão
- percentage: (score / max_score) * 100 (arredondado para 2 decimais)

### Duração
- duration_seconds: diferença em segundos entre finished_at e started_at
- Calculado automaticamente via trigger quando finished_at é definido

### Armazenamento de Respostas
- answers_data (JSONB): { "question_id": "answer_id", ... }
- Permite queries eficientes: `answers_data->>'question_id' = 'answer_id'`
- Facilita análise de respostas sem JOIN complexo

### Histórico e Estatísticas
- Usuário pode ver todas suas tentativas por quiz
- Ordenação padrão: started_at DESC (mais recente primeiro)
- Filtros: por quiz, por status, por período

---

## Escopo de Geração de Artefatos

### 1. **SQL (modo: sql)**
Gerar:
- Tabela attempts completa.
- Foreign key para quizzes com ON DELETE CASCADE.
- Índices: quiz_id, user_id, updated_at, status, started_at DESC, composto (user_id, quiz_id, started_at).
- Constraints para validação de score, percentage, duration, status/finished_at.
- Trigger para atualizar updated_at automaticamente.
- Trigger para calcular percentage automaticamente:
```sql
CREATE OR REPLACE FUNCTION calculate_percentage()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.max_score > 0 THEN
        NEW.percentage := ROUND((NEW.score::numeric / NEW.max_score::numeric) * 100, 2);
    ELSE
        NEW.percentage := 0;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_percentage_trigger
    BEFORE INSERT OR UPDATE OF score, max_score ON attempts
    FOR EACH ROW
    EXECUTE FUNCTION calculate_percentage();
```

- Trigger para calcular duration_seconds:
```sql
CREATE OR REPLACE FUNCTION calculate_duration()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.finished_at IS NOT NULL AND NEW.started_at IS NOT NULL THEN
        NEW.duration_seconds := EXTRACT(EPOCH FROM (NEW.finished_at - NEW.started_at))::integer;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER calculate_duration_trigger
    BEFORE INSERT OR UPDATE OF finished_at ON attempts
    FOR EACH ROW
    EXECUTE FUNCTION calculate_duration();
```

- Ativar RLS.
- Criar policy de leitura isolando por user_id:
```sql
CREATE POLICY "Users can view own attempts"
  ON attempts FOR SELECT
  USING (user_id = current_setting('app.user_id', true));

CREATE POLICY "Users can insert own attempts"
  ON attempts FOR INSERT
  WITH CHECK (user_id = current_setting('app.user_id', true));

CREATE POLICY "Users can update own attempts"
  ON attempts FOR UPDATE
  USING (user_id = current_setting('app.user_id', true));
```

- Comentários explicando relacionamentos, triggers e constraints.

---

### 2. **Setup Flutter (modo: setup_flutter)**
Gerar:
- `main.dart` completo.
- Carregamento dotenv.
- Validação de variáveis SUPABASE_URL e SUPABASE_ANON_KEY.
- Supabase.initialize.
- Configuração de user_id via `Supabase.instance.client.rpc('set_user_id', params: {'user_id': deviceId})`.
- Comentários explicativos.
- Aviso sobre ambientes dev/staging/prod.
- Suporte a `ENV_FILE` via `--dart-define`.

---

### 3. **Entity / DTO / Mapper (modo: entity)**
Gerar:
- `AttemptEntity` em `lib/features/attempts/domain/entities/attempt_entity.dart`
  - Campos: id, quizId, userId, score, maxScore, percentage, startedAt, finishedAt, durationSeconds, status, answersData, createdAt, updatedAt
  - Método toMap() e fromMap()
  - Getters computados: isInProgress, isCompleted, isAbandoned, durationFormatted
- `AttemptDto` em `lib/features/attempts/infrastructure/dtos/attempt_dto.dart`
  - Mesmos campos com snake_case para Supabase
  - toMap() e fromMap()
  - Conversão de answers_data (JSONB) para Map<String, String>
- `AttemptMapper` em `lib/features/attempts/infrastructure/mappers/attempt_mapper.dart`
  - toEntity(AttemptDto) → AttemptEntity
  - toDto(AttemptEntity) → AttemptDto
- Comentários sobre conversão de nomes e tipos (JSONB vs Map)

---

### 4. **Repository Offline-First (modo: repository)**
Gerar:
- `AttemptRepository` em `lib/features/attempts/infrastructure/repositories/attempt_repository.dart`
- Métodos:
  - `Future<List<AttemptEntity>> fetchAttemptsByQuiz(String quizId, {DateTime? lastSync})`
  - `Future<List<AttemptEntity>> fetchAttemptsByUser(String userId, {DateTime? lastSync})`
  - `Future<List<AttemptEntity>> fetchAttemptsByStatus(String status, {DateTime? lastSync})`
  - `Future<AttemptEntity?> fetchAttemptById(String attemptId)`
  - `Future<List<AttemptEntity>> getLocalCache({String? quizId, String? userId})`
  - `Future<void> saveLocalCache(List<AttemptEntity> attempts)`
  - `Future<List<AttemptEntity>> syncIncremental({String? quizId, String? userId})`
  - `Future<AttemptEntity> createAttempt(String quizId, String userId, int maxScore)`
  - `Future<void> updateScore(String attemptId, int score)`
  - `Future<void> finishAttempt(String attemptId, String status)` - marca como completed/abandoned
  - `Future<void> saveAnswer(String attemptId, String questionId, String answerId)`
  - `Future<Map<String, dynamic>> getStatistics(String userId)` - retorna estatísticas do usuário
- Regras:
  - Não bloquear UI.
  - Sincronização incremental por updated_at.
  - Persistência local usando SharedPreferences ou cache escolhido.
  - Filtros: por quiz_id, user_id, status.
  - Ordenação padrão: started_at DESC.
  - Atualizar percentage e duration automaticamente (trigger no Supabase).
  - Aviso sobre paginação futura se necessário.

---

### 5. **Sync Service (modo: sync)**
Gerar:
- `AttemptSyncService` em `lib/features/attempts/services/attempt_sync_service.dart`
- Fluxo:
  1. Ler lastSync para o contexto específico (quiz ou usuário).
  2. Buscar attempts atualizadas no Supabase (WHERE quiz_id = ? AND updated_at >= ? ou WHERE user_id = ? AND updated_at >= ?).
  3. Mesclar com cache local.
  4. Atualizar lastSync.
  5. Salvar no cache.
  6. Retornar lista final ordenada.
- Garantir que UI receba resultados sem lag.
- Métodos:
  - `Future<List<AttemptEntity>> syncAttemptsByQuiz(String quizId)`
  - `Future<List<AttemptEntity>> syncAttemptsByUser(String userId)`
  - `Future<void> syncInProgress()` - sincroniza apenas attempts in_progress

---

### 6. **Attempts Page (modo: page)**
Gerar:
- `AttemptsPage` completa em `lib/features/attempts/presentation/attempts_page.dart`
- Recebe userId como parâmetro (ou usa device_id).
- Opcionalmente filtra por quizId ou status.
- Carrega cache local primeiro.
- Renderização imediata das attempts.
- Atualização silenciosa em background.
- Indicador discreto de atualização (CircularProgressIndicator no AppBar).
- Sem travar UI.
- Sem refresh manual obrigatório.
- Cards de attempt exibindo:
  - Título do quiz (quiz_id → buscar nome do quiz)
  - Status badge (IN_PROGRESS - amarelo, COMPLETED - verde, ABANDONED - vermelho)
  - Score: "X / Y (Z%)"
  - Duração formatada: "Hh Mm Ss" ou "Em andamento"
  - Data/hora: started_at formatada
  - Botão "Ver Detalhes" (navega para detalhes com respostas)
- FloatingActionButton: não aplicável (attempts são criados ao iniciar quiz).
- Filtros no AppBar: por quiz (dropdown), por status (chips).
- Ordenação: started_at DESC (mais recente primeiro).
- Widget para estatísticas: total de tentativas, média de score, melhor score.

---

### 7. **README (modo: readme)**
Gerar:
- Instalação completa do Supabase
- Setup Flutter para attempts
- Como rodar com `.env`
- Como rodar com `--dart-define`
- Segurança e RLS (isolamento por user_id)
- Estrutura de pastas para attempts
- Fluxo de sync incremental
- Relacionamento attempts → quizzes
- Regras de negócio: status, cálculo de score/percentage/duration
- Armazenamento de respostas em JSONB
- Triggers automáticos
- Checklist final:
  - [ ] Tabela attempts criada
  - [ ] RLS ativado com isolamento por user_id
  - [ ] Índices criados (incluindo composto)
  - [ ] Constraints validados
  - [ ] Triggers configurados (percentage, duration, updated_at)
  - [ ] Repository implementado
  - [ ] Sync service implementado
  - [ ] AttemptsPage funcionando offline
  - [ ] Estatísticas implementadas
  - [ ] Filtros por quiz/status funcionando
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
    attempts/
      domain/
        entities/
          attempt_entity.dart
      infrastructure/
        dtos/
          attempt_dto.dart
        mappers/
          attempt_mapper.dart
        repositories/
          attempt_repository.dart
        local/
          attempts_local_dao_shared_prefs.dart
      presentation/
        attempts_page.dart
        attempt_details_page.dart
        widgets/
          attempt_list_item.dart
          attempt_statistics_card.dart
      services/
        attempt_sync_service.dart
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
9. Cálculos automáticos (percentage, duration) via triggers.
10. Foreign key para quizzes respeitada.
11. Isolamento por user_id (RLS).
12. Suporte a filtros e ordenação.
13. Estatísticas do usuário implementadas.
14. Status transitions validadas.

---

## Exemplo de Query Incremental

```sql
-- Por quiz
SELECT * FROM attempts 
WHERE quiz_id = $1 
  AND updated_at >= $2
ORDER BY started_at DESC;

-- Por usuário
SELECT * FROM attempts 
WHERE user_id = $1 
  AND updated_at >= $2
ORDER BY started_at DESC;

-- Por status
SELECT * FROM attempts 
WHERE user_id = $1 
  AND status = $2
  AND updated_at >= $3
ORDER BY started_at DESC;
```

---

## Exemplo de Query para Estatísticas

```sql
SELECT 
  COUNT(*) as total_attempts,
  COUNT(*) FILTER (WHERE status = 'completed') as completed_attempts,
  ROUND(AVG(percentage), 2) as avg_percentage,
  MAX(percentage) as best_percentage,
  SUM(duration_seconds) as total_time_seconds
FROM attempts
WHERE user_id = $1
  AND status = 'completed';
```

---

## Observações Importantes
- O agente deve assumir que este prompt controla todo o fluxo de Attempts no QuizCraft.
- Manter consistência entre backend (Supabase) e frontend (Flutter).
- Todos os trechos gerados devem ser prontos para copiar/colar.
- Attempts dependem de Quizzes - verificar relacionamento.
- user_id: usar device_id para usuários anônimos, auth_id para usuários autenticados.
- Cache local deve ser específico por user_id.
- Sync incremental deve filtrar por user_id/quiz_id E updated_at.
- ON DELETE CASCADE: remover quiz remove suas attempts automaticamente.
- Triggers calculam percentage e duration - não calcular manualmente no app.
- answers_data (JSONB): facilita queries e análise sem JOINs complexos.
- RLS crítico: usuários só veem próprias tentativas (privacy).
- Status transitions: in_progress → completed/abandoned (não pode voltar).
- Paginação: implementar futuramente se histórico crescer muito.
- Filtros e ordenação: essenciais para UX (ver tentativas recentes, filtrar por quiz).
- Estatísticas: motivação do usuário (progresso, melhoria).
