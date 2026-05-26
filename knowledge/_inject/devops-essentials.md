# DevOps Essentials (para inyección)

> Versión compacta para inyección en agents. Referencia completa: `knowledge/domain/infrastructure.md`

## GitFlow Rápido

| Rama | Origen | Destino | Cuándo |
|------|--------|---------|--------|
| `feature/*` | develop | develop | Nueva funcionalidad |
| `hotfix/*` | main | main + develop | Bug crítico en prod |
| `release/*` | develop | main + tag | Preparar release |

## Worktree Strategy

```
.worktrees/environments/
├── dev/   → branch: develop (writable)
├── qa/    → branch: origin/develop (detached)
└── prod/  → branch: origin/main  (READONLY)
```

**Regla**: NUNCA escribir directamente en prod worktree.

## Promoción de Ambientes

```
develop → qa:   git fetch && git checkout origin/develop (en qa worktree)
qa → prod:      Requiere CASTLE FORTIFIED + tag + GitHub Release
```

## CI/CD Señales de Alerta

- Deploy manual sin smoke tests
- Pipeline sin health check post-deploy
- Variables de entorno hardcodeadas en el pipeline
- `force push` a main o develop
- Deploy a prod sin pasar por qa
- Sin rollback automático ante fallo

## Checklist Pre-Deploy

- [ ] CASTLE gate pasó (mínimo CONDITIONAL para dev/qa, FORTIFIED para prod)
- [ ] Health endpoint responde `/health` → `{"status":"ok"}`
- [ ] Smoke tests ejecutados en entorno destino
- [ ] Variables de entorno desde `.env` del worktree (no hardcodeadas)
- [ ] Worktree destino sincronizado con la rama correcta
- [ ] Plan de rollback documentado
