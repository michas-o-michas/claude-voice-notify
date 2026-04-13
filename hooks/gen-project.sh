#!/bin/bash
# Generates and caches per-project name audio on demand.
# Usage: gen-project.sh <cwd> <plugin_dir> <lang_code>
# Prints the audio path to stdout (empty if not yet generated — triggers background generation).

CWD="$1"
PLUGIN_DIR="$2"
LANG_CODE="${3:-pt-BR}"

[ -z "$CWD" ] || [ -z "$PLUGIN_DIR" ] && exit 0
[ ! -d "$CWD" ] && exit 0

# Only announce inside a git repo
if ! git -C "$CWD" rev-parse --show-toplevel >/dev/null 2>&1; then
  exit 0
fi

# Use repo root name as project name (avoids "src" or "components")
REPO_ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null)
[ -z "$REPO_ROOT" ] && REPO_ROOT="$CWD"

PROJ_DIR="$PLUGIN_DIR/audio/projects"
mkdir -p "$PROJ_DIR"

RAW=$(basename "$REPO_ROOT")
SLUG=$(echo "$RAW" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g; s/--*/-/g; s/^-//; s/-$//')
[ -z "$SLUG" ] && exit 0

AUDIO="$PROJ_DIR/${SLUG}.m4a"
LOCK="$PROJ_DIR/${SLUG}.lock"

if [ -f "$AUDIO" ]; then
  echo "$AUDIO"
  exit 0
fi

[ -f "$LOCK" ] && exit 0

# Resolve display text: check aliases file first
ALIASES="$PROJ_DIR/aliases.txt"
TEXT=""
if [ -f "$ALIASES" ]; then
  TEXT=$(grep -E "^${SLUG}=" "$ALIASES" 2>/dev/null | head -1 | sed "s/^${SLUG}=//")
fi
[ -z "$TEXT" ] && TEXT=$(echo "$SLUG" | sed 's/[-_]/ /g')

# Resolve edge-tts binary
EDGE_TTS="$PLUGIN_DIR/.venv/bin/edge-tts"
[ ! -x "$EDGE_TTS" ] && exit 0

# Resolve voice for language
case "$LANG_CODE" in
  en-US) VOICE="en-US-JennyNeural" ;;
  *)     VOICE="pt-BR-FranciscaNeural" ;;
esac

# Generate in background (non-blocking)
(
  touch "$LOCK"
  TMP_MP3="$PROJ_DIR/${SLUG}.tmp.mp3"
  "$EDGE_TTS" --voice "$VOICE" --rate "+5%" \
    --text "$TEXT" --write-media "$TMP_MP3" >/dev/null 2>&1
  if [ -f "$TMP_MP3" ]; then
    afconvert -f m4af -d aac "$TMP_MP3" "$AUDIO" >/dev/null 2>&1
    rm -f "$TMP_MP3"
  fi
  rm -f "$LOCK"
) &

exit 0
