#!/bin/bash
# claude-voice-notify — uninstall.sh
# Removes plugin hooks from ~/.claude/settings.json
set -e

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SETTINGS="$HOME/.claude/settings.json"

[ ! -f "$SETTINGS" ] && echo "settings.json not found, nothing to do." && exit 0

VENV="$PLUGIN_DIR/.venv"
if [ ! -d "$VENV" ]; then
  echo "✗ venv not found. Run install.sh first."
  exit 1
fi

echo "→ Removing hooks from $SETTINGS..."
"$VENV/bin/python3" "$PLUGIN_DIR/scripts/patch-settings.py" --uninstall "$PLUGIN_DIR" "$SETTINGS"
echo "✓ Hooks removed"
echo ""
echo "Note: audio files and venv remain in $PLUGIN_DIR"
echo "To remove everything: rm -rf $PLUGIN_DIR"
