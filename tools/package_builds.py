#!/usr/bin/env python3
"""Package committed source and validated exports for local tester downloads."""

import argparse
from datetime import datetime, timezone
import hashlib
import json
from pathlib import Path
import subprocess
import tarfile
import zipfile

ROOT = Path(__file__).resolve().parents[1]


def package(output: Path) -> None:
    commit = subprocess.check_output(["git", "-C", str(ROOT), "rev-parse", "HEAD"], text=True).strip()
    dirty = subprocess.check_output(["git", "-C", str(ROOT), "status", "--porcelain"], text=True)
    if dirty:
        raise RuntimeError("Commit source changes before packaging so BUILD_INFO matches the source ZIP")
    validation = json.loads((ROOT / "builds/export-validation.json").read_text())
    if len(validation["checks"]) != 8 or any(c["status"] != "passed" for c in validation["checks"]):
        raise RuntimeError("Run tools/check_exports.py successfully before packaging")
    output.mkdir(parents=True, exist_ok=True)
    version = subprocess.check_output(["godot", "--version"], text=True).strip()
    info = (
        "CSTCG / Club Circuit — alpha 0.5 / pack-origin card backs\n"
        f"Source commit: {commit}\n"
        f"Engine: {version}\n"
        f"Packaged (UTC): {datetime.now(timezone.utc).isoformat()}\n"
        "Source origin-ledger/migration, two-size menu UI, pack backs/animation/resume, causal matches, and 12 map routes passed.\n"
        "Playable catalogue: 30 players / 2 alpha pack products. Series 1 remains a design kit.\n"
        "Linux executable and Windows PCK manager/map/live-match checks passed.\n"
        "Native Windows hardware execution was not performed.\n"
        "See TESTING.md for test steps and current prototype scope.\n"
    )
    build_info = ROOT / "builds/BUILD_INFO.txt"
    build_info.write_text(info)
    common = [(ROOT / "TESTING.md", "TESTING.md"), (build_info, "BUILD_INFO.txt"),
              (ROOT / "builds/export-validation.json", "export-validation.json")]
    for path in sorted((ROOT / "builds/notices").glob("*.txt")):
        common.append((path, "LICENSES/" + path.name))
    for path in sorted((ROOT / "assets/fonts").glob("LICENSE-*.txt")):
        common.append((path, "LICENSES/" + path.name))
    if len(common) < 7:
        raise RuntimeError("Generate engine/font notices before packaging")
    windows_zip = output / "CSTCG-Windows-x86_64.zip"
    with zipfile.ZipFile(windows_zip, "w", compression=zipfile.ZIP_DEFLATED, compresslevel=6) as archive:
        for path in sorted((ROOT / "builds/windows").iterdir()):
            if path.is_file():
                archive.write(path, path.name)
        for path, name in common:
            archive.write(path, name)
    linux_tar = output / "CSTCG-Linux-x86_64.tar.gz"
    with tarfile.open(linux_tar, "w:gz") as archive:
        for path in sorted((ROOT / "builds/linux").iterdir()):
            archive.add(path, arcname=path.name)
        for path, name in common:
            archive.add(path, arcname=name)
    source_zip = output / "CSTCG-Godot-Project.zip"
    subprocess.run(["git", "-C", str(ROOT), "archive", "--format=zip", "--prefix=CSTCG/",
                    f"--output={source_zip}", commit], check=True)
    with zipfile.ZipFile(source_zip, "a", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("CSTCG/BUILD_INFO.txt", info)
    archives = [windows_zip, linux_tar, source_zip]
    checksums = []
    for path in archives:
        with path.open("rb") as f:
            digest = hashlib.file_digest(f, "sha256").hexdigest()
        checksums.append(f"{digest}  {path.name}")
        print(f"{path.name}: {path.stat().st_size:,} bytes")
    (output / "SHA256SUMS.txt").write_text("\n".join(checksums) + "\n")
    (output / "BUILD_INFO.txt").write_text(info)


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path("/workspace/releases/cstcg-preview"))
    package(parser.parse_args().output.resolve())
