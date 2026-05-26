---
name: review
description: "Code review stack-agnostic con orquestación de agentes especializados"
argument-hint: "[PR number | branch | files]"
allowed-tools: [Read, Grep, Glob, Bash, Agent]
---

# /review

Ejecutar workflow de revisión de código.

## Instrucciones

1. Invocar el skill `review`
2. Si se proporciona un número de PR, obtener los cambios via `gh pr diff`
3. Si se proporciona un branch o archivos, analizar los cambios directamente
4. Orquestar agentes especializados según el tipo de cambios detectados
5. Generar reporte con hallazgos categorizados por severidad
6. IMPORTANTE: Nunca aprobar código con vulnerabilidades de seguridad críticas
