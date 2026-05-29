# Brainstorming - Reference

> Templates de diseño, ejemplos de output, registro de sesión y notas de performance.

---

## Template: Modo FEATURE

```markdown
---
project: "{Nombre del Proyecto}"
date: "{YYYY-MM-DD}"
author: "{Host}"
version: "1.0"
generated-by: "/brainstorm --feature {feature-name}"
artifact: "feature-design"
---

# Design: {Feature Name}

## Overview

{Brief description and goals}

## Approach

{Chosen approach and rationale}

## Architecture

{High-level architecture decisions}

## Components

{Key components and their responsibilities}

## Data Flow

{How data moves through the system}

## Expert Considerations

> Recomendaciones integradas de agentes especializados

{Solo incluir secciones de agentes que fueron consultados}

### Architecture (si @architect fue consultado)
- {Recomendación 1}
- {Recomendación 2}

### Security Considerations (si @security fue consultado)
- {Recomendación 1}
- {Recomendación 2}

### Accessibility & UX (si @frontend fue consultado)
- {Recomendación 1}
- {Recomendación 2}

### Performance (si @performance fue consultado)
- {Recomendación 1}
- {Recomendación 2}

### API Design (si @api fue consultado)
- {Recomendación 1}
- {Recomendación 2}

### Infrastructure (si @devops fue consultado)
- {Recomendación 1}
- {Recomendación 2}

## Error Handling

{Error scenarios and handling strategy}

## Testing Strategy

{How this will be tested}

## Agents Consulted

| Agent | Signal Detected | Status | Key Recommendation |
|-------|-----------------|--------|-------------------|
| @{agent} | {signal} | {Consulted \| Fallback} | {1-line summary} |
```

---

## Template: Modo PROYECTO (001-arquitectura.md)

```markdown
---
project: "{Nombre del Proyecto}"
date: "{YYYY-MM-DD}"
author: "{Host}"
version: "1.0"
generated-by: "/brainstorm --mode proyecto"
artifact: "001-arquitectura"
---

# Arquitectura: {Nombre del Proyecto}

## Contexto del Sistema

{Qué hace el sistema, para quién, qué problema resuelve}
{Referencia al stack elegido en /genesis}

## Visión General

{Descripción de alto nivel de cómo funciona el sistema}

## Decisiones de Arquitectura (ADR Inicial)

### ADR-001: Stack Tecnológico

**Contexto:** {Por qué se eligió este stack}
**Decisión:** {Stack específico con versiones}
**Consecuencias:** {Trade-offs aceptados}

### ADR-002: Arquitectura General

**Contexto:** {Requisitos que influyen la arquitectura}
**Decisión:** {Monolito, microservicios, serverless, etc.}
**Consecuencias:** {Implicaciones de la decisión}

## Componentes del Sistema

| Componente | Responsabilidad | Tecnología | Ref Deps |
|------------|-----------------|------------|----------|
| {módulo}   | {qué hace}      | {tech}     | [003](#) |

## Flujo de Datos Principal

{Diagrama ASCII del flujo de datos}

```
[Usuario] → [Frontend] → [API] → [DB]
                           ↓
                      [Servicios Externos]
