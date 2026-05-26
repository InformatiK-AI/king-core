---
name: radar
description: "Activar protocolo RADAR de razonamiento estructurado para la tarea actual"
argument-hint: "[<tarea o decisión a analizar>]"
allowed-tools: [Read, Grep, Glob, Agent]
---

# /radar

Activar protocolo RADAR para la tarea actual.

## Instrucciones

1. Invocar el skill `radar`
2. Aplicar las 5 fases de RADAR a la tarea o decisión en curso:
   - **R**ead: Leer todo el contexto relevante
   - **A**nalyze: Generar 2-3 alternativas con trade-offs
   - **D**ecide: Elegir con justificación documentada
   - **A**ct: Ejecutar incrementalmente con verificación
   - **R**eport: Comunicar resultado con razonamiento
3. Si no hay tarea en curso, preguntar al usuario qué quiere analizar
