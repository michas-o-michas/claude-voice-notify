#!/bin/bash
# PostToolUse: speaks when long-running commands complete.
# Silence: export VOICE_NOTIFY_OFF=1

[ "$VOICE_NOTIFY_OFF" = "1" ] && exit 0

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$PLUGIN_DIR/config.txt"
LANG_CODE=$(grep -E "^LANG=" "$CONFIG" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"
AUDIO_DIR="$PLUGIN_DIR/audio/$LANG_CODE"

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
[ "$TOOL_NAME" != "Bash" ] && exit 0

COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
IS_ERROR=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_response',{}).get('isError', False))" 2>/dev/null)
INTERRUPTED=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_response',{}).get('interrupted', False))" 2>/dev/null)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)

[ "$INTERRUPTED" = "True" ] && exit 0

KEY=""
case "$COMMAND" in
  *"npm run build"*|*"vite build"*|*"npm run build:dev"*|*"pnpm build"*|*"yarn build"*)
    KEY="build" ;;
  *"playwright test"*|*"npx playwright"*)
    KEY="e2e" ;;
  *"vitest run"*|*"npm run test"*|*"npm test"*|*"pnpm test"*|*"yarn test"*)
    if echo "$COMMAND" | grep -qE "watch|--watch"; then exit 0; fi
    KEY="tests" ;;
  *"supabase functions deploy"*)
    KEY="deploy" ;;
  *"supabase db push"*)
    KEY="migration" ;;
  *"npm run lint"*|*"eslint ."*|*"eslint src"*|*"pnpm lint"*|*"yarn lint"*)
    KEY="lint" ;;
  *"tsc --noEmit"*|*"npm run typecheck"*|*"pnpm typecheck"*|*"yarn typecheck"*)
    KEY="typecheck" ;;
  *"gh pr create"*)
    KEY="pr" ;;
  *"npx gitnexus analyze"*)
    KEY="gitnexus" ;;
  *)
    exit 0 ;;
esac

SUFFIX="ok"
[ "$IS_ERROR" = "True" ] && SUFFIX="fail"

AUDIO="$AUDIO_DIR/${KEY}_${SUFFIX}.m4a"
[ ! -f "$AUDIO" ] && exit 0

PROJ_AUDIO=""
if [ -n "$CWD" ]; then
  PROJ_AUDIO=$("$PLUGIN_DIR/hooks/gen-project.sh" "$CWD" "$PLUGIN_DIR" "$LANG_CODE" 2>/dev/null)
fi

if [ -n "$PROJ_AUDIO" ] && [ -f "$PROJ_AUDIO" ]; then
  (afplay "$PROJ_AUDIO" >/dev/null 2>&1; afplay "$AUDIO" >/dev/null 2>&1) &
else
  afplay "$AUDIO" >/dev/null 2>&1 &
fi

exit 0
