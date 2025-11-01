# Histórico de alterações — Entities / DTOs / Mappers

Data: 2025-11-01

Resumo
-------
Este documento descreve as alterações realizadas nas camadas de domínio e infraestrutura relacionadas a entidades, DTOs e mappers do módulo de `providers` (adaptação para domínio de quizzes / authors). As mudanças visam padronizar a serialização (Map <-> Entity), prover DTOs com capacidade de conversão para Entity e implementar mappers que convertem Entity -> DTO (e, em vários casos, DTO -> Entity para simetria). Também foram aplicadas práticas defensivas de parsing para datas, URIs e coleções.

O que foi feito
-------------

1. Entities
- Todas as entidades relevantes ao domínio de quizzes foram adicionadas/atualizadas com métodos de serialização:
  - `fromMap(Map<String, dynamic>)` — cria a entidade a partir de um mapa (entrada externa/JSON).
  - `toMap()` — converte a entidade em um `Map<String, dynamic>` adequado para transporte/armazenamento.

  Entidades criadas/atualizadas (principais):
  - `lib/features/providers/domain/entities/author_entity.dart` — AuthorEntity
  - `lib/features/providers/domain/entities/quiz_entity.dart` — QuizEntity
  - `lib/features/providers/domain/entities/question_entity.dart` — QuestionEntity
  - `lib/features/providers/domain/entities/answer_entity.dart` — AnswerEntity
  - `lib/features/providers/domain/entities/attempt_entity.dart` — AttemptEntity

2. DTOs (Data Transfer Objects)
- Para cada entidade de domínio relevante criamos DTOs responsáveis por:
  - `fromMap(Map<String, dynamic>)` — desserializar dados externos em DTO.
  - `toMap()` — serializar DTO para persistência/transporte.
  - `toEntity()` — converter DTO → Entity (DTO é a fonte canônica para DTO->Entity).

  DTOs principais (pasta):
  - `lib/features/providers/infrastructure/dtos/author_dto.dart`
  - `lib/features/providers/infrastructure/dtos/quiz_dto.dart`
  - `lib/features/providers/infrastructure/dtos/question_dto.dart`
  - `lib/features/providers/infrastructure/dtos/answer_dto.dart`
  - `lib/features/providers/infrastructure/dtos/attempt_dto.dart`

3. Mappers
- Implementamos mappers na pasta `infrastructure/mappers` com responsabilidade principal de converter Entity -> DTO (`toDto`). Em complemento, e por solicitação, foram adicionados métodos `toEntity` em mappers para oferecer uma conversão simétrica (DTO -> Entity) onde fez sentido.

  Mappers adicionados/alterados:
  - `lib/features/providers/infrastructure/mappers/author_mapper.dart` — agora contém `toDto` e `toEntity`.
  - `lib/features/providers/infrastructure/mappers/quiz_mapper.dart` — `toDto` e `toEntity` (usa `QuestionMapper`).
  - `lib/features/providers/infrastructure/mappers/question_mapper.dart` — `toDto` e `toEntity` (usa `AnswerMapper`).
  - `lib/features/providers/infrastructure/mappers/answer_mapper.dart` — `toDto` e `toEntity`.
  - `lib/features/providers/infrastructure/mappers/attempt_mapper.dart` — `toDto` e `toEntity`.

Padrões e práticas aplicadas
---------------------------
- Direção de conversão: adotamos uma estratégia mista e explícita:
  - DTOs expõem `toEntity()` — essa função é usada como fonte canônica para conversão de DTO → Entity.
  - Mappers expõem `toDto()` (Entity → DTO). Alguns mappers agora também fornecem `toEntity()` para conveniência e simetria (pedida pelo time).

- Parsing defensivo e conversões seguras:
  - Datas: prefira `DateTime.tryParse(...) ?? DateTime.now()` em pontos onde a string pode ser inválida. Em mappers adicionamos `tryParse` para evitar exceções em entradas externas.
  - URIs: usar `Uri.tryParse(...)` antes de construir `Uri` a partir de strings.
  - Coleções: usar `whereType<T>()`, `List.from(...)` e `toList()` para garantir tipos corretamente convertidos e evitar casts inseguros.
  - Campos opcionais e nulos: tratar corretamente com `?` e valores default onde aplicável.

