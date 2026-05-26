---
name: optimize
description: "Optimización guiada de rendimiento con análisis Big O y design patterns"
argument-hint: "[target a optimizar] [--workflow <nombre>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /optimize

Ejecutar workflow de optimización de rendimiento guiado.

## Instrucciones

1. Invocar el skill `optimize`
2. El argumento describe qué optimizar (función, módulo, algoritmo, componente)
3. Seguir las fases: Profile → Diagnose → Plan → Execute → Benchmark → Report
4. IMPORTANTE: NUNCA cambiar comportamiento externo ni contratos públicos
5. IMPORTANTE: Respetar las convenciones de código del proyecto (ver CLAUDE.md)
6. Commits incrementales con prefijo `perf(scope):` por cada optimización

Si se proporciona `--workflow <nombre>`, asociar la ejecución a ese workflow. Si no se proporciona, se detecta automáticamente del branch actual.
