#!/bin/bash
# Notification: speaks when Claude needs permission or is waiting for input.
# Silence: export VOICE_NOTIFY_OFF=1

[ "$VOICE_NOTIFY_OFF" = "1" ] && exit 0

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$PLUGIN_DIR/config.txt"
LANG_CODE=$(grep -E "^LANG=" "$CONFIG" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"
AUDIO_DIR="$PLUGIN_DIR/audio/$LANG_CODE"

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('message',''))" 2>/dev/null)
CWD=$(echo "$INPUT" | python3 -c "import sys,json; print(json.load(sys.stdin).get('cwd',''))" 2>/dev/null)

KEY="attention_generic"
case "$MESSAGE" in
  *"permission"*|*"permissao"*|*"approve"*|*"authorize"*) KEY="attention_perm" ;;
  *"waiting"*|*"idle"*|*"input"*)                         KEY="attention_idle" ;;
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
