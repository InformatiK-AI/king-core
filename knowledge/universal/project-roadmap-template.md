# Roadmap — {project_slug}

> Generado y mantenido por el Modo Jarvis de King Framework.
> Plantilla: `knowledge/universal/project-roadmap-template.md`. Instancia viva: `.king/jarvis/project-roadmap.md`.

**Fase actual**: {phase} ({roadmap_percent}%)
**Próxima acción**: {next_skill}

---

## Pipeline

{pipeline_visual}

| Fase | Estado | Skills ejecutados | Última sesión |
|------|--------|-------------------|---------------|
{phases_table}

---

## Tareas pendientes

{pending_tasks}

---

## Historial de transiciones

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
  {pipeline_visual} → barra de progreso ASCII derivada de roadmap_percent
  {phases_table}    → filas derivadas de skills_executed + transitions
  {pending_tasks}   → tareas abiertas del workflow activo
  {transitions}     → render de transitions[]

NOTA .gitignore (aplicar en el proyecto que active Jarvis Mode):
  .king/jarvis/project-roadmap.md      # generado — NO versionar
  .king/jarvis/observations.jsonl      # generado — NO versionar
  .king/jarvis/tech-debt.md            # generado — NO versionar
  .king/jarvis/perf.log                # generado — NO versionar
  # .king/jarvis/project-state.json    → SÍ se versiona (estado reproducible)
-->
