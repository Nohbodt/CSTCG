#!/usr/bin/env python3
"""Smoke-test portable exports and write build validation receipts.

Runs the real Linux executable and loads the Windows PCK with Linux Godot.
This does not claim native Windows execution.
"""

import json
import os
from pathlib import Path
import subprocess
import tempfile

ROOT = Path(__file__).resolve().parents[1]


def main() -> None:
    linux = str(ROOT / "builds/linux/CSTCG.x86_64")
    windows_pack = str(ROOT / "builds/windows/CSTCG.pck")
    cases = [
        ("linux-manager", [linux, "--headless", "--quit-after", "900", "--", "--ephemeral", "--ui-smoke"], "CSTCG_UI_SMOKE:"),
        ("linux-map", [linux, "--headless", "--quit-after", "900", "--", "--ephemeral", "--spatial-smoke"], "CSTCG_SPATIAL_UI:"),
        ("linux-live-match", [linux, "--headless", "--quit-after", "900", "--", "--ephemeral", "--live-match-smoke"], "CSTCG_LIVE_UI:"),
        ("windows-pack-manager", ["godot", "--headless", "--main-pack", windows_pack, "--quit-after", "900", "--", "--ephemeral", "--ui-smoke"], "CSTCG_UI_SMOKE:"),
        ("windows-pack-map", ["godot", "--headless", "--main-pack", windows_pack, "--quit-after", "900", "--", "--ephemeral", "--spatial-smoke"], "CSTCG_SPATIAL_UI:"),
        ("windows-pack-live-match", ["godot", "--headless", "--main-pack", windows_pack, "--quit-after", "900", "--", "--ephemeral", "--live-match-smoke"], "CSTCG_LIVE_UI:"),
    ]
    output_dir = ROOT / "builds/validation"
    output_dir.mkdir(parents=True, exist_ok=True)
    receipt = {"checks": [], "windows_native_execution": "not run; resource pack checked with Linux Godot"}
    with tempfile.TemporaryDirectory(prefix="cstcg-export-check-") as directory:
        env = os.environ.copy()
        for name in ["CACHE", "CONFIG", "DATA"]:
            path = Path(directory) / name.lower()
            path.mkdir()
            env[f"XDG_{name}_HOME"] = str(path)
        for name, command, marker in cases:
            result = subprocess.run(command, env=env, cwd=directory,
                                    capture_output=True, text=True, timeout=90)
            output = result.stdout + result.stderr
            (output_dir / f"{name}.log").write_text(output)
            print(output.strip())
            errors = any(line.startswith(("ERROR:", "SCRIPT ERROR:")) for line in output.splitlines())
            if result.returncode or marker not in output or errors:
                raise RuntimeError(f"Export check failed: {name}")
            receipt["checks"].append({"case": name, "status": "passed"})
    (ROOT / "builds/export-validation.json").write_text(json.dumps(receipt, indent=2) + "\n")
    print("CSTCG_EXPORT_CHECKS: 6 checks passed; native Windows not run")


if __name__ == "__main__":
    main()
