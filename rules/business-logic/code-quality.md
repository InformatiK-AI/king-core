---
name: code-quality
description: "Estándares de calidad: complejidad ciclomática, coverage mínimo, linting"
---

# Rule: Code Quality

**Severidad**: WARNING

## Métricas de calidad

| Métrica | Umbral | Acción si supera |
|---------|--------|-----------------|
| Complejidad ciclomática | > 10 por función | Refactorizar |
| Longitud de función | > 50 líneas | Dividir |
| Parámetros por función | > 3 | Usar objeto |
| Deuda técnica estimada | > 1 día por PR | Revisar con @architect |

## Cobertura mínima
- Unit tests: ≥ 70% de líneas
- Branches críticos: 100%
- Funciones públicas: 100%

## Linting
- Sin errores de linting (0 errors)
- Warnings justificados con comentario explicativo

## Duplicación
- Umbral: < 3% de código duplicado
- DRY: Si un bloque se repite 3+ veces, abstraer
