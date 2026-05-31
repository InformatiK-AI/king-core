---
name: license-check
version: 2.0
api_version: 1.0.0
description: "Verifica si hay una licencia King activa con tier suficiente antes de ejecutar un skill premium, leyendo la observation `king-framework/license` en Engram. Retorna { tier, features_available[], upgrade_required }. En modo degradado (Engram no responde en ~3s) asume tier 'core' y NUNCA bloquea por error de infraestructura — solo por ausencia explícita de licencia. También gestiona la licencia desde CLI: `activate <key>` (valida y persiste), `status` (muestra tier/vencimiento/seats con la key enmascarada) y `deactivate`. NUNCA expone la key completa en output. Usar cuando: un skill premium arranca su Fase 0, el usuario activa/consulta/desactiva una licencia, o se necesita resolver el tier efectivo del entorno. Alimenta CASTLE S (Security)."
model: haiku
---

# /license-check — Verificación y Activación de Licencia King

Resuelve el **tier efectivo** del entorno y decide si un skill premium puede ejecutarse. Lee la licencia desde
una observation local en Engram (`king-framework/license`) — sin base de datos externa ni telemetría. En modo
**verificación** (lo invocan otros skills en su Fase 0) retorna `{ tier, features_available[], upgrade_required }`
y, si falta licencia para un skill premium, muestra el mensaje de upgrade estándar y detiene al skill llamador.
En modo **gestión** (CLI directo) activa (`activate <key>`), consulta (`status`) o desactiva (`deactivate`) la
licencia.

> **Confianza, no DRM**: este gate es de buena fe. Un usuario avanzado puede bypassearlo borrando la llamada
> del SKILL.md del skill premium — y eso es esperado. El modelo de King es legal (BSL 1.1), no técnico. No
> prometemos anti-piratería. Ver [[business-model]] §1.

> **Path resolution**: la observation se lee/escribe en el Engram del proyecto actual (resuelto por git remote,
> no por cwd). No hay paths de archivo que resolver.

## Knowledge Injection

Read the following files BEFORE Phase 1. If a file does not exist, log a warning and continue — graceful degradation applies.

| File | Purpose | Required | Source |
|------|---------|----------|--------|
| `knowledge/universal/license-management.md` | Esquema de la observation, lógica de verificación, modo degradado y **mensajes estándar exactos** (upgrade/expiración/degradado) | Yes | framework |
| `knowledge/universal/business-model.md` | Tiers y qué skills son premium (Core/Pro/Team/Enterprise) | Yes | framework |

**Graceful degradation**: If a file does not exist, log a warning and continue — pero los mensajes estándar y
el mapeo de tiers se degradan a defaults documentados aquí.

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Si alguna es TRUE, DETENER inmediatamente

- [ ] Se invocó `activate` sin proveer una `<key>`
- [ ] Se invocó `activate <key>` pero no hay endpoint de validación resoluble NI el usuario acepta activación offline (sin validación)

> Nota: la **ausencia de licencia** NO es una BLOCKING CONDITION de este skill — es justamente su salida normal
> (`upgrade_required: true`). El skill SIEMPRE corre; es el skill *llamador* el que decide detenerse.

### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA imprimir la `key` completa en ningún output — solo los últimos 4 caracteres (`status`) o nada (verify)
- NUNCA volcar el contenido crudo de la observation `king-framework/license` en la respuesta al usuario
- NUNCA bloquear al usuario por un error/timeout de Engram — eso es modo degradado (tier `core`), no un bloqueo
- NUNCA tratar una licencia con `expires_at < today` como válida (es expirada → tier `core`)
- NUNCA persistir una observation de licencia con una key que no pasó validación (modo `activate`)
- NUNCA saltar un CHECKPOINT sin verificar todos sus ítems

### REQUIRED OUTPUTS
> Ver `skills/_shared/lifecycle-outputs.md` para convención de rutas de sesión

- [ ] **Modo verify**: objeto `{ tier, features_available[], upgrade_required }` retornado al skill llamador (y mensaje de upgrade/expiración mostrado si `upgrade_required`)
- [ ] **Modo activate**: observation `king-framework/license` persistida en Engram (solo si la key es válida) + confirmación con fecha de vencimiento
- [ ] **Modo status**: tier activo + `expires_at` + `seats` + key enmascarada (últimos 4 chars)
- [ ] **Modo deactivate**: observation removida/expirada + confirmación
- [ ] Session document creado SOLO en modos con efecto de estado (activate/deactivate) — verify es silencioso (no escribe sesión, para no ensuciar al ser invocado en cada Fase 0)

