# Prompt: QuizCraft – Supabase + Flutter para Answers (Guia Completo Parametrizado)

## Parâmetros (defina no topo antes de executar)
- FEATURE_NAME: answers
- ENTITY: Answer
- ENTITY_PLURAL: answers
- DTO_CLASS: AnswerDto
- REPOSITORY_CLASS: AnswerRepository
- LOCAL_CACHE_CLASS: AnswersLocalCache
- SYNC_SERVICE_CLASS: AnswerSyncService
- ENV_KEYS: [SUPABASE_URL, SUPABASE_ANON_KEY]
- TABLE_NAME: answers

---

## Contexto
Você é um agente especializado na geração de estruturas de software completas para o **QuizCraft**, seguindo arquitetura offline-first com Supabase.  
Seu objetivo é produzir **arquitetura, código, contratos, sincronização, cache offline**, configuração de ambiente, SQL e páginas Flutter para a entidade **Answers**.

O prompt abaixo foi desenhado para permitir gerar:
- SQL da tabela answers + RLS + índice.
- Setup do Supabase no Flutter com dotenv.
- Modelos (Entity, DTO, Mapper) para answers.
- Repository com cache e sync incremental.
- Serviço de sincronização incremental.
- Página de answers offline-first.
- README de setup completo.
- Arquivo `.env.example`.

---

## Objetivo
Gerar (conforme modo solicitado na invocação) um dos seguintes artefatos:

1. **SQL completo**: tabela answers, índice, RLS e policy.  
2. **Setup Flutter Supabase** (main.dart completo, dotenv, validação, warnings).  
3. **Models e camadas de dados**: AnswerEntity, AnswerDto, AnswerMapper.  
4. **Repository offline-first**: cache local + sync incremental por updated_at.  
5. **Serviço de sincronização incremental** com fluxo completo.  
6. **Answers Page** renderizando cache + atualização silenciosa.  
7. **README.md completo** com boas práticas.  
8. **Arquivos de ambiente** `.env.example` e orientações CI/CD.  

Cada saída deve ser completa, funcional e sem omissões.

---

## Estrutura da Tabela Answers

### Campos da tabela `answers`
- `id` (uuid, PRIMARY KEY, DEFAULT gen_random_uuid())
- `question_id` (uuid, FOREIGN KEY → questions.id, NOT NULL)
- `text` (text, NOT NULL) - texto da resposta
- `is_correct` (boolean, NOT NULL, DEFAULT false) - indica se é a resposta correta
- `explanation` (text) - explicação sobre por que a resposta está correta/incorreta (opcional)
- `created_at` (timestamptz, DEFAULT now())
- `updated_at` (timestamptz, DEFAULT now())

### Relacionamentos
- Pertence a uma question (question_id → questions.id)
- Question possui múltiplas answers (1:N)

### Índices necessários
- `answers_question_id_idx` em question_id (para queries por question)
- `answers_updated_at_idx` em updated_at (para sync incremental)
- `answers_is_correct_idx` em is_correct (para filtrar respostas corretas)

### Constraints
- `answers_one_correct_per_question` UNIQUE (question_id) WHERE is_correct = true (garante apenas uma resposta correta por questão)
- Ou usar CHECK para garantir que existe pelo menos uma resposta correta por questão (implementado via trigger)

---

## Entradas Esperadas (inputs)
- mode: `"sql" | "setup_flutter" | "entity" | "repository" | "sync" | "page" | "readme" | "env"`  
- Opcionalmente:
  - lastSync (DateTime)
  - shouldIncludeMapper (boolean)
  - offlineCacheEngine: `"shared_preferences" | "isar" | "sqflite" | "drift"`
  - questionId (String) - para filtrar answers por question específica

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
- Answers devem respeitar permissões da question pai.

---

## Regras de Negócio Específicas

### Validação de Respostas Corretas
- Cada question DEVE ter exatamente UMA resposta correta (is_correct = true)
- Implementar constraint ou trigger para garantir essa regra
- Ao marcar uma resposta como correta, desmarcar outras da mesma question

### Ordem de Exibição
- Answers devem ser embaralhadas na UI para evitar padrões
- Mas manter seed consistente para mesmo quiz/tentativa

---

## Escopo de Geração de Artefatos

### 1. **SQL (modo: sql)**
Gerar:
- Tabela answers completa.
- Foreign key para questions com ON DELETE CASCADE.
- Índices: question_id, updated_at, is_correct.
- Constraint para garantir apenas uma resposta correta por question.
- Trigger para atualizar updated_at automaticamente.
- Trigger para validar que existe pelo menos uma resposta correta antes de inserir/atualizar.
- Ativar RLS.
- Criar policy de leitura (verificar acesso à question).
- Comentários explicando relacionamentos e constraints.

Exemplo de constraint:
```sql
-- Garante apenas uma resposta correta por questão
CREATE UNIQUE INDEX answers_one_correct_per_question_idx 
  ON answers (question_id) 
  WHERE is_correct = true;
```

Exemplo de trigger de validação:
```sql
CREATE OR REPLACE FUNCTION validate_correct_answer()
RETURNS TRIGGER AS $$
BEGIN
    IF NEW.is_correct = true THEN
        -- Desmarca outras respostas corretas da mesma question
        UPDATE answers 
        SET is_correct = false 
        WHERE question_id = NEW.question_id 
          AND id != NEW.id 
          AND is_correct = true;
    END IF;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER ensure_one_correct_answer
    BEFORE INSERT OR UPDATE ON answers
    FOR EACH ROW
    EXECUTE FUNCTION validate_correct_answer();
```

