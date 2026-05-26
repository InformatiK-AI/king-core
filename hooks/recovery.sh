#!/bin/bash
# King Framework — Post-compaction session recovery
# Triggered by hooks.json SessionStart compact event
# Exit 0: recovery done or not needed (never blocks session)

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel 2>/dev/null) || {
  echo "[King] Sin repositorio git. Sin recovery."
  exit 0
}

REGISTRY="$ROOT/.king/registry.md"
if [ ! -f "$REGISTRY" ]; then
  echo "[King] Sin .king/ - sin recovery disponible."
  exit 0
fi

echo "[King] Post-compaction recovery via .king/"
awk '/^## Active Workflows/{f=1;next}/^## /{if(f)exit}f{print}' "$REGISTRY" | head -10

LATEST=$(ls -t "$ROOT/.king/sessions/"*.md 2>/dev/null | head -1 || true)
if [ -n "$LATEST" ]; then
  echo "[King] Ultima sesion: $LATEST"
  head -20 "$LATEST"
fi

for s in "$ROOT/.king/sdd/"*/state.yaml; do
  [ -f "$s" ] && echo "[King] SDD activo: $s"
done

ARCHIVE="$ROOT/.king/registry-archive.md"
if [ -f "$ARCHIVE" ]; then
  echo "[King] Registry archive (ultimas 10 lineas):"
  tail -10 "$ARCHIVE"
fi

exit 0
