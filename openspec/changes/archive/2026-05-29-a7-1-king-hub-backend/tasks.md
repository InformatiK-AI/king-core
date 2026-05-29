# Tasks — A7.1 King Hub backend

> Fase: sdd-tasks · Agrupadas por módulo. Apply con `go build` incremental.

## B0 — Setup
- [ ] B0.1 `git init` king-hub-backend + `.gitignore` (Go) + go.mod (`module github.com/InformatiK-AI/king-hub-backend`, `go 1.25`).
- [ ] B0.2 `.king/quality-gates.yaml`, `railway.json`, `README.md`, `Dockerfile` multi-stage.

## B1 — Lógica pura (verificable sin runtime) + tests
- [ ] B1.1 `internal/manifest/manifest.go` (tipos + `Validate`) + `manifest_test.go` (campos, semver, namespace, rechazo derivados).
- [ ] B1.2 `internal/quality/score.go` (`Score` §5.1, cap 100) + `score_test.go` (invariante mínimo-40, determinismo, cap).
- [ ] B1.3 `internal/semver` helper (válido + rango compat) + test.

## B2 — Integración (implementada, runtime-deferred)
- [ ] B2.1 `internal/config/config.go` (Load env, fail-fast).
- [ ] B2.2 `internal/catalog/` (pgx repo: Search/Get/Insert/AddRating/GetVersion + CRL filter).
- [ ] B2.3 `internal/storage/` (aws-sdk-go-v2 S3 presign GET/PUT).
- [ ] B2.4 `internal/trust/` (VerifyGPG con go-crypto, AssignTier, SignedCRL, IsRevoked).
- [ ] B2.5 `migrations/0001_init.sql` (authors/skills/versions/ratings/crl).

## B3 — API (chi)
- [ ] B3.1 `internal/api/router.go` (chi, rutas /api/v1 + /health + /ready) + `middleware/` (ratelimit, logging, recovery).
- [ ] B3.2 Handlers: search, info, publish, download (302), rate, crl, health/ready.
- [ ] B3.3 `cmd/king-hub/main.go` (subcomandos serve|cron) + graceful shutdown.
- [ ] B3.4 Tests httptest: download responde 302 a presigned (nunca 200 binario); ratelimit 429.

## B4 — VERIFY
- [ ] B4.1 `go mod tidy` (resuelve deps).
- [ ] B4.2 `go build ./...` → 0 errores.
- [ ] B4.3 `go vet ./...` limpio.
- [ ] B4.4 `go test ./...` → unit (quality/manifest/semver) + handler (download-302/ratelimit) pass.
- [ ] B4.5 `gofmt -l .` → sin diffs. Documentar integración diferida (README + verify-report).

## B5 — ARCHIVE
- [ ] B5.1 Commit inicial king-hub-backend + commit planning king-core (openspec).
- [ ] B5.2 Archivar change; state.yaml + memoria; backlog A7 (A7.1 → en build).
- [ ] B5.3 Push/PR/release → DIFERIDO a confirmación del usuario.