```

## Integraciones Externas

| Servicio | Propósito | Credenciales | Ref Deps |
|----------|-----------|--------------|----------|
| {servicio} | {para qué} | {cómo se manejan} | [003](#) |

## Consideraciones de Seguridad

- **Autenticación:** {estrategia}
- **Autorización:** {modelo de permisos}
- **Datos sensibles:** {cómo se protegen}
- **Secrets:** {cómo se gestionan}

## Estrategia de Testing

| Tipo | Herramientas | Cobertura objetivo |
|------|--------------|-------------------|
| Unit | {framework} | {%} |
| Integration | {framework} | {áreas} |
| E2E | {framework} | {flujos críticos} |

## Estructura de Carpetas Propuesta

```
src/
├── {módulo}/
│   ├── components/
│   ├── services/
│   └── types/
```

## Expert Considerations

> Recomendaciones integradas de agentes especializados
> Solo incluir secciones de agentes que fueron consultados

### Architecture (si @architect fue consultado)
- {Recomendación 1}

### Security Considerations (si @security fue consultado)
- {Recomendación 1}

### Accessibility & UX (si @frontend fue consultado)
- {Recomendación 1}

### Performance (si @performance fue consultado)
- {Recomendación 1}

## Agents Consulted

| Agent | Signal Detected | Status | Key Recommendation |
|-------|-----------------|--------|-------------------|
| @{agent} | {signal} | {Consulted \| Fallback} | {1-line summary} |

## Próximos Pasos

1. {Primera feature a implementar}
2. {Segunda feature}
3. {Tercera feature}

## Documentos Relacionados

- [Modelo de Datos](002-{proyecto}-modelo-datos.md)
- [Dependencias](003-{proyecto}-dependencias.md)
- [Log de Inconsistencias](004-{proyecto}-inconsistencias.md)
```

---

## Template: Modo PROYECTO (002-modelo-datos.md)

```markdown
---
project: "{Nombre del Proyecto}"
date: "{YYYY-MM-DD}"
author: "{Host}"
version: "1.0"
generated-by: "/brainstorm --mode proyecto"
artifact: "002-modelo-datos"
---

# Modelo de Datos: {Nombre del Proyecto}

## Modelo Conceptual

> Entidades de negocio y sus relaciones, independiente de tecnología.

### Entidades

| Entidad | Descripción | Atributos clave |
|---------|-------------|-----------------|
| {Entidad} | {qué representa en el negocio} | {atributos principales} |

### Relaciones

```
[Entidad A] ──1:N──> [Entidad B]
[Entidad B] ──N:M──> [Entidad C]
```

| Relación | Cardinalidad | Regla de negocio |
|----------|-------------|------------------|
| {A} → {B} | 1:N | {descripción de la regla} |

### Reglas de Dominio

- {Regla 1: ej. "Una orden no puede existir sin usuario"}
- {Regla 2: ej. "El stock no puede ser negativo"}

## Modelo Técnico

> Implementación específica del stack: {stack del proyecto — de /genesis}

### Esquemas de Base de Datos

{SQL si relacional, estructura de documentos si NoSQL}

```sql
CREATE TABLE {tabla} (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  {campo} {tipo} {restricciones},
  created_at TIMESTAMPTZ DEFAULT NOW()
);
```

### Interfaces / Tipos

{TypeScript si el stack incluye TS}

```typescript
interface {Entidad} {
  id: string;
  {campo}: {tipo};
  createdAt: Date;
}
```

### Migraciones Previstas

| Orden | Migración | Entidades afectadas |
|-------|-----------|---------------------|
| 1 | Crear tablas iniciales | {lista} |
| 2 | {siguiente migración} | {entidades} |

## Documentos Relacionados

- [Arquitectura](001-{proyecto}-arquitectura.md)
- [Dependencias](003-{proyecto}-dependencias.md)
- [Log de Inconsistencias](004-{proyecto}-inconsistencias.md)
```

---

## Template: Modo PROYECTO (003-dependencias.md)

