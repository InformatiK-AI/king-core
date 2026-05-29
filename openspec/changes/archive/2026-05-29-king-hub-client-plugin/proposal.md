# Proposal — King Hub plugin cliente

> Fase: sdd-propose · Change: king-hub-client-plugin · Backend: openspec (king-core) · Backlog: A7.1 (mitad cliente)

## Why

El backend del King Hub está construido + validado (FORTIFIED). Falta la **cara del Hub dentro de un proyecto King**:
el plugin `king-hub` con 4 skills (search/install/publish/stats) que el spec §2 define como "los 4 skills son la cara
del hub dentro de un proyecto King". Sin ellos, el usuario no tiene comandos para descubrir/instalar/publicar skills.

## What Changes

Repo nuevo `king-hub` (`requires:["king-framework"]`) con 4 skills markdown (anatomía v2.0) + 4 commands + la guía de
publicación. **Diseño Híbrido (decisión RADAR)**: cada skill orquesta el CLI `king-framework skill *` (Apex Core) si
está; si no, degrada graceful al flujo HTTP+GPG directo contra el backend. king-core no cambia salvo este planning.

## Capabilities (contrato para sdd-spec)

| # | Capability | Artefactos |
|---|------------|------------|
| 1 | `hub-client-skills` | 4 SKILL.md v2.0 (hub-search/install/publish/stats) + 4 commands + REFERENCE.md c/u + hub-publishing-guide.md |

## Scope

- **In scope**: repo king-hub (plugin.json, 4 skills anatomía v2.0 con ruta CLI + fallback HTTP/GPG graceful, commands,
  knowledge/hub-publishing-guide.md, _shared duplicado); verificación estructural (audit_self ≥75, check_api_version).
- **Out of scope**: construir el CLI Apex Core (repo externo); desplegar el backend; runtime real (los skills son
  instrucciones del agente — verificación estructural, no de ejecución, como todos los skills King); push/release.

## Affected modules
- **Nuevo**: `D:\King Framework\king-hub\` (repo independiente).
- `king-core/openspec/` (este planning).

## Delivery
- Repo nuevo + commit inicial. CASTLE estructural (plugin markdown como king-arch). Push diferido a confirmación.

## Rollback plan
- Repo nuevo aislado: revertir = borrar el directorio. Planning aditivo en king-core/openspec.
