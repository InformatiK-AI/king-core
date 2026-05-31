---
name: create-skill
description: "Meta-skill para crear nuevos skills en el framework. Usar cuando se necesite: crear un skill nuevo, agregar un workflow, definir un nuevo flujo de trabajo automatizado, o extender el framework con nueva funcionalidad."
version: 2.0
api_version: 1.0.0
model: sonnet
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

## Scaffolding Automatizado

Cuando el usuario ejecuta `/create-skill mi-nuevo-skill`, generar automáticamente la estructura
completa. **Antes de crear cualquier archivo, detectar colisión de nombre.**

### Paso 0 — Detección de colisión (ANTES de crear archivos)

1. [ ] Verificar si ya existe `skills/mi-nuevo-skill/`.
2. [ ] **Si existe** → NO crear nada. Presentar el skill existente al usuario (mostrar su
   `description` y propósito) y preguntar:
   - ¿Es una **extensión** del skill existente? → aplicar cambios aditivos al SKILL.md actual.
   - ¿Es un **skill nuevo distinto**? → solicitar otro nombre y volver al Paso 0.
3. [ ] No crear ningún directorio ni archivo hasta recibir respuesta del usuario.

> Regla dura: la verificación de colisión ocurre ANTES de escribir el primer byte. Nunca se
> sobrescribe un skill existente de forma silenciosa.

### Paso 1 — Generación de estructura (solo si NO hay colisión)

1. [ ] Crear directorio `skills/mi-nuevo-skill/`.
2. [ ] Generar `skills/mi-nuevo-skill/SKILL.md` desde el template canónico v2.0
   (`skills/_templates/skill-template-v2.md`) con los placeholders reemplazados:

| Placeholder | Valor |
|-------------|-------|
| `{{SKILL_NAME}}` | `mi-nuevo-skill` |
| `{{SKILL_DESCRIPTION}}` | solicitado al usuario en el paso de definición |
| `{{DATE}}` | fecha actual |
| `{{VERSION}}` | `1.0.0` |
| `{{API_VERSION}}` | `1.0.0` |

3. [ ] Crear `skills/mi-nuevo-skill/references/.gitkeep` (directorio de referencias, inicialmente vacío).
4. [ ] Crear `skills/mi-nuevo-skill/scripts/.gitkeep` (directorio de scripts, inicialmente vacío).
5. [ ] Actualizar `LOAD-INDEX.md` añadiendo la entrada del nuevo skill en "Carga por skill".

### Paso 2 — Verificación

- [ ] El directorio `skills/mi-nuevo-skill/` existe con `SKILL.md`, `references/.gitkeep` y `scripts/.gitkeep`.
- [ ] `SKILL.md` no contiene placeholders `{{...}}` sin reemplazar.
- [ ] `LOAD-INDEX.md` incluye la nueva entrada.

---

## Checklist de Publicación (Tier 3 Hub)

Antes de publicar un skill en el King Hub, verificar. El proceso completo de firma y proceso por
tier está en `knowledge/universal/trust-model.md`; el style guide y la testing guide en
`knowledge/universal/contributor-guide.md`.

### Calidad mínima
- [ ] Todos los BLOCKING CONDITIONS son verificables (no "cuando sea necesario").
- [ ] REQUIRED OUTPUTS con paths exactos.
- [ ] Al menos 3 scenarios Gherkin en el skill o en un archivo `TESTS.md` adjunto.
- [ ] `api_version` presente en frontmatter (semver válido). Ver `knowledge/universal/skill-versioning.md`.
- [ ] Ninguna instrucción que sobrescriba gates CASTLE de Tier 1 (invariante de no-gate-override de `trust-model.md`).

### Identidad del publicador
- [ ] Clave GPG generada y registrada en keyserver público.
- [ ] Email de la clave GPG coincide con la GitHub account verificada.
- [ ] Package firmado: `gpg --armor --detach-sign mi-skill-v{version}.tar.gz`.

### Proceso de publicación
- [ ] Fork del repo `king-framework/king-hub`.
- [ ] PR contra `community/` con: package `.tar.gz` + `.asc` + `manifest.json`.
- [ ] `manifest.json` incluye: `name`, `version`, `api_version`, `author`, `description`, `trust_tier`, `tags`, `castle_layers`.
- [ ] CI del fork pasa sin errores (Semgrep + Trivy + GPG verify).

Ejemplo de `manifest.json` mínimo:

```json
{
  "name": "analytics-tracker",
  "version": "1.0.0",
  "api_version": "1.0.0",
  "author": "github-handle",
  "description": "Instrumenta eventos de analítica en el proyecto",
  "trust_tier": 3,
  "tags": ["analytics", "observability"],
  "castle_layers": "_·_·_·_·L·_"
}
```

---

## Ver también

- **Template v2.0**: `skills/_templates/skill-template-v2.md` — Plantilla base con toda la estructura v2.0 para crear nuevos skills (QUICK REFERENCE, BLOCKING CONDITIONS, REQUIRED OUTPUTS, PHASES, FINAL CHECKPOINT)
- **Contributor Guide**: `knowledge/universal/contributor-guide.md` — Style guide (naming, idioma, fases, auto-triggering, CASTLE, reporte), testing guide y publishing guide
- **Trust Model**: `knowledge/universal/trust-model.md` — Modelo de confianza de 4 tiers, firmas GPG, CRL y proceso de publicación por tier
- **Anatomía v2.0**: `skills/_shared/skill-anatomy.md` — Estructura canónica y contratos semánticos de un skill no-SDD

## Session Tracking

> Skill standalone. Ver convención en `skills/_shared/standalone-convention.md`.
