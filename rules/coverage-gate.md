---
name: coverage-gate
description: "Gate formal de cobertura de tests en /build y /promote. Bloquea o advierte si la cobertura cae bajo el threshold configurado."
---

# Rule: Coverage Gate

**Alcance**: `/build` (Fase 5, step 5.8) y `/promote` (Fase 1, step 1.4)
**Severidad**: BLOQUEANTE en modo `error` | ADVERTENCIA en modo `warn` (default)
**Skills que aplican**: `build`, `promote`
**Configuración por proyecto**: `.king/coverage.yaml`

---

## Thresholds Default

Si `.king/coverage.yaml` no existe, se usan estos valores:

| Métrica | Default | Descripción |
|---------|---------|-------------|
| `overall` | 80% | Cobertura global de líneas |
| `branches` | 70% | Cobertura de ramas condicionales |
| `critical` | 90% | Paths críticos — **solo si `critical_paths` está definido en el YAML** |

---

## Detección de Test Runner

**Allowlist estricta**: solo `jest`, `pytest`, o `go` son runners válidos — nunca se ejecuta un string libre del YAML como comando.

| Runner | Señales de detección (cualquiera) | Comando de cobertura | Verificación disponible |
|--------|-----------------------------------|----------------------|-------------------------|
| `jest` | `package.json` con `"jest"`/`"vitest"` en deps, `jest.config.*`, o script `"test"` invoca jest/vitest | `npx jest --coverage --coverageReporters=text --passWithNoTests 2>&1` | `command -v npx && npx jest --version` |
| `pytest` | `test_*.py` / `*_test.py`, `pytest.ini`, `setup.cfg [tool:pytest]`, o `pyproject.toml [tool.pytest.ini_options]` | `python -m pytest --cov --cov-report=term-missing -q 2>&1` | `python -m pytest --version` |
| `go` | `*_test.go` en cualquier directorio | †dos pasos, ver abajo | `go version` |

†Go (dos pasos):
```bash
go test -coverprofile=.coverage.out ./... 2>&1
go tool cover -func=.coverage.out 2>&1
rm -f .coverage.out
```

Si ningún runner matchea → `COVERAGE-GATE-SKIPPED: no test runner detected — add tests to enable this gate` — el skill continúa sin bloquear.
Si múltiples matchean → evaluarlos **todos** por separado; el gate falla si **cualquiera** está bajo el threshold.

---

## Modos de Operación

| Modo | Comportamiento | Cuándo usar |
|------|---------------|-------------|
| `warn` (default) | Muestra advertencia y continúa | Proyectos nuevos, onboarding, cobertura en construcción |
| `error` | Bloquea el skill si coverage < threshold | Proyectos con cobertura establecida |

**El modo se configura en `.king/coverage.yaml`.** Si el archivo no existe, el modo es `warn`.

---

## Proceso de Evaluación

### Paso 1 — Detectar runner

Aplicar las señales de la tabla de runners en el orden: `jest` → `pytest` → `go` (ver sección "Detección de Test Runner").

### Paso 2 — Cargar configuración

```bash
# Cargar .king/coverage.yaml si existe
cat .king/coverage.yaml 2>/dev/null
```

- Si no existe → usar defaults (overall:80, branches:70, mode:warn) + log: `COVERAGE-GATE-CONFIG-MISSING: .king/coverage.yaml not found — using defaults (overall:80, branches:70, mode:warn). Run: cp $(king-framework)/templates/coverage.yaml .king/coverage.yaml`
- Si YAML malformado (error de parse) → **FAIL** con `COVERAGE-GATE-CONFIG-ERROR: .king/coverage.yaml — {descripción del error}`. No continuar.
- Validar que `thresholds.overall` y `thresholds.branches` son números enteros entre 0 y 100. Si no → FAIL con `COVERAGE-GATE-CONFIG-ERROR: threshold must be integer 0-100`.

### Paso 3 — Verificar tool disponible

Usar el comando de la columna **"Verificación disponible"** de la tabla de runners (sección anterior).

Si la tool no está disponible → `COVERAGE-GATE-SKIPPED: {tool} not found — install it to enable coverage enforcement`
→ El skill **continúa sin bloquear**.