```markdown
---
project: "{Nombre del Proyecto}"
date: "{YYYY-MM-DD}"
author: "{Host}"
version: "1.0"
generated-by: "/brainstorm --mode proyecto"
artifact: "003-dependencias"
---

# Dependencias: {Nombre del Proyecto}

## Dependencias Externas

### Producción

| Paquete | Versión | Propósito | Riesgo | Alternativa |
|---------|---------|-----------|--------|-------------|
| {paquete} | {^X.Y.Z} | {para qué} | BAJO/MEDIO/ALTO | {alternativa viable} |

### Desarrollo

| Paquete | Versión | Propósito |
|---------|---------|-----------|
| {paquete} | {^X.Y.Z} | {para qué} |

### Servicios Externos

| Servicio | Tipo | SLA esperado | Fallback | Riesgo |
|----------|------|-------------|----------|--------|
| {servicio} | API/SaaS/DB | {disponibilidad} | {estrategia si falla} | BAJO/MEDIO/ALTO |

## Módulos Internos

| Módulo | Responsabilidad | Depende de | Lo dependen |
|--------|-----------------|------------|-------------|
| {módulo} | {qué hace} | {módulos internos} | {módulos que lo usan} |

### Grafo de Dependencias

```
{módulo-A} → {módulo-B} → {módulo-C}
{módulo-A} → {módulo-D}
```

## Evaluación de Riesgos

### Riesgos Altos

| Dependencia | Riesgo | Mitigación |
|-------------|--------|------------|
| {dep} | {descripción del riesgo} | {plan de mitigación} |

### Política de Actualización

- **Dependencias de seguridad:** Actualizar inmediatamente
- **Major versions:** Evaluar breaking changes antes de actualizar
- **Lock file:** {package-lock.json / yarn.lock / pnpm-lock.yaml} debe estar en git

## Documentos Relacionados

- [Arquitectura](001-{proyecto}-arquitectura.md)
- [Modelo de Datos](002-{proyecto}-modelo-datos.md)
- [Log de Inconsistencias](004-{proyecto}-inconsistencias.md)
```

---

## Template: Modo PROYECTO (004-inconsistencias.md)

```markdown
---
project: "{Nombre del Proyecto}"
date: "{YYYY-MM-DD}"
author: "{Host}"
version: "1.0"
generated-by: "/brainstorm --mode proyecto"
artifact: "004-inconsistencias"
---

# Log de Inconsistencias: {Nombre del Proyecto}

> Registro de gaps funcionales, ambigüedades y conflictos detectados durante el brainstorming.
> Este documento es un artefacto vivo: se actualiza con cada `/brainstorm --feature`.

## Resumen

| Severidad | Abiertas | Resueltas |
|-----------|----------|-----------|
| HIGH      | {N}      | {N}       |
| MEDIUM    | {N}      | {N}       |
| LOW       | {N}      | {N}       |

## Inconsistencias Abiertas

| ID | Severidad | Descripción | Detectada por | Fase | Fecha | Contexto |
|----|-----------|-------------|---------------|------|-------|----------|
| INC-001 | HIGH/MEDIUM/LOW | {descripción} | {@agente o exploración} | {fase} | {YYYY-MM-DD} | {brainstorm proyecto / feature X} |

### INC-001: {Título descriptivo}

**Descripción:** {Detalle de la inconsistencia o ambigüedad}
**Impacto:** {Qué podría salir mal si no se resuelve}
**Resolución sugerida:** {Propuesta para resolver}
**Status:** ABIERTA

## Inconsistencias Resueltas

| ID | Descripción | Resolución | Fecha resolución |
|----|-------------|------------|-----------------|
| (vacío inicialmente) | | | |

## Documentos Relacionados

- [Arquitectura](001-{proyecto}-arquitectura.md)
- [Modelo de Datos](002-{proyecto}-modelo-datos.md)
- [Dependencias](003-{proyecto}-dependencias.md)
```

---

## Template: Delta Section (Modo FEATURE — append a docs base)

> Este bloque se APPENDA al final de cada documento base que recibe cambios de una feature.
> Usar Edit tool en modo append. NUNCA reescribir el documento completo.

**Para 001-arquitectura.md:**
```markdown
---

## Delta: {feature-name} ({YYYY-MM-DD})
> Generado por: /brainstorm --feature {feature-name} | Versión previa: {1.0} → {1.1}

### Nuevos Componentes
| Componente | Responsabilidad | Tecnología |
|------------|-----------------|------------|
| {módulo}   | {qué hace}      | {tech}     |

### Nuevas Integraciones
| Servicio | Propósito |
|----------|-----------|
| {servicio} | {para qué} |

### ADRs Adicionales (si aplica)
- ADR-00{N}: {decisión}
```

