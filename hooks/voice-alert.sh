#!/bin/bash
# PreToolUse: audio alert for destructive/sensitive actions.
# Does NOT block — uses Claude Code's ask system for actual confirmation.
# Silence: export VOICE_NOTIFY_OFF=1

[ "$VOICE_NOTIFY_OFF" = "1" ] && exit 0

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_name',''))" 2>/dev/null)
[ "$TOOL_NAME" != "Bash" ] && exit 0

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$PLUGIN_DIR/config.txt"
LANG_CODE=$(grep -E "^LANG=" "$CONFIG" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"
AUDIO_DIR="$PLUGIN_DIR/audio/$LANG_CODE"

COMMAND=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('tool_input',{}).get('command',''))" 2>/dev/null)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)

KEY=""
case "$COMMAND" in
  *"git push"*"origin main"*|*"git push"*"main"*|*"git push --force"*|*"git push -f"*)
    KEY="alert_push_main" ;;
  *"git push"*)
    KEY="alert_push" ;;
  *"supabase db reset"*)
    KEY="alert_db_reset" ;;
  *"supabase db push"*)
    if echo "$COMMAND" | grep -q "\-\-local"; then exit 0; fi
    KEY="alert_db_push" ;;
  *"supabase functions deploy"*)
    KEY="alert_func_deploy" ;;
  *"supabase secrets"*|*"supabase link"*)
    KEY="alert_db_prod" ;;
  *"rm -rf"*|*"rm -fr"*)
    KEY="alert_rm_rf" ;;
  *"rm "*)
    if echo "$COMMAND" | grep -qE "rm /tmp/|rm .*cache/"; then exit 0; fi
    KEY="alert_rm" ;;
  *"sudo "*)
    KEY="alert_sudo" ;;
  *"gh pr merge"*)
    KEY="alert_pr_merge" ;;
  *"gh release"*)
    KEY="alert_release" ;;
  *"npm publish"*|*"pnpm publish"*|*"yarn publish"*)
    KEY="alert_publish" ;;
  *"pkill"*|*"kill -9"*)
    KEY="alert_kill" ;;
  *"git reset --hard"*|*"git clean -f"*|*"git checkout ."*|*"git restore ."*|*"git branch -D"*)
    KEY="alert_destructive" ;;
  *)
    exit 0 ;;
esac

AUDIO="$AUDIO_DIR/${KEY}.m4a"
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
