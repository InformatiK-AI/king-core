# Audit — Phases (v2.0)

> Lógica completa de ejecución. Entry point: [SKILL.md](SKILL.md)

---

## PARAMETER VALIDATION

### Validacion de entrada

| Parametro | Valores validos | Si invalido |
|-----------|-----------------|-------------|
| `--scope` | `full`, `quick` | ERROR: "Valor invalido. Use: full \| quick" |
| `--focus` | `agents`, `skills`, `security`, `quality`, `all` | ERROR: "Area no reconocida" |
| `--dry-run` | flag sin valor | N/A |
| `--fix-suggestions` | flag sin valor | N/A |

### Deteccion de modo

```
+-------------------------------------------------------------+
|                     SCOPE CHECK                              |
+-------------------------------------------------------------+
|  --scope quick?                                              |
|       |                                                      |
|       +-- SI --> Ejecutar solo PHASE 1, 2, 7                 |
|       |          Skip PHASE 3, 4, 5, 6                       |
|       |                                                      |
|       +-- NO --> Ejecutar todas las fases (1-7)              |
|                                                              |
|  --focus especifico?                                         |
|       |                                                      |
|       +-- agents --> Filtrar checklists a agentes            |
|       +-- skills --> Filtrar checklists a skills             |
|       +-- security --> Filtrar a Security Gate + deps        |
|       +-- quality --> Filtrar a 3 capas de calidad           |
|       +-- all --> Sin filtro (default)                       |
+-------------------------------------------------------------+
```

---

---

## PHASE 1: INVENTORY
> Verificar existencia de todos los componentes del framework

### GATE IN
- [ ] Directorio `.claude/` existe
- [ ] Es proyecto King Framework (tiene CLAUDE.md o agentes)

### MUST DO

#### 1.1 Verificar Agentes Core (obligatorios)

| Agente | Path esperado | Check |
|--------|---------------|-------|
| @developer | `.claude/agents/developer.md` | [ ] |
| @architect | `.claude/agents/architect.md` | [ ] |
| @qa | `.claude/agents/qa.md` | [ ] |
| @frontend | `.claude/agents/frontend.md` | [ ] |

**Si falta algun agente core:**
```
INVENTORY: Agente core faltante
   Falta: @{nombre}
   Path esperado: .claude/agents/{nombre}.md
   Severidad: HIGH
```

#### 1.2 Verificar Agentes Especializados (segun proyecto)

| Senal detectada | Agente esperado | Path |
|-----------------|-----------------|------|
| Pagos/PCI/compliance | @security | `.claude/agents/security.md` |
| Docker/K8s/CI-CD | @devops | `.claude/agents/devops.md` |
| Mobile/RN/Flutter | @mobile | `.claude/agents/mobile.md` |
| GraphQL/microservices | @api | `.claude/agents/api.md` |
| Performance critico | @performance | `.claude/agents/performance.md` |

**Deteccion de senales:**
```bash
# Buscar en CLAUDE.md, package.json, requirements.txt
grep -rli "payment\|pci\|compliance\|gdpr" . --include="*.md" --include="*.json"
grep -rli "docker\|kubernetes\|k8s\|github.actions\|gitlab-ci" . --include="*.yml" --include="*.yaml"
grep -rli "tensorflow\|pytorch\|sklearn\|machine.learning" . --include="*.py" --include="*.md"
grep -rli "react.native\|flutter\|expo\|ios\|android" . --include="*.json" --include="*.md"
grep -rli "graphql\|microservice\|api.gateway" . --include="*.md" --include="*.ts"
```

#### 1.3 Verificar Skills (esperados segun CLAUDE.md)

| Skill | Path | Categoria |
|-------|------|-----------|
| genesis | `skills/genesis/SKILL.md` | Core |
| brainstorm | `skills/brainstorm/SKILL.md` | Core |
| create-issues | `skills/create-issues/SKILL.md` | Core |
| build | `skills/build/SKILL.md` | Core |
| qa | `skills/qa/SKILL.md` | Core |
| merge | `skills/merge/SKILL.md` | Core |
| promote | `skills/promote/SKILL.md` | Core |
| release | `skills/release/SKILL.md` | Core |
| worktree | `skills/worktree/SKILL.md` | Core |

