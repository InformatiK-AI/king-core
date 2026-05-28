---
name: contract-test
description: "Generar consumer-driven contracts con Pact y verificación del proveedor"
argument-hint: "[--consumer <name>] [--provider <name>] [--verify] [--broker <url>] [--stack <ts|python|java|go>]"
allowed-tools: [Read, Write, Edit, Grep, Glob, Bash, Agent]
---

# /contract-test

Generar contratos Pact consumer-driven entre servicios, los mocks del proveedor para el
consumidor, y el test de verificación del proveedor. Alimenta la capa CASTLE C.

## Instrucciones

1. Invocar el skill `contract-test` usando la herramienta Skill
2. Argumentos opcionales:
   - `--consumer <name>`: nombre lógico del servicio consumidor
   - `--provider <name>`: nombre lógico del servicio proveedor
   - `--verify`: sólo generar/ejecutar verificación del proveedor sobre contratos existentes
   - `--broker <url>`: URL del Pact Broker (opcional; sin él usa archivos locales)
   - `--stack <ts|python|java|go>`: forzar stack si la autodetección falla
3. Seguir todas las fases del skill en orden:
   - Discover Integrations → Consumer Contract → Provider Verification → Broker (opcional) → CASTLE C → Session → Guide
4. Agentes coordinados: @api (principal), @architect (límites de servicio), @qa (cobertura de escenarios)
5. IMPORTANTE: nunca incluir tokens/secrets literales en los contratos o en `broker.yaml`

Si no se detectan integraciones HTTP ni se declaran `--consumer`/`--provider`, el skill
solicita la información al usuario antes de continuar.
