---
description: Install edge-tts in the plugin data dir so voice-notify can speak project names (neural TTS, requires Python 3.10+ and internet).
---

You are helping the user install the optional **project name** feature of `claude-voice-notify`. This uses Microsoft Edge TTS (free, neural voices) to say the project name before each notification.

## Steps

1. **Explain what will happen** and confirm:
   - "Vou configurar a fala do nome do projeto. Isso requer Python 3.10+ e internet na primeira vez. Posso seguir?"
   - If the user declines, stop.

2. **Detect Python 3.10+** via Bash:
   ```bash
   command -v python3.13 || command -v python3.12 || command -v python3.11 || command -v python3.10 || command -v python3
   ```
   If none found or version < 3.10, tell the user: "❌ Python 3.10+ não encontrado. Instale com: `brew install python@3.12`" and stop.

3. **Create venv and install edge-tts** inside `${CLAUDE_PLUGIN_DATA}` (persistent across plugin updates):
   ```bash
   VENV="${CLAUDE_PLUGIN_DATA}/.venv"
   mkdir -p "${CLAUDE_PLUGIN_DATA}"
   python3 -m venv "$VENV"
   "$VENV/bin/pip" install -q --upgrade pip
   "$VENV/bin/pip" install -q edge-tts
   ```

4. **Enable the feature flags**:
   - Touch the flag file: `touch "${CLAUDE_PLUGIN_DATA}/project-name-enabled"`
   - Update `${CLAUDE_PLUGIN_DATA}/config.json` — set `features.project_name = true` (preserve other fields; create file with defaults if absent).

5. **Copy aliases example** so the user can customize project names:
   - If `${CLAUDE_PLUGIN_DATA}/projects/aliases.txt` doesn't exist, copy `${CLAUDE_PLUGIN_ROOT}/audio/projects/aliases.example.txt` to it.
   - Show the path and tell the user: "Edite esse arquivo pra customizar como o nome sai falado (ex: `meu-repo=Meu Projeto`)."

6. **Confirm** to the user:
   - "✓ Pronto! Na próxima vez que um hook tocar dentro de um repositório git, o nome do projeto será falado antes. Primeira vez por projeto pode demorar alguns segundos pra gerar."

## Notes

- Always use `${CLAUDE_PLUGIN_DATA}` (NOT `${CLAUDE_PLUGIN_ROOT}`). The venv must survive plugin updates.
- Never run `pip install` outside the venv.
- If pip install fails (no internet, etc), report the error and leave no half-state.
