# Prompt: QuizCraft – Supabase + Flutter para Authors (Guia Completo Parametrizado)

## Parâmetros (defina no topo antes de executar)
- FEATURE_NAME: authors
- ENTITY: Author
- ENTITY_PLURAL: authors
- DTO_CLASS: AuthorDto
- REPOSITORY_CLASS: AuthorRepository
- LOCAL_CACHE_CLASS: AuthorsLocalCache
- SYNC_SERVICE_CLASS: AuthorSyncService
- ENV_KEYS: [SUPABASE_URL, SUPABASE_ANON_KEY]
- TABLE_NAME: authors

---

## Contexto
Você é um agente especializado na geração de estruturas de software completas para o **QuizCraft**, seguindo arquitetura offline-first com Supabase.  
Seu objetivo é produzir **arquitetura, código, contratos, sincronização, cache offline**, configuração de ambiente, SQL e páginas Flutter para a entidade **Authors**.

O prompt abaixo foi desenhado para permitir gerar:
- SQL da tabela authors + RLS + índice.
- Setup do Supabase no Flutter com dotenv.
- Modelos (Entity, DTO, Mapper) para authors.
- Repository com cache e sync incremental.
- Serviço de sincronização incremental.
- Página de authors offline-first.
- README de setup completo.
- Arquivo `.env.example`.

---

## Objetivo
Gerar (conforme modo solicitado na invocação) um dos seguintes artefatos:

1. **SQL completo**: tabela authors, índice, RLS e policy.  
2. **Setup Flutter Supabase** (main.dart completo, dotenv, validação, warnings).  
3. **Models e camadas de dados**: AuthorEntity, AuthorDto, AuthorMapper.  
4. **Repository offline-first**: cache local + sync incremental por updated_at.  
5. **Serviço de sincronização incremental** com fluxo completo.  
6. **Authors Page** renderizando cache + atualização silenciosa.  
7. **README.md completo** com boas práticas.  
8. **Arquivos de ambiente** `.env.example` e orientações CI/CD.  

Cada saída deve ser completa, funcional e sem omissões.

---

## Estrutura da Tabela Authors

### Campos da tabela `authors`
- `id` (uuid, PRIMARY KEY, DEFAULT gen_random_uuid())
- `name` (text, NOT NULL) - nome do autor
- `email` (text, UNIQUE) - email do autor (opcional)
- `bio` (text) - biografia do autor (opcional)
- `avatar_url` (text) - URL do avatar (opcional)
- `topics` (text[], DEFAULT '{}') - array de tópicos de especialidade
- `is_active` (boolean, DEFAULT true) - status do autor
- `rating` (numeric(3,2), DEFAULT 0) - avaliação média (0.00 a 5.00)
- `quizzes_count` (integer, DEFAULT 0) - contador de quizzes criados
- `created_at` (timestamptz, DEFAULT now())
- `updated_at` (timestamptz, DEFAULT now())

### Relacionamentos
- Possui múltiplos quizzes (quizzes.author_id → authors.id)

### Índices necessários
- `authors_email_idx` em email (para lookup rápido)
- `authors_updated_at_idx` em updated_at (para sync incremental)
- `authors_rating_idx` em rating DESC (para ordenação por popularidade)
- `authors_is_active_idx` em is_active (para filtrar ativos)

### Constraints
- `authors_rating_check` CHECK (rating >= 0 AND rating <= 5)
- `authors_quizzes_count_check` CHECK (quizzes_count >= 0)
- `authors_email_check` CHECK (email ~* '^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\\.[A-Z|a-z]{2,}$')

---

## Entradas Esperadas (inputs)
- mode: `"sql" | "setup_flutter" | "entity" | "repository" | "sync" | "page" | "readme" | "env"`  
- Opcionalmente:
  - lastSync (DateTime)
  - shouldIncludeMapper (boolean)
  - offlineCacheEngine: `"shared_preferences" | "isar" | "sqflite" | "drift"`
  - filterActive (boolean) - para filtrar apenas autores ativos

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
- Email deve ser mascarado na UI para privacidade.

---

## Escopo de Geração de Artefatos

### 1. **SQL (modo: sql)**
Gerar:
- Tabela authors completa.
- Índices: email, updated_at, rating, is_active.
- Constraints: rating, quizzes_count, email format.
- Trigger para atualizar updated_at automaticamente.
- Trigger para atualizar quizzes_count quando quiz é criado/removido.
- Ativar RLS.
- Criar policy de leitura pública.
- Comentários explicando índices e constraints.

Exemplo de trigger updated_at:
```sql
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_authors_updated_at
    BEFORE UPDATE ON authors
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
```

