# catalog-api — Delta Spec

> Los 6 endpoints del King Hub backend (§6.2) + health/ready. Capability del change a7-1.

## ADDED Requirements

### Requirement: Endpoints del catálogo

El servicio MUST exponer en `/api/v1`: `GET /skills`, `GET /skills/{author}/{name}`, `POST /skills`,
`GET /skills/{author}/{name}/download/{version}`, `POST /skills/{author}/{name}/rate`, `GET /crl`. MUST exponer además
`GET /health` y `GET /ready` (gate CASTLE). Router: chi.

#### Scenario: Search filtra por Quality Score
- **GIVEN** el catálogo tiene skills con Quality Score 30 y 78
- **WHEN** `GET /api/v1/skills?query=testing`
- **THEN** solo devuelve los de Quality Score ≥ 40
- **AND** excluye cualquier skill cuyo hash esté en la CRL
- **AND** soporta `--tags`, `--tier`, `--sort` (downloads|rating|date)

#### Scenario: Detalle con versiones
- **GIVEN** un skill `autor/nombre` con versiones 1.0.0 y 1.2.0
- **WHEN** `GET /api/v1/skills/autor/nombre`
- **THEN** devuelve metadatos + lista de versiones + trust_tier + quality_score + rating

#### Scenario: Download responde 302 a presigned URL (guardarraíl económico)
- **GIVEN** un package publicado y no revocado
- **WHEN** `GET /api/v1/skills/autor/nombre/download/1.2.0`
- **THEN** responde **302** con `Location` a una presigned URL del object storage
- **AND** NUNCA responde 200 con el binario en el body (no se proxea el artefacto por el compute)
- **AND** si el hash está en la CRL → 403/410 (revocado), no 302

#### Scenario: Rate actualiza el promedio
- **GIVEN** un skill con rating_avg 4.0 (10 reviews)
- **WHEN** `POST /skills/autor/nombre/rate` con value 5.0 (1.0–5.0)
- **THEN** persiste el rating y recalcula rating_avg
- **AND** rechaza valores fuera de [1.0, 5.0]

#### Scenario: Health y Ready
- **WHEN** `GET /health`
- **THEN** 200 con `{status:"ok", version, timestamp}`
- **WHEN** `GET /ready`
- **THEN** 200/503 con `{status, checks:{db, storage}}` (chequea dependencias)

### Requirement: Rate limiting

El servicio MUST aplicar rate limiting vía middleware: **100 installs/min por IP** y **10 publishes/día por cuenta**.
Token bucket en memoria (single-instance); excedido → 429.

#### Scenario: Límite de installs excedido
- **GIVEN** una IP que hizo 100 requests de download en el último minuto
- **WHEN** hace el request 101
- **THEN** responde 429 Too Many Requests