### PHASES OVERVIEW
```
Phase 0 → Phase 1 → Phase 2 → Phase 3 → Phase N+1 → Phase N+2
(Context)(Resolve   (Validate (Return    (Session:   (Guide)
          mode +     tier /    result /   solo si
          read       key)      persist)   activate/
          engram)                         deactivate)
```

### PARÁMETROS
```
/license-check [--require core|pro|team|enterprise]   # modo verify (default)
/license-check activate <key>                          # activar licencia
/license-check status                                  # consultar estado
/license-check deactivate                              # desactivar
```
- `--require <tier>`: tier mínimo que el skill llamador necesita. Si no se pasa, default `pro` (el caso más común de skill premium).
- `activate <key>`: valida la key contra el endpoint de validación y persiste la observation.
- `status`: muestra el estado sin exponer la key.
- `deactivate`: marca la licencia como expirada / la remueve.

---

## CASTLE activo: _-_-S-_-_-_

> Gate mínimo: CONDITIONAL. Ver `skills/_shared/castle-capas.md`.
> CASTLE S (Security) es la capa central: el activo a proteger es la `key` (nunca exponerla) y la integridad del
> contrato de la observation. Veredicto BREACHED si la key se filtra en logs/output, o si se persiste una
> licencia sin validar. CONDITIONAL si el modo degradado no está implementado (un fallo de Engram bloquearía
> indebidamente). FORTIFIED si la key nunca se expone, el modo degradado funciona y el contrato de la
> observation coincide con `license-management.md`.

## Agentes
- **@security** — Agente principal: garantiza que la key nunca se expone, que el modo degradado no se convierte en bypass silencioso, y que solo se persisten licencias validadas
- **@developer** — Implementa la lectura/escritura de la observation y el parseo del contrato

---

## Phase 0: Load Context

> Delegado a `skills/session-management/SKILL.md` → Phase 0
> Lee los Knowledge Injection files (license-management.md, business-model.md) para resolver el esquema de la
> observation, el mapeo de tiers y los mensajes estándar exactos.

---

## Phase 1: Resolve Mode & Read License

### GATE IN
- [ ] Phase 0 completada (knowledge cargado o degradado con WARN)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] **Resolver el modo** desde los parámetros: `activate <key>` | `status` | `deactivate` | `verify` (default si no hay subcomando). En `verify`, resolver `REQUIRED_TIER` desde `--require` (default `pro`)
2. [ ] **Leer la observation** `king-framework/license` vía `mem_search(query: "king-framework/license")` → `mem_get_observation(id)`. Aplicar **timeout ~3s**
3. [ ] **Fallback degradado** — si Engram no responde dentro del timeout (o falla): marcar `DEGRADED = true`, asumir `tier = "core"`, emitir el mensaje de modo degradado (ver license-management.md §4) y continuar SIN bloquear
4. [ ] **Parsear el contrato** si la observation existe: `{ tier, key, activated_at, expires_at, seats, email }`. Si no existe: `tier = "core"`, `upgrade_required` se decidirá en Phase 2

### CHECKPOINT
- [ ] `MODE` resuelto (`verify` | `activate` | `status` | `deactivate`)
- [ ] Observation leída, o `DEGRADED = true` con tier `core` asumido (nunca bloqueado por Engram)
- [ ] En `verify`: `REQUIRED_TIER` resuelto
- [ ] Contrato parseado o ausencia registrada (sin volcar la key cruda)

### OUTPUTS
- Variables: `MODE`, `REQUIRED_TIER`, `LICENSE{tier,key,expires_at,seats,email}` o `null`, `DEGRADED`

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: No se pudo resolver el modo o leer la licencia.
Cause: parámetros ambiguos, o Engram inaccesible.
Recovery:
  [ ] Option A: si los parámetros son ambiguos, asumir `verify` con `--require pro` (el caso por defecto)
  [ ] Option B: si Engram falla, activar modo degradado (`tier = core`, `DEGRADED = true`) — NUNCA bloquear
  [ ] Option C: en `activate` sin key, abortar con el mensaje de uso del comando (ver commands/license-check.md)

---

## Phase 2: Validate Tier / Key

### GATE IN
- [ ] `MODE` y `LICENSE` (o `null`) resueltos (Phase 1)

