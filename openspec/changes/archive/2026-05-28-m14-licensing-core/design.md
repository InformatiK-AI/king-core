# Design — M14 Licensing Core

> Fase: sdd-design · Change: m14-licensing-core
> Fuente de verdad: `mejora/planes-detallados/M14-business-model-monetization.md` §2.

## Decisiones de arquitectura

### D1 — Licensing por confianza (BSL 1.1), no por DRM

El modelo es **legal, no técnico**. BSL 1.1 (igual que Terraform): libre para uso no-comercial, licencia paga
para comercial, conversión a Apache 2.0 a los 4 años. `license-check` es un gate de **confianza** — un usuario
avanzado puede bypassearlo borrando la llamada del SKILL.md, y eso se documenta explícitamente para no crear
falsa expectativa de "anti-piracy" (riesgo S-LIC-3). El moat real es soporte + comunidad + features, no el
candado técnico.

**Rationale**: invertir en DRM técnico para un framework open-source de Markdown sería esfuerzo desperdiciado;
el ROI está en la propuesta de valor, no en la protección.

### D2 — Engram como store de licencia (no DB externa)

La licencia vive como una observation `king-framework/license` en Engram del entorno del usuario. Ventajas:
cero infraestructura nueva, ya está integrado, y el contrato es un JSON simple. El webhook de Stripe escribe la
observation; `license-check` la lee. Son los dos extremos del mismo flujo.

**Modo degradado (D2.1)**: si Engram no responde en ~3s, `license-check` asume tier `core` y continúa. NUNCA
bloquea por error de infraestructura — solo por ausencia explícita de licencia. Esto evita que una caída de
Engram deje inutilizable todo skill premium (riesgo S-LIC-2).

### D3 — Contrato de observation congelado en un solo archivo

El esquema JSON de `king-framework/license` se define **una sola vez** en
`knowledge/universal/license-management.md` y los demás (skill license-check, webhook Stripe del cambio hermano)
lo referencian. Single source of truth → evita drift entre el que escribe y el que lee (riesgo R1).

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

### D4 — Step de genesis informativo, no bloqueante

La integración en genesis (Bloque C) muestra el mensaje de upgrade **una sola vez** al cerrar el scaffold si no
hay licencia activa. NO bloquea, NO interrumpe — solo informa. Genesis debe funcionar idéntico para usuarios
Core. Esto preserva la experiencia free-tier y evita fricción en el primer uso.

### D5 — Seguridad de la key (riesgo S-LIC-1)

`license-check` NUNCA imprime la key completa en output. `/license status` muestra solo los últimos 4
caracteres. La observation no se vuelca en respuestas al usuario. La key solo es visible en el momento de
activación (el usuario la tipea) y luego desaparece del contexto.

## Fases del skill license-check

```
Phase 0 (Load) → Phase 1 (read-engram, con fallback degradado)
             → Phase 2 (validate-tier) → Phase 3 (return-result / activate)
```

- **Phase 1** lee la observation; si Engram no responde → tier `core` (degradado).
- **Phase 2** valida `expires_at` (expirada → core) y `seats` vs devs activos (sobreuso → tier reducido).
- **Phase 3** retorna `{ tier, features_available[], upgrade_required }`. Si se invocó con `activate <key>`,
  valida y persiste la observation.

## CASTLE

`_·_·S·_·_·_` — capa S central: no exponer la key en output; el contrato de la observation es el activo a
proteger. Verdicto BREACHED si la key se filtra en logs/output; CONDITIONAL si el modo degradado no está
implementado.

## Alternativas descartadas

| Alternativa | Por qué se descartó |
|-------------|---------------------|
| DB externa para licencias | Infra nueva, costo operativo, latencia; Engram ya resuelve el caso |
| DRM técnico (ofuscación, firma de skills) | Esfuerzo alto, ROI nulo en framework de Markdown open-source; el modelo es de confianza |
| Bloquear genesis sin licencia | Mata la experiencia free-tier y la conversión; el step debe ser informativo |
| Esquema de observation duplicado por consumidor | Drift garantizado entre escritor y lector; se congela en un solo archivo |
