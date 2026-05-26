---
name: release
description: "Crear release GitFlow completo: certificación CASTLE, version bump, tag, GitHub release"
argument-hint: "[vX.Y.Z] [--workflow <nombre>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /release

Ejecutar workflow de release GitFlow completo.

## Instrucciones

1. Invocar el skill `release`
2. El argumento es la versión del release (ej: v4.5.0)
3. Si no se proporciona versión, sugerir la siguiente basándose en conventional commits:
   - feat → minor bump
   - fix → patch bump
   - BREAKING CHANGE → major bump
4. Seguir las 14 fases del skill
5. IMPORTANTE: CASTLE debe ser FORTIFIED para proceder con el release
6. IMPORTANTE: Merge a main REQUIERE confirmación del usuario

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual.
