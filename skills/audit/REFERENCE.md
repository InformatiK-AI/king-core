# Audit - Reference

> Archivo parte de: `skills/audit/SKILL.md`
> Contiene: Severidades, issues conocidos baseline, patrones de deteccion, comandos utiles

---

## Severidades

| Severidad | Criterio | Impacto |
|-----------|----------|---------|
| CRITICAL | Bloquea funcionamiento del framework | -10% score |
| HIGH | Causa comportamiento incorrecto o inseguro | -3% score |
| MEDIUM | Reduce calidad o mantenibilidad | -1% score |
| LOW | Mejora cosmetica o de documentacion | -0% score |

---

## Issues Conocidos (Baseline)

Los siguientes issues fueron identificados durante la exploracion inicial y sirven como baseline:

### En Agentes (8 issues)
1. [MEDIUM] Orquestacion en `/qa --env qa` poco clara
2. [MEDIUM] Knowledge injection timing no especificado
3. [HIGH] Security Gate ownership ambiguo (@qa vs @security)
4. [LOW] Colaboracion N-way no documentada
5. [HIGH] Return context sin timeout/fallback
6. [LOW] Nomenclatura ADR inconsistente (id vs numero)
7. [MEDIUM] Logging de decisiones sin ubicacion clara
8. [MEDIUM] Validation layer integration no clara

### En Skills (9 issues)
1. [HIGH] Agent invocation sin especificar Task tool
2. [MEDIUM] QA Security Gate duplicado (basic vs deep)
3. [HIGH] Release sin validacion explicita de qa --env qa
4. [MEDIUM] --agent validado tardiamente en /build
5. [HIGH] merge.lock no documentado en /merge
6. [LOW] Session enum values inconsistentes
7. [LOW] Falta validacion de --backend en /create-issues
8. [LOW] QA expiracion (7 dias) hardcoded
9. [MEDIUM] react-best-practices no sigue v2.0

### En Calidad (7 issues)
1. [MEDIUM] Duplicacion de severidades en dependencias
2. [MEDIUM] Code patterns sin centralizacion
3. [MEDIUM] Error handling <-> Security desacoplado
4. [HIGH] Recovery procedures incompletas
5. [MEDIUM] Knowledge versions sin sync automatico
6. [LOW] Metricas no centralizadas
7. [HIGH] Security Gate bypass sin auditoria

---

## Patrones de Deteccion

```bash
# Detectar skills sin v2.0
grep -L "version: 2.0" skills/*/SKILL.md

# Detectar agentes sin RADAR
grep -L "RADAR\|Protocolo RADAR" agents/*.md

# Detectar referencias rotas (busca en skills y agents del plugin)
grep -rhoP '\.claude/[^\s\)]+\.md' skills/ agents/ | sort -u | while read f; do
  [ ! -f "$f" ] && echo "BROKEN: $f"
done

# Detectar invocaciones implicitas de agentes
grep -rn "@[a-z-]+" skills/ | grep -v "subagent_type"

# Detectar blocking conditions ambiguas
grep -rn "BLOCKING" skills/ -A5 | grep -E "bueno|malo|limpio|adecuado"
```

---

## Comandos Utiles Post-Auditoria

```bash
# Ver ultimo reporte
cat .king/docs/audits/$(ls -t .king/docs/audits/*-audit-report.md | head -1)

# Ver backlog actual
cat .king/docs/audits/$(ls -t .king/docs/audits/*-improvement-backlog.md | head -1)

# Contar issues por severidad en backlog
grep -c "CRITICAL\|HIGH\|MEDIUM\|LOW" .king/docs/audits/*-backlog.md
```

---

## Sub-Dimension Quick Reference

> Lookup rápido de las 25 sub-dimensiones. Ver `SUBDIMENSIONS.md` para criterios de scoring completos.

| ID | Name | Parent | Weight % | Autofix Class |
|----|------|--------|----------|---------------|
| I-01 | metadata-completeness | Inventory | 8% | auto |
| I-02 | description-quality | Inventory | 4% | guided |
| I-03 | author-present | Inventory | 4% | auto |
| I-04 | license-declared | Inventory | 4% | auto |
| F-01 | directory-structure | Format | 6% | guided |
| F-02 | entrypoint-exists | Format | 6% | auto |
| F-03 | skill-file-present | Format | 5% | auto |
| F-04 | api-version-present | Format | 0%* | auto |
| F-05 | frontmatter-validity | Format | 3% | guided |
| X-01 | command-declarations | Cross-refs | 7% | manual |
| X-02 | command-descriptions | Cross-refs | 5% | guided |
| X-03 | command-examples | Cross-refs | 4% | guided |
| X-04 | hook-declarations | Cross-refs | 4% | manual |
| Q-01 | test-coverage-declared | Instructions Quality | 5% | guided |
| Q-02 | test-runner-present | Instructions Quality | 4% | auto |
| Q-03 | changelog-present | Instructions Quality | 3% | guided |
| Q-04 | version-bump-consistency | Instructions Quality | 3% | manual |
| C-01 | readme-present | Communication | 5% | guided |
| C-02 | usage-examples-documented | Communication | 4% | guided |
| C-03 | api-reference-present | Communication | 3% | guided |
| C-04 | inline-comments-quality | Communication | 3% | manual |
| E-01 | install-script-present | Efficiency | 3% | auto |
| E-02 | uninstall-script-present | Efficiency | 3% | guided |
| E-03 | dependency-manifest | Efficiency | 2% | auto |
| E-04 | upgrade-notes-present | Efficiency | 2% | guided |

> *F-04 `api-version-present` is WARNING-only (pending M-71). Weight = 0% — does NOT contribute to health_score.
