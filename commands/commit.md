---
name: commit
description: "Crear commit con conventional commits y co-authoring automático"
argument-hint: "[type(scope): message]"
allowed-tools: [Bash, Read, Grep]
---

# /commit

Crear un commit con conventional commits.

## Instrucciones

1. Invocar el skill `github-ops` (operación commit)
2. Si se proporciona mensaje, usarlo directamente
3. Si no se proporciona mensaje:
   a. Analizar los cambios staged (`git diff --staged`)
   b. Analizar los cambios unstaged (`git diff`)
   c. Generar mensaje de conventional commit basado en los cambios
4. Formato del commit:
   ```
   type(scope): descripción corta

   [Cuerpo opcional]

   Co-Authored-By: Claude <noreply@anthropic.com>
   ```
5. Tipos válidos: feat, fix, refactor, docs, chore, test, style, perf, ci
6. NUNCA commitear .env o node_modules
