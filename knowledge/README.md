# Knowledge Base — King Framework

Repositorio de conocimiento del framework. Contiene dos tipos de archivos:

## Tipos de Knowledge

### Tipo A — Generados por `/genesis` (proyecto-específicos)

Estos archivos son **placeholders** en el plugin. `/genesis` los genera con contenido real para cada proyecto del usuario, creándolos en `.king/knowledge/` del proyecto.

| Archivo | Generado en |
|---------|-------------|
| `architecture.md` | `.king/knowledge/architecture.md` |
| `conventions.md` | `.king/knowledge/conventions.md` |
| `environments.md` | `.king/knowledge/environments.md` |
| `stack.md` | `.king/knowledge/stack.md` |

### Tipo B — Documentación del framework (plugin-permanentes)

Estos archivos documentan cómo funciona King Framework. Son leídos por agentes y skills durante la ejecución.

| Archivo | Leído por |
|---------|-----------|
| `gitflow.md` | `@devops`, `skills/gitflow/` |
| `pipeline.md` | Todos los agentes (referencia del flujo) |
| `session-tracking.md` | `skills/session-management/SKILL.md` |

## Subdirectorios

| Directorio | Propósito | Cargado por |
|-----------|-----------|-------------|
| `_inject/` | Archivos slim para inyección en agentes | `/genesis` — inyecta según stack detectado |
| `context7/` | Documentación de integración con Context7 MCP | `@architect`, `@api` |
| `domain/` | Knowledge de dominio específico del proyecto | `/genesis` — si existe |
| `stacks/` | Patrones por stack tecnológico (Node, Python, Go, Rust, Java, React) | `/genesis` — según stack detectado |
| `universal/` | Conocimiento universal aplicable a todos los proyectos | `/genesis` — siempre inyectado |

## Flujo de Inyección

```
/genesis detecta stack
  │
  ├─► _inject/*-essentials.md     → Inyectado en CLAUDE.md (slim)
  ├─► stacks/{stack}/patterns.md  → Referenciado en agentes especializados
  └─► universal/*                 → Siempre disponible para todos los agentes
```
