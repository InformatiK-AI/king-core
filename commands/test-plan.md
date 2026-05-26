---
name: test-plan
description: "Generar planes de pruebas HTML interactivos con tema King 'Dark Royalty'"
argument-hint: "[--mode single|consolidated] [--feature <nombre>] [--role <nombre>] [--gherkin <path>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent, WebSearch]
---

# /test-plan

Generar un plan de pruebas HTML interactivo auto-contenido con tema King "Dark Royalty".

## Instrucciones

1. Invocar el skill `test-plan` usando la herramienta Skill
2. Argumentos opcionales:
   - `--mode single|consolidated`: Modo de generación (default: single)
   - `--feature <nombre>`: Nombre de la feature a documentar en el plan
   - `--role <nombre>`: Rol del tester (ej: admin, user, qa)
   - `--gherkin <path>`: Ruta a archivo `.feature` con escenarios Gherkin como fuente
3. Seguir todas las fases del skill en orden:
   - Discover → Analyze → Compose → Generate → Verify → Write Session → Guide Next Step
4. Agentes coordinados: @qa (principal), @developer (análisis de codebase), @frontend (verificación visual)

Si no se proporcionan argumentos, el skill solicitará el modo y feature al usuario.

Si se proporciona `--mode consolidated`, generar un único HTML que agrupe múltiples features.
