---
name: health-check-gate
description: "Gate formal de health check endpoints en /promote. Bloquea o advierte si los endpoints /health y /ready no están implementados con el contrato correcto antes de deployar a producción."
---

# Rule: Health Check Gate

**Alcance**: `/promote` (Fase 1c — entre Fase 1b DR Gate y Fase 2 Security Gate)
**Severidad**: BLOQUEANTE en prod en modo `error` | ADVERTENCIA en qa en modo `warn` (default)
**Skills que aplican**: `promote`
**Configuración por proyecto**: `.king/health-check-setup.yaml`

---

## Contrato Esperado de Respuesta

```yaml
health_contract:
  endpoint: /health
  method: GET
  success_status: 200
  required_fields: [status, version, timestamp]
  status_value: "ok"

ready_contract:
  endpoint: /ready
  method: GET
  success_status: 200
  fail_status: 503
  required_fields: [status, checks]
  checks_format: "{dep_name: ok|fail}"
```

---

## Alcance

El gate evalúa si el proyecto destino expone los endpoints `/health` y `/ready` con el contrato correcto antes de promover a un ambiente controlado.

| Ambiente | Comportamiento por defecto |
|----------|---------------------------|
| `prod` | BLOQUEANTE en modo `error` — deploy rechazado si falta algún endpoint |
| `qa` | ADVERTENCIA en modo `warn` — continúa pero emite warning |
| `dev` | SKIP sin error — no aplica por defecto |

---

## Configuración por Proyecto

```yaml
# .king/health-check-setup.yaml
enabled: true
mode:
  prod: error        # BLOQUEANTE — deploy rechazado si faltan endpoints o contrato incorrecto
  qa: warn           # Advertencia sin bloqueo
  dev: skip          # Sin gate
scope:
  environments: [prod]    # en cuáles ambientes aplica el gate
dependencies:
  db: true
  cache: false
  external_apis: []
cache_ttl: 5         # segundos de cache para /ready
```

Si `.king/health-check-setup.yaml` no existe, se usan estos defaults:

| Campo | Default | Descripción |
|-------|---------|-------------|
| `enabled` | `true` | Gate activo |
| `mode` para `prod` | `error` | BLOQUEANTE — deploy rechazado si faltan endpoints o contrato incorrecto |
| `mode` para `qa` | `warn` | Advertencia sin bloqueo |
| `mode` para `dev` | `skip` | Sin gate — no aplica |
| `scope.environments` | `[prod]` | Solo aplica a producción |
| `dependencies.db` | `true` | Verificar check de DB |
| `dependencies.cache` | `false` | No verificar cache por defecto |
| `cache_ttl` | `5` | TTL en segundos para cache de /ready |

---

## Modos de Operación

| Modo | Comportamiento | Cuándo usar |
|------|---------------|-------------|
| `warn` (default) | Muestra advertencia y continúa | Proyectos en onboarding, migración progresiva |
| `error` | Bloquea el skill si algún endpoint falta o tiene contrato incorrecto | Proyectos con health checks establecidos |

**El modo se configura en `.king/health-check-setup.yaml`.** Si el archivo no existe, el modo es `warn`.

---

## Proceso de Evaluación

### Paso 1 — Cargar configuración

Leer `.king/health-check-setup.yaml`.

- Si no existe → usar defaults según el ambiente destino del promote:
  - `prod` → `mode: error` (BLOQUEANTE)
  - `qa`   → `mode: warn`  (ADVERTENCIA)
  - `dev`  → `mode: skip`  (SIN GATE)
  Log: `Health check gate: using defaults (.king/health-check-setup.yaml not found). Run /health-check-setup to configure.`
- Si YAML malformado → **FAIL** con `HEALTH-CHECK-GATE-CONFIG-ERROR: .king/health-check-setup.yaml — {descripción del error}`. No continuar.

### Paso 2 — Verificar scope

Verificar si el ambiente destino está en `scope.environments`.

- Si el ambiente **NO** está en scope → `HEALTH-CHECK-GATE-SKIPPED: environment {env} is not in scope` → continuar sin bloquear.

### Paso 3 — Verificar si está habilitado

