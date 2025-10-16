# Untitled

# Formulário do Observador — Gallery Walk (Observação rápida)

> Objetivo: registrar evidências observáveis do fluxo apresentado e produzir feedback EOA (Específico, Observável e Acionável) que possa ser implementado em 1 dia, facilitando o cruzamento com o Formulário do Avaliador.
> 

## Identificação

- **Expositor (nome/repo):** João Pedro Zanetti Sartori
- **Tema do aplicativo observado:** Criador de quiz
- **Observador:** Rondineli Bitencourt Junior
- **Rodada:** 1 ☐ 2 ☐ **Data:** 16**/10**/2025   **Horário:** 17:03

---

## Como observar (roteiro de 90 segundos)

> Siga o fluxo demonstrado: Splash → Onboarding → Políticas (viewer) → Consentimento → Home
> 
> 
> Marque a checklist e anote **onde** você viu cada evidência (tela/rota/print/commit).
> 

---

## Mini-Checklist (Sim / Parcial / Não) + Evidência

> Como preencher: Marque Sim/Parcial/Não e descreva onde verificou (ex.: “tela X”, “rota onboarding→consent”, “print Y”, “commit abc123”).
> 

### 1) Fluxo Claro (dots / pular / splash)

- **Dots** sincronizados e **ocultos na última tela**. **Sim  (X)  Parcial ☐ Não ☐**

**Onde vi:**  Na parte inferior da tela

- **“Pular”** leva ao **Consentimento** (não salta para a Home). **Sim (X) Parcial ☐ Não ☐**

**Onde vi:** Na parte superior direita da tela

- **Splash** decide a rota pela **versão aceita** das políticas. **Sim (X) Parcial ☐ Não ☐**

**Onde vi:**  Após aceitar os termos e consentimentos foi feito um restart e o splash levou direto á home

### 2) Legal & Consentimento (viewer / aceite / versão / revogação)

- **Viewer** de políticas com **progresso** visível. **Sim (X) Parcial ☐ Não ☐**

**Onde vi:**  Na parte superior da tela

- **“Marcar como lido”** só **habilita ao final** do texto. **Sim (X)  Parcial ☐ Não ☐**

**Onde vi:**  O botão fica visível na parte inferior da tela na cor cinza e sem poder ser clicado, após toda a leitura a cor fica azul e permite o clique

- **Aceite após 2 leituras** + **versão** registrada. **Sim (X)  Parcial ☐ Não ☐**

**Onde vi:**  Logo após a leitura dos 2 itens

- **Revogar/Desfazer** consentimento está claro na UI. **Sim (X) Parcial ☐ Não ☐**

**Onde vi:**  Página inicial possui uma opção de revogar consentimento

### 3) Acessibilidade (48dp / contraste / foco / botões)

- Alvos táteis ≥ **48dp** (toque confortável). **Sim ☐  Parcial (X)  Não ☐**

**Onde vi:** Logo na primeira tela um dos botões não possui o “toque confortável”

- **Contraste** suficiente (texto/ícones). **Sim (X)  Parcial ☐ Não ☐**

**Onde vi:** Em todas as telas os elementos são visíveis, com correspondência nos contrastes e suas respectivas funções

- **Foco visível** (teclado/leitor de tela). **Sim (X) Parcial ☐ Não ☐**

**Onde vi:** O teclado não atrapalha a  leitura quando utilizado

- Botões **desabilitados** são perceptíveis/acessíveis. **Sim (X) Parcial ☐ Não ☐**

**Onde vi:** Eles são perceptíveis e inacessíveis antes da leitura necessária

### 4) Evidências & Registro (prints / [README.md](http://readme.md/) / commit)

- Há **prints/GIFs** anexados ou referenciados. **Sim ☐ Parcial ☐ Não (X)**

- [**README.md/docs**](http://readme.md/docs) descrevem **fluxo e decisões**. **Sim (X) Parcial ☐ Não ☐**

**Onde vi:**  [https://github.com/JPZS-Git/Quiz_craft.App/blob/main/README.md](https://github.com/JPZS-Git/Quiz_craft.App/blob/main/README.md)

- **Commits/PRs** evidenciam a entrega. **Sim ☐ Parcial (X)  Não ☐**

**Onde vi (IDs/links):**  [https://github.com/JPZS-Git/Quiz_craft.App/commits/main](https://github.com/JPZS-Git/Quiz_craft.App/commits/main)

### 5) Identidade Visual (ColorScheme sem “cores mágicas”)

- Uso consistente de **ColorScheme/tema** (Material 3). **Sim (X) Parcial ☐ Não ☐**

**Onde vi:**  Nas telas da aplicação

- **Sem** “cores mágicas” hard-coded. **Sim (X) Parcial ☐ Não ☐**
    
    **Onde vi:**  Somente foram utilizadas cores estáticas
    

---

## EOA — Feedback principal (executável em 1 dia)

> O que é EOA?
> 
> 
> **E**specífico: diga **exatamente** o que mudar (componente/rota/arquivo).
> 
> **O**bservável: algo que possa ser **verificado** (print, vídeo, teste, código).
> 
> **A**cionável (em 1 dia): que caiba em **uma iteração curta**.
> 
- **Útil porque…** *(valor para usuário/negócio/UX)*
    
    → Criação rápida e prática de quiz
    
- **Melhoraria se…** *(ação concreta em 1 dia; indique onde e como)*
    
    → Se fosse direto para a home dos quizes ao invés de ir para uma home inicial
    

**Onde verificar (evidência esperada):**

- Arquivo/rota/widget:  lib/screens/home/home_screen.dart

- Commit/PR esperado:  commit adicionando redirecionamento após consentimento

- Critério de aceite (como saberei que ficou pronto?):  após aceitar termos, app abre direto a home dos quizzes sem tela intermediária

---

## Post-its para o Gallery Walk

- **Verde — “Útil porque…”**  Facilita a criação rápida de quizes

- **Amarelo — “Melhoraria se (1 dia)…”**  Direcionasse direto para a home de quizzes após consentimento

> Dica: mantenha as frases curtas e claras; objetivo é facilitar a ação imediata.
> 

---

## Como registrar os pontos (padrão do repositório)

> Padronize para facilitar o cruzamento com o Formulário do Avaliador:
> 
1. **Crie a pasta**: `docs/reviews/YYYY-MM-DD/`
2. **Salve este arquivo** como: `docs/reviews/YYYY-MM-DD/form-observador-<expositor>.md`
3. **Anexe evidências** (prints/GIFs curtos) em `docs/reviews/YYYY-MM-DD/evidences/` e **referencie** neste arquivo.
4. **Aponte commits/PRs** (IDs/links) quando citá-los nas respostas.
5. (Opcional) **Comente na issue “Warm-up”** do repositório com um resumo EOA + link deste formulário.

---

### Legenda de marcação (para referência rápida)

- **Sim**: requisito claramente observado.
- **Parcial**: observado com lacunas/ambiguidade.
- **Não**: não observado ou contraditório.