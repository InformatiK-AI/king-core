# License Management — Engram Observation Contract

> Knowledge universal · Milestone M14 (M-95c + B4) · Fuente: `mejora/planes-detallados/M14-business-model-monetization.md`
> **Single source of truth** del esquema de la licencia. Lo consumen tres extremos:
> `/license-check` (lee), el CLI de activación (escribe), y el webhook `checkout.session.completed` de Stripe
> (escribe, en king-entrepreneur). Si cambiás el esquema, cambialo SOLO acá.

---

## 1. Esquema de la observation `king-framework/license`

La licencia vive como una observation en el Engram del entorno del usuario. No hay base de datos externa ni
telemetría: la verificación es 100% local contra Engram.

```json
{
  "topic_key": "king-framework/license",
  "type": "policy",
  "scope": "project",
  "content": {
    "tier": "pro",
    "key": "KF-PRO-XXXX-XXXX",
    "activated_at": "2026-05-28T00:00:00Z",
    "expires_at": "2026-06-28T00:00:00Z",
    "seats": 1,
    "email": "user@example.com"
  }
}
```

| Campo | Tipo | Descripción |
|-------|------|-------------|
| `tier` | `"core" \| "pro" \| "team" \| "enterprise"` | Tier activo. Ausencia de observation ⇒ `core`. |
| `key` | string | Key de licencia (`KF-<TIER>-XXXX-XXXX`). NUNCA se imprime completa en output. |
| `activated_at` | ISO 8601 | Cuándo se activó. |
| `expires_at` | ISO 8601 | Vencimiento. Si `< today` ⇒ tratada como `core` (expirada). |
| `seats` | int | Asientos contratados. Si `seats < devs_activos` ⇒ tier reducido (sobreuso de Team). |
| `email` | string | Email del titular (para soporte/renovación). |

> **Contrato congelado**: el handler `checkout.session.completed` de Stripe (cambio `m14-billing-entrepreneur`)
> MUST escribir exactamente estos campos. `/license-check` Phase 1 los parsea. Cualquier divergencia rompe el
> flujo end-to-end pago→activación (riesgo R1).

---

## 2. Flujo de activación

```
Usuario recibe email post-pago con key: KF-PRO-XXXX-XXXX
  ↓
Ejecuta: /license activate KF-PRO-XXXX-XXXX
  ↓
license-check detecta el parámetro "activate"
  ↓
Valida la key contra el endpoint de validación (Stripe metadata o Keygen.sh)
  ↓
Si válida: mem_save observation king-framework/license con los datos del tier
  ↓
Confirma: "Licencia King Pro activada hasta YYYY-MM-DD. ¡A construir!"
  ↓
Próxima invocación de skill premium: license-check pasa sin fricción
```

**Endpoint de validación**: en v1.9 puede ser un webhook simple en Vercel (Node.js + Stripe SDK, ~50 líneas)
que valida la key contra la metadata de Stripe. En v2.0, migrar a Keygen.sh si el volumen lo justifica. Este
endpoint NO es parte de este cambio (es infraestructura desplegada aparte).

**Persistencia (escritura)**:
```
mem_save(
  topic_key: "king-framework/license",
  type: "policy",
  scope: "project",
  content: { tier, key, activated_at, expires_at, seats, email }
)
```

**Lectura**:
```
mem_get_observation(topic_key: "king-framework/license")  // vía mem_search → mem_get_observation
```

---

## 3. Lógica de verificación de tier

`/license-check` resuelve el tier efectivo así (Phase 1 → Phase 2):

```
1. Leer observation `king-framework/license` (mem_search → mem_get_observation)
2. Si la observation no existe              → TIER = "core"
3. Si existe → parsear { tier, key, expires_at, seats }
4. Si expires_at < today                    → TIER = "core" (expirada)
5. Si seats < devs_activos                  → TIER reducido (sobreuso de Team)
6. Retornar { tier, features_available[], upgrade_required: bool }
```

**Modo degradado (no bloquear por infraestructura — riesgo S-LIC-2)**: si Engram no responde en ~3 segundos,
license-check continúa con tier `core` (o el último tier conocido cacheado en la sesión). NUNCA bloquea al
usuario por un error de Engram; solo bloquea por **ausencia explícita** de licencia para un skill premium.

---

## 4. Mensajes estándar (B4 — texto exacto, no negociable)

Estos mensajes son fijos. Mantenerlos idénticos en todos los skills premium para coherencia de marca.

### Mensaje de upgrade (skill premium sin licencia suficiente)

```
Este skill requiere King Pro ($29/mes).
Activá tu licencia con: king-framework license activate <key>
Conseguí tu key en: kingframework.dev/pro
```

> Si el skill requiere un tier superior (Team/Enterprise), sustituir "King Pro ($29/mes)" por el tier exacto
> requerido (e.g. "King Team ($99/mes)").

### Mensaje de expiración (licencia vencida)

```
Tu licencia King Pro venció el YYYY-MM-DD.
Renovala con: king-framework license activate <key>
Gestioná tu suscripción en: kingframework.dev/account
```

### Mensaje de modo degradado (Engram no responde)

```
No se pudo verificar la licencia (Engram no respondió). Continuando en tier Core.
Si tenés una licencia activa, reintentá cuando Engram esté disponible.
```

---

## 5. Integración con skills premium (contrato de Fase 0)

Cualquier skill premium invoca license-check al inicio de su Fase 0:

```
Fase 0 de cualquier skill premium:
  [ ] Invocar license-check
  [ ] Si upgrade_required: mostrar el mensaje de upgrade estándar y DETENER (no ejecutar lógica de negocio)
  [ ] Si tier suficiente: continuar con Fase 1 del skill
```

---

## 6. Seguridad de la key (riesgo S-LIC-1)

- license-check NUNCA imprime la key completa en su output.
- `/license status` muestra solo los **últimos 4 caracteres** (e.g. `KF-PRO-····-X4F2`).
- La observation no se vuelca en respuestas al usuario.
- La key solo es visible en el momento de activación (el usuario la tipea) y luego desaparece del contexto.

---

## Relacionado

- [[business-model]] — tiers, qué skills son premium, términos BSL 1.1.
- [[soc2-compliance]] — Engram como retention policy (CC6.7).
