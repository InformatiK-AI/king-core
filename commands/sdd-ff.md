---
name: sdd-ff
description: "Fast-forward SDD: ejecuta propose → spec → design → tasks en secuencia para cambios bien entendidos."
argument-hint: "<change-name>"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent]
---
# /sdd-ff

Meta-comando SDD fast-forward. Procesado por el orquestador.

Secuencia: `sdd-propose` → `sdd-spec` || `sdd-design` (paralelo) → `sdd-tasks`

Referencia: `agents/_common/protocols/sdd-orchestrator.md`
