#!/bin/bash
# play_audio <file> — cross-platform: afplay (macOS) or ffplay (Linux)
play_audio() {
  if command -v afplay >/dev/null 2>&1; then
    afplay "$1" >/dev/null 2>&1
  elif command -v ffplay >/dev/null 2>&1; then
    ffplay -nodisp -autoexit -loglevel quiet "$1" >/dev/null 2>&1
  fi
}
