---
name: plan
description: "Planificar feature con agentes especializados (idea → design doc → plan de implementación)"
argument-hint: "[descripción de la idea] [--workflow <nombre>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent, WebSearch]
---

# /plan

Planificación de features usando agentes especializados que enriquecen la idea con perspectivas de arquitectura, seguridad, QA y desarrollo.

## Instrucciones

1. Invocar el skill `plan` usando la herramienta Skill
2. El argumento del usuario es la descripción de la idea/feature a planificar
3. Seguir todas las fases del skill en orden:
   - Captura de Idea → Exploración → Análisis Multi-Agente → Consolidación RADAR → Aprobación → Generación del Plan → Report
4. Coordinar los agentes @architect, @developer, @security, @qa (y opcionalmente @frontend, @api, @devops) según el skill indica
5. El output principal es un plan de implementación en `docs/plans/YYYY-MM-DD-<topic>.md`

Si no se proporciona descripción, preguntar al usuario qué feature quiere planificar.

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual (ver Phase 0 del skill).
