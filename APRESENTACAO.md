# 🔊 Claude Voice Notify

**Notificações por voz pro Claude Code — pra você parar de ficar olhando o terminal esperando o Claude responder.**

---

## O problema que resolve

Quando você usa o Claude Code pra tarefas médias/longas, cai numa rotina chata:

- 👀 Fica alt-tabando toda hora pra ver se ele terminou
- ⏳ Claude pede permissão e trava esperando você aprovar — e você só percebe 5 minutos depois
- 🔁 Builds, testes e deploys longos te forçam a ficar de babá do terminal
- 🧠 Seu foco quebra a cada checagem, e demora pra voltar pro flow

**Resultado:** você rende menos porque fica gerenciando o Claude em vez de fazer o trabalho.

---

## O que o plugin faz

Toca um áudio curto (TTS neural em português ou inglês) quando eventos importantes acontecem no Claude Code:

- 🔔 **Claude pediu permissão** → "Precisa de autorização."
- ✅ **Task concluída** → "Pronto."
- 🔨 **Build/teste/lint acabou** → "Build OK." ou "Build falhou."
- 🚀 **PR criado, deploy feito, migração rodada** → aviso específico
- ⚠️ **Comando perigoso** (`rm -rf`, `git push main`, `supabase db push`) → alerta
- 💤 **Sessão ficou idle** ou **contexto foi compactado** → aviso discreto
- 🏷️ **(opcional)** Fala o nome do projeto antes do aviso, útil quando você tem várias sessões abertas

Você escolhe quais categorias quer ligar. Por padrão ele vem **minimalista** — só avisa o essencial, pra não virar barulho.

---

## Como instalar

### 1. Adicionar o marketplace (só a primeira vez)

No Claude Code, rode:

```
/plugin marketplace add michascorreia/claude-voice-notify
```

### 2. Instalar o plugin

```
/plugin install claude-voice-notify@michascorreia
```

Pronto. Já funciona com os avisos básicos ligados (permissão, idle, task concluída).

### 3. (Opcional) Configurar categorias

```
/voice-notify-config
```

Abre um checklist interativo onde você liga/desliga cada tipo de aviso e escolhe o idioma (pt-BR ou en-US).

### 4. (Opcional) Ligar o "nome do projeto"

Se quiser que o Claude fale o nome do repositório antes de cada aviso (útil pra quem mantém várias sessões abertas):

```
/voice-notify-setup
```

Isso instala o `edge-tts` (Python + Microsoft Edge TTS) localmente pra gerar neural voice do nome de cada projeto. Requer Python 3.10+ e internet na primeira geração.

---

## Categorias disponíveis

| # | Categoria | Quando toca | Default |
|---|-----------|-------------|---------|
| 1 | **Básico** | Claude pediu permissão / ficou idle / compactou contexto | ✅ ON |
| 2 | **Task concluída** | Claude terminou a tarefa | ✅ ON |
| 3 | **Build & Tests** | `npm run build`, `vitest`, `playwright`, `eslint`, `tsc` | ⬜ OFF |
| 4 | **Git & Deploy** | `gh pr create`, `supabase functions deploy`, `supabase db push`, `gitnexus` | ⬜ OFF |
| 5 | **Alertas** | `rm -rf`, `git push origin main`, `sudo`, `db push` | ⬜ OFF |
| 6 | **Nome do projeto** | Fala o nome do repo antes do aviso | ⬜ OFF (requer setup) |

---

## Como funciona por baixo

- 🎙️ **Áudios pré-gerados** (72 arquivos `.m4a`) usando Microsoft Edge TTS neural — voz **Francisca** (pt-BR) e **Jenny** (en-US)
- 🪝 **Hooks do Claude Code** — `PostToolUse`, `PreToolUse`, `Notification`, `Stop`, `PostCompact`
- 🎛️ **Config por usuário** em `~/.claude/plugins/data/.../config.json` (sobrevive a updates do plugin)
- 🔇 **Silenciar temporariamente**: `export VOICE_NOTIFY_OFF=1`

Zero dependência pra uso básico — áudios vêm prontos no plugin. Só o "nome do projeto" precisa de Python + internet.

---

## Limitações (sendo sincero)

### ❌ Só funciona no macOS
Usa `afplay` pra tocar áudio. Linux e Windows **não são suportados** por enquanto. Se houver demanda, dá pra abstrair, mas não é o caso hoje.

### ❌ Não é silencioso se você usa fone/música alta
Óbvio, mas vale falar: o ganho desaparece se você não consegue ouvir o áudio. Não tem fallback visual (notificação do sistema, por exemplo).

### ⚠️ Pode virar ruído se você ligar tudo
Quanto mais categorias ligadas, mais som. Recomendação: comece com o default (básico + task concluída), ligue outras só se sentir falta. Fadiga auditiva é real — se tocar demais, seu cérebro começa a ignorar.

### ⚠️ "Nome do projeto" tem custo na primeira vez
Gera áudio via rede (Microsoft Edge TTS, grátis, mas precisa de internet). A primeira vez que você entra num projeto demora ~2-3s. Depois fica em cache.

### ⚠️ Detecção de comandos é por pattern-matching
A categorização de build/git/alerts é baseada em strings no comando (ex: `npm run build`, `gh pr create`). Se você roda com alias ou via npm script custom, pode não disparar. É simples de estender (editar `hooks/voice-notify.sh`).

### ⚠️ Sem testes automatizados ainda
Os hooks funcionam, mas não tem suite de testes. Refactor futuro tem que ser feito com cuidado.

### ⚠️ Nicho
Plugins de Claude Code ainda são uma categoria nova. Não espere comunidade enorme — é ferramenta útil pra quem já vive no Claude Code.

---

## Desinstalar / silenciar

**Silenciar temporariamente** (sem desinstalar):
```bash
export VOICE_NOTIFY_OFF=1
```

**Desligar categorias específicas:**
```
/voice-notify-config
```

**Desinstalar completo:**
```
/plugin uninstall claude-voice-notify@michascorreia
```

---

## Pra quem é útil

- 👨‍💻 **Devs que usam Claude Code várias horas por dia** e se cansam de alt-tab
- 🔄 **Quem trabalha com builds/testes longos** e quer saber o momento exato que termina
- 🧑‍🚀 **Quem mantém múltiplas sessões** do Claude abertas (com o "nome do projeto" ligado dá pra saber qual tocou)
- 🎧 **Quem trabalha em ambiente silencioso** e pode ouvir o áudio sem atrapalhar

**Pra quem NÃO é útil:**
- Usuários Linux/Windows (por enquanto)
- Quem trabalha sempre de fone com música alta
- Quem acha TTS irritante (gosto pessoal)

---

## Repositório

https://github.com/michascorreia/claude-voice-notify

**Feedback, issues e PRs são bem-vindos.**

---

> Feito pra resolver um incômodo real. Se ajudar você a render mais, missão cumprida. Se virar ruído, desliga tudo tranquilo — o plugin é pensado pra ser opt-in progressivo.