### Paso 4 — Ejecutar con timeout

Ejecutar el comando con timeout de 120 segundos.

Si el proceso no termina en 120s:
→ `COVERAGE-GATE-TIMEOUT: coverage tool exceeded 120s limit`
→ En modo `warn`: continuar. En modo `error`: continuar con WARN (no bloquear por timeout).

Si la tool termina con exit code ≠ 0 **por un error interno** (distinto de "threshold not met"):
→ Reportar el error original del comando, no "cobertura insuficiente".
→ El gate no emite veredicto de cobertura — reporta el error y continúa.

### Paso 5 — Parsear output

**Jest:** Buscar la línea `All files` en la tabla de cobertura de texto:
```
All files          |    78.5 |     69.2 |   ...
```
Extraer: `overall = 78.5`, `branches = 69.2`

**pytest-cov:** Buscar la línea `TOTAL` al final del reporte:
```
TOTAL              247    52    79%
```
Extraer: `overall = 79`
Para branches: buscar `TOTAL ... XX% (branch coverage)` si `--cov-branch` está activo. Si no disponible → evaluar solo `overall`.

**go cover:** Buscar la línea `total:` al final de `go tool cover -func`:
```
total:	(statements)	82.4%
```
Extraer: `overall = 82.4`
Branches en Go no reporta separado → evaluar solo `overall`.

### Paso 6 — Comparar vs thresholds

Semántica: **`actual ≥ threshold` = PASS** (igual al threshold es PASS, no FAIL).

```
overall_pass   = actual_overall   >= threshold_overall
branches_pass  = actual_branches  >= threshold_branches  (si disponible)
critical_pass  = actual_critical  >= threshold_critical  (SOLO si critical_paths definido)

gate_pass = overall_pass AND branches_pass AND critical_pass
```

### Paso 7 — Generar reporte

```
╔══════════════════════════════════════════════════╗
║            COVERAGE GATE REPORT                   ║
╠══════════════════════════════════════════════════╣
║  Runner:   {jest|pytest|go}                       ║
║  Scope:    {diff|full}                            ║
╠══════════════════════════════════════════════════╣
║  Overall:   {actual}% (threshold: {t}%)   {✓|✗}  ║
║  Branches:  {actual}% (threshold: {t}%)   {✓|✗}  ║
║  Critical:  {actual}% (threshold: {t}%)   {✓|✗}  ║
╠══════════════════════════════════════════════════╣
║  Modo:     {warn|error}                           ║
║  Resultado: {PASS | WARN | FAIL | SKIPPED}        ║
╚══════════════════════════════════════════════════╝
```

Si FAIL en modo `error` → mostrar además los **5 archivos con menor cobertura** del reporte del runner para guiar al developer.

---

## Skills que usan esta regla

- `/build` → Fase 5, ítem 8 del MUST DO (después de smoke test visual)
- `/promote` → Fase 1, ítem 1 del MUST DO (primera verificación de Readiness)

---

## Excepciones — Skip automático con WARN

El gate se omite **sin error bloqueante** cuando:

| Condición | Acción |
|-----------|--------|
| No se detecta ningún runner | `COVERAGE-GATE-SKIPPED: no test runner detected — add tests to enable this gate` |
| `.king/coverage.yaml` con `enabled: false` | `COVERAGE-GATE-DISABLED: enabled: false in .king/coverage.yaml` |
| Tool no instalada en el entorno | `COVERAGE-GATE-SKIPPED: {tool} not found — install it to enable coverage enforcement` |
| Timeout > 120s | `COVERAGE-GATE-TIMEOUT` — continúa en modo warn |
| Tool exit code ≠ 0 por error interno | Reportar error original — no emitir veredicto de cobertura |

**Nota de seguridad**: Si `coverage.yaml` es modificado en un PR (thresholds bajados), el reviewer debe verificar que la reducción es intencional. Esta es la primera línea de defensa contra threshold bypass.

---

## Configuración Completa

Ver template: `templates/coverage.yaml`

Copiar al proyecto: `cp templates/coverage.yaml .king/coverage.yaml`
