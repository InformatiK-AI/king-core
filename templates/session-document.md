# Session Document — [ID]

> Auto-generado al completar un skill. Parte del sistema de persistencia de contexto.

---

## Metadata

| Campo | Valor |
|-------|-------|
| **Session ID** | WF-XXX-SNNN |
| **Workflow** | WF-XXX — [nombre] |
| **Skill** | [nombre del skill ejecutado] |
| **Usuario** | [gh_user (git: git_user)] |
| **Hora Inicio** | YYYY-MM-DD HH:MM |
| **Hora Fin** | YYYY-MM-DD HH:MM |
| **Fecha** | YYYY-MM-DD |
| **Branch** | [branch activo] |
| **Pipeline Position** | N de M (ej: 4 de 8) |
| **Agentes** | [@agent1, @agent2] |

---

## Protocolo RADAR

### Read
- **Archivos revisados**: [lista de archivos leídos]
- **Contexto identificado**: [resumen del contexto relevante]
- **Contexto heredado**: [qué se cargó del workflow context]

### Analyze
- **Alternativas evaluadas**: [N alternativas]
- **Trade-offs principales**: [resumen]

### Decide
- **Decisión tomada**: [descripción]
- **Justificación**: [razón de la elección]

### Act
- **Cambios implementados**: [lista]
- **Commits realizados**: [lista de hashes y mensajes]

### Report
- **Resultado**: [resumen del outcome]

---

## CASTLE Assessment

```
C  Contracts     [PASS|WARN|FAIL|----]
A  Architecture  [PASS|WARN|FAIL|----]
S  Security      [PASS|WARN|FAIL|----]
T  Testing       [PASS|WARN|FAIL|----]
L  Logging       [PASS|WARN|FAIL|----]
E  Environment   [PASS|WARN|FAIL|----]

Veredicto: [FORTIFIED|CONDITIONAL|BREACHED]
```

### Findings
- [finding 1: descripción y severidad]
- [finding 2: descripción y severidad]

---

## Archivos Modificados

| Archivo | Lineas | Tipo | Detalle |
|---------|--------|------|---------|
| [path] | [rango] | [add/mod/del] | [descripción del cambio] |

---

## Commits Realizados

| Hash | Mensaje | Archivos |
|------|---------|----------|
| [short hash] | [conventional commit message] | [N archivos] |

---

## Evidencia Visual

### Checklist
| Campo | Valor |
|-------|-------|
| **Captura intentada** | SI / NO |
| **App corriendo** | SI / NO / NO VERIFICADO |
| **Screenshots capturados** | [N] |
| **Directorio** | `.king/sessions/evidence/YYYY-MM-DD_NNN_[skill-name]/` o N/A |
| **Motivo si omitida** | [App no iniciada / Cambio no-visual / Otro] |

### Screenshots
| # | Screenshot | Descripción | Estado |
|---|-----------|-------------|--------|
| 1 | [path] | [descripción] | OK |
| — | N/A | [motivo] | SKIP |

---

## Artefactos

| Tipo | Referencia |
|------|-----------|
| PR | [URL o N/A] |
| Branch | [nombre] |
| Build | [OK/FAIL] |
| Report | [path o N/A] |

---

## Proxima Accion

### Skill Recomendado
`/[skill]` — [objetivo]

### Que Verificar Antes
- [pre-condición 1]
- [pre-condición 2]

### Arbol de Decision
```
Si CASTLE FORTIFIED   → [skill A]
Si CASTLE CONDITIONAL → [skill B]
Si CASTLE BREACHED    → [skill C]
```
