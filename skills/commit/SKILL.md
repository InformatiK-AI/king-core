---
name: commit
version: 2.0
internal: true
description: "Crear commits con conventional commits. Analiza los cambios staged y genera un mensaje de commit semántico."
---

# Commit — Conventional Commits

Crea commits siguiendo el estándar de Conventional Commits.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] No hay cambios staged (`git diff --staged` vacío)
- [ ] El path de destino incluye `.env` con valores reales o `node_modules/`

### REQUIRED OUTPUTS
> 📦 Resultados que DEBEN producirse al finalizar

- [ ] Commit creado con mensaje en formato Conventional Commits

---

## Formato de Commit

```
type(scope): descripción corta en imperativo

[Cuerpo opcional: contexto del cambio]
```

### Tipos válidos

| Tipo | Cuándo usar |
|------|-------------|
| `feat` | Nueva funcionalidad |
| `fix` | Corrección de bug |
| `refactor` | Refactoring sin cambio de comportamiento |
| `docs` | Documentación |
| `test` | Tests (nuevos o modificados) |
| `chore` | Tareas de mantenimiento, config |
| `style` | Formato, sin cambio de lógica |
| `perf` | Mejora de performance |
| `ci` | Changes en CI/CD |

## Proceso

1. Si se proporciona mensaje: usar directamente en el formato estándar
2. Si no se proporciona:
   a. `git diff --staged` → analizar archivos y cambios
   b. Generar tipo y scope apropiados
   c. Descripción corta en imperativo, <72 caracteres
3. Ejecutar: `git commit -m "$(cat <<'EOF'\n{mensaje}\nEOF\n)"`

## Ver también

- **Command**: `commands/commit.md`
- **GitHub Ops**: `skills/github-ops/SKILL.md` (operaciones avanzadas de Git)
