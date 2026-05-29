# Delta Spec — api-contract-first (M-30)

## ADDED Requirements

### Requirement: Skill `/api-contract-first`
El skill `/api-contract-first` SHALL generar server stubs, client SDKs, mock server, contract tests y docs
desde una spec OpenAPI 3.1, y detectar breaking changes vs una versión anterior. Cada output MUST ser
independiente (se puede pedir solo stubs). Breaking change check (oasdiff) MUST ser una fase explícita.

#### Scenario: Genera stubs desde spec OpenAPI 3.1
- **Given** un `openapi.yaml` con 3 endpoints y un proyecto TS/Express
- **When** el developer ejecuta `/api-contract-first openapi.yaml --outputs stubs,mock`
- **Then** genera 3 handlers TS con tipos derivados de la spec y docker-compose con Prism mock
- **And** los handlers validan request/response con los schemas

#### Scenario: Detecta breaking change
- **Given** spec original con `email` opcional y nueva spec con `email` requerido
- **When** `/api-contract-first new-spec.yaml --compare-to old-spec.yaml`
- **Then** reporta "email: optional → required" como BREAKING con endpoint y ruta del schema

### Requirement: Hook `api-change-check` (ADITIVO) + CASTLE C
`hooks/hooks.json` SHALL incorporar un hook PostToolUse `api-change-check`: si se modifica un handler/controller
y existe spec OpenAPI → WARNING de validar contrato (enforcement: warn). MUST añadirse al array sin remover existentes.
CASTLE C SHALL verificar que cambios en handlers no rompan la spec; si no hay spec → WARNING "contrato implícito".

> Set Gherkin completo: M04 §7 (Feature: API Contract-First).
