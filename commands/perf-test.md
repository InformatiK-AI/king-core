---
name: perf-test
description: "Generar y ejecutar performance tests con gates p95/p99 (k6/Artillery/Gatling)"
argument-hint: "[--feature <name>] [--env local|staging] [--tool k6|artillery|gatling] [--scenario smoke|load|spike|all]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /perf-test

Generar scripts de performance testing, ejecutarlos contra el entorno objetivo y comparar
p50/p95/p99 contra los budgets de `.king/performance.yaml`. Alimenta CASTLE E y `/promote`.

## Instrucciones

1. Invocar el skill `perf-test` usando la herramienta Skill
2. Argumentos opcionales:
   - `--feature <name>`: nombre del feature/endpoint group a testear
   - `--env local|staging`: entorno objetivo (default: `local`; staging/prod requieren confirmación)
   - `--tool k6|artillery|gatling`: herramienta (default: k6; gatling para stacks JVM)
   - `--scenario smoke|load|spike|all`: escenario (default: smoke automático)
3. Seguir todas las fases del skill en orden:
   - Discover Endpoints + Thresholds → Generate Scripts → Smoke → Load + Metrics → Gate + CASTLE E → Session → Guide
4. Agentes coordinados: @performance (principal), @architect (endpoints críticos), @developer (optimizaciones)
5. IMPORTANTE: NUNCA correr load/spike contra staging/prod sin confirmación explícita
6. IMPORTANTE: usar variables de entorno para URLs y auth — nunca hardcodear secrets

Si no se proporciona `--feature`, el skill descubre endpoints del router; si no encuentra,
solicita la lista al usuario.