#### 1.4 Verificar Infraestructura de Calidad

| Componente | Path | Check |
|------------|------|-------|
| Security Gate | `security/SECURITY-GATE.md` | [ ] |
| Validation Layer | `validation/VALIDATION.md` | [ ] |
| Knowledge Base | `knowledge/` (directorio) | [ ] |
| Rules | `rules/` (directorio) | [ ] |
| RADAR Protocol | `agents/_common/protocols/radar.md` | [ ] |
| Session Template | `templates/session-document.md` | [ ] |
| Escalation Matrix | `agents/_common/escalation-matrix.md` | [ ] |

#### 1.5 Verificar Directorios Requeridos

| Directorio | Proposito | Check |
|------------|-----------|-------|
| `.claude/agents/` | Agentes generados por genesis (proyecto) | [ ] |
| `skills/` | Skills del framework (plugin) | [ ] |
| `rules/` | Reglas de codigo/arquitectura (plugin) | [ ] |
| `.king/docs/` | Documentacion generada (proyecto) | [ ] |
| `.king/sessions/` | Registro de ejecuciones (proyecto) | [ ] |
| `.king/issues/` | Sistema de issues local (proyecto) | [ ] |
| `knowledge/` | Base de conocimiento (plugin) | [ ] |
| `validation/` | Capa de validacion (plugin) | [ ] |
| `security/` | Gate de seguridad (plugin) | [ ] |

### CHECKPOINT
- [ ] Conteo de componentes encontrados vs esperados
- [ ] Lista de componentes faltantes con severidad
- [ ] `inventory_score` calculado (encontrados/esperados * 100)

### IF FAILS
```
INVENTORY CRITICO
   Componentes encontrados: {N}/{total}
   Faltantes criticos: {lista}

   El framework no esta correctamente configurado.
   Ejecuta /genesis para inicializar la infraestructura.
```

---

## PHASE 2: FORMAT COMPLIANCE
> Validar que componentes siguen templates v2.0 y RADAR

### GATE IN
- [ ] PHASE 1 completada
- [ ] Al menos 50% de componentes encontrados

### MUST DO

#### 2.1 Validar Skills siguen v2.0

**Template v2.0 requerido:**
```markdown
---
name: {skill}
version: 2.0
description: "{descripcion}"
---

# {Nombre}

## QUICK REFERENCE
### BLOCKING CONDITIONS
### REQUIRED OUTPUTS
### PHASES OVERVIEW
### PARAMETERS

## PHASE N: {NOMBRE}
### GATE IN
### MUST DO
### CHECKPOINT
### IF FAILS

## FINAL CHECKPOINT
## Ver también
```

**Checklist por skill:**
- [ ] Tiene frontmatter YAML (name, version, description)
- [ ] `version: 2.0` presente
- [ ] Seccion QUICK REFERENCE existe
- [ ] BLOCKING CONDITIONS definidas
- [ ] REQUIRED OUTPUTS definidos
- [ ] PHASES OVERVIEW con diagrama
- [ ] Cada PHASE tiene GATE IN, MUST DO, CHECKPOINT
- [ ] FINAL CHECKPOINT existe
- [ ] "Ver también" con referencias

**Si skill no cumple v2.0:**
```
FORMAT: Skill no sigue v2.0
   Skill: {nombre}
   Faltante: {seccion}
   Severidad: MEDIUM
   Fix: Agregar seccion {seccion} siguiendo template
```

#### 2.2 Validar Agentes siguen RADAR

**Estructura RADAR requerida:**
```markdown
# @{nombre}

## Rol
## Responsabilidades
## Protocolo RADAR
## Triggers de activacion
## Handoff protocol
## Outputs esperados
```

**Checklist por agente:**
- [ ] Tiene seccion "Rol" clara
- [ ] Responsabilidades definidas
- [ ] Mencion explicita de RADAR
- [ ] Triggers de activacion listados
- [ ] Handoff protocol definido
- [ ] Outputs esperados documentados

