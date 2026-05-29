# Verify Report — M-17 Apex Core + M-63 CLI (spec)

> Fase: sdd-verify · Change: m17-m63-apex-core-cli-spec · Naturaleza: SPEC-ONLY (valida el DOCUMENTO, no un binario).

## Compliance matrix — Gherkin §7

### M-17 (Feature: Apex Core Multi-platform Adapters) — 5/5
| Escenario | Contrato en el doc | ✓ |
|-----------|--------------------|:-:|
| Cursor no sobreescribe reglas existentes | Merge strategy + backup `.king/backups/pre-install/` + Adapter Cursor | ✓ |
| Gemini genera GEMINI.md válido sin truncar | Idempotencia con marcadores + Adapter Gemini | ✓ |
| Verify reporta capacidades por plataforma | `VerifyReport` struct + render `[OK]/[WARN]/[OK]` | ✓ |
| dry-run muestra cambios sin aplicar | sección `--dry-run` | ✓ |
| Distribución verificable (firma GPG) | ref a `cli-architecture.md` §Firma | ✓ |

### M-63 (Feature: CLI Cross-Platform) — 6/6
| Escenario | Contrato en el doc | ✓ |
|-----------|--------------------|:-:|
| install detecta agente automáticamente | comando `install` | ✓ |
| doctor detecta y reporta problemas (exit 2) | comando `doctor` | ✓ |
| doctor --fix corrige problemas | comando `doctor --fix` | ✓ |
| status output JSON | comando `status --json` | ✓ |
| CLI es cross-platform | §Output (cross-platform) | ✓ |
| update verifica firma antes de aplicar | comando `update` + §Firma | ✓ |

## Cobertura de tareas
- T16-T29 (M-17): cubiertas en `multi-platform-adapters.md` (interface, 11 adapters por tier, structs, fixtures, versioning, checklist T29).
- T22, T24-T26, T30-T40 (M-63 + structs): cubiertas en `cli-architecture.md` (KingConfig, comandos, distribución, firma, completions, testing, consistencia con M-11 T40).
- **Excluidas de este cambio**: T49-T50 (código TS) pertenecen a C3 (M-64), no a C1.

## Checks estructurales
- ✅ Ambos deliverables existen en `knowledge/universal/`.
- ✅ Cross-references relativas (`./skill-versioning.md`, `./cli-architecture.md`, `./multi-platform-adapters.md`) resuelven en worktree y en destino (mismo directorio).
- ✅ Sin secretos (escaneo M-2).
- ✅ Sin scope creep: bloques ```go son CONTRATO (interfaces/structs), no implementación. Binario Go fuera de alcance (repo externo `king-framework/apex-core`).
- ✅ Revisión adversarial: 98% — fixes aplicados (orden por tier documentado, checklist T29 agregado, cross-ref testing). Hallazgo "archivos en worktree" descartado (es la copia de trabajo; el merge los lleva a develop).

## Veredicto
**PASS** (spec-only). Listo para gate CASTLE y merge a develop (CP4 — pausa humana).
