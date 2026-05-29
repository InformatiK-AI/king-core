---
name: license-check
description: "Verifica si hay una licencia King activa con tier suficiente antes de ejecutar un skill premium, leyendo la observation king-framework/license en Engram. Modo verify retorna { tier, features_available[], upgrade_required }; en modo degradado (Engram caído) asume 'core' y nunca bloquea. También gestiona la licencia: activate <key>, status (key enmascarada), deactivate. Nunca expone la key completa."
argument-hint: "[--require core|pro|team|enterprise] | activate <key> | status | deactivate"
allowed-tools: [Read, Skill]
---

# /license-check

Resuelve el **tier efectivo** del entorno y decide si un skill premium puede ejecutarse, leyendo una
observation local en Engram (`king-framework/license`) — sin base de datos externa ni telemetría. Lo invocan
otros skills premium en su Fase 0 (modo `verify`), y el usuario directamente para gestionar su licencia
(`activate` / `status` / `deactivate`). Alimenta **CASTLE S (Security)**: la key NUNCA se expone en output.

> **Confianza, no DRM**: el gate es de buena fe (BSL 1.1, no protección técnica). Bypassearlo es posible y
> esperado — el moat de King es soporte + comunidad + features, no un candado. Ver `knowledge/universal/business-model.md`.

## Instrucciones

1. Invocar el skill `license-check` usando la herramienta Skill
2. Argumentos (modo se resuelve del subcomando; default `verify`):
   - `--require <tier>`: tier mínimo que el skill llamador necesita (`core|pro|team|enterprise`, default `pro`)
   - `activate <key>`: valida la key contra el endpoint de validación y persiste la observation si es válida
   - `status`: muestra tier activo, vencimiento y seats (key enmascarada — solo últimos 4 chars)
   - `deactivate`: expira/remueve la licencia local
3. Seguir las fases del skill en orden: Resolve mode + read engram → Validate tier/key → Return result/persist
4. Agente coordinado: @security (key nunca expuesta, modo degradado no es bypass silencioso, solo persistir licencias validadas)
5. IMPORTANTE: NUNCA imprimir la key completa; NUNCA bloquear por fallo de Engram (modo degradado → `core`);
   NUNCA tratar una licencia `expires_at < today` como válida; NUNCA persistir una licencia sin validar la key

El contrato de la observation, la lógica de verificación de 6 pasos, el modo degradado y los mensajes estándar
exactos (upgrade / expiración / degradado) viven en `knowledge/universal/license-management.md` — single source
of truth que este skill consume.

## Ejemplos

### Un skill premium verifica licencia en su Fase 0

```
/license-check --require pro
```
Retorna `{ tier, features_available[], upgrade_required }`. Si `upgrade_required`, el skill llamador muestra el
mensaje de upgrade y se detiene.

### Activar una licencia tras pagar

```
/license-check activate KF-PRO-7H2K-X4F2
```
Valida la key y persiste la observation. Confirma: "Licencia King Pro activada hasta 2026-06-28. ¡A construir!".

### Consultar estado (key enmascarada)

```
/license-check status
```
Muestra: `Tier: pro · Vence: 2026-06-28 · Seats: 1 · Key: KF-PRO-····-X4F2`.

### Desactivar la licencia local

```
/license-check deactivate
```

## Los 4 modos

| Modo | Disparador | Qué hace | Escribe sesión |
|------|-----------|----------|----------------|
| `verify` (default) | Skill premium en su Fase 0, o `--require <tier>` | Resuelve tier efectivo y `upgrade_required` | No (silencioso) |
| `activate <key>` | Usuario tras pagar | Valida la key y persiste la observation | Sí |
| `status` | Usuario | Muestra estado con key enmascarada | No |
| `deactivate` | Usuario | Expira/remueve la licencia local | Sí |

## Lógica de verificación (6 pasos)

```
1. Leer observation king-framework/license (mem_search → mem_get_observation, timeout ~3s)
2. Si no existe              → TIER = "core"
3. Si existe → parsear { tier, key, expires_at, seats }
4. Si expires_at < today     → TIER = "core" (expirada)
5. Si seats < devs_activos   → TIER reducido (sobreuso de Team)
6. Retornar { tier, features_available[], upgrade_required }
```

> **Modo degradado**: si Engram no responde en ~3s, continúa en tier `core` y NUNCA bloquea. Solo bloquea por
> ausencia explícita de licencia para un skill premium.

## Mensajes estándar (texto exacto)

**Upgrade** (skill premium sin licencia suficiente):
```
Este skill requiere King Pro ($29/mes).
Activá tu licencia con: king-framework license activate <key>
Conseguí tu key en: kingframework.dev/pro
```

**Expiración** (licencia vencida):
```
Tu licencia King Pro venció el YYYY-MM-DD.
Renovala con: king-framework license activate <key>
Gestioná tu suscripción en: kingframework.dev/account
```

> Para skills que requieren Team/Enterprise, sustituir el tier en el mensaje de upgrade por el requerido.

## Seguridad (CASTLE S)

- La `key` NUNCA aparece completa en output — solo los últimos 4 chars en `status`, o nada en `verify`.
- El JSON crudo de la observation NUNCA se vuelca al usuario.
- En `activate`, NO se persiste ninguna licencia sin validar la key primero.
- El contrato de la observation que este skill lee es el mismo que escribe el webhook
  `checkout.session.completed` de Stripe (cambio `m14-billing-entrepreneur`) — dos extremos del mismo flujo.
