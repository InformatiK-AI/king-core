# SDD vs No-SDD — Decision Boundary

> Guía de decisión rápida para elegir entre el flujo SDD y skills no-SDD.
> Referencia completa: `.king/sdd/` (Chronicle), `design.md` (ADRs por cambio).

## Tabla de Señales

| Señal | Umbral | Acción recomendada |
|-------|--------|--------------------|
| Archivos afectados | ≥ 3 con dependencias entre sí | Usar SDD |
| Sesiones estimadas | > 1 sesión para completar | Usar SDD |
| Riesgo de compactación | Feature en progreso por más de un día | Usar SDD |
| Trazabilidad requerida | Audit trail de decisiones para compliance o revisión | Usar SDD |
| Cambio discreto | Completable en una sesión, 1-2 archivos sin dependencias | Non-SDD suficiente |

## Ejemplos por Señal

**Archivos afectados ≥ 3**
- SDD: Añadir una nueva fase al flujo `/qa` (SKILL.md + specs + tasks + design + CLAUDE.md — 5 archivos con dependencias).
- No-SDD: Corregir un typo en `testing-essentials.md` (1 archivo, sin dependencias).

**Sesiones estimadas > 1**
- SDD: Refactorizar el sistema de `persistence-contract` que afecta todos los skills SDD — requiere múltiples sesiones coordinadas.
- No-SDD: Añadir una fila a la tabla de Knowledge en CLAUDE.md (completable en minutos, una sesión).

**Riesgo de compactación**
- SDD: Integración de Context7 en 3+ skills que tarda varios días — `state.yaml` en Chronicle garantiza recovery post-compactación.
- No-SDD: Fix urgente en un agent completable en una sola sesión — sin riesgo de pérdida de contexto.

**Trazabilidad requerida**
- SDD: Cambio en SECURITY-GATE.md que requiere audit trail para compliance — el Chronicle registra cada decisión con su rationale.
- No-SDD: Optimizar la descripción de un skill sin impacto en seguridad — no requiere trazabilidad formal.

**Cambio discreto**
- No-SDD: Crear un nuevo knowledge file `_inject/api-design-essentials.md` (1 archivo, una sesión) — SDD sería overhead.
- No-SDD: Añadir un ejemplo a un agent existente (sin dependencias cruzadas).

## Non-SDD Design Principle

Los skills no-SDD (`/build`, `/fix`, `/review`, `/qa`, `/refactor`, etc.) están diseñados
para **operaciones discretas de una sesión**. Cada skill es autocontenido: empieza, ejecuta
y concluye en una sola ejecución sin depender de estado persistido entre sesiones.

Cuando un cambio supera este perfil — múltiples sesiones, múltiples archivos con dependencias,
necesidad de Chronicle para recuperación — SDD es la herramienta correcta. No adaptes un skill
no-SDD para tareas multi-sesión: usa SDD desde el inicio.

**Regla práctica**: Si te preguntas "¿necesito rastrear dónde quedé?", la respuesta es SDD.

## Auto-Detección en el Pipeline

`/plan` (Fase 2.5) y `/build` (Phase 2, Discovery) detectan automáticamente señales de complejidad y ofrecen escalar a SDD cuando corresponde. No es necesario decidir manualmente a priori — el pipeline hace el triage y pregunta al usuario antes de proceder.
