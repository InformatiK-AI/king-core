# Design — M-17 Apex Core + M-63 CLI (spec)

> Fase: sdd-design · Fuente de verdad: `mejora/planes-detallados/M12-developer-experience-tooling.md`
> (§2 M-17/M-63, §6 T16-T40, §7 Gherkin). Este design no duplica ese detalle: lo referencia.

## Decisión arquitectónica central

M-17/M-63 se entregan **como spec accionable** (knowledge markdown), no como código Go. El "producto" in-repo
son DOS docs en `knowledge/universal/` que definen el CONTRATO del binario `king-framework` (Apex Core). El
binario, su CI, firma y distribución viven en el repo externo `king-framework/apex-core`. La verificación in-repo
es **completitud y coherencia del contrato**, no ejecución de un binario.

## Por qué un solo cambio (fusión M-17 + M-63)

M-17 (motor: interface + adapters) y M-63 (volante: comandos) describen el **mismo binario** y M-63 escribe en el
**mismo archivo** `cli-architecture.md` que M-17 (T22/T24-T26 vs T30-T40). Separarlos garantizaría conflicto de
escritura. Un cambio = un dueño del archivo = cero conflicto. El `multi-platform-adapters.md` es de M-17; el
`cli-architecture.md` es compartido y lo posee este cambio.

## Anatomía de cada knowledge doc (convención `knowledge/universal/`)

- Encabezado con propósito + a qué item M12 corresponde + nota "SPEC del binario externo".
- Secciones con contrato preciso: interfaces/structs (en bloque ```go como contrato, no como impl), tablas de
  plataformas/comandos/exit-codes, mapeos de formato, merge strategy, fixtures, testing strategy.
- Cada escenario del Gherkin §7 MUST tener su contrato reflejado en el doc (trazabilidad verify).
- Referencias cruzadas: `cli-architecture.md` ↔ `multi-platform-adapters.md`; ambos ↔ `skill-versioning.md`.

## Mapeo tareas → artefacto

| Tareas | Artefacto |
|--------|-----------|
| T16-T21, T23, T27-T29 | `multi-platform-adapters.md` (interface, adapters por tier, fixtures, versioning, revisión) |
| T22, T24-T26, T30-T40 | `cli-architecture.md` (structs, comandos, distribución, firma, completions, testing, revisión) |

## Decisiones específicas

1. **Merge no-destructivo + backup** es requisito transversal de TODO adapter (riesgo R02 del doc). Se especifica
   `.king/backups/pre-install/` e idempotencia para formatos append.
2. **Tiers 1/2/3** explícitos: feature-parity total en 11 plataformas es imposible (R05) → la matriz declara qué
   capacidad ofrece cada tier; Tier 2/3 no bloquean release.
3. **Firma GPG obligatoria** en `update` (R01): se especifica verificación previa al reemplazo del binario.
4. **Consistencia con M-11**: los comandos `doctor`/`status` del CLI deben cubrir lo que el skill `onboard`
   (C2) invocará como `doctor`/`status`/`hint` (T40). Por eso C1 va ANTES de C2.

## Fuera de alcance (repo externo)

Implementación Go, packages reales, CI matrix OS, publicación Homebrew/Scoop/Docker/go-install, generación de la
key GPG. El doc los ESPECIFICA (qué y cómo), el repo `apex-core` los ejecuta.
