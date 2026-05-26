---
name: accessibility-gate
description: "Gate formal de accesibilidad WCAG 2.2 AA. Bloquea /review ante violaciones critical y /promote ante violaciones critical o serious. Se omite automáticamente en proyectos sin frontend."
---

# Rule: Accessibility Gate WCAG 2.2 AA

**Alcance**: proyectos con frontend detectado (ver Detección de Frontend)  
**Nivel**: WCAG 2.2 AA  
**Motor**: axe-core via Playwright MCP (`browser_evaluate`)  
**Decisión**: ADR-004  
**Knowledge**: `knowledge/universal/accessibility.md` — criterios WCAG 2.1/2.2

---

## Niveles de Bloqueo

| Impact | `/review` | `/promote` |
|--------|-----------|------------|
| `critical` | ⛔ BLOCKED | ⛔ BLOCKED |
| `serious` | ⚠️ WARNING | ⛔ BLOCKED |
| `moderate` | ℹ️ INFO | ⚠️ WARNING |
| `minor` | — | ℹ️ INFO |

---

## Precondiciones

> Evaluar en orden antes de continuar. Si alguna condición dispara SKIP o WARNING, no ejecutar el gate.

| # | Condición | Acción |
|---|-----------|--------|
| 1 | No hay frontend detectado (ver heurísticas abajo) | SKIP — `"Accessibility gate skipped: no frontend detected"` |
| 2 | URL no accesible / app no corriendo | SKIP — `"Accessibility gate skipped: app not running"` |
| 3 | Playwright MCP no disponible | WARNING — `"Accessibility gate warning: Playwright MCP unavailable"` + continuar |

Si todas las precondiciones pasan → ejecutar el gate (ver secciones siguientes).

---

## Detección de Frontend

Verificar en orden. Si alguna condición es verdadera → frontend detectado.

1. Existe `index.html` en `./`, `./public/` o `./src/`
2. `package.json` contiene alguna de estas keys en `dependencies` (NO `devDependencies`):
   `react`, `vue`, `angular`, `svelte`, `solid-js`, `preact`, `@angular/core`
3. Existe `./src/App.tsx` o `./src/App.jsx` o `./src/App.vue`

---

## URL Resolution

Resolver en orden. Usar la primera URL accesible.

1. Leer `.king/knowledge/environments.md` → buscar URL del ambiente dev/qa
2. Leer `package.json` → buscar `scripts.dev` o `scripts.start` → inferir `localhost:{puerto}`
3. Fallback: `http://localhost:3000`

---

## Ejecución del Gate

Pasos en orden tras pasar las Precondiciones:

**A — NAVIGATE**: navegar a la URL resuelta
```
browser_navigate(url)
```

**B — INJECT + RUN**: inyectar axe-core y ejecutar análisis WCAG 2.2 AA
```javascript
browser_evaluate(`
  if (!window.axe) {
    const s = document.createElement('script');
    s.src = 'https://cdnjs.cloudflare.com/ajax/libs/axe-core/4.9.1/axe.min.js';
    s.integrity = 'sha384-mFMBMhQgpRCUMUHMHDLBHyP7QNQN3Qy2EMW0xrRdNfXQbFqTU2m/X8GXUV5e4Lk'; // actualizar hash en cada release de axe-core
    s.crossOrigin = 'anonymous';
    document.head.appendChild(s);
    const loaded = await Promise.race([
      new Promise(r => { s.onload = () => r(true); s.onerror = () => r(false); }),
      new Promise(r => setTimeout(() => r(false), 5000))  // timeout 5s para CI air-gapped
    ]);
    if (!loaded) return { violations: [], _skip: 'axe-core CDN unavailable' };
  }
  return await axe.run(document, { runOnly: { type: 'tag', values: ['wcag2a', 'wcag2aa', 'wcag22aa'] } });
`)
```

**C — FILTER**: agrupar violations por impact
```
critical = results.violations.filter(v => v.impact === 'critical')
serious  = results.violations.filter(v => v.impact === 'serious')
moderate = results.violations.filter(v => v.impact === 'moderate')
minor    = results.violations.filter(v => v.impact === 'minor')
```

---

## Formato de Reporte

### Gate BLOQUEADO (critical o serious en /promote)

```
⛔ Accessibility Gate — BLOCKED
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Critical violations: N
  Serious violations:  N
  URL escaneada: http://localhost:3000
  WCAG: 2.2 AA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

  id:             color-contrast
  impact:         critical
  element:        <button class="cta-primary">Comprar</button>
  wcag:           1.4.3 Contrast (Minimum)
  current:        ratio 2.8:1          ← omitir si axe no provee valor numérico
  required:       ratio 4.5:1          ← omitir si axe no provee valor numérico
  fix:            Cambiar color de texto a #595959 (en lugar de #767676)
  wcag_url:       https://www.w3.org/WAI/WCAG22/Understanding/contrast-minimum

  id:             image-alt
  impact:         critical
  element:        <img src="hero.jpg">
  wcag:           1.1.1 Non-text Content
  current:        —                    ← omitir si no aplica
  required:       —                    ← omitir si no aplica
  fix:            Agregar atributo alt descriptivo
  wcag_url:       https://www.w3.org/WAI/WCAG22/Understanding/non-text-content
```

### Gate WARNINGS

```
⚠️ Accessibility Gate — WARNINGS (no bloquea /review)
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Serious violations: N (revisar antes de /promote)
  [detalles en mismo formato que arriba]
```

### Gate PASADO

```
✅ Accessibility Gate — PASS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
  Critical violations: 0
  Serious violations:  0
  Moderate/minor:      N (solo informativos)
  URL escaneada: http://localhost:3000
  WCAG: 2.2 AA
```

---

## Configuración (`.king/a11y.yaml` — schema, no creado por defecto)

```yaml
accessibility:
  enabled: true                    # false para deshabilitar el gate globalmente
  wcag_version: "2.2"             # "2.1" | "2.2" — explícito para evitar ambigüedad
  scan_depth: root                 # root (solo /) | full (todas las rutas) | custom (ver pages)

  review:
    threshold: critical            # impact mínimo que bloquea /review

  promote:
    threshold: serious             # impact mínimo que bloquea /promote (serious incluye critical)

  pages:                           # solo si scan_depth: custom
    - /
    - /checkout
    - /dashboard

  exceptions:
    - element: ".legacy-modal"
      rule: "color-contrast"
      reason: "Legacy component, refactor planificado Q3 2026"
      expires: "2026-09-30"
      approved_by: "InformatiK-AI"   # OBLIGATORIO — quién aprobó la excepción
      issue: "https://github.com/org/repo/issues/123"  # OBLIGATORIO — tracking formal de la deuda
```

> Si `.king/a11y.yaml` no existe, se usan los valores por defecto documentados arriba.
