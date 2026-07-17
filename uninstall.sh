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

# Detect OS to pick correct venv binary path
case "$(uname -s 2>/dev/null)" in
  MINGW*|MSYS*|CYGWIN*|Windows_NT*)
    VENV_PY="$VENV/Scripts/python.exe"
    ;;
  *)
    VENV_PY="$VENV/bin/python3"
    ;;
esac

echo "→ Removing hooks from $SETTINGS..."
"$VENV_PY" "$PLUGIN_DIR/scripts/patch-settings.py" --uninstall "$PLUGIN_DIR" "$SETTINGS"
echo "✓ Hooks removed"
echo ""
echo "Note: audio files and venv remain in $PLUGIN_DIR"
echo "To remove everything: rm -rf $PLUGIN_DIR"
