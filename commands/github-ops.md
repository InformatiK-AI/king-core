---
name: github-ops
description: "Automatización de operaciones GitHub: commits, PRs, push, y gestión de issues"
argument-hint: "<operación> [opciones]"
allowed-tools: [Bash, Read, Grep, Glob]
---

# /github-ops

Automatizar operaciones GitHub.

## Instrucciones

1. Invocar el skill `github-ops`
2. Operaciones soportadas: commit, pr, push, issue
3. Para commits: usar conventional commits con co-authoring automático
4. Para PRs: crear, revisar, o mergear PRs con quality gates
5. Para push: push al remoto con verificaciones pre-push
6. IMPORTANTE: Nunca hacer force push a main/master sin confirmación explícita
