---
name: build
description: "Construir una feature completa con workflow guiado (architecture → implementation → QA → PR)"
argument-hint: "[descripción | #issue-number] [--workflow <nombre>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent, WebSearch]
---

# /build

Ejecutar el workflow completo de desarrollo de features.

## Instrucciones

1. Invocar el skill `build` usando la herramienta Skill
2. El argumento del usuario es la descripción de la feature o un número de issue `#N`:
   - Si el argumento es `#N`, obtener detalles del issue con `gh issue view N --json title,body,labels` y usar como spec
   - Si es texto libre, usar como descripción de la feature
3. Seguir todas las fases del skill en orden:
   - Setup → Discovery → Architecture → Implementation → Testing → Security → CASTLE → GitHub → Report
4. Coordinar los agentes @architect, @developer/@frontend, @qa, @security según el skill indica
5. Generar reporte final con CASTLE Score

Si no se proporciona descripción, preguntar al usuario qué feature quiere construir.

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual (ver Phase 0 del skill).
