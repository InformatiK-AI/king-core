# Skill Template v2.0

> Plantilla para skills con ejecución completa garantizada.

## Principios de Diseño

1. **QUICK REFERENCE arriba** - Todo lo crítico visible inmediatamente
2. **OUTPUTS como requisitos** - No escondidos, listados prominentemente
3. **BLOCKING CONDITIONS explícitas** - Lo que detiene la ejecución
4. **Fases con gates** - Cada fase tiene entrada, acciones, checkpoint y salida
5. **MUST DO con checkboxes** - Fuerza secuencialidad y verificación
6. **REFERENCE separado** - Explicaciones no interfieren con ejecución

---

## Estructura del Template

```markdown
---
name: skill-name
version: 2.0
description: "Descripción breve"
# model: sonnet   # opcional — workers-inline=sonnet, triviales=haiku, orquestadores=sin campo. Nunca opus.
---

# Skill Name

## QUICK REFERENCE

### BLOCKING CONDITIONS
> ⛔ Condiciones que DETIENEN la ejecución inmediatamente

- [ ] Condición 1
- [ ] Condición 2

<!-- OPTIONAL: incluir si el skill tiene prohibiciones de conducta runtime -->
### ABSOLUTE RESTRICTIONS
> 🚫 Comportamientos absolutamente prohibidos — sin excepciones

- NUNCA [prohibición runtime 1]
- NUNCA [prohibición runtime 2]
<!-- Nota: usar bullets `-` (no checkboxes `[ ]`) — estas reglas son siempre activas, no se verifican puntualmente -->
<!-- Distinción semántica: BLOCKING CONDITIONS = gates pre-ejecución (estado del sistema); ABSOLUTE RESTRICTIONS = prohibiciones de conducta durante ejecución -->

### REQUIRED OUTPUTS
> 📦 Archivos que DEBEN crearse al finalizar

- [ ] `path/to/output1`
- [ ] `path/to/output2`

### PHASES OVERVIEW
```
PHASE 1 → PHASE 2 → PHASE 3 → PHASE 4
   ↓         ↓         ↓         ↓
 Gate 1   Gate 2    Gate 3   Complete
```

---

## PHASE 1: Name

### GATE IN
> Condiciones para entrar a esta fase

- [ ] Pre-condición 1
- [ ] Pre-condición 2

### MUST DO
> ⚠️ Todas las acciones son OBLIGATORIAS

1. [ ] **Acción 1** - Descripción breve
2. [ ] **Acción 2** - Descripción breve
3. [ ] **Acción 3** - Descripción breve

### CHECKPOINT
> ✅ Verificar antes de continuar

- [ ] Verificación 1
- [ ] Verificación 2

### OUTPUTS
- `path/to/file` - Descripción

### IF FAILS
> ❌ Qué hacer si la fase falla

```
Mensaje de error estructurado
```

---

## PHASE N: ...

[Repetir estructura]

---

## FINAL CHECKPOINT

Antes de terminar, verificar:

- [ ] TODOS los REQUIRED OUTPUTS existen
- [ ] TODOS los CHECKPOINTS de cada fase pasaron
- [ ] Sesión registrada

---

## REFERENCE

> 📚 Información adicional para entender el skill.
> Esta sección NO contiene acciones, solo contexto.

### Casos Edge

#### Caso 1: Descripción
Explicación de cómo manejar...

### Ejemplos

#### Ejemplo 1
```
Ejemplo detallado...
```

### Integraciones
- Relación con otros skills
- Agentes que puede invocar
```

---

## Checklist de Creación

Al crear un nuevo skill v2.0, verificar:

- [ ] QUICK REFERENCE cabe en una pantalla
- [ ] BLOCKING CONDITIONS son verificables programáticamente
- [ ] Si el skill tiene prohibiciones runtime: incluir `### ABSOLUTE RESTRICTIONS` con bullets NUNCA
- [ ] REQUIRED OUTPUTS tienen paths concretos
- [ ] Cada PHASE tiene GATE IN, MUST DO, CHECKPOINT
- [ ] MUST DO usa checkboxes `[ ]`
- [ ] No hay acciones en sección REFERENCE
- [ ] Total < 200 líneas (excluye REFERENCE)

## Convenciones de Marcado

| Marcador | Significado |
|----------|-------------|
| `[ ]` | Acción obligatoria, debe completarse |
| `⛔` | Condición bloqueante |
| `🚫` | Prohibición absoluta de conducta runtime |
| `⚠️` | Advertencia importante |
| `✅` | Checkpoint de verificación |
| `❌` | Condición de fallo |
| `📦` | Output requerido |
| `📚` | Referencia/documentación |

## Diferencias con v1.0

| Aspecto | v1.0 | v2.0 |
|---------|------|------|
| Estructura | Narrativa | Fases discretas |
| Outputs | Al final, mezclados | Arriba, lista explícita |
| Condiciones | Enterradas en texto | BLOCKING CONDITIONS arriba |
| Acciones | Párrafos explicativos | Checkboxes MUST DO |
| Verificación | Implícita | CHECKPOINT explícito |
| Documentación | Mezclada con acciones | REFERENCE separado |
