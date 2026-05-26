---
name: merge
description: "Merge de branch con quality gates pre y post merge"
argument-hint: "[branch|PR#] [--workflow <nombre>]"
allowed-tools: [Read, Grep, Glob, Bash, Agent]
---

# /merge

Ejecutar merge con verificaciones de calidad.

## Instrucciones

1. Invocar el skill `merge`
2. Si se proporciona un branch name o PR#, usar ese como target
3. Si no se proporciona, mostrar branches disponibles y pedir al usuario que elija
4. Seguir todas las fases: Pre-merge → Architecture → Merge → Post-merge → Report
5. IMPORTANTE: Para branches protegidos (main), SIEMPRE pedir confirmación al usuario antes de ejecutar

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual.