Exemplo de policy:
```sql
CREATE POLICY "Answers are viewable by everyone"
  ON answers FOR SELECT
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
- `AnswerEntity` em `lib/features/answers/domain/entities/answer_entity.dart`
  - Campos: id, questionId, text, isCorrect, explanation, createdAt, updatedAt
  - Método toMap() e fromMap()
- `AnswerDto` em `lib/features/answers/infrastructure/dtos/answer_dto.dart`
  - Mesmos campos com snake_case para Supabase
  - toMap() e fromMap()
- `AnswerMapper` em `lib/features/answers/infrastructure/mappers/answer_mapper.dart`
  - toEntity(AnswerDto) → AnswerEntity
  - toDto(AnswerEntity) → AnswerDto
- Comentários sobre conversão de nomes (is_correct vs isCorrect, question_id vs questionId)

---

### 4. **Repository Offline-First (modo: repository)**
Gerar:
- `AnswerRepository` em `lib/features/answers/infrastructure/repositories/answer_repository.dart`
- Métodos:
  - `Future<List<AnswerEntity>> fetchAnswersByQuestion(String questionId, {DateTime? lastSync})`
  - `Future<AnswerEntity?> fetchCorrectAnswer(String questionId)`
  - `Future<List<AnswerEntity>> getLocalCache(String questionId)`
  - `Future<void> saveLocalCache(List<AnswerEntity> answers)`
  - `Future<List<AnswerEntity>> syncIncremental(String questionId)`
  - `Future<void> markAsCorrect(String answerId, String questionId)` - marca resposta como correta e desmarca outras
- Regras:
  - Não bloquear UI.
  - Sincronização incremental por updated_at.
  - Persistência local usando SharedPreferences ou cache escolhido.
  - Filtrar por question_id.
  - Ordenação aleatória na UI (não no repository).
  - Validar que existe pelo menos uma resposta correta.
  - Aviso sobre paginação futura se necessário.

---

### 5. **Sync Service (modo: sync)**
Gerar:
- `AnswerSyncService` em `lib/features/answers/services/answer_sync_service.dart`
- Fluxo:
  1. Ler lastSync para a question específica.
  2. Buscar answers atualizadas no Supabase (WHERE question_id = ? AND updated_at >= ?).
  3. Mesclar com cache local.
  4. Validar que existe pelo menos uma resposta correta.
  5. Atualizar lastSync.
  6. Salvar no cache.
  7. Retornar lista final.
- Garantir que UI receba resultados sem lag.
- Método: `Future<List<AnswerEntity>> syncAnswers(String questionId)`

---

### 6. **Answers Page (modo: page)**
Gerar:
- `AnswersPage` completa em `lib/features/answers/presentation/answers_page.dart`
- Recebe questionId como parâmetro.
- Carrega cache local primeiro.
- Renderização imediata das answers (EMBARALHADAS para quiz, ordenadas para admin).
- Atualização silenciosa em background.
- Indicador discreto de atualização (CircularProgressIndicator no AppBar).
- Sem travar UI.
- Sem refresh manual obrigatório.
- Exibir texto da resposta.
- Badge visual para resposta correta (CORRETA - verde).
- Mostrar explanation quando disponível.
- Cards expansíveis.
- FloatingActionButton para criar nova answer.
- Validação visual: questão deve ter pelo menos uma resposta correta.

---

### 7. **README (modo: readme)**
Gerar:
- Instalação completa do Supabase
- Setup Flutter para answers
- Como rodar com `.env`
- Como rodar com `--dart-define`
- Segurança e RLS
- Estrutura de pastas para answers
- Fluxo de sync incremental
- Relacionamento answers → questions
- Regra de negócio: uma resposta correta por questão
- Embaralhamento de respostas
- Checklist final:
  - [ ] Tabela answers criada
  - [ ] RLS ativado
  - [ ] Índices criados
  - [ ] Constraints validados
  - [ ] Triggers configurados
  - [ ] Repository implementado
  - [ ] Sync service implementado
  - [ ] AnswersPage funcionando offline
  - [ ] Validação de resposta correta implementada
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
    answers/
      domain/
        entities/
          answer_entity.dart
      infrastructure/
        dtos/
          answer_dto.dart
        mappers/
          answer_mapper.dart
        repositories/
          answer_repository.dart
        local/
          answers_local_dao_shared_prefs.dart
      presentation/
        answers_page.dart
        widgets/
          answer_list_item.dart
        dialogs/
          answer_form_dialog.dart
      services/
        answer_sync_service.dart
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
9. Apenas uma resposta correta por questão (validado).
10. Foreign key para questions respeitada.
11. Embaralhamento de respostas na UI do quiz.

---

## Exemplo de Query Incremental

```sql
SELECT * FROM answers 
WHERE question_id = $1 
  AND updated_at >= $2
ORDER BY created_at ASC;
```

Onde $1 = questionId e $2 = lastSync

---

## Exemplo de Query para Validação

```sql
-- Verifica se question tem pelo menos uma resposta correta
SELECT EXISTS (
  SELECT 1 FROM answers 
  WHERE question_id = $1 
    AND is_correct = true
) AS has_correct_answer;
```

---

## Observações Importantes
- O agente deve assumir que este prompt controla todo o fluxo de Answers no QuizCraft.
- Manter consistência entre backend (Supabase) e frontend (Flutter).
- Todos os trechos gerados devem ser prontos para copiar/colar.
- Answers dependem de Questions - verificar relacionamento.
- Apenas UMA resposta correta por questão (constraint crítico).
- Cache local deve ser específico por question_id.
- Sync incremental deve filtrar por question_id E updated_at.
- ON DELETE CASCADE: remover question remove suas answers automaticamente.
- Embaralhamento de respostas: implementar no frontend, não no SQL.
- Explanation é opcional mas recomendado para propósitos educacionais.
- is_correct deve ser protegido: não permitir que usuário final marque arbitrariamente.
