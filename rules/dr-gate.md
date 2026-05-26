---
name: dr-gate
description: "Disaster Recovery prerequisite gate for /promote. Verifies that DR configuration (backup strategy, RTO/RPO, runbook) is in place before deploying to production."
version: "1.0"
applies_to: [promote]
castle_layer: A
---

# Rule: Disaster Recovery Gate

| Campo | Valor |
|-------|-------|
| **Alcance** | `/promote` (Fase 1b — entre Readiness y Security) |
| **Severidad** | BLOQUEANTE en modo `error` | ADVERTENCIA en modo `warn` (default) |
| **Skills que aplican** | `promote` |
| **Configuración** | `.king/dr-setup.yaml` |
| **Template** | `templates/dr-setup.yaml` |

---

## Cuándo aplica

El gate tiene 4 niveles de activación evaluados en orden:

**Nivel 1 — Disabled explícito:**
Si `.king/dr-setup.yaml` existe y contiene `enabled: false` → **SKIP sin error**.
El promote continúa normalmente. No se emite advertencia.

**Nivel 2 — Scope de ambiente:**
Si el ambiente destino del promote NO está en `scope.environments` de `.king/dr-setup.yaml` (default: `[prod]`) → **SKIP automático**.
Para promotes a `qa` o `dev`, el gate no corre — nunca bloquea ambientes no-productivos.

**Nivel 3 — Componentes sin estado:**
Si no se detectan componentes con estado en el proyecto → **SKIP con nota** `DR-GATE-SKIPPED: no stateful components detected`.
El promote continúa sin error.

**Nivel 4 — Señales de detección automática** (componentes con estado):

| Señal | Detección |
|-------|-----------|
| Base de datos vía Docker | `docker-compose.yml` contiene imagen `postgres`, `mysql`, `mongo`, `mariadb`, o `redis` |
| ORM o migraciones | Existe `migrations/`, `prisma/schema.prisma`, `alembic.ini`, o `flyway.conf` |
| Cloud storage | Variables de entorno con prefijo `S3_`, `BUCKET_`, `AZURE_STORAGE_`, `GCS_` |
| Ambiente prod definido | `.king/knowledge/environments.md` define ambiente `prod` |

Si se detecta alguna señal del Nivel 4 y no aplica SKIP por Nivel 1, 2 o 3 → evaluar el gate.

---

## Proceso de Evaluación

### Paso 1 — Verificar scope

¿El promote destino es `prod` (o está en `scope.environments`)?
- No → **SKIP** (Nivel 2). Terminar evaluación.
  - ⚠️ SCOPE MISMATCH WARNING: If the destination environment is `prod` AND `prod` is NOT in `scope.environments`,
    emit a visible warning in the Promote Report:
    "DR_GATE_SCOPE_MISMATCH: promoting to prod but prod is not in scope.environments — DR gate was skipped.
     Verify this is intentional. Update scope.environments in .king/dr-setup.yaml if needed."
    This warning does NOT block the promote but MUST appear in the report for auditability.
- Sí → continuar al Paso 2.

### Paso 2 — Verificar existencia del archivo

¿Existe `.king/dr-setup.yaml`?
- No → aplicar detección heurística de stack con estado (señales del Nivel 4):
  - Sin señales de componentes con estado → **SKIP** (Nivel 3).
  - Con señales detectadas → **FAIL** (archivo requerido, no existe). Continuar al reporte.
- Sí → continuar al Paso 3.

### Paso 3 — Verificar `enabled`

¿Existe `.king/dr-setup.yaml` con `enabled: false`?
- Sí → **SKIP** (Nivel 1). Terminar evaluación.
- No → continuar al Paso 4.

### Paso 4 — Verificar campos mínimos

Leer `.king/dr-setup.yaml` y verificar presencia de:
- `recovery.rto_hours` — número > 0
- `recovery.rpo_hours` — número > 0
- `storage.backends` — lista con al menos un item

Si todos presentes → **PASS**.
Si alguno falta → **FAIL** (campos mínimos incompletos).

### Paso 5 — Generar resultado

