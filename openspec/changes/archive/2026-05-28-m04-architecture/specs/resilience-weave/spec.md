# Delta Spec — resilience-weave (M-10)

## ADDED Requirements

### Requirement: Knowledge `resilience-patterns.md`
El framework SHALL proveer `knowledge/domain/resilience-patterns.md` con 9 patrones (Retry, Circuit Breaker,
Bulkhead, Timeout, Rate Limiting, Throttling, Hedged Requests, Graceful Degradation, Chaos Engineering),
tabla de librerías por stack (Node/Go/Python/Java/Rust) y anti-patrones (retry en op. no idempotente).

### Requirement: Skill `/resilience-weave`
El skill `/resilience-weave` SHALL tejer retry/circuit-breaker/bulkhead/timeout/fallback en código que llama
a servicios externos. La fase Classify MUST determinar idempotencia ANTES de tejer retry. SHALL generar
`apex.resilience.yaml` y tests de chaos.

#### Scenario: Teje los 5 patrones en código HTTP
- **Given** un archivo con una llamada fetch sin manejo de fallos
- **When** el developer ejecuta `/resilience-weave` sobre el archivo
- **Then** el código tiene retry (backoff exp + jitter), circuit breaker (50%), bulkhead (10), timeout (5000ms), fallback
- **And** se genera `apex.resilience.yaml` con la configuración aplicada

#### Scenario: NO teje retry en operación no idempotente
- **Given** un endpoint `POST /orders` (no idempotente)
- **When** el developer ejecuta `/resilience-weave`
- **Then** NO agrega retry, sugiere `/idempotency` primero, y sí teje circuit breaker + timeout

### Requirement: Hook `resilience-check` (ADITIVO)
`hooks/hooks.json` SHALL incorporar un hook PostToolUse `resilience-check` que detecte llamadas HTTP/SDK
sin wrapper de retry/timeout y emita WARNING (enforcement: warn por defecto; block opcional vía `.king/resilience.yaml`).
El hook MUST añadirse al array existente sin remover hooks previos.

#### Scenario: Hook advierte sobre llamada HTTP sin resiliencia
- **Given** un archivo con llamada axios sin retry ni timeout
- **When** el agente modifica el archivo via Write
- **Then** el hook emite WARNING con la línea específica y sugiere `/resilience-weave` (no bloquea)

> Set Gherkin completo: M04 §7 (Feature: Resilience Weaver).
