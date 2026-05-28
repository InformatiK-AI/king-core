---
name: create-skill
description: "Meta-skill para crear nuevos skills en el framework. Usar cuando se necesite: crear un skill nuevo, agregar un workflow, definir un nuevo flujo de trabajo automatizado, o extender el framework con nueva funcionalidad."
version: 2.0
api_version: 1.0.0
---

# Create Skill — Crear Nuevos Skills

Meta-skill para crear skills que sigan las convenciones del framework King.

## Estructura de un skill

Cada skill vive en su propio directorio dentro de `skills/`:

```
skills/
└── mi-nuevo-skill/
    ├── SKILL.md          # Obligatorio: definición del skill
    ├── references/       # Opcional: archivos de referencia
    │   └── guia.md
    └── scripts/          # Opcional: scripts auxiliares
        └── helper.sh
```

## Template de SKILL.md

Usar el template canónico v2.0: `skills/_templates/skill-template-v2.md`

Este template incluye: frontmatter, QUICK REFERENCE, BLOCKING CONDITIONS, REQUIRED OUTPUTS, PHASES con GATE IN/MUST DO/CHECKPOINT, y FINAL CHECKPOINT. Ver el archivo para la estructura completa.

## Checklist para crear un skill

### 1. Definición
- [ ] Nombre en kebab-case
- [ ] Description para auto-triggering clara y con múltiples frases
- [ ] Version semántica (empezar en 1.0.0)

### 2. Contenido
- [ ] Agentes involucrados identificados
- [ ] Capas CASTLE definidas
- [ ] Fases claras y secuenciales
- [ ] Cada fase tiene pasos concretos y verificables
- [ ] Formato de reporte definido

### 3. Integración
- [ ] ¿Necesita un slash command asociado? → Crear en commands/
- [ ] ¿Necesita referencias? → Crear en references/
- [ ] ¿Necesita scripts? → Crear en scripts/
- [ ] ¿Necesita nuevo agente? → Crear en agents/

### 4. Convenciones
- [ ] Todo el contenido en español
- [ ] Referencias a agentes con @nombre
- [ ] CASTLE con formato C·A·S·T·L·E
- [ ] Protocolo RADAR integrado donde aplique
- [ ] Formato de reporte al final

## Ejemplo de creación

Para crear un skill de "database-migration":

1. Crear directorio: `skills/database-migration/`
2. Crear `SKILL.md` con el template
3. Definir agentes: @devops + @developer
4. Definir CASTLE: _·A·_·_·_·E
5. Definir fases: Plan → Script → Execute → Verify → Rollback Plan
6. Crear command: `commands/db-migrate.md`
7. Probar triggering: "migrar base de datos", "ejecutar migración de DB"

## Buenas prácticas
- Skills deben ser **autocontenidos**: todo lo necesario está en el SKILL.md o sus references
- Skills deben ser **secuenciales**: las fases van en orden y cada una produce un output claro
- Skills deben tener **reporte**: siempre documentar el resultado
- Skills deben integrar **RADAR**: para decisiones no triviales dentro del skill
- Skills deben ser **verificables**: cada paso tiene un criterio de éxito

---

## Ver también

- **Template v2.0**: `skills/_templates/skill-template-v2.md` — Plantilla base con toda la estructura v2.0 para crear nuevos skills (QUICK REFERENCE, BLOCKING CONDITIONS, REQUIRED OUTPUTS, PHASES, FINAL CHECKPOINT)

## Session Tracking

> Skill standalone. Ver convención en `skills/_shared/standalone-convention.md`.
