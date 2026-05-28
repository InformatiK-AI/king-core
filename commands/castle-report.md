---
name: castle-report
description: "Genera el CASTLE Score numérico reproducible agregando sub-reports JSON existentes."
allowed-tools: [Read, Write, Bash]
---

# /castle-report

Genera el CASTLE Score numérico reproducible agregando sub-reports JSON.

## Instrucciones

1. Usar el skill `skills/castle-report/SKILL.md`
2. Leer sub-reports de `.king/castle/` en el proyecto actual
3. Calcular score 0-100 con graceful degradation para gates ausentes
4. Mostrar tabla en terminal y escribir `.king/castle/castle-report.json`
