---
name: castle
description: "Ejecutar evaluación CASTLE (Contracts, Architecture, Security, Testing, Logging, Environment)"
argument-hint: "[--layer C|A|S|T|L|E]"
allowed-tools: [Read, Grep, Glob, Bash, Agent]
---

# /castle

Ejecutar CASTLE Assessment del proyecto.

## Instrucciones

1. Invocar el skill `castle`
2. Si se especifica `--layer`, evaluar solo esa capa:
   - `--layer C` → Solo Contracts
   - `--layer A` → Solo Architecture
   - `--layer S` → Solo Security
   - `--layer T` → Solo Testing
   - `--layer L` → Solo Logging
   - `--layer E` → Solo Environment
3. Si no se especifica layer, evaluar las 6 capas completas
4. Leer los checks de cada capa desde `skills/castle/references/[capa]-checks.md`
5. Generar reporte con formato visual CASTLE (caja ASCII)
6. Determinar veredicto: FORTIFIED, CONDITIONAL, o BREACHED
