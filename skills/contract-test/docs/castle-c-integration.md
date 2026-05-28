# Integración CASTLE C — /contract-test (T-08)

> Cómo `/contract-test` alimenta la capa **C (Contracts)** del gate CASTLE.
> Referencia de la capa: `skills/castle/SKILL.md` + `skills/_shared/castle-capas.md`.

## Qué evalúa la capa C

La capa C verifica la **consistencia de interfaces y contratos entre servicios**. Antes de
M05 era un checklist cualitativo; `/contract-test` la convierte en señal cuantitativa:

```
cobertura_contratos = integraciones_con_contrato / integraciones_detectadas
```

## Señales que aporta el skill

| Evidencia | Origen | Ubicación |
|-----------|--------|-----------|
| Integraciones HTTP detectadas | Phase 1 (Discover) | `.king/pact/contract-summary.md` |
| Contratos Pact generados | Phase 2 | `tests/contracts/*.pact.json` |
| Verificación del proveedor | Phase 3 | `tests/contracts/*.provider.test.*` |
| Cobertura de contratos (%) | Phase 5 | `.king/pact/contract-summary.md` |

## Reglas de veredicto (v1)

| Condición | Veredicto C | Efecto |
|-----------|-------------|--------|
| 100% de integraciones con contrato y verificación en verde | `PASS` (FORTIFIED) | sin acción |
| ≥1 integración HTTP sin contrato | `CONDITIONAL` (WARNING) | reportar `"Integration without contract detected: {url}"` |
| Verificación del proveedor en rojo | `CONDITIONAL` + finding | sugerir `/fix` sobre el proveedor |

> **Decisión v1**: la ausencia de contrato produce **WARNING (CONDITIONAL)**, nunca **BREACH**.
> Esto evita bloquear pipelines en proyectos que recién adoptan contract testing. Migrar a
> `BREACH` es una decisión de política por proyecto (futuro: campo `enforcement` en config).

## Consumo por /qa y /castle-report

- `/qa` Fase 5 (CASTLE) lee `.king/pact/contract-summary.md` y agrega el veredicto C al assessment.
- `/castle-report` incluye la cobertura de contratos en el score agregado.
- `/promote` puede leer el broker (`can-i-deploy`) si está configurado, antes de promover a prod.

## Ejemplo de `contract-summary.md`

```markdown
# Contract Summary — order-service

| Integración | Provider | Contrato | Verificación |
|-------------|----------|----------|--------------|
| GET /users/{id} | user-service | ✓ order-service-user-service.pact.json | ✓ PASS |
| POST /payments | payment-service | ✗ sin contrato | — |

Cobertura: 1/2 (50%)  ·  Veredicto CASTLE C: CONDITIONAL
WARNING: Integration without contract detected: POST /payments → payment-service
```
