---
name: audit
description: "Auditar la salud del King Framework instalado. Genera Health Score con 6 dimensiones y verifica LOAD-INDEX, agentes, skills y hooks."
argument-hint: "[--scope full|quick] [--focus agents|skills|security|quality|all] [--dry-run] [--fix-suggestions]"
allowed-tools: [Read, Grep, Glob, Bash]
---
# /audit

Usa el skill `skills/audit/SKILL.md`.
