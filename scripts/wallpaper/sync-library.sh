#!/usr/bin/env bash

set -euo pipefail

readonly repo_dir="${REPO_DIR:-${HOME}/nixos}"
readonly target_dir="${HOME}/.local/share/wallpapers/library"

mkdir -p "${target_dir}"

python3 - <<'PY'
import os
from pathlib import Path

repo_dir = Path(os.environ.get("REPO_DIR", str(Path.home() / "nixos")))
target_dir = Path.home() / ".local" / "share" / "wallpapers" / "library"
target_dir.mkdir(parents=True, exist_ok=True)

for existing in target_dir.iterdir():
    if existing.is_symlink() or existing.is_file():
        existing.unlink()

sources = [
    ("local", Path.home() / "wallpapers"),
    ("eljangus", repo_dir / "Wallpapers-reference" / "Walls"),
]

valid_suffixes = {".png", ".jpg", ".jpeg", ".webp", ".gif", ".avif"}

for prefix, root in sources:
    if not root.exists():
        continue
    for path in sorted(root.rglob("*")):
        if not path.is_file() or path.suffix.lower() not in valid_suffixes:
            continue
        safe_name = path.name.replace("/", "-")
        link_path = target_dir / f"{prefix}-{safe_name}"
        if link_path.exists() or link_path.is_symlink():
            link_path.unlink()
        link_path.symlink_to(path)
PY