**Para 002-modelo-datos.md:**
```markdown
---

## Delta: {feature-name} ({YYYY-MM-DD})
> Generado por: /brainstorm --feature {feature-name} | Versión previa: {1.0} → {1.1}

### Nuevas Entidades
| Entidad | Descripción | Atributos clave |
|---------|-------------|-----------------|
| {Entidad} | {qué representa} | {atributos} |

### Nuevas Relaciones
| Relación | Cardinalidad | Regla de negocio |
|----------|-------------|------------------|
| {A} → {B} | {1:N} | {regla} |

### Nuevos Schemas / Interfaces
{código según stack}
```

**Para 003-dependencias.md:**
```markdown
---

## Delta: {feature-name} ({YYYY-MM-DD})
> Generado por: /brainstorm --feature {feature-name} | Versión previa: {1.0} → {1.1}

### Nuevos Paquetes
| Paquete | Versión | Propósito | Riesgo | Alternativa |
|---------|---------|-----------|--------|-------------|
| {paquete} | {^X.Y.Z} | {para qué} | {riesgo} | {alternativa} |

### Nuevos Módulos Internos
| Módulo | Responsabilidad | Depende de |
|--------|-----------------|------------|
| {módulo} | {qué hace} | {deps} |
```

**Para 004-inconsistencias.md:**
```markdown
---

## Delta: {feature-name} ({YYYY-MM-DD})
> Generado por: /brainstorm --feature {feature-name} | Versión previa: {1.0} → {1.1}

### Nuevas Inconsistencias

| ID | Severidad | Descripción | Detectada por | Fase | Fecha | Contexto |
|----|-----------|-------------|---------------|------|-------|----------|
| INC-{N} | {sev} | {descripción} | {@agente} | {fase} | {YYYY-MM-DD} | feature: {feature-name} |

### Inconsistencias Resueltas en esta sesión

| ID | Resolución |
|----|------------|
| INC-{N} | {cómo se resolvió} |
```

---

## Output de Finalización

### Modo PROYECTO

```
Blueprint técnico del proyecto generado.

Documentos creados en: `.king/docs/architecture/`
   - 001-{proyecto}-arquitectura.md  ← Arquitectura, ADRs, componentes
   - 002-{proyecto}-modelo-datos.md  ← Modelo conceptual + técnico
   - 003-{proyecto}-dependencias.md  ← Deps externas + módulos internos
   - 004-{proyecto}-inconsistencias.md ← Gaps funcionales detectados

Estos documentos sirven como:
   - Base de conocimiento técnico para todos los agentes
   - Contexto primario para /plan y /build
   - Referencia viva que se expande con cada /brainstorm --feature

Progreso del flujo:
   [done] Génesis
   [done] Brainstorming (arquitectura del sistema) ← completado
   [ ] Brainstorming (features)
   [ ] Plan
   [ ] Crear Issues
   [ ] Build

Próximo paso: /brainstorm --feature {nombre} para diseñar tu primera feature
```

### Modo FEATURE

> **Detección de señales UI**: Si el diseño incluye componentes de interfaz
> (formularios, dashboards, landing pages, visualización de datos, flujos de onboarding),
> sugerir `/frontend-design` (king-content, si king-content está instalado) como paso intermedio antes de `/create-issues`.

```
Brainstorming completado.

Documento guardado en: `{output_path}`

Agentes consultados: {lista o "ninguno (no se detectaron señales)"}
   - @{agente}: {recomendación clave integrada}

Progreso del flujo:
   [done] Génesis
   [done] Brainstorming ← completado
   [ ] Frontend Design (si UI)
   [ ] Crear Issues
   [ ] Build
   [ ] QA + Merge
```

Si señales UI detectadas en el diseño:
```
Próximo paso sugerido: /frontend-design --feature {feature}
   (king-content, si king-content está instalado — diseño visual de alta calidad antes de implementar)
   Alternativa: /create-issues (si prefieres ir directo a implementación)
```

Si NO hay señales UI:
```
Próximo paso: /create-issues
```

---

## Registro de Sesión

> Formato base: `skills/session-management/SKILL.md`

Crea `.king/sessions/YYYY-MM-DD-brainstorm-{feature}.md` con campos adicionales:

