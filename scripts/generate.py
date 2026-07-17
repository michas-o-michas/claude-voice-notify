#!/usr/bin/env python3
"""Pre-generates m4a notification audio using edge-tts.
Supports pt-BR (FranciscaNeural) and en-US (JennyNeural).

Usage:
  python3 scripts/generate.py              # regenerate all languages
  python3 scripts/generate.py pt-BR        # only pt-BR
  python3 scripts/generate.py en-US        # only en-US
"""
import shutil
import subprocess
import sys
from pathlib import Path

PLUGIN_DIR = Path(__file__).parent.parent
VENV_EDGE_TTS = PLUGIN_DIR / ".venv" / "bin" / "edge-tts"

LANGUAGES = {
    "pt-BR": {
        "voice": "pt-BR-FranciscaNeural",
        "rate": "+5%",
        "phrases": {
            # PostToolUse
            "build_ok":         "Compilação concluída.",
            "build_fail":       "Compilação falhou.",
            "e2e_ok":           "Testes de ponta a ponta concluídos.",
            "e2e_fail":         "Testes de ponta a ponta falharam.",
            "tests_ok":         "Testes concluídos.",
            "tests_fail":       "Testes falharam.",
            "deploy_ok":        "Implantação da função concluída.",
            "deploy_fail":      "Implantação da função falhou.",
            "migration_ok":     "Migração concluída.",
            "migration_fail":   "Migração falhou.",
            "lint_ok":          "Análise de código concluída.",
            "lint_fail":        "Análise de código falhou.",
            "typecheck_ok":     "Verificação de tipos concluída.",
            "typecheck_fail":   "Verificação de tipos falhou.",
            "pr_ok":            "Solicitação de mesclagem criada.",
            "pr_fail":          "Solicitação de mesclagem falhou.",
            "gitnexus_ok":      "Indexação do código concluída.",
            "gitnexus_fail":    "Indexação do código falhou.",
            # Destructive alerts (PreToolUse)
            "alert_push_main":  "Atenção. Envio direto para a branch principal.",
            "alert_push":       "Atenção. Envio para o repositório remoto.",
            "alert_db_reset":   "Atenção. Reset do banco de dados.",
            "alert_db_push":    "Atenção. Envio de migração para o banco.",
            "alert_db_prod":    "Cuidado. Comando de banco em produção.",
            "alert_rm":         "Atenção. Remoção de arquivos.",
            "alert_rm_rf":      "Cuidado. Remoção recursiva de arquivos.",
            "alert_sudo":       "Atenção. Comando com privilégio de administrador.",
            "alert_pr_merge":   "Atenção. Mesclagem de solicitação de pull.",
            "alert_release":    "Atenção. Criação de release.",
            "alert_publish":    "Atenção. Publicação de pacote.",
            "alert_kill":       "Atenção. Encerramento de processo.",
            "alert_func_deploy":"Atenção. Implantação de função em produção.",
            "alert_destructive":"Atenção. Ação destrutiva detectada.",
            # PostCompact
            "compact_done":     "Contexto compactado.",
            # Notification
            "attention_perm":   "Precisa de autorização.",
            "attention_idle":   "Aguardando sua resposta.",
            "attention_generic":"Precisa da sua atenção.",
            # Stop (task completed)
            "task_done":        "Pronto.",
        },
    },
    "en-US": {
        "voice": "en-US-JennyNeural",
        "rate": "+5%",
        "phrases": {
            # PostToolUse
            "build_ok":         "Build complete.",
            "build_fail":       "Build failed.",
            "e2e_ok":           "End-to-end tests complete.",
            "e2e_fail":         "End-to-end tests failed.",
            "tests_ok":         "Tests complete.",
            "tests_fail":       "Tests failed.",
            "deploy_ok":        "Function deployed.",
            "deploy_fail":      "Function deployment failed.",
            "migration_ok":     "Migration complete.",
            "migration_fail":   "Migration failed.",
            "lint_ok":          "Lint check complete.",
            "lint_fail":        "Lint check failed.",
            "typecheck_ok":     "Type check complete.",
            "typecheck_fail":   "Type check failed.",
            "pr_ok":            "Pull request created.",
            "pr_fail":          "Pull request failed.",
            "gitnexus_ok":      "Code index complete.",
            "gitnexus_fail":    "Code index failed.",
            # Destructive alerts (PreToolUse)
            "alert_push_main":  "Warning. Pushing to main branch.",
            "alert_push":       "Warning. Pushing to remote.",
            "alert_db_reset":   "Warning. Database reset.",
            "alert_db_push":    "Warning. Pushing migration to database.",
            "alert_db_prod":    "Caution. Production database command.",
            "alert_rm":         "Warning. Removing files.",
            "alert_rm_rf":      "Caution. Recursive file removal.",
            "alert_sudo":       "Warning. Running as administrator.",
            "alert_pr_merge":   "Warning. Merging pull request.",
            "alert_release":    "Warning. Creating release.",
            "alert_publish":    "Warning. Publishing package.",
            "alert_kill":       "Warning. Terminating process.",
            "alert_func_deploy":"Warning. Deploying function to production.",
            "alert_destructive":"Warning. Destructive action detected.",
            # PostCompact
            "compact_done":     "Context compacted.",
            # Notification
            "attention_perm":   "Needs authorization.",
            "attention_idle":   "Waiting for your response.",
            "attention_generic":"Needs your attention.",
            # Stop (task completed)
            "task_done":        "Done.",
        },
    },
}