#### 2.3 Validar Rules

**Estructura requerida:**
```markdown
# {Titulo}

## Aplica a
## Reglas
## Ejemplos
### Correcto
### Incorrecto
## Razon
## Cuando romper las reglas
```

**Checklist por rule:**
- [ ] "Aplica a" define scope
- [ ] Reglas son especificas y verificables
- [ ] Ejemplos de correcto e incorrecto
- [ ] "Razon" explica el porque
- [ ] "Cuando romper" documenta excepciones

### CHECKPOINT
- [ ] Lista de skills no-compliant con detalle
- [ ] Lista de agentes no-compliant con detalle
- [ ] `format_score` calculado

### IF FAILS
```
FORMAT: Componentes no siguen estandar
   Skills no-v2.0: {lista}
   Agentes sin RADAR: {lista}

   Revisar templates en:
      - Skills: skills/_templates/skill-template-v2.md
      - Agentes: agents/templates/
```

---

## PHASE 3: CROSS-REFERENCE VALIDATION
> Verificar que referencias entre documentos son validas

### GATE IN
- [ ] PHASE 2 completada
- [ ] Modo no es `quick`

### MUST DO

#### 3.1 Extraer todas las referencias

**Patrones a buscar:**
```regex
# Referencias a archivos
\.claude/[a-zA-Z0-9/_-]+\.(md|json|yaml)

# Referencias a skills
/[a-z-]+(\s+--[a-z]+)?

# Referencias a agentes
@[a-z-]+

# Referencias a reglas
rules/[a-z-]+\.md

# Referencias "Ver también"
Ver también:.*
```

#### 3.2 Validar referencias de Skills

Para cada skill, verificar:
- [ ] "Skill anterior" existe y es correcto en flujo
- [ ] "Skill siguiente" existe y es correcto en flujo
- [ ] Referencias a agentes (@nombre) tienen definicion
- [ ] Referencias a rules existen
- [ ] Referencias a validation/security existen

**Flujo esperado:**
```
genesis -> brainstorm -> create-issues -> build -> qa -> merge -> promote -> release
```

#### 3.3 Validar referencias de Agentes

Para cada agente, verificar:
- [ ] Referencias a otros agentes existen
- [ ] Referencias a knowledge base existen
- [ ] Referencias a validation layer existen
- [ ] Escalation targets existen

#### 3.4 Detectar referencias huerfanas

```bash
# Buscar archivos referenciados que no existen
for ref in $(grep -rhoP '\.claude/[a-zA-Z0-9/_-]+\.md' .claude/); do
  if [ ! -f "$ref" ]; then
    echo "ORPHAN: $ref"
  fi
done
```

#### 3.5 Detectar archivos sin referencias

```bash
# Archivos que existen pero no son referenciados
# Potencialmente obsoletos o mal integrados
```

### CHECKPOINT
- [ ] Lista de referencias rotas con source -> target
- [ ] Lista de archivos huerfanos (sin referencias entrantes)
- [ ] `cross_refs_score` calculado

### IF FAILS
```
CROSS-REF: Referencias invalidas detectadas
   Referencias rotas: {N}
   Archivos huerfanos: {N}

   Detalle en reporte completo.
```

---

## PHASE 4: INSTRUCTION QUALITY
> Evaluar claridad y verificabilidad de instrucciones

### GATE IN
- [ ] PHASE 3 completada (o PHASE 2 si `--scope quick`)
- [ ] Modo no es `quick`

### MUST DO

#### 4.1 Evaluar BLOCKING CONDITIONS

**Criterios de calidad:**
- [ ] Son verificables programaticamente (si/no claro)
- [ ] No son ambiguas ("codigo limpio" es ambiguo)
- [ ] Tienen criterio de exito medible
- [ ] Cubren casos de fallo principales

**Ejemplos de buena blocking condition:**
```markdown
"Security Gate FAILED"
"Tests criticos fallando"
"No existe entrada en promotions.json"

MAL: "Codigo de mala calidad"
MAL: "Performance insuficiente" (sin metrica)
MAL: "Requiere revision" (subjetivo)
```

