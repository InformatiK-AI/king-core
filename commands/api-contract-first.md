---
name: api-contract-first
description: "Contract-first desde OpenAPI 3.1: genera server stubs, client SDKs, mock server (Prism), contract tests (schemathesis/dredd) y docs (Redoc) — cada output independiente. Valida con spectral y detecta breaking changes con oasdiff"
argument-hint: "[spec-file] [--outputs stubs,sdks,mock,tests,docs] [--server-stack <stack>] [--client-langs <l1,l2>] [--compare-to <prev-spec>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /api-contract-first

Toma una spec **OpenAPI 3.1** y genera, de forma **independiente por output**: **server stubs**
type-safe con validación request/response, **client SDKs**, un **mock server** (Prism) para
`docker-compose`, **contract tests** (schemathesis/dredd) que verifican que el server cumple la spec, y
**docs** (Redoc + Swagger UI). Valida la spec con **spectral** antes de generar nada, y si se provee una
spec anterior, ejecuta una fase EXPLÍCITA de **breaking-change check** con `oasdiff`, reportando cada
cambio con severidad. Alimenta **CASTLE C (Contracts)**.

## Instrucciones

1. Invocar el skill `api-contract-first` usando la herramienta Skill
2. Argumentos:
   - `[spec-file]`: path a la spec OpenAPI 3.1 (YAML/JSON). Si se omite, el skill genera la spec desde una descripción en lenguaje natural del usuario
   - `--outputs <lista>`: outputs a generar, separados por comas (`stubs,sdks,mock,tests,docs`). Default: `stubs,mock,tests`. Cada output es INDEPENDIENTE — se puede pedir solo uno
   - `--server-stack <stack>`: fuerza el stack del servidor para los stubs (ej. `ts-express`, `go-chi`, `python-fastapi`). Default: auto-detectado desde `.king/knowledge/stack.md`
   - `--client-langs <l1,l2,...>`: lenguajes target de los SDKs (ej. `typescript,python,go`). Default: el mismo stack del proyecto
   - `--compare-to <prev-spec>`: path a la spec anterior. Activa la fase EXPLÍCITA de breaking-change check (`oasdiff`)
3. Seguir todas las fases del skill en orden:
   - Validate spec (spectral) → Generate stubs → Generate SDKs → Generate mock (Prism) → Generate contract tests → Generate docs (Redoc) → Breaking change check (oasdiff)
   - Cada fase de generación tiene GATE IN sobre `--outputs`: si el output no fue pedido, la fase se SALTA. Solo la validación (spectral) corre siempre
4. Agentes coordinados: @architect (principal: valida contratos de diseño, clasifica severidad de breaking changes, decide versionado), @developer (genera stubs/SDKs/mock/compose), @qa (valida que los contract tests fallen ante divergencia)
5. IMPORTANTE: nunca generar outputs desde una spec inválida; nunca sobrescribir lógica de handlers existente; nunca degradar un `breaking` a `non-breaking`; nunca embeber secretos en mock/SDKs/compose

Si no se pasa `[spec-file]`, el skill genera primero la spec OpenAPI 3.1 desde la descripción en lenguaje
natural y la valida con spectral antes de cualquier generación. Si `spectral` reporta ERRORES (no solo
warnings), el skill NO continúa a la generación hasta repararlos o confirmar.

## Ejemplos

### Solo stubs + mock para un proyecto TS/Express

```
/api-contract-first openapi.yaml --outputs stubs,mock
```

### Stubs Go + SDKs en TypeScript y Python

```
/api-contract-first api/openapi.yaml --server-stack go-chi --client-langs typescript,python
```

### Solo documentación (output independiente)

```
/api-contract-first openapi.yaml --outputs docs
```

### Generar spec desde lenguaje natural (sin spec-file)

```
/api-contract-first --outputs stubs,tests
```

(el skill pide la descripción de endpoints/schemas, genera `openapi.yaml`, la valida y luego genera)

### Breaking-change check entre dos versiones

```
/api-contract-first new-spec.yaml --compare-to old-spec.yaml --outputs ""
```

## Ejemplo de breaking-change report (con severidad)

`oasdiff breaking` compara la spec anterior contra la nueva y clasifica cada cambio. La severidad la
dicta `oasdiff`, NUNCA la conveniencia — un `breaking` sin bump de versión MAJOR es BREACH de CASTLE C:

```
Breaking Change Report — oasdiff (old.yaml → new.yaml)
======================================================
Total: 3 changes  |  BREAKING: 2  |  non-breaking: 1

[BREAKING]  POST /users — request.body.email
  optional → required
  Clientes que no enviaban `email` recibirán 400. Requiere bump MAJOR.

[BREAKING]  GET /orders/{id} — response.200.body.discount
  field removed (was: number)
  Clientes que leían `discount` obtendrán undefined. Requiere bump MAJOR.

[non-breaking]  GET /products — response.200.body.tags
  field added (string[])
  Aditivo; clientes existentes lo ignoran.

Recomendación: 2 breaking changes → versionar como MAJOR (v2) y mantener v1
hasta la deprecación. Estrategia: versionado por path (/v2) o header (Accept-Version).
```

| Cambio | Severidad |
|--------|-----------|
| Campo de request `optional → required` | `breaking` |
| Eliminación de endpoint/campo de response | `breaking` |
| Cambio de tipo de un campo | `breaking` |
| Status code declarado removido | `breaking` |
| Campo de response nuevo / endpoint nuevo / campo opcional nuevo | `non-breaking` |

## Tooling

`spectral` (validación) · `openapi-generator-cli` (stubs + SDKs) · `@stoplight/prism-cli` (mock) ·
`schemathesis`/`dredd` (contract tests) · `redocly` (docs) · `oasdiff` (breaking changes).

La spec OpenAPI es la ÚNICA fuente de verdad del contrato: stubs, SDKs y mock se DERIVAN de ella. Un
handler que diverge de la spec es una violación de contrato que CASTLE C vigila — por eso el
breaking-change check es una fase de primera clase. Detalle de diseño y versionado de APIs en
`knowledge/universal/api-design.md`.
