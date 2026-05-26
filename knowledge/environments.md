# Configuración de Ambientes

> **Nota**: Este archivo es generado por `/genesis` para cada proyecto específico.
> Documenta los ambientes reales del proyecto que usa King Framework.

## Ambientes

| Ambiente | Branch    | URL / Puerto | Descripción        |
|----------|-----------|--------------|--------------------|
| dev      | develop   | localhost:*  | Desarrollo local   |
| qa       | develop   | ...          | QA / Staging       |
| prod     | main      | ...          | Producción         |

## Variables de entorno por ambiente

### Desarrollo (dev)
```env
NODE_ENV=development
# ... variables del proyecto
```

### QA
```env
NODE_ENV=staging
# ... variables del proyecto
```

### Producción
```env
NODE_ENV=production
# ... variables del proyecto
```

## Worktrees

```
.worktrees/
├── environments/
│   ├── dev/   → develop
│   ├── qa/    → origin/develop
│   └── prod/  → origin/main
└── features/
    └── [feature-name]/
```

## Health checks

```bash
# Verificar que el ambiente está corriendo
# [comando específico del proyecto - ver CLAUDE.md]
```

---
*Poblar este archivo durante la ejecución de `/genesis`.*
