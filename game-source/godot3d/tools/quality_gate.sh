#!/usr/bin/env bash
# Strict public 3D-only smoke gate. Does not access signing secrets or old private code.
set -euo pipefail
project="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo_root="$(cd "$project/../.." && pwd)"
godot="${GODOT_BIN:-godot}"
logdir="${QA_LOG_DIR:-$project/qa-logs}"
mkdir -p "$logdir"
python3 "$repo_root/tools/audit_public_3d.py" --root "$repo_root" | tee "$logdir/public-3d-source-audit.log"
timeout 150s "$godot" --headless --editor --path "$project" --import > "$logdir/godot-3d-import.log" 2>&1 || {
  cat "$logdir/godot-3d-import.log"
  exit 10
}
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Parser Error:|Failed to load script' "$logdir/godot-3d-import.log"; then
  cat "$logdir/godot-3d-import.log"
  exit 11
fi
timeout 150s "$godot" --headless --path "$project" --script res://tests/world_smoke.gd > "$logdir/godot-3d-smoke.log" 2>&1 || {
  cat "$logdir/godot-3d-smoke.log"
  exit 12
}
cat "$logdir/godot-3d-smoke.log"
grep -Fq 'PASS PUBLIC CANGLAN 3D GODOT SCENE' "$logdir/godot-3d-smoke.log"
if grep -Eq 'SCRIPT ERROR:|Parse Error:|Parser Error:|Assertion failed|Failed to load script|ERROR:|WARNING:.*unsafe' "$logdir/godot-3d-smoke.log"; then
  echo 'BLOCKED: Godot engine emitted an error'
  exit 13
fi
echo 'PASS PUBLIC 3D SOURCE TECHNICAL QA ONLY — VISUAL ANDROID RELEASE UNAPPROVED'
