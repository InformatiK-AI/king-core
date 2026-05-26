---
name: pr
description: "Gestión de Pull Requests: crear, revisar, o mergear PRs"
argument-hint: "[create|review|merge] [PR#] [--workflow <nombre>]"
allowed-tools: [Read, Grep, Glob, Bash, Agent]
---

# /pr

Gestionar Pull Requests en GitHub.

## Instrucciones

1. Invocar el skill `github-ops`
2. Según el subcomando:

### `create`
Crear un PR desde el branch actual hacia develop (o el target apropiado).
Usar template con Summary, CASTLE Score, Test Plan, Issues.

### `review [PR#]`
Invocar el skill `review` para revisar el PR especificado.
Obtener diff con `gh pr diff [PR#]` y ejecutar review completo.

### `merge [PR#]`
Invocar el skill `merge` para mergear el PR especificado.
Verificar quality gates antes de proceder.

Si no se especifica subcomando, mostrar PRs abiertos con `gh pr list`.

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual.