- **Alternativas consideradas**: Enfoques descartados con razón

---

## Performance Notes

La consulta de agentes NO degrada el rendimiento porque:

1. **Consulta selectiva**: Solo agentes cuyas señales se detectan (típicamente 2-4, no 8)
2. **Consultas concisas**: Se pide recomendaciones puntuales, no análisis exhaustivos
3. **Integración inline**: Las recomendaciones se incorporan al diseño, no generan documentos separados
4. **Evita retrabajo**: Detectar problemas en diseño es más barato que rediseñar después de implementar

```
SIN consulta de agentes:
  Diseño (10 min) → Issues → Build → "No es seguro" → Rediseño (30 min) = 40+ min

CON consulta de agentes:
  Diseño (10 min) → Consulta @security (2 min) → Diseño completo → Issues → Build = 12 min
```

---

## METADATA FORMAT
> 📝 Frontmatter YAML que encabeza cada artefacto generado

```yaml
---
project: "{from CLAUDE.md title heading}"
date: "YYYY-MM-DD"
author: "{Host — git config user.name / gh auth status}"
version: "1.0"
generated-by: "/brainstorm --mode proyecto"
artifact: "001-arquitectura"
---
```

- `author`: siempre el Host (usuario humano). NUNCA hardcodear "Claude".
- `version`: inicia en `1.0`. Cada `/brainstorm --feature` que modifica el doc incrementa minor: `1.1`, `1.2`, etc.
- `generated-by`: skill invocation que creó o modificó el archivo.
- `artifact`: identificador del artefacto (`001-arquitectura`, `002-modelo-datos`, `003-dependencias`, `004-inconsistencias`).

---

## AGENT CONSULTATION MATRIX
> 🤖 Señales que activan consulta a agentes durante el diseño

| Señal en el diseño | Agente a consultar | Qué aporta |
|-------------------|-------------------|------------|
| Multi-componente, patrones, data flow, dependencias entre módulos | `@architect` | Decisiones de diseño, ADRs, trade-offs arquitectónicos |
| Pagos, auth, datos sensibles, compliance | `@security` | Arquitectura segura por diseño |
| UI, frontend, formularios, dashboards | `@frontend` | Patrones accesibles, WCAG |
| Alto tráfico, escala, caching | `@performance` | Diseño escalable |
| API pública, GraphQL, microservicios | `@api` | Contratos bien diseñados |
| Containers, cloud, CI/CD, deploy | `@devops` | Arquitectura cloud-native |
| Mobile app, React Native, Flutter | `@mobile` | Patrones móviles |

---

## Detección Automática de Modo

**ANTES de comenzar, detectar el modo:**

> Si el usuario pasa `--mode {proyecto|feature}`, usar ese modo directamente sin detección automática.

### Verificación

```
SI NO existe `.king/docs/plans/*-design.md`
   Y NO existe `.king/docs/architecture/*-arquitectura.md`
   Y existe `.king/sessions/*genesis.md`
ENTONCES
   → Modo PROYECTO (primer brainstorming post-genesis)
SINO
   → Modo FEATURE (comportamiento estándar)
```

### Modo PROYECTO
Cuando es el primer brainstorming después de `/genesis`:
- Alcance ampliado: diseñar la arquitectura completa del sistema
- Output: 4 artefactos en `.king/docs/architecture/`

### Modo FEATURE
Comportamiento estándar: diseñar una feature específica.
- Output: `design.md` + deltas appendeados a los 4 docs base

---

## IF FAILS

### Escenario A: Usuario no responde a pregunta de discovery
**Recovery**: Reformular más simple o con opciones concretas. Si continúa sin respuesta, usar valor default y documentar supuesto.

### Escenario B: Usuario rechaza el diseño después de 3+ iteraciones
**Recovery**: Parar, pedir qué aspecto específico no funciona. Usar `/genesis` si hay confusión sobre el contexto del proyecto.

### Escenario C: Sesión interrumpida
**Recovery**: Leer `.king/sessions/` para el último estado. Resumir desde la última fase completada.
