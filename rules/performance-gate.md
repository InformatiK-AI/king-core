---
name: performance-gate
description: "Gate formal de performance budget basado en Lighthouse. Bloquea /build y /promote si los scores caen por debajo de thresholds configurados."
---

# Rule: Performance Budget Gate

**Alcance**: Proyectos con frontend (HTML, JSX, TSX, Vue, Svelte, o configuración de bundler)
**Severidad**: BLOQUEANTE (modo `error`) | ADVERTENCIA (modo `warn`)
**Skills que aplican**: `/build`, `/promote`

---

## Thresholds Default

| Categoría | Threshold | Descripción |
|-----------|-----------|-------------|
| Performance | ≥ 90 | Velocidad de carga y Core Web Vitals |
| Accessibility | ≥ 90 | Cumplimiento WCAG y accesibilidad |
| Best Practices | ≥ 90 | Uso correcto de APIs web y seguridad |
| SEO | ≥ 85 | Optimización para motores de búsqueda |

Override via `.king/performance-budget.yaml` en el directorio raíz del proyecto.

---

## Detección de Frontend

El gate se activa SOLAMENTE si el proyecto tiene frontend. Detección basada en tres categorías:
archivos fuente (`*.html`, `*.jsx`, `*.tsx`, `*.vue`, `*.svelte`), configuración de bundler
(`vite.config.*`, `webpack.config.*`, `next.config.*`, `nuxt.config.*`), y scripts de
`package.json` apuntando a bundler.

Ver comando exacto en **Proceso de Evaluación → Paso 1**. Si no se detecta nada:
```
Performance gate skipped: no frontend detected
```

---

## Modos de Ejecución

| Modo | Comportamiento |
|------|---------------|
| `error` (default) | Bloquea la ejecución del skill si algún score está por debajo del threshold |
| `warn` | Muestra advertencia en el output pero no bloquea — continúa el skill |

Configurar en `.king/performance-budget.yaml`:
```yaml
mode: warn  # o error
```

---

## Proceso de Evaluación

### Paso 1: Detectar frontend
```bash
# Buscar indicadores de frontend — maxdepth 3 evita traversal completo del repo
find . -maxdepth 3 \( \
  -name "*.html" -o -name "*.jsx" -o -name "*.tsx" -o -name "*.vue" -o -name "*.svelte" -o \
  -name "vite.config.*" -o -name "webpack.config.*" -o -name "next.config.*" -o -name "nuxt.config.*" \
\) -not -path "*/node_modules/*" -not -path "*/.git/*" | head -1
```

Si el resultado está vacío → registrar y detener:
```
Performance gate skipped: no frontend detected
```
> No continuar a Pasos 2-4.

### Paso 2: Cargar thresholds

Leer `.king/performance-budget.yaml` y extraer los valores configurados. Si el archivo no existe, usar defaults del framework:

| Campo YAML | Default | Equivalente LHCI (÷100) |
|------------|---------|------------------------|
| `thresholds.performance` | 90 | 0.90 |
| `thresholds.accessibility` | 90 | 0.90 |
| `thresholds.best-practices` | 90 | 0.90 |
| `thresholds.seo` | 85 | 0.85 |

> **Escala**: LHCI usa 0-1 (`minScore=0.90` = score 90/100). Dividir el threshold del YAML por 100 para obtener el flag de LHCI.

### Paso 3: Ejecutar audit con Lighthouse CI

Sustituir `{PERF}`, `{A11Y}`, `{BP}`, `{SEO}` con los valores de Paso 2 divididos por 100:

```bash
npx lhci autorun --collect.url=http://localhost:PORT \
                  --assert.preset=lighthouse:recommended \
                  --assert.assertions.categories:performance.minScore={PERF} \
                  --assert.assertions.categories:accessibility.minScore={A11Y} \
                  --assert.assertions.categories:best-practices.minScore={BP} \
                  --assert.assertions.categories:seo.minScore={SEO}
```

Ejemplo con config custom `performance: 85`: `{PERF}=0.85` (resto usa defaults de Paso 2).

> **Nota**: Si LHCI no está instalado o el servidor no está corriendo, registrar WARN y continuar (no bloquear por tool unavailability).

### Paso 4: Evaluar resultados

Si algún score está por debajo del threshold:

**Modo `error`:**
```
PERFORMANCE GATE FAILED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Score:     Performance = 78  (threshold: ≥ 90)  ❌
           Accessibility = 92  (threshold: ≥ 90)  ✓
           Best Practices = 91  (threshold: ≥ 90)  ✓
           SEO = 87  (threshold: ≥ 85)  ✓

Core Web Vitals que fallan:
  LCP: 4.2s  (bueno: < 2.5s)  ❌
  CLS: 0.12  (bueno: < 0.1)   ❌
  FID/INP: 89ms  (bueno: < 100ms)  ✓

Acción requerida: mejorar Performance antes de continuar.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

**Modo `warn`:**
```
PERFORMANCE GATE WARNING (modo: warn — no bloquea)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Score:     Performance = 78  (threshold: ≥ 90)  ⚠️
           Accessibility = 92  (threshold: ≥ 90)  ✓
           Best Practices = 91  (threshold: ≥ 90)  ✓
           SEO = 87  (threshold: ≥ 85)  ✓

Core Web Vitals que fallan:
  LCP: 4.2s  (bueno: < 2.5s)  ⚠️
  CLS: 0.12  (bueno: < 0.1)   ⚠️

Continúa el skill. Resolver antes del siguiente /promote.
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

Si todos los scores pasan:
```
PERFORMANCE GATE ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Performance = 92 ✓ | Accessibility = 95 ✓ | Best Practices = 90 ✓ | SEO = 87 ✓
LCP: 1.8s ✓ | CLS: 0.05 ✓ | INP: 72ms ✓
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

---

## Integración con Skills

Esta rule es ejecutada por `/build` (Fase 5, paso 5.8) y `/promote` (Fase 1, paso 1.4).
Ver cada skill para el flujo de decisión específico.

---

## Excepciones

Las condiciones de omisión están documentadas en el Proceso de Evaluación (Pasos 1 y 3).
Excepción adicional no cubierta en el proceso:

- Existe `.king/performance-budget.yaml` con `enabled: false` → gate omitido globalmente sin ejecutar ningún paso

---

## Configuración Completa

Ver template en `templates/performance-budget.yaml`.
