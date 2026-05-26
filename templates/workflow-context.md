# Workflow Context — [NOMBRE]

> Auto-generado por el sistema de persistencia de contexto. NO editar manualmente.

---

## Metadata

| Campo | Valor |
|-------|-------|
| **ID** | WF-NNN |
| **Nombre** | [nombre descriptivo] |
| **Branch** | feature/[nombre] |
| **Iniciado** | YYYY-MM-DD |
| **Fase Actual** | [skill en progreso o completado] |
| **Estado** | ACTIVO |

---

## Decisiones Clave

1. [Decisión tomada con justificación RADAR]
2. [Otra decisión]

---

## Archivos Modificados

| Archivo | Secciones | Cambios |
|---------|-----------|---------|
| [path] | [secciones afectadas] | [resumen de cambios] |

---

## Estado CASTLE

| Campo | Valor |
|-------|-------|
| **Último Assessment** | [FORTIFIED/CONDITIONAL/BREACHED] |
| **Skill que evaluó** | [skill] |
| **Fecha** | YYYY-MM-DD |

### Detalle por Capa
```
C  Contracts     [PASS|WARN|FAIL|----]
A  Architecture  [PASS|WARN|FAIL|----]
S  Security      [PASS|WARN|FAIL|----]
T  Testing       [PASS|WARN|FAIL|----]
L  Logging       [PASS|WARN|FAIL|----]
E  Environment   [PASS|WARN|FAIL|----]
```

### Warnings Activos
- [warning pendiente de resolver]

### Blockers
- [blocker que impide avanzar]

### Target
- [objetivo de CASTLE para el workflow, ej: FORTIFIED para release]

---

## Sesiones Archivadas (compactadas)

> Esta sección es generada automáticamente por Phase N+1.2 de session-management cuando
> "Cadena de Sesiones" supera 20 filas. NO editar manualmente.
>
> RESTRICCIÓN INMUTABLE: El formato de cada fila NO puede cambiar sin actualizar
> simultáneamente el algoritmo de compactación en session-management/SKILL.md.
>
> Deferral: Si hay blockers activos en CASTLE, la compactación se difiere y se agrega:
> `<!-- Compactación diferida: blockers activos en YYYY-MM-DD -->`

| Fecha | Skill | Resultado |
|-------|-------|-----------|
| YYYY-MM-DD | /skill-name | FORTIFIED/CONDITIONAL/BREACHED (resumen 1 línea) |

---

## Cadena de Sesiones

> RESTRICCIÓN INMUTABLE: El formato de cada fila es `| SXXX | /skill | usuario | RESULTADO | path |`
> Este formato NO puede cambiar sin actualizar simultáneamente el algoritmo de compactación.
> Phase N+1.2 compacta esta sección cuando supera 20 filas (preserva las últimas 5 completas).

| # | Skill | Usuario | Resultado | Documento |
|---|-------|---------|-----------|-----------|
| S001 | [skill] | [usuario] | [PASS/FAIL] | [path al session document] |

---

## Artefactos Producidos

| Tipo | Referencia |
|------|-----------|
| Design Doc | [path o N/A] |
| Plan | [path o N/A] |
| PR | [URL o N/A] |
| Branch | [nombre del branch] |
| Tag | [tag o N/A] |
| Release | [URL o N/A] |

---

## Tareas Pendientes

- [ ] [tarea pendiente 1]
- [ ] [tarea pendiente 2]

---

## Proxima Accion

### Skill Recomendado
`/[skill]` — [objetivo del próximo paso]

### Pre-condiciones
- [qué verificar antes de ejecutar el próximo skill]

### Arbol de Decision Post-Skill
```
Si [resultado positivo] → [siguiente skill]
Si [resultado negativo] → [skill alternativo]
Si [caso especial]     → [acción especial]
```