| Estado | Condición |
|--------|-----------|
| `PASS` | Campos mínimos presentes y válidos |
| `WARN` | FAIL detectado + modo `warn` — promote continúa con warning en el reporte |
| `SKIP` | Nivel 1, 2 o 3 activado |
| `FAIL` | FAIL detectado + modo `error` — promote bloqueado |

> **Determinación del modo cuando no existe `.king/dr-setup.yaml`**: usar el default por ambiente (ver tabla "Campos Mínimos Requeridos"). Para `prod` sin yaml → modo `error` → resultado `FAIL` → promote bloqueado.

---

## Campos Mínimos Requeridos

| Campo | Requerido | Descripción |
|-------|-----------|-------------|
| `recovery.rto_hours` | Sí | Recovery Time Objective en horas (número > 0) |
| `recovery.rpo_hours` | Sí | Recovery Point Objective en horas (número > 0) |
| `storage.backends` | Sí | Al menos un backend de storage (`s3`, `gcs`, o `azure`) |
| `enabled` | No | Default: `true`. Usar `false` para deshabilitar el gate |
| `mode` | No | Default por ambiente cuando no existe yaml: `prod=error` (BLOQUEANTE), `qa=warn` (ADVERTENCIA), `dev=skip`. Usar `error` para bloqueo duro explícito |
| `scope.environments` | No | Default: `[prod]`. Ambientes donde aplica el gate |

---

## Formato de Reporte

```
DR Gate: [PASS|WARN|SKIP|FAIL]
  Config: .king/dr-setup.yaml
  RTO: [N]h | RPO: [N]h
  Storage backends: [s3|gcs|azure|...]
  Recovery tested: [YES|NO|UNKNOWN]
  Reason: [solo si WARN/SKIP/FAIL]
```

---

## Mensaje de Error Accionable

Cuando el resultado es FAIL (modo `error`):

```
DR Gate: FAIL — Disaster Recovery not configured for production.

To configure DR:
  Option A (guided): Run /dr-setup — detects your stack and generates all DR artifacts automatically.
  Option B (manual): cp templates/dr-setup.yaml .king/dr-setup.yaml
                     Edit .king/dr-setup.yaml with your project values.

Required minimum fields: recovery.rto_hours, recovery.rpo_hours, storage.backends (at least one).

To disable the gate for this project: set enabled: false in .king/dr-setup.yaml
```

---

## Modos de Operación

| Modo | Comportamiento | Cuándo usar |
|------|---------------|-------------|
| `warn` (default) | Reporta el problema y permite que el promote continúe — se registra en el Promote Report | Proyectos nuevos, onboarding, equipos adoptando DR progresivamente |
| `error` | Bloquea el promote cuando el gate falla — promote no puede avanzar a Fase 2 | Proyectos críticos de producción donde DR es requisito no negociable |

**El modo se configura en `.king/dr-setup.yaml`.** Si el archivo no existe, el modo se determina según el ambiente destino del promote:
- `prod` → `mode: error` (BLOQUEANTE — promote rechazado si falta la config DR)
- `qa`   → `mode: warn`  (ADVERTENCIA — promote continúa con warning en el reporte)
- `dev`  → `mode: skip`  (SIN GATE — no aplica)

> **Production recommendation**: Once your team has completed the initial DR setup, the `.king/dr-setup.yaml`
> will have `mode: error` for prod by default. If you need to temporarily bypass the gate, set `enabled: false`
> and document the exception — do NOT change to `warn` in production environments.

---

## Excepciones

Para deshabilitar el gate en un proyecto:

```yaml
# .king/dr-setup.yaml
enabled: false
```

Con `enabled: false`, el gate emite **SKIP sin error ni advertencia** en todos los promotes. Usar cuando el proyecto no tiene estado persistente (stateless, serverless sin BD).

---

## Configuración Completa

Ver template: `templates/dr-setup.yaml`

Copiar al proyecto: `cp templates/dr-setup.yaml .king/dr-setup.yaml`

Para generar la configuración automáticamente con detección de stack: ejecutar `/dr-setup`
