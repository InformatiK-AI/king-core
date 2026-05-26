---
name: qa-env
description: "Ejecutar QA con verificación de ambiente: smoke tests, health checks, environment parity"
argument-hint: "[--workflow <nombre>]"
allowed-tools: [Read, Grep, Glob, Bash, Agent]
---

# /qa-env

Alias de `/qa --env`. Invocar el skill `qa-env` para ejecutar QA con verificación de ambiente completa.

## Instrucciones

Invocar el skill `qa-env` directamente.

Incluye: smoke tests, health checks, environment parity checks, y CASTLE E layer.

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow.
Si no se proporciona, detectar automáticamente del branch actual.
