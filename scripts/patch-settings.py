#!/usr/bin/env python3
"""Patches ~/.claude/settings.json to register claude-voice-notify hooks.
Idempotent: running twice does not duplicate entries."""
import json
import shutil
import sys
from pathlib import Path

PLUGIN_DIR = Path(sys.argv[1]).resolve()
SETTINGS_PATH = Path(sys.argv[2]).resolve()

HOOK_COMMANDS = {
    "PostToolUse": str(PLUGIN_DIR / "hooks" / "voice-notify.sh"),
    "PreToolUse":  str(PLUGIN_DIR / "hooks" / "voice-alert.sh"),
    "PostCompact": str(PLUGIN_DIR / "hooks" / "voice-compact.sh"),
    "Notification":str(PLUGIN_DIR / "hooks" / "voice-attention.sh"),
}

PRETOOLUSE_MATCHER = "Bash"
PRETOOLUSE_TIMEOUT = 3
DEFAULT_TIMEOUT = 3


def load(path: Path) -> dict:
    try:
        return json.loads(path.read_text())
    except Exception:
        return {}


def hook_block(command: str, timeout: int, matcher: str | None = None) -> dict:
    block: dict = {"type": "command", "command": command, "timeout": timeout}
    if matcher:
        block["matcher"] = matcher
    return block


def ensure_hook(hooks: list[dict], command: str, timeout: int) -> bool:
    """Returns True if the hook was added (not already present)."""
    for h in hooks:
        if h.get("type") == "command" and h.get("command") == command:
            return False
    hooks.append({"type": "command", "command": command, "timeout": timeout})
    return True


def patch(settings: dict) -> dict:
    h = settings.setdefault("hooks", {})

    # PostToolUse — matcher Bash
    post = h.setdefault("PostToolUse", [])
    # Find or create the Bash-matched block
    bash_block = next(
        (b for b in post if isinstance(b, dict) and b.get("matcher") == "Bash"),
        None,
    )
    if bash_block is None:
        bash_block = {"matcher": "Bash", "hooks": []}
        post.append(bash_block)
    ensure_hook(bash_block.setdefault("hooks", []),
                HOOK_COMMANDS["PostToolUse"], DEFAULT_TIMEOUT)

    # PreToolUse — matcher Bash
    pre = h.setdefault("PreToolUse", [])
    bash_pre = next(
        (b for b in pre if isinstance(b, dict) and b.get("matcher") == "Bash"),
        None,
    )
    if bash_pre is None:
        bash_pre = {"matcher": "Bash", "hooks": []}
        pre.append(bash_pre)
    ensure_hook(bash_pre.setdefault("hooks", []),
                HOOK_COMMANDS["PreToolUse"], PRETOOLUSE_TIMEOUT)

    # PostCompact
    compact = h.setdefault("PostCompact", [])
    compact_block = next(
        (b for b in compact if isinstance(b, dict) and "hooks" in b),
        None,
    )
    if compact_block is None:
        compact_block = {"hooks": []}
        compact.append(compact_block)
    ensure_hook(compact_block.setdefault("hooks", []),
                HOOK_COMMANDS["PostCompact"], DEFAULT_TIMEOUT)

    # Notification
    notif = h.setdefault("Notification", [])
    notif_block = next(
        (b for b in notif if isinstance(b, dict) and "hooks" in b),
        None,
    )
    if notif_block is None:
        notif_block = {"hooks": []}
        notif.append(notif_block)
    ensure_hook(notif_block.setdefault("hooks", []),
                HOOK_COMMANDS["Notification"], DEFAULT_TIMEOUT)

    return settings


def main() -> None:
    settings = load(SETTINGS_PATH)

    # Backup
    backup = SETTINGS_PATH.with_suffix(".json.bak")
    shutil.copy2(SETTINGS_PATH, backup)

    patched = patch(settings)
    SETTINGS_PATH.write_text(json.dumps(patched, indent=2, ensure_ascii=False) + "\n")
    print(f"  Backup: {backup}")
    print(f"  Patched: {SETTINGS_PATH}")


if __name__ == "__main__":
    main()
