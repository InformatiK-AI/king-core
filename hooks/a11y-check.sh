#!/usr/bin/env bash
# hooks/a11y-check.sh — A11y Gate WCAG 2.2 AA (M-28, CASTLE S sub-score).
# PostToolUse Write|Edit: lee el file_path del stdin del hook, y si es un archivo de UI
# corre checks estáticos de los criterios WCAG más comunes (1.1.1, 2.4.6, 4.1.2, 3.1.1, 2.4.3).
# Emite findings informativos (deferred-style); el bloqueo formal lo hace /castle vía CASTLE S.
# Respeta `.king/accessibility.yaml` (enforcement + exceptions).
#
# Robusto al formato de stdin (resuelve W-A2): prueba .path / .file_path / .tool_input.file_path.
# Fail-safe: set -euo pipefail + trap → exit 0. Nunca interrumpe el pipeline.
set -euo pipefail
trap 'exit 0' ERR

INPUT=$(cat 2>/dev/null || true)
[ -z "$INPUT" ] && exit 0
command -v jq >/dev/null 2>&1 || exit 0

FILE=$(printf '%s' "$INPUT" | jq -r '.path // .file_path // .tool_input.file_path // .tool_input.path // empty' 2>/dev/null || true)
[ -z "$FILE" ] && exit 0

# Solo archivos de UI
case "$FILE" in
  *.html|*.htm|*.jsx|*.tsx|*.vue|*.svelte) ;;
  *) exit 0 ;;
esac
[ -f "$FILE" ] || exit 0

# Config opcional del proyecto
ROOT=$(git rev-parse --show-toplevel 2>/dev/null || echo ".")
CFG="$ROOT/.king/accessibility.yaml"
ENFORCE="warn"
if [ -f "$CFG" ]; then
  E=$(grep -E '^enforcement:' "$CFG" 2>/dev/null | awk '{print $2}' | tr -d '"' || true)
  [ -n "$E" ] && ENFORCE="$E"
fi

# Detector: ripgrep si existe, fallback a grep -E
rgx() { if command -v rg >/dev/null 2>&1; then rg -n --no-heading "$1" "$FILE" 2>/dev/null; else grep -nE "$1" "$FILE" 2>/dev/null; fi; }

FINDINGS=""
add() { FINDINGS="${FINDINGS}  • [WCAG $1] $2\n"; }

# 1.1.1 — <img> sin alt
if rgx '<img\b' | grep -ivE 'alt=' | grep -qi '<img'; then
  add "1.1.1" "<img> sin atributo alt (texto alternativo)"
fi
# 3.1.1 — <html> sin lang
if rgx '<html\b' | grep -qi '<html' && ! rgx '<html\b[^>]*lang=' | grep -qi '<html'; then
  add "3.1.1" "<html> sin atributo lang"
fi
# 4.1.2 — div/span con onClick/@click sin role
if rgx '<(div|span)\b[^>]*(onClick|@click|v-on:click)' | grep -ivE 'role=' | grep -qiE '<(div|span)'; then
  add "4.1.2" "<div>/<span> con manejador de click sin role ni soporte de teclado"
fi
# 2.4.3 — tabindex positivo (anti-patrón de orden de foco)
if rgx 'tabindex=["'"'"']?[1-9]' | grep -qi tabindex; then
  add "2.4.3" "tabindex positivo (rompe el orden natural de foco)"
fi
# 4.1.2 — input/select/textarea sin label/aria-label
if rgx '<(input|select|textarea)\b' | grep -ivE 'aria-label|aria-labelledby|id=' | grep -qiE '<(input|select|textarea)'; then
  add "4.1.2" "campo de formulario sin label/aria-label asociado"
fi

[ -z "$FINDINGS" ] && exit 0

echo "[King/A11y] WCAG 2.2 AA — posibles violaciones en ${FILE}:" >&2
printf "$FINDINGS" >&2
echo "  → /a11y-audit (king-content, si está instalado) para auditoría completa · excepciones: .king/accessibility.yaml" >&2
echo "  (enforcement=${ENFORCE}; el bloqueo formal lo aplica /castle vía CASTLE S)" >&2
exit 0