#### 4.2 Evaluar REQUIRED OUTPUTS

**Criterios de calidad:**
- [ ] Path exacto especificado
- [ ] Formato de archivo claro
- [ ] Contenido minimo definido
- [ ] Verificable con ls/cat

#### 4.3 Evaluar Acceptance Criteria en Issues

Si sistema de issues local activo:
- [ ] ACs siguen formato Given/When/Then
- [ ] ACs son especificos y testeables
- [ ] No hay ACs ambiguos

#### 4.4 Evaluar instrucciones de agentes

**Criterios:**
- [ ] Triggers son especificos (no "cuando sea necesario")
- [ ] Outputs tienen formato definido
- [ ] Handoffs tienen destinatario claro
- [ ] No hay instrucciones contradictorias

### CHECKPOINT
- [ ] Lista de instrucciones ambiguas con ubicacion
- [ ] Lista de blocking conditions no verificables
- [ ] `instructions_quality_score` calculado

### IF FAILS
```
QUALITY: Instrucciones ambiguas detectadas
   Blocking conditions vagas: {N}
   Outputs sin formato: {N}
   ACs no testeables: {N}

   Reescribir siguiendo criterios de verificabilidad.
```

---

## PHASE 5: COMMUNICATION VALIDATION
> Verificar protocolos de comunicacion agent-skill

### GATE IN
- [ ] PHASE 4 completada
- [ ] Modo no es `quick`
- [ ] `--focus` es `all`, `agents`, o no especificado

### MUST DO

#### 5.1 Validar Escalation Matrix

**Verificar existencia y completitud:**
```markdown
# Escalation Matrix esperada

| Desde | Hacia | Trigger | Informacion requerida |
|-------|-------|---------|----------------------|
| @developer | @architect | Decision arquitectonica | Contexto, alternativas |
| @developer | @security | Codigo sensible | Codigo, threat model |
| @qa | @security | Vulnerabilidad detectada | Finding, severidad |
| @architect | @security | Diseno con implicaciones | ADR draft, risks |
```

**Checklist:**
- [ ] Matriz existe en `agents/_common/escalation-matrix.md`
- [ ] Todos los agentes core estan representados
- [ ] Triggers son especificos
- [ ] Informacion requerida esta definida

#### 5.2 Validar Handoff Protocol

Para cada agente, verificar:
- [ ] Tiene seccion "Handoff protocol" o "Return context"
- [ ] Define que informacion pasa al siguiente
- [ ] Define formato de la informacion
- [ ] Define timeout o fallback

**Issue conocido: Return context sin timeout**
```
COMMUNICATION: Handoff sin fallback
   Agente: @{nombre}
   Issue: No define que hacer si receptor no responde
   Severidad: HIGH
   Fix: Agregar "Si no hay respuesta en X, entonces Y"
```

#### 5.3 Validar Invocacion de Agentes desde Skills

Para cada skill que invoca agentes:
- [ ] Usa Task tool explicitamente (no invocacion implicita)
- [ ] Especifica `subagent_type` correcto
- [ ] Define que informacion pasar al agente
- [ ] Define que esperar del agente

**Issue conocido: Invocacion sin Task tool**
```
COMMUNICATION: Invocacion de agente implicita
   Skill: {nombre}
   Linea: "Consulta a @security para..."
   Issue: No especifica como invocar (Task tool)
   Severidad: HIGH
   Fix: Usar Task tool con subagent_type="security"
```

#### 5.4 Validar Colaboracion Multi-Agente

Escenarios de colaboracion documentados:
- [ ] QA + Security en Security Gate
- [ ] Architect + Developer en diseno
- [ ] QA + Frontend en validacion UI

**Para cada colaboracion:**
- [ ] Roles estan claros (quien lidera)
- [ ] Secuencia definida (quien primero)
- [ ] Conflicto resolution documentado

### CHECKPOINT
- [ ] Escalation matrix completa: Si/No
- [ ] Handoffs con fallback: N/total
- [ ] Invocaciones con Task tool: N/total
- [ ] `communication_score` calculado

