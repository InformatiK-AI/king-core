---
name: github-ops
description: "Automatización de operaciones GitHub. Usar cuando se necesite: crear PRs, hacer commits con conventional commits, push branches, comentar en PRs, gestionar issues, o cualquier operación de GitHub."
version: 2.0
internal: true
---

# GitHub Ops — Automatización GitHub

Operaciones automatizadas de GitHub que otros skills invocan internamente.

## Agente involucrado
- **@devops** → Operaciones de GitHub

## CASTLE: N/A (infraestructura)

## Operaciones

### Commit
Conventional commits con co-authoring automático.

```bash
# Formato
git commit -m "$(cat <<'EOF'
type(scope): descripción corta

[Cuerpo opcional con más detalle]

[Closes #issue-number]

Co-Authored-By: Claude Opus 4.6 <noreply@anthropic.com>
EOF
)"
```

**Tipos válidos**: feat, fix, refactor, docs, chore, test, style, perf, ci
**Scopes comunes**: pipeline, ui, api, i18n, security, config

**Reglas**:
- Solo commitear archivos relevantes (nunca .env, node_modules)
- Mensaje basado en el contexto del skill activo
- Siempre incluir Co-Authored-By

### Push
```bash
# Branch nuevo
git push -u origin [branch-name]

# Branch existente
git push origin [branch-name]
```

**Verificaciones pre-push**:
- Branch tiene tracking correcto
- No hay conflictos con remote
- Nunca force push a main o develop sin confirmación

### PR Create

**Validación GitFlow obligatoria** — Antes de crear cualquier PR, verificar que el target branch es correcto:

| Branch origen | Target correcto | Target PROHIBIDO |
|---------------|----------------|-----------------|
| `feature/*` | `develop` | `master`/`main` |
| `hotfix/*` | `master`/`main` | — |
| `release/*` | `master`/`main` | — |
| `develop` | `release/*` | `master` directamente |

```bash
# Verificar ANTES de crear el PR:
CURRENT=$(git branch --show-current)
if [[ "$CURRENT" == feature/* ]]; then
  BASE="develop"  # NUNCA master para features
elif [[ "$CURRENT" == hotfix/* || "$CURRENT" == release/* ]]; then
  BASE="master"
fi
echo "PR target validado: $CURRENT → $BASE"
```

Si el base branch no coincide con la tabla, **BLOQUEAR** y advertir al usuario.

```bash
gh pr create \
  --base "$BASE" \
  --title "[type]: descripción corta" \
  --body "$(cat <<'EOF'
## Summary
- [Cambio principal 1]
- [Cambio principal 2]

## CASTLE Score
[Resultado del assessment si se ejecutó]

## Test Plan
- [ ] Verificación 1
- [ ] Verificación 2

## Issues
Closes #[número]

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)" \
  --assignee @me
```

**Labels automáticos**:
- feat → `feature`
- fix → `bugfix`
- refactor → `refactor`
- release → `release`

### PR Comment
```bash
# Comentar CASTLE Score
gh pr comment [PR#] --body "[CASTLE Report]"

# Comentar QA results
gh pr comment [PR#] --body "[QA Report]"
```

### PR Merge
```bash
# Features: squash merge
gh pr merge [PR#] --squash --delete-branch

# Releases: merge commit
gh pr merge [PR#] --merge

# REQUIERE confirmación para branches protegidos
```

### Issue Management
```bash
# Cerrar issue via commit message: "Closes #N"
# NOTA GitFlow: "Closes #N" solo funciona al mergear al branch DEFAULT (master).
# Para merges a develop (features), usar cierre explicito:
gh issue close N --comment "Cerrado al mergear PR #[PR#] a develop"
gh issue edit N --add-label "status:done"

# Crear issue para findings
gh issue create --title "[finding]" --body "[detalle]" --label "bug"
```

### GitFlow Issue Closure

> **Limitación GitHub**: `Closes #N`, `Fixes #N`, `Resolves #N` solo auto-cierran issues al mergear al branch **default** (`master`). Features mergean a `develop` → issues NO se cierran automáticamente.
>
> **Solución del framework**: El skill `/merge` incluye Fase 3.5 que ejecuta `gh issue close` explícitamente después de mergear a `develop`.

| Target branch | Método de cierre |
|---------------|-----------------|
| `develop` | Explícito: `gh issue close N` (Fase 3.5 de /merge) |
| `master` | Automático: GitHub procesa `Closes #N` del PR |

## Integración con skills

| Skill | Operación GitHub |
|-------|-----------------|
| build | commit + push + PR create |
| fix | commit + push + PR create (con "Fixes #N") |
| merge | PR merge |
| promote | PR create (promote report) |
| release | PR create + merge + tag + release |
| qa | PR comment (QA report) |
| review | PR comment (review findings) |

---

## Session Tracking

> Skill standalone. Ver convención en `skills/_shared/standalone-convention.md`.
