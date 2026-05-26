---
name: frontend-design-benchmark
version: "1.0"
description: "Scoring objetivo de 12 criterios para evaluar la calidad del output de /frontend-design. Target: 75% = 37.5/47 puntos."
---

# /frontend-design — BENCHMARK v1.0

Evaluación objetiva de calidad. Ejecutar al finalizar Phase 5 del skill.
Target: **37.5/47 puntos (75%)** para considerarse exitoso.

## Criterios

| # | Criterio | Verificación | Pts |
|---|----------|--------------|-----|
| 1 | **Tokens generados** | `.king/design/tokens.json` (DTCG) y `.king/design/tokens.sd.json` existen; `tokens.json` tiene al menos los campos `color.primary.500`, `typography.heading.fontFamily`, `spacing.base` | 5 |
| 2 | **Paleta WCAG AA** | Todos los pares semánticos en `tokens.json` tienen contrast ratio ≥ 4.5:1: `fg-default/bg-default`, `fg-default/bg-surface`, `fg-inverted/bg-primary-500`, `fg-muted/bg-default` | 5 |
| 3 | **Tipografía pairing** | `heading.fontFamily` ≠ `body.fontFamily`; ambos en `typography.csv`; Google Fonts URL presente en la sesión | 3 |
| 4 | **Catálogo consultado** | Session doc referencia ≥3 IDs de `styles.csv` o `palettes.csv` en las decisiones de la Phase 1 | 3 |
| 5 | **Stack detectado** | Session doc registra el stack detectado; al menos un adapter de `stack-adapters/` fue cargado | 4 |
| 6 | **Componente compila** | Si el stack tiene compilación (`npm run build` / `flutter build` / `cargo build`): exit code 0 sin errores nuevos. Para stacks sin compilación (HTML, SwiftUI via Xcode): verificación de sintaxis equivalente | 5 |
| 7 | **Evidencia visual** | Screenshot o descripción visual capturada en session doc vía `visual-evidence` skill | 4 |
| 8 | **Estados UI** | El componente generado implementa y documenta ≥3 de: Loading, Error, Empty, Success, Disabled | 4 |
| 9 | **Animaciones GPU-safe** | Si hay animaciones: solo usan `transform` / `opacity` en keyframes; `prefers-reduced-motion` respetado con fallback | 3 |
| 10 | **Responsive** | ≥3 breakpoints documentados o en CSS generado (sm/md/lg/xl o equivalentes del stack) | 3 |
| 11 | **Brand-aligned** | Tokens leídos de `.king/brand/tokens.json` via Phase 0.5 Brand Sync, no hardcodeados. Si no existe `.king/brand/`, usar catálogo como fallback (puntaje parcial: 2/5) | 5 |
| 12 | **Session doc existe** | `.king/sessions/` contiene un archivo con `frontend-design` en el nombre, creado en esta ejecución | 3 |
| **Total** | | | **47** |

## Cómo ejecutar

Al finalizar Phase 5 del skill `/frontend-design`, calcular:

```
score = suma de puntos obtenidos
percentage = (score / 47) * 100
passed = score >= 37.5
```

Reportar en el session doc:
```
BENCHMARK: [score]/47 pts ([percentage]%) — [PASSED ✓ | FAILED ✗]
```

## Criterios de falla frecuentes

- **Criterio 2 falla**: paleta generada sin verificar contraste → volver a Phase 3, re-ejecutar palette-wcag algorithm
- **Criterio 6 falla**: tokens mal formateados rompen la configuración de Tailwind → verificar que `tokens.sd.json` tiene la estructura correcta para Style Dictionary
- **Criterio 11 falla parcial** (2/5): `.king/brand/` no existe → sugerir `/brand-identity` al usuario al final de Phase 6
