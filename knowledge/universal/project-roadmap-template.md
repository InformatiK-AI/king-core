# Roadmap — {project_slug}

> Generado y mantenido por el Modo Jarvis de King Framework.
> Plantilla: `knowledge/universal/project-roadmap-template.md`. Instancia viva: `.king/jarvis/project-roadmap.md`.

**Fase actual**: {phase} ({roadmap_percent}%)
**Próxima acción**: {next_skill}
**Última actualización**: {updated_at}

---

## Pipeline

[{bar}] {roadmap_percent}%
{pipeline_visual}

| Fase | Estado | Skills ejecutados | Última sesión |
|------|--------|-------------------|---------------|
{phases_table}

---

## Tareas Pendientes

{pending_tasks}

---

## Historial de Transiciones

| Fecha | De → A | Señal |
|-------|--------|-------|
{transitions}

---

<!--
NOTA DE SUSTITUCIÓN
Este template se rellena por reemplazo simple de {placeholders} (sed/envsubst).
Cada {placeholder} mapea a un campo de .king/jarvis/project-state.json:
  {project_slug}    → project_slug
  {phase}           → phase            (ideacion|spec|mvp|produccion|escala)
  {roadmap_percent} → roadmap_percent
  {next_skill}      → next_skill
  {updated_at}      → updated_at       (ISO 8601 de la última actualización)
  {bar}             → barra de progreso ASCII derivada de roadmap_percent
                      (ej: ████████░░░░░░░░░░░░ para 40%; 20 celdas, 1 celda = 5%)
  {pipeline_visual} → render textual del pipeline de fases (ideacion → … → escala)
  {phases_table}    → filas derivadas de skills_executed + transitions
  {pending_tasks}   → tareas abiertas del workflow activo
  {transitions}     → filas de transitions[] (formato: | {at} | {from} → {to} | {status} |)

NOTA .gitignore (aplicar en el proyecto que active Jarvis Mode):
  .king/jarvis/project-roadmap.md      # generado — NO versionar
  .king/jarvis/observations.jsonl      # generado — NO versionar
  .king/jarvis/tech-debt.md            # generado — NO versionar
  .king/jarvis/perf.log                # generado — NO versionar
  # .king/jarvis/project-state.json    → SÍ se versiona (estado reproducible: fingerprint + TTFC)

  Estas líneas ya vienen incluidas en los templates de gitignore de King
  (templates/gitignore/*.gitignore, bloque "Modo Jarvis"). /genesis las copia
  al .gitignore del proyecto según el stack detectado.

NOTA AUTO-UPDATE (semántica de actualización automática)
  project-roadmap.md es un artefacto EFÍMERO y DERIVADO: nunca se edita a mano.
  Se regenera por completo desde .king/jarvis/project-state.json (la fuente única
  de verdad) tras cada transición de fase del pipeline.

  Flujo:
    1. Un skill King completa y produce una transición (ver hooks/phase-transition.md).
    2. El ciclo de actualización persiste el nuevo estado en project-state.json
       mediante escritura atómica (escribir a .tmp + rename), nunca in-place.
       Ver session-management/SKILL.md (Phase N+1) y hooks/phase-transition.md
       ("Escritura atómica").
    3. Este template se rellena con los valores de project-state.json y se escribe
       sobre .king/jarvis/project-roadmap.md (también de forma atómica).
    4. @conductor LEE project-state.json para el banner de SessionStart, pero es
       read-only: no persiste el estado (ver agents/conductor.md §3.bis y sus
       Contratos Bilaterales). La persistencia la hace el ciclo de actualización.

  Por eso project-state.json SE VERSIONA (es reproducible) y project-roadmap.md NO
  (se puede regenerar en cualquier momento desde el estado).
-->
