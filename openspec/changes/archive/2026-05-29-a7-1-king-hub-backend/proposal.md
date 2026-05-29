# Proposal — A7.1 King Hub backend (servicio Go)

> Fase: sdd-propose · Change: a7-1-king-hub-backend · Backend: openspec (king-core) · Backlog: A7.1

## Why

El King Hub (`king-hub-spec.md`) es el marketplace oficial de skills: terceros publican, los usuarios descubren e
instalan, y el ecosistema crece sin trabajo proporcional del core. La spec (M13) entregó el diseño completo; el
**backend HTTP en Go quedó diferido por diseño**. A7.1 lo construye. El hosting ya fue decidido (ADR Railway,
`king-hub-hosting-adr.md`), así que este ciclo arranca con la infra resuelta.

## What Changes

Repo nuevo standalone `king-hub-backend`: servicio Go (chi) que implementa los 6 endpoints del §6.2, la verificación
del trust-model (GPG/CRL/tiers), el Quality Score determinista y el rate limiting. king-core no cambia salvo el
planning (este change) + cierre del backlog.

## Capabilities (contrato para sdd-spec)

| # | Capability | Artefactos |
|---|------------|------------|
| 1 | `catalog-api` | 6 endpoints HTTP (search/info/publish/download/rate/crl) + /health + /ready, chi router + middleware |
| 2 | `quality-score` | Fórmula determinista §5.1 (PURA, unit-tested), filtro ≥40 en search, recálculo semanal (cron) |
| 3 | `manifest-validation` | Validación de schema §3 (PURA, unit-tested): campos, semver, namespace, rechazo de derivados |
| 4 | `trust-enforcement` | Verificación GPG en publish, asignación de `trust_tier` (derivado), CRL por hash SHA-256 (serve + filtrado) |
| 5 | `secure-downloads` | Descargas vía presigned URL (302), nunca proxy; rechazo si revocado |
| 6 | `rate-limiting` | 100 installs/min/IP, 10 publishes/día/cuenta (chi middleware, token bucket en memoria) |

## Scope

- **In scope**: scaffold Go completo y **compilable** (`go build`/`vet`/`test` verificados); lógica pura
  (Quality Score, manifest, semver) implementada + unit-tested; capas de integración (catalog pgx, storage presigned,
  trust GPG, api chi) implementadas y compilando; migraciones SQL; Dockerfile multi-stage; railway.json;
  `.king/quality-gates.yaml`; README; `git init`.
- **Out of scope (runtime del usuario)**: validar integración Postgres, presigned S3/Railway Buckets, GPG contra
  keyservers, HTTP e2e, deploy a Railway. Se entregan implementadas y compilando; su verificación de runtime queda
  para el usuario (requiere DATABASE_URL + bucket + claves GPG + Railway).
- **Out of scope**: el plugin `king-hub` (4 skills) y el CLI Apex Core (piezas separadas); push/PR/release a remoto
  (diferido a confirmación del usuario); el scanning CI (Semgrep/Trivy/Snyk) vive en GitHub Actions del repo, no en el runtime.

## Affected modules
- **Nuevo**: `D:\King Framework\king-hub-backend\` (repo independiente).
- `king-core/openspec/` (este planning).

## Delivery
- Repo nuevo con commit inicial. La generación es grande (6 endpoints + seguridad) → apply incremental con `go build`
  frecuente. CASTLE esperado **CONDITIONAL** (build+unit verificados; integración/runtime diferidos), como A7.3.

## Rollback plan
- Repo nuevo y aislado: revertir = borrar el directorio. No afecta ningún plugin.
- El planning en king-core/openspec es aditivo: revertir = borrar el change.
