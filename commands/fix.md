---
name: fix
description: "Corrección sistemática de bugs: reproduce → root cause → fix → test → verify"
argument-hint: "[issue# o descripción del bug] [--workflow <nombre>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /fix

Ejecutar workflow de corrección sistemática de bugs.

## Instrucciones

1. Invocar el skill `fix`
2. El argumento puede ser un número de issue (#N) o una descripción del bug
3. Si es un issue#, obtener detalles con `gh issue view N`
4. Seguir las fases: Reproduce → Root Cause → Fix → Test → Regression → Report
5. IMPORTANTE: Atacar la causa raíz, NO el síntoma
6. El fix debe ser MÍNIMO — no refactorizar código circundante

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual.