### MUST DO
1. [ ] **Modo verify** — resolver el tier efectivo (lógica de license-management.md §3):
   - sin observation → `tier = core`
   - `expires_at < today` → `tier = core` (expirada; recordar para el mensaje de expiración)
   - `seats < devs_activos` → tier reducido (sobreuso de Team)
   - comparar `tier` efectivo vs `REQUIRED_TIER` → `upgrade_required = tier < REQUIRED_TIER`
2. [ ] **Modo activate** — validar la `<key>` contra el endpoint de validación (Stripe metadata / Keygen.sh). Derivar `{ tier, expires_at, seats, email }` de la respuesta. Si inválida: marcar `KEY_VALID = false`
3. [ ] **Modo status / deactivate** — no requiere validación externa; usar la observation leída en Phase 1
4. [ ] **Construir `features_available[]`** (modo verify) según el tier efectivo y el mapeo de business-model.md

### CHECKPOINT
- [ ] Modo verify: `EFFECTIVE_TIER` y `upgrade_required` calculados; expiración detectada si aplica
- [ ] Modo activate: `KEY_VALID` resuelto; si válida, datos del tier derivados; si inválida, NO se persistirá nada
- [ ] `features_available[]` construido (verify)

### OUTPUTS
- Variables: `EFFECTIVE_TIER`, `upgrade_required`, `features_available[]`, `KEY_VALID`, `EXPIRED`

### IF FAILS
ERROR: No se pudo validar el tier o la key.
Cause: endpoint de validación inaccesible (activate), o mapeo de tiers ausente (knowledge degradado).
Recovery:
  [ ] Option A: en `activate`, si el endpoint no responde, ofrecer reintento; NO persistir sin validación (salvo modo offline explícito del usuario)
  [ ] Option B: en `verify`, si el mapeo de tiers no cargó, usar el default conservador (solo los 5 core son gratis; el resto requiere Pro)
  [ ] Option C: ante duda en `verify`, preferir `upgrade_required = false` SOLO si la observation prueba un tier válido; ante ausencia, mantener `core`

---

## Phase 3: Return Result / Persist

### GATE IN
- [ ] Phase 2 completada (`EFFECTIVE_TIER` / `KEY_VALID` resueltos)

### MUST DO
1. [ ] **Modo verify** — retornar `{ tier: EFFECTIVE_TIER, features_available, upgrade_required }`. Si `upgrade_required`: mostrar el **mensaje de upgrade estándar** (o el de **expiración** si `EXPIRED`) exactamente como en license-management.md §4, con el tier requerido correcto. El skill llamador DEBE detenerse
2. [ ] **Modo activate** — solo si `KEY_VALID`: `mem_save` la observation `king-framework/license` con el contrato completo. Confirmar: "Licencia King {Tier} activada hasta YYYY-MM-DD. ¡A construir!". Si `!KEY_VALID`: mostrar error sin persistir nada
3. [ ] **Modo status** — mostrar `tier`, `expires_at`, `seats` y la key **enmascarada** (últimos 4 chars: `KF-PRO-····-X4F2`)
4. [ ] **Modo deactivate** — marcar la observation como expirada (o removerla) y confirmar
5. [ ] **Seguridad** — verificar que en NINGÚN output apareció la key completa ni el JSON crudo de la observation

### CHECKPOINT
- [ ] Verify: objeto retornado + mensaje correcto mostrado si `upgrade_required`/`EXPIRED`
- [ ] Activate: observation persistida SOLO si `KEY_VALID`; confirmación con fecha
- [ ] Status: key enmascarada (nunca completa)
- [ ] Deactivate: licencia marcada expirada/removida
- [ ] Ningún output expuso la key completa ni la observation cruda

### OUTPUTS
- Resultado del modo (objeto verify / confirmación activate / status / deactivate)
- Observation persistida o removida (activate/deactivate)

### IF FAILS
ERROR: No se pudo retornar el resultado o persistir la licencia.
Cause: `mem_save` falló (activate), o el render del mensaje no encontró el tier requerido.
Recovery:
  [ ] Option A: en `activate`, si `mem_save` falla, informar al usuario y NO confirmar activación (estado inconsistente evitado)
  [ ] Option B: si el mensaje estándar no cargó (knowledge degradado), usar el texto default embebido en este skill
  [ ] Option C: en `verify`, ante cualquier fallo, degradar a `core` + `upgrade_required` acorde (nunca falso positivo de licencia)

---

## FINAL CHECKPOINT

