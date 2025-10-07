# QuizCraft - Quizzes de Revisão

Link PRD: https://docs.google.com/document/d/1j0MURGEOpWCgxeIYNGAvaBmAp1jjRVuRFjJkTK78bhk/edit?usp=sharing

![Ícone do App](assets/logo_com_fundo.png)

QuizCraft é um aplicativo de quizzes de revisão que permite ao aluno criar e realizar quizzes rápidos por tema para testar seu conhecimento e reforçar a revisão espaçada.  

---

## 📌 Visão Geral

O objetivo do QuizCraft é proporcionar uma **primeira experiência clara, guiada e memorável**, garantindo que o usuário:

- Entenda o valor imediato do aplicativo.
- Faça escolhas legais (consentimentos) de forma transparente.
- Tenha seus dados tratados conforme a **LGPD**.
- Tenha acessibilidade garantida (A11Y).

---

## 👤 Persona Principal

Aluno que gosta de testar conhecimento e busca uma ferramenta rápida para autoavaliação e revisão antes de provas.

---

## 🚀 Fluxo de Primeira Execução

1. **Splash Screen:** Exibe branding e checa se as políticas mais recentes foram aceitas.
2. **Onboarding:** 2-4 telas apresentando o valor do app. Botão "Pular" disponível.
3. **Visualização de Políticas e Termos:** Leitura obrigatória de Política de Privacidade e Termos de Uso em Markdown.
4. **Consentimento:** Opt-in para Analytics só após leitura completa das políticas.
5. **Home:** Tela principal com opção de criar quizzes, revogação de consentimento disponível em Configurações.

---

## 🎨 Identidade Visual

- **Primária:** #2563EB (Blue)  
- **Secundária:** #F59E0B (Amber)  
- **Acento/Contraste:** #475569 (Gray)  

**Direção:** Flat minimalista, Material 3, alto contraste (WCAG AA).  

**Ícone do App:** Insígnia vetorial circular, fundo transparente, estilo flat moderno com ponto de interrogação e escudo, cores Blue, Amber e Gray.  

---

## ⚙️ Requisitos Funcionais (RF)

- Progresso visual com **DotsIndicator** sincronizado ao PageView do Onboarding.  
- Navegação contextual (Pular → Consentimento).  
- Visualizador de políticas com scroll obrigatório para habilitar "Marcar como lido".  
- Consentimento habilita o botão apenas após leitura completa e decisão sobre o opt-in.  
- Revogação do consentimento com **AlertDialog + SnackBar** com opção de Desfazer.

---

## 🔧 Requisitos Não Funcionais (RNF)

- **Acessibilidade (A11Y):** Alvos ≥48dp, contraste AA, suporte a Text Scaling ≥1.3.  
- **LGPD/Privacidade:** Registro da data e versão do aceite, opt-in para Analytics.  
- **Arquitetura:** Persistência via PrefsService, sem SharedPreferences direto na UI.

---

## 💾 Dados & Persistência

| Chave                     | Tipo   | Descrição |
|----------------------------|--------|-----------|
| privacy_read_v{N}          | bool   | Política de Privacidade (versão N) lida |
| terms_read_v{N}            | bool   | Termos de Uso (versão N) lidos |
| policies_version_accepted  | string | Versão das políticas aceitas |
| analytics_consent          | bool   | Consentimento para Analytics |
| accepted_at                | string | Data do aceite (ISO8601) |

---

## 🛣️ Roteamento

- `/` : Splash Screen  
- `/onboarding` : Fluxo de Onboarding  
- `/policy-viewer` : Visualizador de Políticas  
- `/home` : Tela principal

---

## ✅ Checklist de Conformidade

- [ ] Dots sincronizados e ocultos na última tela do Onboarding  
- [ ] Pular → consentimento; Voltar/Avançar contextuais  
- [ ] Visualizador com progresso + "Marcar como lido"  
- [ ] Aceite habilita somente após leitura dos dois documentos  
- [ ] Splash decide rota por versão aceita  
- [ ] Revogação com confirmação + SnackBar  
- [ ] Sem SharedPreferences direto na UI  
- [ ] Ícones gerados  
- [ ] A11Y validada (48dp, contraste, Semantics, text scaling)  

---

## 🧪 Testes Manuais (QA)

1. **Primeira Execução:** Onboarding → Viewer → Aceite → Home  
2. **Revogação com Desfazer:** Revogar consentimento e restaurar via SnackBar  
3. **Revogação Completa:** Revogar sem usar Desfazer, retornando ao fluxo de aceite legal  

---

## 📁 Entregáveis (Evidências)

- `icone.png` → Ícone do App  
- `viwer-100%.png` → Visualizador 100% lido  
- `consentimento-2.png` → Consentimento habilitado  
- `Revogar.png` → Revogação com SnackBar  
- `sem_dots.png` → Home sem DotsIndicator  

---

## 📚 Referências

- Padrões internos de UI: DotsIndicator, Onboarding, PolicyViewerPage, PrefsService, Splash, AlertDialog + SnackBar.  
- Geração de ícones: `flutter_launcher_icons`.  
- Material 3, alto contraste e acessibilidade WCAG AA.

---

## 🔗 Links Úteis

- [GitHub Repository](#)  
- [Documentação Flutter](https://flutter.dev/docs)  
- [LGPD Brasil](https://www.lgpdbrasil.com.br/)  

[def]: assets/logo_com_fundo.png