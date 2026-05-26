# Stack Knowledge Base

Conocimiento experto por stack tecnológico. Se inyecta en agents durante `/genesis` según el stack detectado.

## Archivos disponibles

| Stack | Archivo | Contenido |
|-------|---------|-----------|
| React | `react/patterns.md` | Patrones de componentes, hooks, estado, performance |
| React | `react/rules.md` | Reglas de código React (componentes, hooks, TypeScript) |
| Node.js | `node/patterns.md` | Patrones de backend Node.js, Express, APIs |
| Node.js | `node/security.md` | Seguridad específica de Node.js |
| Python | `python/patterns.md` | Patrones de Python, FastAPI, Django |
| Go | `go/patterns.md` | Patrones de Go, idioms, concurrencia |
| Rust | `rust/patterns.md` | Patrones de Rust, ownership, async Tokio |
| Java | `java/patterns.md` | Patrones de Spring Boot, inyección, testing |

## Uso

Durante `/genesis`, al detectar el stack del proyecto:

```bash
# Detección automática
if [ -f "package.json" ]; then
  # Cargar react/ si tiene react en dependencies
  # Cargar node/ si tiene express/fastify/nest
fi
if [ -f "pyproject.toml" ] || [ -f "requirements.txt" ]; then
  # Cargar python/
fi
if [ -f "go.mod" ]; then
  # Cargar go/
fi
if [ -f "Cargo.toml" ]; then
  # Cargar rust/
fi
if [ -f "pom.xml" ] || [ -f "build.gradle" ]; then
  # Cargar java/
fi
```

## Cuándo usar cada versión

| Contexto | Versión |
|----------|---------|
| Inyección en agent | `_inject/*-essentials.md` (slim) |
| Consulta profunda | `stacks/{stack}/*.md` (completo) |
| Code review | `stacks/{stack}/patterns.md` |
