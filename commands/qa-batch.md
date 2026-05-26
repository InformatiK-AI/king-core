---
name: qa-batch
description: "Ejecutar QA en batch: evalúa múltiples issues/PRs antes de promover"
argument-hint: "[--workflow <nombre>]"
allowed-tools: [Read, Grep, Glob, Bash, Agent]
---

# /qa-batch

Alias de `/qa --batch`. Invocar el skill `qa-batch` para evaluar un conjunto de issues antes de promover.

## Instrucciones

Invocar el skill `qa-batch` directamente.

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow.
Si no se proporciona, detectar automáticamente del branch actual.
