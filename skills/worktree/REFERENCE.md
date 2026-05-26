# Worktree - Reference

> Archivo parte de: `skills/worktree/SKILL.md`
> Contiene: Comando `status` detallado, integración con skills, nomenclatura, principios y registro de sesión.

---

## status

Muestra estado completo del sistema de worktrees con información de sincronización y sugerencias.

**Proceso:**

1. Obtener estado de cada ambiente:
```bash
# Para cada ambiente (dev, qa, prod)
cd .worktrees/environments/{env}
BRANCH=$(git branch --show-current)
if [ -z "$BRANCH" ]; then
  BRANCH="(detached at $(git rev-parse --short HEAD))"
fi
COMMIT=$(git rev-parse --short HEAD)
CHANGES=$(git status --porcelain | wc -l)
```

2. Calcular diferencias entre ambientes:
```bash
# Obtener commits de cada ambiente (funciona con detached HEAD)
DEV_COMMIT=$(cd .worktrees/environments/dev && git rev-parse HEAD)
QA_COMMIT=$(cd .worktrees/environments/qa && git rev-parse HEAD)
PROD_COMMIT=$(cd .worktrees/environments/prod && git rev-parse HEAD)

# Commits de dev adelante de qa
DEV_AHEAD_QA=$(git rev-list ${QA_COMMIT}..${DEV_COMMIT} --count 2>/dev/null || echo "?")

# Commits de qa adelante de prod
QA_AHEAD_PROD=$(git rev-list ${PROD_COMMIT}..${QA_COMMIT} --count 2>/dev/null || echo "?")

# Cálculo robusto usando merge-base (funciona con detached HEAD)
MERGE_BASE=$(git merge-base ${QA_COMMIT} ${DEV_COMMIT} 2>/dev/null)
if [ -n "$MERGE_BASE" ]; then
  COMMITS_AHEAD=$(git rev-list ${MERGE_BASE}..${DEV_COMMIT} --count 2>/dev/null || echo "?")
  COMMITS_BEHIND=$(git rev-list ${MERGE_BASE}..${QA_COMMIT} --count 2>/dev/null || echo "?")
else
  # Fallback: branches divergieron completamente
  COMMITS_AHEAD="?"
  COMMITS_BEHIND="?"
  echo "⚠️ No se pudo calcular merge-base entre qa/ y dev/"
fi
```

> **Nota**: Se usan commits resueltos en vez de nombres de branch porque
> qa/ y prod/ usan detached HEAD (no tienen branch local).
> El cálculo con `merge-base` es más robusto cuando los ambientes divergen
> (ej: reset parcial en qa/) ya que detecta tanto commits adelante como atrás.

3. Obtener estado de QA de features activos:
```bash
# Leer active-features.json
# Para cada feature, buscar sesión de QA
# Determinar estado: PENDING, APPROVED, REJECTED
```

4. Detectar solapamiento de archivos entre features activos:
```bash
# Para cada par de features activos, comparar archivos modificados
for FEATURE in .worktrees/features/*/; do
  cd "$FEATURE"
  # Archivos modificados respecto a develop
  git diff --name-only origin/develop...HEAD
done
# Cruzar listas para encontrar archivos modificados en común
```

**Salida mejorada:**

```
=== ESTADO DE AMBIENTES ===

ENV     BRANCH      COMMIT    SYNC STATUS
───────────────────────────────────────────────────
dev/    develop     abc123d   [3 commits ahead of qa]
qa/     develop     def456a   [2 commits ahead of prod]
prod/   main        789xyz0   [v1.2.3] ✓ sincronizado

Última sincronización:
  dev:  2026-02-03 10:00
  qa:   2026-02-02 15:30
  prod: 2026-02-01 09:00

=== FEATURES ACTIVOS ===

WORKTREE                    BRANCH                    COMMITS   QA STATUS
────────────────────────────────────────────────────────────────────────
feature-001-auth-login      feature/001-auth-login    +5        PENDING
feature-002-payments        feature/002-payments      +2        APPROVED
hotfix-123-urgent           hotfix/123-urgent         +1        APPROVED

=== SOLAPAMIENTO DE ARCHIVOS ===

(Solo se muestra si hay archivos modificados en común entre features)

ADVERTENCIA: Los siguientes features modifican archivos en común:

feature/001-auth-login × feature/002-payments:
  - src/middleware/session.ts
  - src/types/user.ts

Recomendación: Sincronizar con develop frecuentemente (/worktree update)

**Algoritmo de detección de solapamiento:**
1. Para cada feature activo: obtener lista de archivos modificados via `git diff --name-only origin/develop...{feature_branch}`
2. Comparar listas par a par (feature A vs feature B)
3. Intersección no vacía = solapamiento detectado
4. Reportar archivos en común con ambos features que los modifican

=== ACCIONES SUGERIDAS ===

→ /promote --to qa     (2 features con QA aprobado listos)
→ /qa --env qa         (validar integración post-promote)
→ /release             (qa-env aprobado, considerar release)
→ /qa --issue 001      (feature pendiente de QA individual)
```

**Lógica de sugerencias:**

| Condición | Sugerencia |
|-----------|------------|
| Features con QA aprobado + dev ahead of qa | `/promote --to qa` |
| qa promovido + sin qa-env session | `/qa --env qa` |
| qa-env aprobado + sin features pendientes | `/release` |
| Features sin QA | `/qa --issue {id}` |
| Release completado + main ahead of prod | `/promote --to prod` |
| Features en worktrees sin commits | `/build` |

**Información adicional:**

- Si hay cambios sin commit en algún worktree, mostrar advertencia
- Si hay worktrees huérfanos, sugerir `/worktree cleanup`
- Mostrar tiempo desde última promoción si hay promotions.json

---

## Integración con otros skills

| Skill | Integración |
|-------|-------------|
| `/build` | Crea worktree automático si habilitado |
| `/merge` | Cleanup automático post-merge, auto-sync dev/ |
| `/qa` | Opción de probar en worktree o ambiente QA |
| `/promote` | Sincroniza ambientes con verificación de calidad |
| `/release` | Auto-ejecuta `/promote --to prod` post-release |

---

## Nomenclatura GitFlow

| Tipo | Branch | Worktree |
|------|--------|----------|
| Feature | `feature/{slug}` | `.worktrees/features/feature-{slug}` |
| Hotfix | `hotfix/{id}-{slug}` | `.worktrees/features/hotfix-{id}-{slug}` |
| Release | `release/v{X.Y.Z}` | - |

---

## Principios

- **Aislamiento**: Cada feature tiene su espacio
- **Ambientes permanentes**: dev, qa, prod siempre disponibles
- **Cleanup automático**: Features eliminados tras merge
- **Protección de prod**: Readonly

---

## Registro de sesión

> Formato base: `skills/session-management/SKILL.md`

Crea `.king/sessions/YYYY-MM-DD-worktree-{comando}.md` con:
- **Estado actual**: Resumen del sistema de worktrees
