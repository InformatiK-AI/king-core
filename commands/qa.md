---
name: qa
description: "Ejecutar quality assurance: estándar (por feature), batch (múltiples issues), o con verificación de ambiente"
argument-hint: "[--standard|--batch|--env] [--issue N] [--workflow <nombre>]"
allowed-tools: [Read, Grep, Glob, Bash, Agent]
---

# /qa

Ejecutar quality assurance según el modo seleccionado.

## Instrucciones

Determinar el modo de QA según los argumentos:

### `--standard` (default si no se especifica modo)
Invocar el skill `qa` para evaluar una feature o cambio individual.
Si se proporciona `--issue N`, focalizar el QA en ese issue.

### `--batch`
Invocar el skill `qa-batch` para evaluar un conjunto de issues antes de promover a QA.
Recopilar todos los issues/PRs pendientes y evaluarlos como batch.

### `--env`
Invocar el skill `qa-env` para ejecutar QA con verificación de ambiente.
Incluye smoke tests, health checks, y environment parity además del QA estándar.

Si no se especifica modo, usar `--standard` por defecto.

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual.
