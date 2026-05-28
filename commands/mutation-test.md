---
name: mutation-test
description: "Ejecutar mutation testing y evaluar el mutation score contra el gate CASTLE T"
argument-hint: "[--scope <path>] [--threshold <n>] [--full] [--stack <ts|python|java|go>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /mutation-test

Ejecutar mutation testing sobre un scope acotado, interpretar el mutation score, listar los
mutantes sobrevivientes y evaluar el gate CASTLE T.

## Instrucciones

1. Invocar el skill `mutation-test` usando la herramienta Skill
2. Argumentos opcionales:
   - `--scope <path>`: archivo o módulo a mutar (default: changed files del branch)
   - `--threshold <n>`: override del `mutation_score_threshold` (default: `.king/coverage.yaml` o 80)
   - `--full`: ejecutar sobre el proyecto completo (REQUIERE confirmación; advierte el costo)
   - `--stack <ts|python|java|go>`: forzar stack si la autodetección falla
3. Seguir todas las fases del skill en orden:
   - Detect Tool + Scope → Run → Parse Surviving Mutants → Generate Test Stubs → CASTLE T Gate → Session → Guide
4. Agentes coordinados: @qa (principal), @developer (test stubs)
5. IMPORTANTE: NUNCA ejecutar sobre el proyecto completo sin confirmación explícita (riesgo de timeout)
6. IMPORTANTE: NUNCA modificar código de producción para matar mutantes — sólo generar tests

Si no se especifica `--scope`, el skill usa los changed files del branch actual.
