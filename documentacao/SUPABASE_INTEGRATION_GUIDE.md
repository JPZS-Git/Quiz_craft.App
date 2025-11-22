# 🚀 Guia de Integração Supabase - QuizCraft

## ✅ Pré-requisitos Completados
- [x] Projeto Supabase criado
- [x] URL: https://jbfjpsviebmbpmmlekzx.supabase.co
- [x] ANON_KEY configurada
- [x] Arquivo .env criado
- [x] .gitignore atualizado

---

## 📋 Roteiro de Execução (Siga esta ordem)

### **ETAPA 1: SQL - Criar Tabelas no Supabase** 

Acesse o Supabase SQL Editor e execute na ordem:

#### 1.1 - Authors (tabela independente)
```bash
Execute: prompts/supabase/prompt_supabase_authors.md
Modo: sql
```
⚠️ **Ação**: Copie o SQL gerado e execute no Supabase SQL Editor

#### 1.2 - Quizzes (depende de authors)
```bash
Execute: prompts/supabase/prompt_supabase_quizzes.md
Modo: sql
```
⚠️ **Ação**: Copie o SQL gerado e execute no Supabase SQL Editor

#### 1.3 - Questions (depende de quizzes)
```bash
Execute: prompts/supabase/prompt_supabase_questions.md
Modo: sql
```
⚠️ **Ação**: Copie o SQL gerado e execute no Supabase SQL Editor

#### 1.4 - Answers (depende de questions)
```bash
Execute: prompts/supabase/prompt_supabase_answers.md
Modo: sql
```
⚠️ **Ação**: Copie o SQL gerado e execute no Supabase SQL Editor

#### 1.5 - Attempts (depende de quizzes)
```bash
Execute: prompts/supabase/prompt_supabase_attempts.md
Modo: sql
```
⚠️ **Ação**: Copie o SQL gerado e execute no Supabase SQL Editor

---

### **ETAPA 2: Setup Flutter**

#### 2.1 - Instalar Dependências
```bash
cd quiz_craft
flutter pub add supabase_flutter
flutter pub add flutter_dotenv
```

#### 2.2 - Configurar Inicialização
```bash
Execute: prompts/supabase/prompt_supabase_questions.md
Modo: setup_flutter
```
⚠️ **Ação**: 
- Copie o código do main.dart gerado
- Atualize seu `lib/main.dart`
- Adicione `.env` ao `pubspec.yaml` em assets

---

### **ETAPA 3: Migração de Entidades (uma por vez)**

Para cada entidade, execute na ordem:

#### 3.A - Authors (COMEÇAR POR AQUI - mais simples)

```bash
1. Execute prompt_supabase_authors.md modo: entity
   → Cria AuthorEntity, AuthorDto, AuthorMapper

2. Execute prompt_supabase_authors.md modo: repository
   → Cria AuthorRepository com Supabase + cache

3. Execute prompt_supabase_authors.md modo: sync
   → Cria AuthorSyncService

4. Execute prompt_supabase_authors.md modo: page
   → Atualiza AuthorsPage para sync offline-first
```

✅ **Checkpoint**: Teste Authors funcionando com Supabase

---

#### 3.B - Quizzes (DEPOIS de Authors)

```bash
1. Execute prompt_supabase_quizzes.md modo: entity
2. Execute prompt_supabase_quizzes.md modo: repository
3. Execute prompt_supabase_quizzes.md modo: sync
4. Execute prompt_supabase_quizzes.md modo: page
```

✅ **Checkpoint**: Teste Quizzes funcionando com Supabase

---

#### 3.C - Questions (DEPOIS de Quizzes)

```bash
1. Execute prompt_supabase_questions.md modo: entity
2. Execute prompt_supabase_questions.md modo: repository
3. Execute prompt_supabase_questions.md modo: sync
4. Execute prompt_supabase_questions.md modo: page
```

✅ **Checkpoint**: Teste Questions funcionando com Supabase

---

#### 3.D - Answers (DEPOIS de Questions)

```bash
1. Execute prompt_supabase_answers.md modo: entity
2. Execute prompt_supabase_answers.md modo: repository
3. Execute prompt_supabase_answers.md modo: sync
4. Execute prompt_supabase_answers.md modo: page
```

✅ **Checkpoint**: Teste Answers funcionando com Supabase

---

#### 3.E - Attempts (DEPOIS de Quizzes)

```bash
1. Execute prompt_supabase_attempts.md modo: entity
2. Execute prompt_supabase_attempts.md modo: repository
3. Execute prompt_supabase_attempts.md modo: sync
4. Execute prompt_supabase_attempts.md modo: page
```

✅ **Checkpoint**: Teste Attempts funcionando com Supabase

---

### **ETAPA 4: Documentação**

```bash
Execute: prompt_supabase_questions.md modo: readme
```
⚠️ **Ação**: Gera documentação completa da arquitetura

---

## 🎯 Próximos Passos IMEDIATOS

### 1️⃣ **AGORA**: Criar prompts faltantes

Você tem apenas `prompt_supabase_questions.md`. Precisa criar:
- [ ] `prompt_supabase_authors.md`
- [ ] `prompt_supabase_quizzes.md`
- [ ] `prompt_supabase_answers.md`
- [ ] `prompt_supabase_attempts.md`

### 2️⃣ **DEPOIS**: Executar ETAPA 1 (SQL)

Começar criando todas as tabelas no Supabase.

### 3️⃣ **DEPOIS**: Executar ETAPA 2 (Setup Flutter)

Configurar o app para conectar com Supabase.

### 4️⃣ **DEPOIS**: Executar ETAPA 3 (Migração)

Migrar entidade por entidade, testando cada uma.

---

## 📊 Status Atual

```
✅ Supabase criado
✅ Credenciais configuradas
✅ .env criado
✅ .gitignore atualizado
✅ prompt_supabase_questions.md criado

⏳ Faltam 4 prompts (authors, quizzes, answers, attempts)
⏳ Falta executar SQL
⏳ Falta configurar Flutter
⏳ Falta migrar código
```

---

## ❓ Você Quer:

**A)** Que eu crie os 4 prompts faltantes agora?
**B)** Que eu execute o modo: sql para Questions e gere o SQL?
**C)** Outro caminho?

---

## 💡 Dica Importante

**NÃO migre tudo de uma vez!** 

Faça assim:
1. SQL de todas as tabelas → teste no Supabase
2. Setup Flutter → teste conexão
3. Authors completo → teste CRUD
4. Se funcionar, parta para próxima entidade

Isso evita debugar 5 entidades ao mesmo tempo.
