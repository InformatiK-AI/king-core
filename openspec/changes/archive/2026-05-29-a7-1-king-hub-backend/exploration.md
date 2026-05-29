# Exploration — A7.1 King Hub backend

> Fase: sdd-explore · Change: a7-1-king-hub-backend

## Fuentes de verdad
- `king-hub-spec.md` §3 (manifest schema), §5 (Quality Score), §6 (backend: stack, 6 endpoints, reglas de negocio).
- `trust-model.md` §1-4: 4 tiers, firma GPG (RSA 4096, detached `.asc`, email=GitHub), scanning (Semgrep/Trivy/Snyk en CI),
  CRL (hashes SHA-256, JSON firmado por core, <48h Tier 3), invariante no-gate-override.
- `king-hub-hosting-adr.md`: Railway (Go always-on + Postgres + Buckets), descargas presigned 302, rate limiting en Go, Cloudflare al frente.

## Requisitos de seguridad que el backend implementa (no redefine)
- **Publish (`POST /skills`)**: verificar firma GPG detached contra el package; clave no expirada; email coincide con
  GitHub; asignar `trust_tier` (derivado, no confiar en lo declarado); rechazar campos derivados (downloads/rating/published_at);
  validar namespace (`author.github` dueño; misma clave para nuevas versiones); rechazar si hash en CRL.
- **Download**: 302 a presigned URL del bucket (NUNCA proxy del binario); rechazar si revocado.
- **Search**: solo Quality Score ≥ 40; excluir revocados; filtros tags/tier/sort.
- **CRL (`GET /crl`)**: JSON firmado por core con hashes revocados.
- **Rate limiting**: 100 installs/min/IP, 10 publishes/día/cuenta.
- **Sin OAuth/JWT**: la confianza viene de GPG + scanning CI + CRL, no de usuarios logueados (per cli-architecture.md).

## Entorno y convenciones (verificado)
- **Go 1.26.3** instalado (scoop) → `go build`/`vet`/`test`/`gofmt` ejecutables localmente.
- Convenciones King (`knowledge/stacks/go/patterns.md`): error wrapping `%w`, context en I/O, interfaces chicas,
  repository pattern, table-driven tests, config por env con fail-fast, graceful shutdown.
- Referencia engram: Go 1.25/1.26, chi, **pgx/v5**, Dockerfile multi-stage (golang-alpine→alpine, CGO_ENABLED=0, non-root 10001).
- Gates CASTLE: coverage 80% global (warn), `/health` + `/ready` obligatorios en prod (`rules/coverage-gate.md`, `health-check-gate.md`).

## Decisión de aproximación
Scaffold completo y **compilable**. Lógica pura (Quality Score determinista — incl. invariante mínimo-40 §5.3 —,
validación de manifest, semver) implementada con tests table-driven (alto valor verificable). Capas de integración
(pgx, S3 presigned, GPG) implementadas con sus libs reales y compilando; su ejecución real necesita DB/bucket/claves
(runtime del usuario). Honestidad: no afirmar que la integración "pasa" sin haberla corrido.

## Riesgos
- **R1**: versiones de libs (pgx/v5, aws-sdk-go-v2, ProtonMail/go-crypto) — `go mod tidy` resuelve; `go build` valida.
- **R2**: GPG en Go (ProtonMail/go-crypto) API verbosa; encapsular en `internal/trust`.
- **R3**: integración no verificable localmente — explícito en README/verify-report.
