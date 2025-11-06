# AGENTS — Automated Fixes and Tools

Este arquivo documenta ferramentas e instruções para que um agente (ou você) corrija automaticamente avisos comuns encontrados pela análise estática (flutter analyze), em especial o aviso relacionado ao uso de `.withOpacity` em `Color` que foi marcado como deprecated.

Uso recomendado
--------------
- Antes de rodar correções automáticas, faça um `git status` e commit/push das suas mudanças atuais. As correções serão aplicadas em vários arquivos e é importante ter um ponto de restauração.

- Executar análise para identificar avisos:

```powershell
cd quiz_craft
flutter analyze
```

- Para corrigir automaticamente ocorrências do padrão `Color(0xAARRGGBB).withOpacity(x)` (quando aplicado a literais hexadecimais) use a ferramenta fornecida em `tools/fix_withopacity.dart`.

Script automático (fix_withopacity.dart)
-------------------------------------
Onde: `tools/fix_withopacity.dart` — script Dart que faz _scan_ recursivo por arquivos `.dart`, encontra ocorrências do padrão e sugere ou aplica a substituição por `Color.fromRGBO(r, g, b, alpha)`.

Como usar (modo apenas relatório / dry-run):

```powershell
cd quiz_craft
dart run ../tools/fix_withopacity.dart
# ou, dependendo da sua configuração:
dart ../tools/fix_withopacity.dart
```

Como aplicar as mudanças (modo destrutivo / apply):

```powershell
cd quiz_craft
dart run ../tools/fix_withopacity.dart --apply
```

O que o script faz
- Procura por padrões do tipo: `Color(0xFF112233).withOpacity(0.05)`.
- Transforma em: `Color.fromRGBO(17, 34, 51, 0.05)` — onde 0xFF112233 representa (AARRGGBB), e extraímos R/G/B do valor hex.
- Só altera casos onde a cor é literal hexadecimal (ex.: `Color(0xFF...)`). Chamadas como `_myColor.withOpacity(...)` NÃO são alteradas automaticamente (pois exigem resolução de variável/objeto para obter seus canais de cor). Nesse caso, o script emite um aviso para revisão manual.

Limitações & cuidados
---------------------
- O script substitui apenas `Color(0xAARRGGBB).withOpacity(alpha)` onde o literal é totalmente conhecido.
- Não tenta converter chamadas encadeadas em variáveis, por exemplo `_surfaceGray.withOpacity(0.05)` deverá ser adaptado manualmente, geralmente substituindo a definição da constante por um literal ou usando `Color.fromRGBO` diretamente.
- Para arquivos onde a substituição automática não é segura, o script apenas reporta a ocorrência.
- Faça commit antes de rodar com `--apply`. Depois de aplicar, execute `flutter analyze` novamente e rode os testes.

Exemplo de fluxo (recomendado)
------------------------------
1. git add . && git commit -m "WIP: before automated fixes"
2. cd quiz_craft
3. dart run ../tools/fix_withopacity.dart --apply
4. flutter analyze
5. git add -A && git commit -m "chore: fix deprecated withOpacity -> fromRGBO"

Suporte adicional
------------------
Se quiser, posso estender este repositório com outros scripts automáticos (linters fixes, reformats, conversões de APIs deprecated) e integrá-los em um job de CI para rodar em PRs.
