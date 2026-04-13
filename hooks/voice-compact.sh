#!/bin/bash
# PostCompact: speaks when context is auto-compacted.
# Silence: export VOICE_NOTIFY_OFF=1

[ "$VOICE_NOTIFY_OFF" = "1" ] && exit 0

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CONFIG="$PLUGIN_DIR/config.txt"
LANG_CODE=$(grep -E "^LANG=" "$CONFIG" 2>/dev/null | head -1 | sed "s/^LANG=//" | tr -d '[:space:]')
[ -z "$LANG_CODE" ] && LANG_CODE="pt-BR"

AUDIO="$PLUGIN_DIR/audio/$LANG_CODE/compact_done.m4a"
[ -f "$AUDIO" ] && afplay "$AUDIO" >/dev/null 2>&1 &

exit 0
