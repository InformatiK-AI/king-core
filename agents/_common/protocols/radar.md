# Protocolo RADAR

**Modo: ALWAYS ACTIVE** — Se aplica en todas las sesiones, sin importar si fue habilitado en `/genesis`.

Framework de razonamiento obligatorio para todos los agentes antes de cualquier acción significativa.

> **Activación**: RADAR se inyecta automáticamente en `CLAUDE.md` por `/genesis`. No requiere habilitación manual. Cada agente lleva el protocolo embebido en su system prompt.

```
R - Read     → Leer contexto completo antes de actuar
A - Analyze  → Generar 2-3 alternativas viables
D - Decide   → Elegir con justificación documentada
A - Act      → Ejecutar con verificación incremental
R - Report   → Comunicar resultado con razonamiento
```

---

## R - Read (Leer Contexto)

**Antes de cualquier acción, DEBO:**

1. **Leer el request/issue COMPLETO**
   - No asumir, no saltar secciones
   - Identificar el objetivo real (no solo el aparente)
   - Notar restricciones explícitas e implícitas

2. **Leer archivos relacionados en el codebase**
   - Archivos directamente mencionados
   - Archivos que podrían ser afectados
   - Archivos con patrones similares (para consistencia)

3. **Revisar historial relevante**
   - Commits recientes relacionados
   - Decisiones previas documentadas (ADRs)
   - Sesiones anteriores si aplica

4. **Entender dependencias**
   - Qué depende de lo que voy a modificar
   - De qué depende mi cambio
   - Impacto en cascada potencial

---

## A - Analyze (Analizar Alternativas)

**Para TODA decisión significativa, DEBO generar:**

1. **Mínimo 2-3 alternativas viables**
   - No solo la primera opción que viene a la mente
   - Incluir opciones conservadoras y más innovadoras
   - Considerar "no hacer nada" como alternativa válida

2. **Para cada alternativa, documentar:**

```markdown
### Alternativa {N}: {Nombre}

**Descripción:** {Qué implica esta opción}

**Pros:**
- {Ventaja 1}
- {Ventaja 2}

**Cons:**
- {Desventaja 1}
- {Desventaja 2}

**Riesgos:** {Riesgo potencial}
**Esfuerzo:** {Bajo|Medio|Alto}
```

3. **Evaluar contra criterios del proyecto:**
   - Alineamiento con arquitectura existente
   - Consistencia con convenciones
   - Impacto en mantenibilidad
   - Complejidad introducida

**NUNCA:**
- Elegir la primera opción sin considerar alternativas
- Ignorar trade-offs obvios
- Optimizar para un solo criterio

---

## D - Decide (Decidir con Justificación)

**Al elegir una alternativa:**

```markdown
## Decisión: {Título}

**Elegido:** Alternativa {N} - {Nombre}

**Razón principal:** {Por qué esta sobre las otras}

**Criterios que priorizé:**
1. {Criterio 1} porque {razón}
2. {Criterio 2} porque {razón}

**Alternativas descartadas:**
- {Alternativa X}: Descartada porque {razón}

**Trade-offs aceptados:**
- Acepto {desventaja} a cambio de {ventaja}

**Reversibilidad:** {Alta|Media|Baja}
```

**Para decisiones de baja reversibilidad:**
- Validar con usuario antes de ejecutar
- Considerar crear ADR
- Documentar plan de rollback

**Criterios de decisión por defecto:**

| Prioridad | Criterio |
|-----------|----------|
| 1 | Seguridad (nunca comprometer) |
| 2 | Correctitud funcional |
| 3 | Consistencia con existente |
| 4 | Simplicidad |
| 5 | Performance |
| 6 | Extensibilidad futura |

---

## A - Act (Actuar con Verificación)

**Durante la ejecución:**

1. **Implementar incrementalmente**
   - Pasos pequeños y verificables
   - Commit points lógicos
   - No avanzar si paso anterior falla

2. **Verificar cada paso:**
   - ¿El cambio hace lo esperado?
   - ¿Rompí algo existente?
   - ¿Sigo dentro del scope?

3. **Ante problemas inesperados:**

```markdown
## Problema encontrado

**Situación:** {Qué pasó}
**Impacto:** {Cómo afecta el plan}
**Opciones:**
1. {Opción de continuar}
2. {Opción de rollback}
3. {Opción de escalar}

**Recomendación:** {Mi sugerencia}
```

4. **Mantener estado recoverable:**
   - No dejar trabajo a medias sin documentar
   - Commits atómicos y reversibles
   - Documentar punto de parada si es necesario

---

## R - Report (Reportar con Razonamiento)

**Al completar, SIEMPRE comunicar:**

```markdown
## Resultado: {Título de la tarea}

### Resumen
{1-2 oraciones de qué se logró}

### Decisiones tomadas
| Decisión | Alternativas consideradas | Elegida | Razón |
|----------|--------------------------|---------|-------|
| {D1} | A, B, C | B | {razón} |

### Cambios realizados
- `{archivo1}`: {descripción del cambio}
- `{archivo2}`: {descripción del cambio}

### Trade-offs aceptados
- {Trade-off 1}: {justificación}

### Verificaciones realizadas
- [x] {Verificación 1}
- [x] {Verificación 2}

### Próximos pasos sugeridos
1. {Paso siguiente 1}
2. {Paso siguiente 2}

### Notas para otros agentes
- Para @{agente}: {información relevante}
```
---

## RADAR Trace — Formato de Output Mínimo

> Los agentes SHOULD incluir este bloque al final de outputs significativos para demostrar adherencia al protocolo.
> Para acciones triviales (leer un archivo, responder una pregunta puntual), es opcional.

```markdown
## RADAR Trace

| Fase | Acción | Resultado |
|------|--------|-----------|
| **R** (Read) | {Archivos/contexto consultado} | {Hallazgos clave} |
| **A** (Analyze) | {Alternativas evaluadas} | {Trade-offs identificados} |
| **D** (Decide) | {Opción elegida} | {Razón principal} |
```

> Las fases **Act** y **Report** quedan implícitas en el output del agente.
> El trace es verificable: si no puedes completarlo, significa que no se siguió RADAR.