- [ ] TODOS los REQUIRED OUTPUTS del modo ejecutado existen
- [ ] La `key` NUNCA apareció completa en output (solo últimos 4 chars en `status`, o nada)
- [ ] El JSON crudo de la observation NUNCA se volcó al usuario
- [ ] Modo degradado funciona: un fallo de Engram resultó en tier `core`, NO en bloqueo
- [ ] `expires_at < today` se trató como expirada (tier `core` + mensaje de expiración)
- [ ] Modo activate: NO se persistió ninguna licencia sin validación previa de la key
- [ ] El contrato de la observation usado coincide con `knowledge/universal/license-management.md`
- [ ] Session document creado SOLO si el modo tuvo efecto de estado (activate/deactivate)

---

## Execution Summary

> Ver template canónico en `skills/_shared/skill-envelope.md`

| Field | Value |
|-------|-------|
| Status | `COMPLETE` \| `PARTIAL` \| `BLOCKED` |
| CASTLE Verdict | _(key nunca expuesta + modo degradado OK + contrato == license-management.md = FORTIFIED; modo degradado ausente = CONDITIONAL; key filtrada o licencia sin validar persistida = BREACHED)_ |
| Artifacts | _(modo verify: objeto {tier,features_available,upgrade_required}; activate: observation persistida; status/deactivate: confirmación)_ |
| Next Recommended | _(el skill llamador continúa su Fase 1 si tier suficiente; si upgrade_required, el usuario va a kingframework.dev/pro)_ |
| Risks | _(Engram como SPOF mitigado por modo degradado; bypass trivial es esperado — modelo de confianza; o "None")_ |

---

## Phase N+1: Write Session

> Delegado a `skills/session-management/SKILL.md` → Phase N+1
> **Condicional**: solo en modos `activate` / `deactivate` (acciones con efecto de estado). El modo `verify` es
> silencioso — NO escribe sesión, porque se invoca en la Fase 0 de cada skill premium y ensuciaría `.king/sessions/`.

---

## Phase N+2: Guide Next Step

> Delegado a `skills/session-management/SKILL.md` → Phase N+2

| Condición | Próximo paso |
|-----------|--------------|
| `verify` con tier suficiente | El skill llamador continúa su Fase 1 normalmente |
| `verify` con `upgrade_required` | Usuario activa licencia: `/license-check activate <key>` (key de kingframework.dev/pro) |
| `verify` con licencia expirada | Usuario renueva en kingframework.dev/account y reactiva |
| `activate` exitoso | Reintentar el skill premium que disparó la verificación |
| Engram caído (degradado) | Reintentar cuando Engram esté disponible si hay licencia activa |

---

## REFERENCE

> 📚 Contexto adicional. Esta sección NO contiene acciones.

### Los 4 modos del skill

| Modo | Disparador | Qué hace | Escribe sesión |
|------|-----------|----------|----------------|
| `verify` (default) | Invocado por un skill premium en su Fase 0, o `--require <tier>` | Resuelve el tier efectivo y decide `upgrade_required` | No (silencioso) |
| `activate <key>` | CLI del usuario tras pagar | Valida la key y persiste la observation | Sí |
| `status` | CLI del usuario | Muestra tier/vencimiento/seats (key enmascarada) | No |
| `deactivate` | CLI del usuario | Expira/remueve la licencia local | Sí |

### Contrato de la observation

El esquema completo (`tier`, `key`, `activated_at`, `expires_at`, `seats`, `email`), la lógica de verificación
de 6 pasos, el modo degradado y los **mensajes estándar exactos** viven en
`knowledge/universal/license-management.md` — **single source of truth**. Este skill los consume; no los
redefine. El webhook `checkout.session.completed` de Stripe (cambio `m14-billing-entrepreneur`) escribe la misma
observation que este skill lee: son los dos extremos del mismo flujo pago→activación.

### Por qué el modo degradado no es un bypass

El modo degradado (Engram caído → `core`) podría parecer un agujero ("apago Engram y soy Core gratis"). No lo
es en la práctica: un usuario que ya tiene licencia válida pierde acceso a sus features premium si apaga Engram
— se castiga a sí mismo. Y el modelo es de confianza de todos modos (ver [[business-model]] §1). La prioridad de
diseño es NO romper el flujo del usuario legítimo ante un fallo de infraestructura (riesgo S-LIC-2) por encima
de cerrar un bypass que el modelo de negocio ya asume abierto.

### Integración con genesis

El skill `genesis` invoca este skill en modo `verify` en su fase final (Bloque C), de forma **informativa y no
bloqueante**: si no hay licencia, muestra el mensaje de upgrade una vez y termina con éxito igual. Ver
`skills/genesis/GENERATION.md`.
