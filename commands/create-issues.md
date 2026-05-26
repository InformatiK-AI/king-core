---
name: create-issues
description: "Crear issues GitHub estructurados desde plan de implementación (Epic + Stories con Gherkin y DoD)"
argument-hint: "[ruta/al/plan.md] [--repo <owner/repo>] [--milestone <nombre>] [--assignee <usuario>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /create-issues

Crear issues GitHub estructurados (Epic + Stories) desde un plan de implementación, con escenarios Gherkin, Definition of Done y Acceptance Criteria.

## Instrucciones

1. Invocar el skill `create-issues` usando la herramienta Skill
2. El argumento principal es la ruta al plan de implementación (ej: `docs/plans/2026-03-07-swift-support.md`)
3. Seguir todas las fases del skill en orden:
   - Validación → Análisis del Plan → Gherkin → DoD/ACs → Composición → Creación en GitHub → Verificación → Report
4. Coordinar los agentes @architect, @qa, @devops según el skill indica
5. El output son issues en GitHub: 1 Epic + N Stories

Si no se proporciona ruta al plan, preguntar al usuario qué plan quiere convertir en issues.

Flags opcionales:
- `--repo <owner/repo>`: Especificar repositorio destino (si no, se detecta del directorio actual)
- `--milestone <nombre>`: Asignar milestone a todos los issues
- `--assignee <usuario>`: Asignar usuario a las Stories

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual (ver Phase 0 del skill).
