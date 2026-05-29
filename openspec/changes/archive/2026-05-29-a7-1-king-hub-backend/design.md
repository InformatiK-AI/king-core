# Design — A7.1 King Hub backend

> Fase: sdd-design · Fuente: king-hub-spec.md §6 + trust-model.md + king-hub-hosting-adr.md + knowledge/stacks/go/patterns.md

## Decisiones

### D1 — Stack y versiones
Go (go.mod `go 1.25`) · `github.com/go-chi/chi/v5` (router) · `github.com/jackc/pgx/v5` (Postgres, alineado a engram) ·
`github.com/aws/aws-sdk-go-v2` + `feature/s3/v4` presign (S3-compat / Railway Buckets / Tigris) ·
`github.com/ProtonMail/go-crypto/openpgp` (verificación GPG). stdlib `net/http`, `crypto/sha256`, `encoding/json`.

### D2 — Layout (cmd/internal)
Un solo binario con subcomandos (per ADR): `cmd/king-hub/main.go` → `serve` (HTTP) | `cron` (recálculo semanal de QS).
`internal/` no exporta fuera del módulo. Capas: `api` (router/handlers/middleware) → `catalog` (repo pgx) +
`quality`/`manifest` (puro) + `trust` (GPG/CRL) + `storage` (S3 presign) + `config`.

### D3 — Lógica pura aislada y testeable
`quality.Score(inputs) int` y `manifest.Validate(raw []byte) (Manifest, []error)` y `semver` son **funciones puras**
(sin I/O) → unit tests table-driven. Es el núcleo verificable sin DB/red. La Quality Score implementa §5.1 con cap 100
y el invariante mínimo-40 (§5.3) como caso de test.

### D4 — Descargas presigned 302 (guardarraíl económico del ADR)
`storage.PresignGet(key) (url, error)` genera la URL firmada; el handler de download responde `http.Redirect(w,r,url,302)`.
NUNCA `io.Copy` del binario por el handler. Un test de handler verifica que la respuesta es 302 con Location al host del bucket.

### D5 — trust_tier y derivados son server-side
El handler de publish ignora `trust_tier`, `downloads`, `rating`, `published_at` del request y los calcula/inicializa.
`trust.AssignTier(gpgResult)` deriva el tier de la verificación GPG.

### D6 — Rate limiting en middleware
`api/middleware/ratelimit.go`: token bucket en memoria por IP (installs) y por cuenta (publishes). Single-instance
(suficiente always-on); nota para Redis al escalar a réplicas. Excedido → 429.

### D7 — Config fail-fast
`config.Load()` lee env (DATABASE_URL, STORAGE_*, CORE_GPG_KEY, PORT) y falla en startup si faltan los requeridos.

## Schema Postgres (migrations/0001_init.sql)
```
authors(github PK, gpg_key_id, created_at)
skills(id PK, namespace UNIQUE, author_github FK, description, tags[], castle_layers[], created_at)
versions(id PK, skill_id FK, version, api_version, king_framework_version, package_hash, quality_score, published_at,
         UNIQUE(skill_id, version))
ratings(id PK, skill_id FK, value REAL CHECK 1..5, created_at)
crl(package_hash PK, skill_namespace, revoked_at, reason)
```

## Mapa endpoint → capa
| Endpoint | Handler usa |
|----------|-------------|
| GET /skills | catalog.Search (filtra QS≥40 + CRL) |
| GET /skills/{a}/{n} | catalog.Get + versions |
| POST /skills | manifest.Validate → trust.VerifyGPG → trust.AssignTier → quality.Score → catalog.Insert (rechaza CRL/namespace) |
| GET .../download/{v} | catalog.GetVersion (check CRL) → storage.PresignGet → 302 |
| POST .../rate | catalog.AddRating → quality.Score recalc |
| GET /crl | trust.SignedCRL (JSON) |
| GET /health,/ready | api.health (ready chequea db+storage) |

## Verificación (alineada al scope)
- **Por mí (Go 1.26 instalado)**: `go mod tidy` · `go build ./...` 0 errores · `go vet ./...` · `go test ./...`
  (quality/manifest/semver + handler download-302 + ratelimit-429 con httptest) · `gofmt -l`.
- **Runtime del usuario**: migraciones+queries Postgres, presigned real S3, GPG contra keyservers, e2e, deploy Railway.

## Estrategia git
Repo nuevo `king-hub-backend` + commit inicial. Push/PR/release → diferido a confirmación del usuario.
