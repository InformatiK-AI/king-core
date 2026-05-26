---
name: promote
description: "Promover código entre ambientes: develop→qa o qa→prod usando worktrees"
argument-hint: "--to [qa|prod] [--workflow <nombre>]"
allowed-tools: [Read, Grep, Glob, Bash, Agent]
---

# /promote

Ejecutar promoción entre ambientes.

## Instrucciones

1. Invocar el skill `promote`
2. El argumento `--to` determina el ambiente destino:
   - `--to qa`: Promover de develop a QA
   - `--to prod`: Promover de QA/main a producción
3. Si no se especifica destino, preguntar al usuario
4. Seguir todas las fases del skill: Readiness → Security → DB → Config → Deploy → Setup → Smoke → Health → GitHub → Report
5. IMPORTANTE: La promoción a prod requiere CASTLE FORTIFIED

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual.
