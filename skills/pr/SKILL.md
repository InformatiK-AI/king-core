---
name: pr
version: 2.0
internal: true
description: "Gestión de Pull Requests: crear PRs con template estándar, revisar código de un PR, o mergear PR con quality gates."
---

# PR — Gestión de Pull Requests

Crea, revisa y mergea Pull Requests con quality gates integrados.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] (`create`) No hay commits nuevos en el branch actual respecto a develop
- [ ] (`merge`) QA no aprobado o CASTLE BREACHED

### REQUIRED OUTPUTS
> 📦 Resultados por operación

- [ ] (`create`) PR creado en GitHub con template completo
- [ ] (`review`) Review report con veredicto y hallazgos
- [ ] (`merge`) Branch mergeada, PR cerrado

---

## Operaciones

### `create`
Crea un PR desde el branch actual hacia develop (o target especificado).

**Template de PR:**
```markdown
## Summary
- [Cambio principal]

## CASTLE Score
C [--] A [--] S [--] T [--] L [--] E [--]
Veredicto: [FORTIFIED|CONDITIONAL|BREACHED]

## Test Plan
- [ ] Tests unitarios ejecutados
- [ ] Acceptance criteria verificados

## Issues relacionados
Closes #[número]
```

### `review [PR#]`
Obtiene el diff del PR y ejecuta el skill `/review` completo.

```bash
gh pr diff [PR#]   # Obtener cambios
gh pr view [PR#]   # Ver descripción y contexto
```

### `merge [PR#]`
Verifica quality gates y ejecuta el skill `/merge`.

```bash
gh pr merge [PR#] --squash  # o --merge según convención del proyecto
```

## Ver también

- **Command**: `commands/pr.md`
- **GitHub Ops**: `skills/github-ops/SKILL.md`
- **Merge**: `skills/merge/SKILL.md`
- **Review**: `skills/review/SKILL.md`
