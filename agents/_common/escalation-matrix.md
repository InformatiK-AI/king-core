# Escalation Matrix

## Propósito
Define cuándo y a quién escalan los agentes cuando encuentran situaciones fuera de su alcance.

---

## Matrix de Escalación

| Agente origen | Situación | Escala a | Formato |
|---------------|-----------|----------|---------|
| @developer | Decisión arquitectónica significativa | @architect | "Necesito decisión de arquitectura: {contexto}" |
| @developer | Vulnerabilidad de seguridad detectada | @security (si activo) o usuario | "Posible vulnerabilidad: {detalle}" |
| @developer | Performance concern | @performance (si activo) o @architect | "Concern de performance: {detalle}" |
| @developer | Componente UI con interacción, formularios, patrones a11y | @frontend (si activo) o checklist básico | "Necesito validar accesibilidad: {componente}" |
| @architect | Trade-off seguridad vs funcionalidad | Usuario + @security | "Trade-off requiere decisión: {opciones}" |
| @architect | Cambio de stack/framework | Usuario | "Cambio significativo propuesto: {razón}" |
| @qa | Security Gate FAIL persistente | @security (si activo) o usuario | "Security Gate bloqueado: {findings}" |
| @qa | Resultado ambiguo (CONDITIONAL) | Usuario | "QA condicional, requiere decisión: {condiciones}" |
| @security | Vulnerabilidad crítica en producción | Usuario + @devops | "URGENTE: Vulnerabilidad crítica: {CVE/detalle}" |
| @security | Trade-off seguridad vs UX | Usuario | "Trade-off seguridad/UX: {opciones}" |
| @security | Cambio arquitectónico requerido | @architect | "Requiere cambio arquitectónico para seguridad: {razón}" |
| @devops | Aumento significativo de costo | Usuario | "Costo aumentaría {X}%: {razón}" |
| @devops | Cambio que afecta desarrollo | @developer | "Cambio de infra afecta dev workflow: {detalle}" |
| @api | Breaking change en API pública | Usuario | "Breaking change propuesto: {impacto}" |
| @api | Cambio REST→GraphQL o viceversa | @architect | "Cambio de paradigma de API: {justificación}" |
| @mobile | Cambio de framework | Usuario | "Cambio de framework mobile: {razón}" |
| @mobile | Native module complejo | @developer | "Requiere native module: {spec}" |
| @performance | Cambio arquitectónico para performance | @architect | "Refactor necesario para performance: {bottleneck}" |
| @frontend | WCAG A violation en componente core | @developer | "Violación WCAG A bloqueante: {componente}" |

---

## Protocolo de Escalación

1. **Documentar contexto**: Antes de escalar, el agente documenta el contexto completo
2. **Proporcionar opciones**: Siempre presentar 2-3 alternativas cuando sea posible
3. **Indicar urgencia**: CRITICAL (inmediato), HIGH (antes de continuar), MEDIUM (puede esperar)
4. **Seguir RADAR**: La escalación ocurre en la fase "Decide" del protocolo RADAR

---

## Fallback cuando agente destino no está disponible

| Agente no disponible | Fallback |
|---------------------|----------|
| @security | Escalar a usuario con nota: "Requiere revisión de seguridad manual" |
| @devops | Escalar a @architect para decisión de infra básica |
| @performance | Escalar a @architect para evaluación de trade-offs |
| @api | Escalar a @architect para diseño de API |
| @mobile | Escalar a @developer con guías de platform |

---

## Contratos Bidireccionales

### Matrix de Escalación Extendida

| Agente origen | Situación | Escala a | Response Format | SLA | Acceptance Criteria |
|---------------|-----------|----------|-----------------|-----|---------------------|
| @developer | Decisión arquitectónica | @architect | ADR + implementation guidance | Mismo skill turn | Decisión clara con justificación |
| @developer | Vulnerabilidad detectada | @security | Security assessment + mitigation | HIGH: inmediato | Severidad + acción requerida |
| @developer | Performance concern | @performance | Profiling result + recommendations | MEDIUM: antes de QA | Bottleneck identificado + fix |
| @developer | UI/A11y patterns | @frontend | WCAG compliance report | Antes de merge | Pass/Fail con violations listadas |
| @architect | Security trade-off | @security | Risk assessment + options | Mismo skill turn | Risk level + recommendation |
| @qa | Security Gate FAIL | @security | Deep review | HIGH: bloquea merge | Clear Pass/Fail |
| @security | Arch change needed | @architect | ADR proposal | Siguiente skill turn | Accepted/Rejected |

### Reverse Mappings (Qué hace el receptor)

Cuando un agente recibe una escalación, debe:

| Receptor | Recibe de | Debe hacer | Output esperado |
|----------|-----------|------------|-----------------|
| @architect | @developer | 1. Evaluar alternativas 2. Documentar trade-offs 3. Crear ADR | ADR + guía de implementación |
| @architect | @security | 1. Evaluar impacto 2. Proponer refactor 3. Estimar esfuerzo | Plan de acción + ADR si aplica |
| @architect | @performance | 1. Analizar bottleneck 2. Decidir si requiere refactor | Decisión: quick-fix vs refactor |
| @security | @developer | 1. Clasificar severidad 2. Proponer mitigación 3. Definir urgencia | Security assessment |
| @security | @qa | 1. Deep review 2. STRIDE si aplica 3. Aprobar o bloquear | Pass/Fail con justificación |
| @frontend | @developer | 1. Evaluar WCAG 2. Listar violations 3. Sugerir fixes | A11y audit report |
| @performance | @developer | 1. Profile 2. Identificar bottleneck 3. Sugerir optimización | Performance report |
| @devops | @security | 1. Evaluar impacto infra 2. Planificar patch 3. Coordinar deploy | Deployment plan |

### Acceptance Criteria por Tipo de Decisión

| Tipo de decisión | Debe incluir | Formato |
|------------------|--------------|---------|
| Arquitectura | Opciones evaluadas, trade-offs, decisión, justificación | ADR (`king-framework/docs/architecture/`) |
| Seguridad | Severidad, impacto, mitigación, timeline | Security Assessment |
| Performance | Métricas before/after, bottleneck, solución propuesta | Performance Report |
| Accesibilidad | WCAG level, violations, remediations | A11y Audit Report |
| UX | Heurísticas evaluadas, issues, recomendaciones | UX Review |

### SLA por Urgencia

| Urgencia | Response time | Bloquea |
|----------|--------------|---------|
| CRITICAL | Inmediato (mismo turno) | Sí, todo |
| HIGH | Antes de continuar skill | Sí, skill actual |
| MEDIUM | Antes de siguiente fase | No, puede continuar |
| LOW | Cuando sea posible | No |

---

## Formato de Handoff

Para el formato completo de transferencia de contexto entre agentes, ver:
`agents/_common/context-handoff.md`
