# claude-voice-notify

> Voice notifications for [Claude Code](https://claude.ai/code) — speaks when Claude asks permission, finishes a task, and (optionally) when builds, tests, deploys and destructive commands happen.

Uses pre-generated neural TTS audio (Microsoft Edge — **FranciscaNeural** pt-BR / **JennyNeural** en-US). Zero dependencies for basic use.

## Install

```
/plugin marketplace add michascorreia/claude-voice-notify
/plugin install claude-voice-notify@michascorreia
```

That's it. After restarting Claude Code, the plugin speaks by default when:

- Claude needs **permission** or is **waiting** for input
- Claude **finishes** a task (short "Pronto." / "Done.")
- Context is **compacted** automatically

**macOS only** (uses `afplay`).

## Configure

Run the config command to toggle categories:

```
/voice-notify-config
```

A checklist appears — enable only what you want:

| Category | Default | What it speaks |
|---|---|---|
| **Básico** | ✅ ON | permission, idle, compacted |
| **Task concluída** | ✅ ON | short "Pronto." when Claude stops |
| **Build & Tests** | ⬜ OFF | build, tests, lint, typecheck, e2e |
| **Git & Deploy** | ⬜ OFF | PR, deploy, migration, gitnexus |
| **Alertas** | ⬜ OFF | `git push main`, `rm -rf`, `db push`, `sudo`, etc. |
| **Nome do projeto** | ⬜ OFF | speaks project name before each cue |

You can also switch language (`pt-BR` / `en-US`) from the same command.

## Project name (optional, neural)

To have the plugin say your **project name** (e.g., "Licita Pública") before each notification:

```
/voice-notify-setup
```

This installs Python + `edge-tts` inside the plugin's data directory (persists across updates, isolated from your system). After setup, names are generated once per project on first trigger and cached.

Customize pronunciation in `${CLAUDE_PLUGIN_DATA}/projects/aliases.txt`:

```
my-repo-slug=My Project Name
licita-publica=Licita Pública
```

## Silence all notifications

```bash
export VOICE_NOTIFY_OFF=1
```

Add to your shell profile to persist.

## Detected commands

| Category | Commands |
|---|---|
| Build | `npm run build`, `vite build`, `pnpm build`, `yarn build` |
| Tests | `vitest run`, `npm test`, `pnpm test` |
| E2E | `playwright test`, `npx playwright` |
| Lint | `npm run lint`, `eslint .` |
| Typecheck | `tsc --noEmit`, `npm run typecheck` |
| Deploy | `supabase functions deploy` |
| Migration | `supabase db push` |
| PR | `gh pr create` |
| GitNexus | `npx gitnexus analyze` |
| Alerts | `git push` (main/force), `rm -rf`, `supabase db push/reset`, `sudo`, `npm publish`, `gh release`, `kill -9`, destructive git |

Edit `hooks/voice-notify.sh` or `hooks/voice-alert.sh` to add more.

## Uninstall

```
/plugin uninstall claude-voice-notify@michascorreia
```

## Development

Regenerate audio after editing `scripts/generate.py`:

```bash
./install.sh      # creates venv, installs edge-tts, regenerates audio
```

## License

MIT © [michascorreia](https://github.com/michascorreia)
