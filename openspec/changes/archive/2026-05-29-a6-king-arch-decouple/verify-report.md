# Verify Report — A6 king-arch decouple

> Fase: sdd-verify · Change: a6-king-arch-decouple · Fecha: 2026-05-29

## Resultados de verificación

| Check | Comando | Resultado | Criterio |
|-------|---------|-----------|----------|
| pytest king-core | `pytest tests/ --cov=src --cov-fail-under=80` | **59 passed**, cov **97.78%** | ✅ ≥59, ≥80% |
| audit_self king-core | `audit_self.py --ci-threshold 80` | health **82.60** (52 skills), EXIT 0 | ✅ ≥80 |
| check_api_version king-core | `check_api_version.py skills/**/SKILL.md` | EXIT 0 | ✅ sin missing |
| JSON válido | parse de 4 manifiestos | OK (king-core plugin.json, hooks.json, king-arch plugin.json, marketplace.json) | ✅ 4/4 |
| audit_self king-arch | `audit_self.py --scope king-arch/skills` | health **75.58** (13 skills) tras `git init` | ✅ paridad hijos |
| check_api_version king-arch | sobre king-arch/skills | EXIT 0 | ✅ sin missing |
| Hook resilience-check (graceful) | stdin con fetch sin resiliencia | WARNING + "(king-arch, si está instalado)", EXIT 0 | ✅ |
| Hook api-change-check (graceful) | stdin handler + openapi.yaml | WARNING + "(king-arch, si está instalado)", EXIT 0 | ✅ |
| No-regresión: dependencia inversa | `requires` de king-core | **ABSENT** | ✅ |
| No-regresión: refs kernel | grep de los 12 slash-commands | todas las refs OPERATIVAS graceful | ✅ |

## Calibración del health de king-arch (importante)

El umbral 80 es **específico de king-core** (tiene tooling Python: `pyproject.toml`, `requirements-test.txt` que
puntúan en las dimensiones Q01/Q02). Los plugins hijos markdown-only puntúan naturalmente más bajo:

| Plugin | Health | Tooling Python |
|--------|--------|----------------|
| king-infra | 76.22 | no |
| king-content | 75.00 | no |
| **king-arch** | **75.58** | no |

king-arch (75.58) está **en paridad con sus hermanos**. El 72.58 inicial era únicamente por falta de `.git`
(el audit resolvía `repo_root` al drive root y no detectaba el CHANGELOG.md de king-arch). Tras `git init`: 75.58.
Conclusión: king-arch es estructuralmente sano para un plugin hijo.

## Decisión de scope — refs en knowledge/universal (precedente A3)

`knowledge/universal/soc2-compliance.md` y `certification-curriculum.md` mencionan varias de las 12 skills (currículo
de certificación y mapa de controles SOC2). **NO se reescriben graceful**: son documentación descriptiva
cross-ecosistema, no referencias operativas del kernel. Precedente directo: A3 dejó `/db-optimize` y `/explain-query`
(movidas a king-infra) sin anotar en `certification-curriculum.md:194`. Se mantiene la consistencia con A3.

Las refs **operativas** del kernel SÍ se reescribieron graceful: `agents/architect.md`, `skills/sdd-apply/SKILL.md`,
`knowledge/domain/resilience-patterns.md`, `hooks/resilience-check.sh`, `hooks/api-change-check.sh`, `LOAD-INDEX.md`.

## Veredicto CASTLE: **FORTIFIED**

- **C (Contracts)**: `requires:[king-framework]` en king-arch; `requires` ausente en king-core (dirección de dependencias intacta); refs operativas graceful. ✅
- **A (Architecture)**: kernel de razonamiento intacto; solo migró el dominio cohesivo de patrones; knowledge/agentes/hooks compartidos quedaron como kernel. Cambio quirúrgico. ✅
- **S (Security)**: sin secrets, sin nueva superficie de ataque (solo movimiento de archivos markdown). ✅
- **T (Testing)**: pytest 59 passed; auditoría estructural king-core 82.60 / king-arch 75.58. ✅
- **L (Logging)**: ambos hooks degradan con WARNING claro y EXIT 0 cuando king-arch no está. ✅
- **E (Environment)**: 4 manifiestos JSON válidos; king-arch registrado en marketplace e instalable (`requires`). ✅

## Pendientes (no bloqueantes)
- Commit inicial de king-arch + commit del feature branch de king-core: **ARCHIVE**.
- **Push / PR / merge / release**: diferido a confirmación del usuario (acción outward-facing).
- Deuda preexistente NO tocada (fuera de scope A6): marketplace omite king-content/infra/ai/mobile/legal; conteo "47 skills" en blurb de marketplace de king-core.
