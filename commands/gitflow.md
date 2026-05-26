---
name: gitflow
description: "Gestión GitFlow: estado de branches, crear branches, sincronizar worktrees"
argument-hint: "[status|branch|sync] [nombre]"
allowed-tools: [Read, Grep, Glob, Bash]
---

# /gitflow

Gestionar el flujo GitFlow y worktrees del proyecto.

## Instrucciones

1. Invocar el skill `gitflow`
2. Según el subcomando:

### `status` (default)
Mostrar estado de branches, worktrees y ambientes.

### `branch [tipo] [nombre]`
Crear un branch nuevo:
- `branch feature mi-feature` → `feature/mi-feature` desde develop
- `branch hotfix fix-critico` → `hotfix/fix-critico` desde main
- `branch release v4.5.0` → `release/v4.5.0` desde develop

### `sync`
Sincronizar worktrees con sus branches remotos.

Si no se especifica subcomando, mostrar `status` por defecto.