- Si `enabled: false` → `HEALTH-CHECK-GATE-DISABLED: enabled: false in .king/health-check-setup.yaml. Se recomienda ejecutar /health-check-setup. Documentar en exceptions.yml si es intencional.` → continuar con WARN.

### Paso 4 — Buscar evidencia de endpoints en el código

Buscar en el código del proyecto archivos que registren las rutas:

**Buscar `/health`:**
- Node.js: `router.get('/health'` | `app.get('/health'` | `fastify.get('/health'`
- Python: `@router.get("/health"` | `@health_bp.route("/health"` | `@app.get("/health"`
- Go: `r.GET("/health"` | `r.Get("/health"` | `http.HandleFunc("/health"`

**Buscar `/ready`:**
- Node.js: `router.get('/ready'` | `app.get('/ready'` | `fastify.get('/ready'`
- Python: `@router.get("/ready"` | `@health_bp.route("/ready"` | `@app.get("/ready"`
- Go: `r.GET("/ready"` | `r.Get("/ready"` | `http.HandleFunc("/ready"`

**Verificar contrato de `/health`** (en el archivo que define el handler):
- Contiene los campos `status`, `version`, `timestamp` en el body de respuesta
- Retorna `status: "ok"` con HTTP 200

**Verificar contrato de `/ready`** (en el archivo que define el handler):
- Contiene los campos `status` y `checks` en el body de respuesta
- Retorna HTTP 200 cuando todo está ok, HTTP 503 cuando alguna dependencia falla
- El campo `checks` tiene formato `{dep_name: "ok"|"fail"}`

### Paso 5 — Evaluar resultado

```
health_found  = archivo con /health encontrado
health_ok     = contrato de /health correcto
ready_found   = archivo con /ready encontrado
ready_ok      = contrato de /ready correcto

gate_pass = health_found AND health_ok AND ready_found AND ready_ok
```

### Paso 6 — Aplicar modo y generar reporte

- Si `gate_pass = true` → PASS
- Si `gate_pass = false` y `mode = warn` → WARN + continuar
- Si `gate_pass = false` y `mode = error` → FAIL + bloquear promote

---

## Reporte

```
╔══════════════════════════════════════════════════╗
║         HEALTH CHECK GATE REPORT                  ║
╠══════════════════════════════════════════════════╣
║  Scope:    {prod|qa|dev}                          ║
║  Config:   .king/health-check-setup.yaml          ║
╠══════════════════════════════════════════════════╣
║  /health:  {FOUND|MISSING}   contrato: {OK|WARN}  ║
║  /ready:   {FOUND|MISSING}   contrato: {OK|WARN}  ║
╠══════════════════════════════════════════════════╣
║  Modo:     {warn|error}                           ║
║  Resultado: {PASS|WARN|FAIL|SKIP}                 ║
╚══════════════════════════════════════════════════╝
```

Si FAIL en modo `error` → mostrar además qué campo del contrato está faltando o incorrecto para guiar al developer.

---

## Skills que usan esta regla

- `/promote` → Fase 1c (entre Fase 1b DR Gate y Fase 2 Security Gate)

---

## Excepciones — Skip automático con WARN

El gate se omite **sin error bloqueante** cuando:

| Condición | Error code | Comportamiento |
|-----------|-----------|----------------|
| `enabled: false` | `HEALTH-CHECK-GATE-DISABLED` | SKIP + WARN — ver Paso 3 para mensaje completo |
| Ambiente fuera de scope | `HEALTH-CHECK-GATE-SKIPPED` | SKIP sin error — ver Paso 2 |
| Código inaccesible (acceso denegado) | `HEALTH-CHECK-GATE-SKIPPED` | SKIP + WARN |
| YAML malformado | `HEALTH-CHECK-GATE-CONFIG-ERROR` | FAIL — ver Paso 1 para mensaje completo |

**Nota de seguridad**: Los templates generados por `/health-check-setup` nunca incluyen IPs, mensajes del driver, stack traces ni credenciales hardcodeadas en el body de los endpoints. Si el reviewer detecta alguno de estos valores en una PR que modifica los handlers de `/health` o `/ready`, debe rechazarla.