def detect_platform() -> str:
    """Detect OS: 'mac', 'linux', or 'windows'."""
    import platform
    system = platform.system().lower()
    if system == "darwin":
        return "mac"
    elif system == "windows":
        return "windows"
    else:
        return "linux"


def find_converter(platform: str):
    """Find audio converter. Returns (converter_cmd, output_ext, needs_ffmpeg)."""
    if platform == "mac":
        if shutil.which("afconvert"):
            return (["afconvert", "-f", "m4af", "-d", "aac"], "m4a", False)
    # Linux, Windows, or macOS fallback: try ffmpeg
    if shutil.which("ffmpeg"):
        return (
            ["ffmpeg", "-y", "-i", "INPUT", "-c:a", "aac", "-b:a", "128k", "OUTPUT"],
            "m4a",
            True,
        )
    # No converter: keep mp3 (all players support it)
    return (None, "mp3", False)


def generate_lang(lang_code: str, platform: str, converter_info: tuple) -> None:
    config = LANGUAGES[lang_code]
    voice = config["voice"]
    rate = config["rate"]
    phrases = config["phrases"]
    out_dir = PLUGIN_DIR / "audio" / lang_code
    out_dir.mkdir(parents=True, exist_ok=True)

    edge_tts = str(VENV_EDGE_TTS) if VENV_EDGE_TTS.exists() else "edge-tts"

    converter_cmd, output_ext, needs_ffmpeg = converter_info

    total = len(phrases)
    print(f"\n[{lang_code}] voice={voice}  ({total} files → audio/{lang_code}/)")
    for i, (key, text) in enumerate(phrases.items(), 1):
        mp3_path = out_dir / f"{key}.mp3"
        out_path = out_dir / f"{key}.{output_ext}"
        print(f"  [{i:02d}/{total}] {key}: \"{text}\"")
        subprocess.run(
            [edge_tts, "--voice", voice, "--rate", rate, "--text", text, "--write-media", str(mp3_path)],
            check=True, capture_output=True,
        )
        if output_ext == "mp3":
            # No conversion needed, rename mp3 to final name if needed
            if out_path != mp3_path and out_path.exists():
                out_path.unlink()
            if mp3_path.exists() and out_path != mp3_path:
                mp3_path.rename(out_path)
        else:
            # Convert using afconvert or ffmpeg
            if out_path.exists():
                out_path.unlink()
            if needs_ffmpeg:
                # ffmpeg: replace INPUT/OUTPUT placeholders
                cmd = [c.replace("INPUT", str(mp3_path)).replace("OUTPUT", str(out_path)) if c in ("INPUT", "OUTPUT") else c for c in converter_cmd]
            else:
                # afconvert
                cmd = converter_cmd + [str(mp3_path), str(out_path)]
            subprocess.run(cmd, check=True, capture_output=True)
            mp3_path.unlink(missing_ok=True)

    print(f"  Done. {total} files in audio/{lang_code}/")


def main() -> None:
    target = sys.argv[1] if len(sys.argv) > 1 else None
    langs = [target] if target and target in LANGUAGES else list(LANGUAGES.keys())

    platform = detect_platform()
    converter_info = find_converter(platform)
    _, output_ext, _ = converter_info

    print(f"Platform: {platform}  Output format: {output_ext}")
    print(f"Generating audio for: {', '.join(langs)}")
    for lang in langs:
        generate_lang(lang, platform, converter_info)

    print("\nAll done.")


if __name__ == "__main__":
    main()