### IF FAILS
```
COMMUNICATION: Protocolos incompletos
   Escalations sin definir: {N}
   Handoffs sin fallback: {N}
   Invocaciones implicitas: {N}

   Revisar agents/_common/escalation-matrix.md
```

---

## PHASE 6: EFFICIENCY ANALYSIS
> Detectar duplicaciones, optimizar token budget

### GATE IN
- [ ] PHASE 5 completada
- [ ] Modo no es `quick`

### MUST DO

#### 6.1 Detectar Duplicacion de Contenido

**Areas de duplicacion comun:**
- Security Gate descrito en multiples lugares
- Validaciones repetidas entre skills
- Instrucciones RADAR duplicadas en agentes
- Templates copiados sin referencia central

**Deteccion:**
```bash
# Buscar bloques de texto similares (>50 caracteres)
# Herramientas: simhash, diff, fdupes para contenido
```

**Si duplicacion detectada:**
```
EFFICIENCY: Contenido duplicado
   Contenido: "{primeras palabras}..."
   Ubicaciones:
     - {archivo1}:{linea}
     - {archivo2}:{linea}
   Severidad: MEDIUM
   Fix: Centralizar en archivo comun y referenciar
```

#### 6.2 Analizar Token Budget via Performance Budget Gate

→ Ver `rules/token-budget-gate.md` para el proceso completo.

Scope: todos los componentes listados en `LOAD-INDEX.md` (skills + agents).
El resultado de este gate alimenta `efficiency_score` del Health Score.

**Umbrales default** (configurables en `.king/token-budget.yaml`):
| Componente | Umbral warning | Umbral error |
|------------|----------------|--------------|
| Skill entry | 2000 tokens | 5000 tokens |
| Agent .md | 1500 tokens | 3000 tokens |
| Rule .md | 500 tokens | 1000 tokens |
| CLAUDE.md | 3000 tokens | 6000 tokens |

**Si LOAD-INDEX.md no existe:**
→ Emitir `PERFORMANCE-BUDGET-LOAD-INDEX-MISSING`
→ Dimensión "Performance Budget" del Health Score = UNKNOWN (no penaliza el score)
→ Continuar con 6.3 sin interrumpir el audit

**Si gate retorna PASS:** dimensión = GREEN — efficiency_score sin penalización
**Si gate retorna WARN:** dimensión = YELLOW — documentar los excesos en el backlog de mejoras
**Si gate retorna FAIL** (solo posible con `mode: error` en `.king/token-budget.yaml`): dimensión = RED — incluir en findings CRITICAL del audit

#### 6.3 Detectar Contenido Huerfano

Archivos que:
- No son referenciados desde ningun otro archivo
- No tienen uso aparente
- Pueden ser obsoletos

#### 6.4 Evaluar Carga Bajo Demanda

**Verificar que skills usan carga modular:**
- [ ] Skills grandes divididos en archivos (SKILL.md, REFERENCE.md, etc.)
- [ ] Agentes no cargan knowledge completo, solo _inject/
- [ ] Rules son pequenas y especificas

### CHECKPOINT
- [ ] Lista de duplicaciones con sugerencia de consolidacion
- [ ] Performance Budget Gate ejecutado — resultado documentado (PASS / WARN / FAIL / UNKNOWN)
- [ ] Lista de componentes sobre umbral de tokens (si aplica)
- [ ] Lista de contenido huerfano
- [ ] `efficiency_score` calculado (incluye resultado del Performance Budget Gate)

### IF FAILS
```
EFFICIENCY: Optimizaciones posibles
   Duplicaciones: {N} bloques
   Archivos sobre umbral: {N}
   Contenido huerfano: {N}

   Ver backlog para tareas de optimizacion.
```

---

## PHASE 7: REPORT GENERATION
> Generar reporte final y backlog priorizado

### GATE IN
- [ ] Todas las fases anteriores completadas (o 1,2 si `quick`)
- [ ] `--dry-run` es false

### MUST DO
> ⚠️ All actions are MANDATORY

#### 7.1 Calcular Health Score Final

