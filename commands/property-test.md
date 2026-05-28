---
name: property-test
description: "Generar property-based tests para funciones puras e invariantes de dominio"
argument-hint: "[--target <path>] [--invariant \"<texto>\"] [--runs <n>] [--stack <ts|python|java|go>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /property-test

Generar property-based tests que ejercitan boundary conditions y valores extremos, con
shrinking automático para reportar el contraejemplo mínimo. Alimenta CASTLE T.

## Instrucciones

1. Invocar el skill `property-test` usando la herramienta Skill
2. Argumentos opcionales:
   - `--target <path>`: función o módulo objetivo
   - `--invariant "<texto>"`: invariante en lenguaje natural (ej: "el descuento nunca supera el precio")
   - `--runs <n>`: número de ejemplos por propiedad (default: 100)
   - `--stack <ts|python|java|go>`: forzar stack si la autodetección falla
3. Seguir todas las fases del skill en orden:
   - Identify Functions + Invariants → Select Property Types → Generate → Run + Counterexamples → CASTLE T Evidence → Session → Guide
4. Agentes coordinados: @qa (principal), @developer (arbitraries tipados)
5. IMPORTANTE: fijar SIEMPRE una semilla reproducible; reportar el contraejemplo mínimo tras shrinking

Si no se proporciona `--target`, el skill intenta inferir la función del contexto; si no puede,
solicita el target al usuario.
