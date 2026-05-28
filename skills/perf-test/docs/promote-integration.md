# Integración perf-test ↔ /promote (T-24)

> Cómo el gate de performance de `/perf-test` puede vetar `/promote`.
> Referencia: `skills/promote/SKILL.md`, `knowledge/universal/performance-budget.md`.

## Contrato

`/perf-test` escribe, en cada corrida, un resumen en `.king/perf/{timestamp}-{feature}-summary.md`
y los datos en `.king/perf/{timestamp}-{feature}-results.json`. `/promote` lee el **resultado más
reciente** por feature antes de promover a `staging`/`prod`.

## Flujo del gate

```
/perf-test  ──escribe──►  .king/perf/{ts}-{feature}-results.json  (verdict, enforcement)
                                        │
/promote staging/prod  ──lee el más reciente──►  ¿enforcement == block  Y  p95 > budget?
                                        │
                          sí ──► VETO: bloquea el promote
                          no ──► continúa el pipeline de promote
```

## Condición de veto

`/promote` veta cuando, para algún endpoint del feature promovido:

```
enforcement == "block"   AND   p95_medido > budget_p95
```

Mensaje de veto (estándar):

```
Performance gate failed: p95 1200ms > 500ms for POST /orders.
Run /perf-test and fix before promoting.
```

## Reglas de frescura

- `/promote` considera sólo resultados con antigüedad ≤ configurable (default: vigentes para el
  commit/branch actual). Un `results.json` de un commit anterior no satisface el gate.
- Si NO existe ningún `.king/perf/*` para el feature y `enforcement: block` → `/promote` advierte
  "sin evidencia de performance" y solicita correr `/perf-test` primero.
- Con `enforcement: warn`, el exceso de p95 produce WARNING en el reporte de promote, sin bloquear.

## Interacción con CASTLE E

El veredicto CASTLE E del último `/perf-test` se agrega al CASTLE assessment de `/promote`:

| perf-test verdict | enforcement | Efecto en /promote |
|-------------------|-------------|--------------------|
| PASS (dentro de budget) | cualquiera | sin efecto |
| CONDITIONAL (excede) | warn | WARNING en el reporte, promueve |
| BREACHED (excede) | block | VETO — promote bloqueado |

> El budget vive en `.king/performance.yaml`. Subir el budget para "pasar" el gate es una
> decisión consciente y trazable (queda en el diff), no un bypass silencioso.