```
inventory_score = (componentes_encontrados / componentes_esperados) * 100
format_score = (componentes_compliant / componentes_total) * 100
cross_refs_score = (refs_validas / refs_total) * 100
instructions_quality_score = (instrucciones_claras / instrucciones_total) * 100
communication_score = (protocolos_completos / protocolos_total) * 100
efficiency_score = 100 - (duplicaciones * 5) - (sobre_umbral * 3)

base_score = (
  inventory_score * 0.20 +
  format_score * 0.20 +
  cross_refs_score * 0.20 +
  instructions_quality_score * 0.15 +
  communication_score * 0.15 +
  efficiency_score * 0.10
)

# Aplicar penalties
penalties = (critical_count * 10) + (high_count * 3) + (medium_count * 1)
final_score = max(0, base_score - penalties)
```

#### 7.2 Generar Reporte de Auditoria

**Path:** `.king/docs/audits/YYYY-MM-DD-audit-report.md`

**Contenido:**
```markdown
# Audit Report - {fecha}

## Executive Summary
- **Health Score:** {score}%
- **Resultado:** {PASSED|PARTIAL|NEEDS WORK|FAILED}
- **Issues encontrados:** {N} CRITICAL, {N} HIGH, {N} MEDIUM, {N} LOW

## Scores por Area
| Area | Score | Estado |
|------|-------|--------|
| Inventory | {N}% | {status} |
| Format Compliance | {N}% | {status} |
| Cross-References | {N}% | {status} |
| Instruction Quality | {N}% | {status} |
| Communication | {N}% | {status} |
| Efficiency | {N}% | {status} |

## Issues por Severidad

### CRITICAL
{lista de issues criticos}

### HIGH
{lista de issues altos}

### MEDIUM
{lista de issues medios}

### LOW
{lista de issues bajos}

## Recomendaciones Inmediatas
1. {recomendacion 1}
2. {recomendacion 2}

## Metricas Detalladas
{tablas con metricas de cada fase}
```

#### 7.3 Generar Backlog de Mejoras

**Path:** `.king/docs/audits/YYYY-MM-DD-improvement-backlog.md`

**Contenido:**
```markdown
# Improvement Backlog - {fecha}

## Prioridad 1: CRITICAL (resolver inmediatamente)
| # | Issue | Ubicacion | Fix sugerido |
|---|-------|-----------|--------------|
| 1 | {issue} | {path:line} | {fix} |

## Prioridad 2: HIGH (resolver esta semana)
| # | Issue | Ubicacion | Fix sugerido |
|---|-------|-----------|--------------|

## Prioridad 3: MEDIUM (resolver este sprint)
| # | Issue | Ubicacion | Fix sugerido |
|---|-------|-----------|--------------|

## Prioridad 4: LOW (backlog)
| # | Issue | Ubicacion | Fix sugerido |
|---|-------|-----------|--------------|

## Tareas de Consolidacion
{lista de duplicaciones a consolidar}

## Archivos a Revisar
{lista de archivos huerfanos o sobre umbral}
```

#### 7.4 Crear Sesion de Auditoria

**Path:** `skills/_shared/lifecycle-outputs.md` (convención canónica)

Usando template de sesion con campos:
- Scope ejecutado
- Focus aplicado
- Duracion de auditoria
- Health score
- Issues encontrados por severidad
- Archivos generados

### CHECKPOINT
- [ ] Reporte generado en `.king/docs/audits/`
- [ ] Backlog generado en `.king/docs/audits/`
- [ ] Sesion creada en `.king/sessions/`
- [ ] Health score comunicado al usuario

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Audit report or backlog could not be written to .king/docs/audits/
Cause: Directory does not exist, write permission denied, or disk space insufficient.
Recovery:
  [ ] Option A: Run `mkdir -p .king/docs/audits/` and retry the write — verify disk space with `df -h` if still failing
  [ ] Option B: If `--dry-run` is not set but writing fails, output the report content directly to the user and ask them to save it manually
  [ ] Option C: If Health Score was calculated but session could not be registered, communicate the score to the user verbally and note that session registration failed — do not block the audit result on session write failure
