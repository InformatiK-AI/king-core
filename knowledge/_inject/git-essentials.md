# Git Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia completa: `universal/git-mastery.md`

## Comandos Críticos

| Acción | Comando | NUNCA |
|--------|---------|-------|
| Stage archivos | `git add {archivo}` | `git add -A` o `git add .` |
| Commit | `git commit -m "type: msg"` | Sin mensaje descriptivo |
| Merge | `git merge --no-ff` | `git merge` (fast-forward) |
| Revert | `git revert HEAD` | `git reset --hard` en shared |
| Sync | `git pull --rebase` | `git pull` con divergencia |

## Conventional Commits

```bash
# Formato
type(scope): description

# Tipos
feat:     Nueva funcionalidad
fix:      Bug fix
docs:     Documentación
refactor: Refactorización
test:     Tests
chore:    Mantenimiento
```

## GitFlow Básico

```
feature/* → develop → release/* → main
                ↑                    │
                └────── hotfix/* ────┘
```

## Señales de Alerta

- Commit a main/develop directo
- `--force` en branches compartidos
- Merge sin `--no-ff` (pierde historial)
- `git add .` (incluye archivos no deseados)
- Commits WIP en branch compartido

## Checklist Pre-Push

- [ ] Commits siguen conventional commits
- [ ] Sin archivos sensibles (.env, keys)
- [ ] Tests pasan localmente
- [ ] Branch actualizado con base
- [ ] Sin merge conflicts pendientes
