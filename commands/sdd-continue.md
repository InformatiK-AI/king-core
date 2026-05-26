---
name: sdd-continue
description: "Continuar el SDD en la siguiente fase disponible del DAG. Detecta automáticamente qué fases están listas para ejecutar."
argument-hint: "[change-name]"
allowed-tools: [Read, Write, Edit, Bash, Glob, Grep, Agent]
---
# /sdd-continue

Meta-comando SDD. Procesado por el orquestador.

Lee `state.yaml` del cambio activo, detecta fases con dependencias satisfechas, y ejecuta la siguiente.

DAG: proposal → specs || design → tasks → apply → verify → archive

Referencia: `agents/_common/protocols/sdd-orchestrator.md`