Validação automática
-------------------
- Foi executado `flutter analyze` especificamente nas pastas de `dtos` e `mappers` após as mudanças. Resultado: `No issues found!` (análise direcionada executada em 2025-11-01).

Testes
------
- Foram adicionados testes unitários de round‑trip para validar a consistência das conversões entre Entity <-> DTO:
  - `test/roundtrip_dto_entity_test.dart` cobre: Author, Quiz (com perguntas/respostas aninhadas) e Attempt.
  - Os testes foram executados com `flutter test` e todos passaram (status: sucesso).

Observações de design
---------------------
- Evitamos duplicação de lógica sempre que possível. Inicialmente `AuthorMapper` continha `toEntity` enquanto `AuthorDto` também tinha `toEntity` — isso foi revisado e hoje ambos existem para compatibilidade, mas recomenda-se escolher uma única fonte de verdade (DTO ou Mapper) para DTO→Entity para reduzir riscos de divergência.
- Recomenda-se adicionar testes automatizados de round-trip (Entity -> DTO -> Map -> DTO.fromMap -> Entity) para Author, Quiz e Attempt. Isso garante que serialização/deserialização e mappers sejam consistentes.

Arquivos alterados / adicionados (lista resumida)
-------------------------------------------------
- Entities
  - `lib/features/providers/domain/entities/author_entity.dart`
  - `lib/features/providers/domain/entities/quiz_entity.dart`
  - `lib/features/providers/domain/entities/question_entity.dart`
  - `lib/features/providers/domain/entities/answer_entity.dart`
  - `lib/features/providers/domain/entities/attempt_entity.dart`

- DTOs
  - `lib/features/providers/infrastructure/dtos/author_dto.dart`
  - `lib/features/providers/infrastructure/dtos/quiz_dto.dart`
  - `lib/features/providers/infrastructure/dtos/question_dto.dart`
  - `lib/features/providers/infrastructure/dtos/answer_dto.dart`
  - `lib/features/providers/infrastructure/dtos/attempt_dto.dart`

- Mappers
  - `lib/features/providers/infrastructure/mappers/author_mapper.dart`
  - `lib/features/providers/infrastructure/mappers/quiz_mapper.dart`
  - `lib/features/providers/infrastructure/mappers/question_mapper.dart`
  - `lib/features/providers/infrastructure/mappers/answer_mapper.dart`
  - `lib/features/providers/infrastructure/mappers/attempt_mapper.dart`

Checklist
---------

- [x] Criar/atualizar Entities com `fromMap` e `toMap`.
- [x] Criar DTOs com `fromMap`, `toMap` e `toEntity`.
- [x] Criar Mappers com `toDto` (Entity -> DTO).
- [x] Adicionar `toEntity` em mappers para `Answer`, `Question`, `Quiz`, `Attempt` e `Author` (simetria).
- [x] Aplicar parsing defensivo (DateTime.tryParse, Uri.tryParse onde usado nos mappers).
- [x] Rodar `flutter analyze` em `dtos` e `mappers` (resultado: sem issues).
 - [ ] Padronizar a responsabilidade de conversão (escolher DTO->Entity em DTOs, ou centralizar tudo nos mappers).
 - [x] Adicionar testes de round-trip unitários (Author, Quiz, Attempt) — adicionados e executados com sucesso.
 - [x] Executar testes unitários (`flutter test`) — todos os testes relacionados passaram.

Se quiser que eu: (escolha uma)
- padronize removendo/centralizando `toEntity` em mappers ou DTOs,
- crie os testes de round-trip automatizados e execute `flutter test`,
- ou aplique parsing defensivo em todos os `toEntity` dentro dos DTOs também — eu executo a opção escolhida.

---

Arquivo gerado automaticamente em 2025-11-01 pelo fluxo de revisão de mappers/entities/dtos.
