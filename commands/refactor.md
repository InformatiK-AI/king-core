---
name: refactor
description: "Refactoring guiado con preservación de comportamiento y verificación continua"
argument-hint: "[target a refactorizar] [--workflow <nombre>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /refactor

Ejecutar workflow de refactoring guiado.

## Instrucciones

1. Invocar el skill `refactor`
2. El argumento describe qué refactorizar (función, sección, componente)
3. Seguir las fases: Identify → Plan → Execute → Verify → Review
4. IMPORTANTE: NUNCA cambiar comportamiento durante refactoring
5. IMPORTANTE: Respetar las convenciones de código del proyecto (ver CLAUDE.md). No cambiar estilo en archivos que no son parte del refactor.
6. Commits incrementales por cada paso del refactoring

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual.