Exemplo de policy:
```sql
CREATE POLICY "Authors are viewable by everyone"
  ON authors FOR SELECT
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
- `AuthorEntity` em `lib/features/authors/domain/entities/author_entity.dart`
  - Campos: id, name, email, bio, avatarUrl, topics, isActive, rating, quizzesCount, createdAt, updatedAt
  - Método toMap() e fromMap()
- `AuthorDto` em `lib/features/authors/infrastructure/dtos/author_dto.dart`
  - Mesmos campos com snake_case para Supabase
  - toMap() e fromMap()
  - Conversão de topics (array SQL ↔ List<String> Dart)
- `AuthorMapper` em `lib/features/authors/infrastructure/mappers/author_mapper.dart`
  - toEntity(AuthorDto) → AuthorEntity
  - toDto(AuthorEntity) → AuthorDto
- Comentários sobre conversão de nomes (avatar_url vs avatarUrl, quizzes_count vs quizzesCount)
- Método helper para mascarar email: `String maskEmail(String? email)`

---

### 4. **Repository Offline-First (modo: repository)**
Gerar:
- `AuthorRepository` em `lib/features/authors/infrastructure/repositories/author_repository.dart`
- Métodos:
  - `Future<List<AuthorEntity>> fetchAuthors({DateTime? lastSync, bool onlyActive = false})`
  - `Future<AuthorEntity?> fetchAuthorById(String id)`
  - `Future<List<AuthorEntity>> getLocalCache()`
  - `Future<void> saveLocalCache(List<AuthorEntity> authors)`
  - `Future<List<AuthorEntity>> syncIncremental()`
  - `Future<void> incrementQuizzesCount(String authorId)`
  - `Future<void> decrementQuizzesCount(String authorId)`
- Regras:
  - Não bloquear UI.
  - Sincronização incremental por updated_at.
  - Persistência local usando SharedPreferences ou cache escolhido.
  - Ordenar por rating DESC por padrão.
  - Filtrar is_active se necessário.
  - Aviso sobre paginação futura se necessário.

---

### 5. **Sync Service (modo: sync)**
Gerar:
- `AuthorSyncService` em `lib/features/authors/services/author_sync_service.dart`
- Fluxo:
  1. Ler lastSync.
  2. Buscar authors atualizados no Supabase (WHERE updated_at >= ?).
  3. Mesclar com cache local.
  4. Ordenar por rating DESC.
  5. Atualizar lastSync.
  6. Salvar no cache.
  7. Retornar lista final.
- Garantir que UI receba resultados sem lag.
- Método: `Future<List<AuthorEntity>> syncAuthors({bool onlyActive = false})`

---

### 6. **Authors Page (modo: page)**
Gerar:
- `AuthorsPage` completa em `lib/features/authors/presentation/authors_page.dart`
- Carrega cache local primeiro.
- Renderização imediata dos authors ordenados por rating.
- Atualização silenciosa em background.
- Indicador discreto de atualização (CircularProgressIndicator no AppBar).
- Sem travar UI.
- Sem refresh manual obrigatório.
- Exibir avatar, nome, rating com estrelas, quizzes count, tópicos.
- Email mascarado na UI.
- Cards expansíveis mostrando bio e detalhes.
- FloatingActionButton para criar novo author (se aplicável).
- Badges de status: ATIVO/INATIVO.
- Ordenação por rating decrescente.

---

### 7. **README (modo: readme)**
Gerar:
- Instalação completa do Supabase
- Setup Flutter para authors
- Como rodar com `.env`
- Como rodar com `--dart-define`
- Segurança e RLS
- Estrutura de pastas para authors
- Fluxo de sync incremental
- Explicação sobre mascaramento de email
- Checklist final:
  - [ ] Tabela authors criada
  - [ ] RLS ativado
  - [ ] Índices criados
  - [ ] Constraints validados
  - [ ] Triggers configurados
  - [ ] Repository implementado
  - [ ] Sync service implementado
  - [ ] AuthorsPage funcionando offline
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
    authors/
      domain/
        entities/
          author_entity.dart
      infrastructure/
        dtos/
          author_dto.dart
        mappers/
          author_mapper.dart
        repositories/
          author_repository.dart
        local/
          authors_local_dao_shared_prefs.dart
      presentation/
        authors_page.dart
        widgets/
          author_list_item.dart
        dialogs/
          author_form_dialog.dart
      services/
        author_sync_service.dart
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
9. Authors ordenados por rating por padrão.
10. Email mascarado na UI.
11. Contador de quizzes sincronizado.

---

## Exemplo de Query Incremental

```sql
SELECT * FROM authors 
WHERE updated_at >= $1
  AND (is_active = true OR $2 = false)
ORDER BY rating DESC, name ASC;
```

Onde $1 = lastSync e $2 = filterActive

---

## Observações Importantes
- O agente deve assumir que este prompt controla todo o fluxo de Authors no QuizCraft.
- Manter consistência entre backend (Supabase) e frontend (Flutter).
- Todos os trechos gerados devem ser prontos para copiar/colar.
- Authors são tabela independente (sem foreign keys).
- Quizzes referenciam authors - verificar integridade referencial.
- Topics devem suportar array de strings.
- Rating deve ser validado entre 0 e 5.
- Quizzes_count deve ser mantido consistente via triggers ou lógica de aplicação.
- Email é opcional mas deve ser validado se presente.
- Avatar_url deve suportar URLs externas ou storage Supabase.
