---
name: sdd-new
description: "Iniciar un nuevo cambio SDD. Crea la estructura OpenSpec y ejecuta sdd-init → sdd-explore → sdd-propose en secuencia."
argument-hint: "<change-name>"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent]
---
# /sdd-new

Meta-comando SDD. Procesado por el orquestador — no es un skill directo.

1. Crea `.king/sdd/<change-name>/` con estructura OpenSpec
2. Ejecuta `/sdd-init` → `/sdd-explore` → `/sdd-propose` en secuencia

Referencia: `agents/_common/protocols/sdd-orchestrator.md`
