# Genesis - Generation + Setup + Onboarding

> Fases 3-5 del skill `/genesis`. Router principal: [SKILL.md](SKILL.md)

---

## PHASE 3: Generation

### GATE IN
> Condiciones para entrar

- [ ] PHASE 2 completada
- [ ] Equipo de agentes confirmado
- [ ] Templates existen en `agents/templates/`
- [ ] Si `.king/.genesis-merge-mode` existe → activar merge mode (restauracion post-compactacion)

### MUST DO
> ⚠️ All actions are MANDATORY

> Generar CON VALIDACION - presentar y esperar OK antes de crear

0. [ ] **Modo de confirmacion de artefactos**

   ```
   Para generar la infraestructura del proyecto:
   a) Confirmar cada artefacto individualmente (recomendado primer uso)
   b) Generar todo de una vez y mostrar resumen al final

   Modo de confirmacion? [a/b]
   ```
   - Si elige (b) → activar BATCH_MODE: generar Steps 2-12 sin confirmaciones individuales, mostrar resumen consolidado de todos los archivos creados al finalizar Step 12
   - Si elige (a) o no responde → modo individual (comportamiento actual preservado)

1. [ ] **Cargar Knowledge Base**

   Leer archivos segun matriz de inyeccion:

   | Agente | Universal | Stack | Domain |
   |--------|-----------|-------|--------|
   | @developer | testing, git, security basics, context7 | stack/patterns | - |
   | @architect | api-design, performance, observability, context7 | stack/patterns | - |
   | @qa | testing, security checks | stack/security | - |
   | @frontend | accessibility (FULL) | react/patterns (si aplica) | - |
   | @security | security (FULL) | stack/security | domain/compliance |
   | @devops | observability | - | domain/infrastructure |
   | @mobile | testing | - | - |
   | @api | api-design (FULL) | stack/patterns | - |
   | @performance | performance (FULL), observability | stack/patterns | - |

   > **Nota de presupuesto de tokens**: Cargar knowledge para 6+ agentes puede consumir
   > 1.500-3.000 tokens adicionales. Preferir archivos `_inject/` (slim) sobre archivos full.
   > Si el contexto esta limitado, omitir archivos full y usar solo los slim.

2. [ ] **Generar CLAUDE.md**
   - Presentar contenido propuesto
   - Esperar confirmacion
   - Crear archivo en raiz

3. [ ] **Generar `.gitignore` (protección de scaffold)**

   > Verificar existencia ANTES de escribir. Si ya existe, preservar intacto y advertir.

   a. Verificar si `.gitignore` existe en la raíz del proyecto:
      ```bash
      ls .gitignore 2>/dev/null && echo "EXISTS" || echo "MISSING"
      ```

   b. Si EXISTE → mostrar advertencia visible y continuar sin tocar el archivo:
      ```
      ⚠️  .gitignore ya existe — preservado sin modificaciones.
          Si querés actualizarlo, editalo manualmente.
      ```

   c. Si NO EXISTE → seleccionar template según stack detectado en Phase 1 (Q4):

      | Stack detectado | Template a copiar |
      |-----------------|-------------------|
      | Node.js / TypeScript / JavaScript | `templates/gitignore/node.gitignore` |
      | Python | `templates/gitignore/python.gitignore` |
      | Go | `templates/gitignore/go.gitignore` |
      | Rust / Java / PHP / Ruby / otro | `templates/gitignore/generic.gitignore` |

      > Si el stack no está en la tabla → usar `generic.gitignore` como fallback.

   d. Leer el template seleccionado. Si el template no existe o no puede leerse:
      ```
      ⚠️  Template de .gitignore no encontrado para stack {stack} — omitiendo generación.
          Podés crear el archivo .gitignore manualmente.
      ```
      Continuar con el paso siguiente sin interrumpir genesis (graceful degradation).

   e. Si el template fue leído exitosamente → copiar su contenido a `.gitignore` en la raíz del proyecto.

   f. Confirmar al usuario:
      ```
      ✓ .gitignore generado para stack {stack} — plantilla {template}.
      ```

   > **Idempotencia**: La garantía es la verificación de existencia en paso (a).
   > No se mergea contenido — si el archivo existe, se preserva intacto.

3.5. [ ] **Generar `.env.example`**

   > Prerequisito: Step 3 completado (`.gitignore` ya cubre `.env`).
   > Verificar existencia ANTES de escribir.

   a. Verificar si `.env.example` ya existe en la raíz del proyecto:
      ```bash
      ls .env.example 2>/dev/null && echo "EXISTS" || echo "MISSING"
      ```

   b. Si EXISTE → preservar sin modificaciones y advertir:
      ```
      ⚠️  .env.example ya existe — preservado sin modificaciones.
          Si querés actualizarlo, editalo manualmente.
      ```

   c. Si NO EXISTE:
      1. Leer `templates/env-example/base.env.example` del framework como base
      2. Revisar las integraciones detectadas en Q5 (PHASE 1 Discovery) y descomentar
         las secciones correspondientes:

         | Integración detectada en Q5 | Sección a descomentar |
         |-----------------------------|-----------------------|
         | Base de datos (postgres, mysql, mongodb) | Database |
         | Auth provider (auth0, jwt, oauth) | Autenticación |
         | Pagos (stripe, paypal) | Pagos |
         | Cloud/storage (aws, gcp, azure, s3) | Cloud / Storage |
         | Email (sendgrid, resend, smtp) | Email |
         | AI/ML (anthropic, openai) | Inteligencia Artificial |

      3. Escribir `.env.example` en la raíz del proyecto con las secciones activadas
      4. Verificar que `.env` está en `.gitignore`:
         ```bash
         grep -E "^\.env($|\.|\*| )" .gitignore 2>/dev/null || echo "MISSING"
         ```
         Si no está → agregar `.env` y `.env.*.local` al `.gitignore` existente

   d. Confirmar al usuario:
      ```
      ✓ .env.example generado con {N} secciones activas.
        Copiar a .env y completar con valores reales: cp .env.example .env
      ```

   > **Idempotencia**: Si `.env.example` existe, se preserva intacto. Mismo patrón que `.gitignore`.
   > **Knowledge**: Referenciar `knowledge/_inject/secrets-management.md` en @developer para
   > buenas prácticas de gestión de secretos (vault, rotación, 12-factor app).

4. [ ] **Generar `.king/knowledge/stack.md`**

   Usando Q4 (stack confirmado del discovery) + auto-deteccion de manifest files:
   - Si existe `package.json`: extraer dependencias principales con versiones
   - Si existe `requirements.txt` / `pyproject.toml`: extraer dependencias Python
   - Si existe `Cargo.toml`: extraer dependencias Rust
   - Si existe `go.mod`: extraer dependencias Go

   Generar contenido poblado con secciones: Frontend, Backend, Base de datos, Testing, DevOps, Dependencias clave (tabla con versiones reales detectadas).

   Frontmatter YAML:
   ```yaml
   ---
   project: "{nombre del proyecto de Q1 o package.json}"
   generated-by: /genesis
   genesis-version: 2.0
   date: {YYYY-MM-DD}
   author: Host
   ---
   ```

   a. Presentar contenido propuesto al usuario
   b. Esperar confirmacion
   c. Crear archivo en `.king/knowledge/stack.md`

   **Si merge mode activo (usuario eligio opcion b en PHASE 1):** verificar si `.king/knowledge/stack.md` ya existe antes de crear.

5. [ ] **Generar `.king/knowledge/architecture.md`**

   Usando Q1 (idea/problema), Q2 (tipo de producto), Q3 (prioridades), Q5 (contexto/dominio):
   - Inferir capas segun tipo de producto (ej: SPA -> Browser/Frontend/API/DB; API Backend -> Client/API/Service/DB)
   - Generar flujo de datos generico basado en el tipo
   - Crear ADR-001 desde las prioridades de Q3

   Incluir seccion explicita:
   ```
   ## Pendiente de Refinamiento
   > Este documento contiene la arquitectura base inferida de /genesis.
   > Ejecutar /brainstorm para completar:
   > - Modelo de dominio detallado
   > - Componentes especificos del sistema
   > - Decisiones arquitectonicas adicionales (ADRs)
   ```

   Frontmatter YAML identico al de stack.md.

   a. Presentar contenido propuesto al usuario
   b. Esperar confirmacion
   c. Crear archivo en `.king/knowledge/architecture.md`

   **Si merge mode activo (usuario eligio opcion b en PHASE 1):** verificar si `.king/knowledge/architecture.md` ya existe antes de crear.

6. [ ] **Generar `.king/knowledge/conventions.md`**

   Usando Q4 (stack) + auto-deteccion de archivos de configuracion:
   - `.eslintrc*` -> registrar linting rules detectadas
   - `.prettierrc*` -> registrar formatting rules
   - `tsconfig.json` -> registrar TypeScript strict settings
   - Si ninguno detectado: proponer convenciones estandar para el stack

   Generar secciones: Naming Conventions (por tipo de archivo segun stack), Estructura de Archivos, Patrones de Codigo, Linting y Formato.

   Frontmatter YAML identico.

   a. Presentar, confirmar, crear en `.king/knowledge/conventions.md`

   **Si merge mode activo (usuario eligio opcion b en PHASE 1):** verificar si `.king/knowledge/conventions.md` ya existe antes de crear.

7. [ ] **Generar `.king/knowledge/environments.md`**

   Usando Q5 (infraestructura seleccionada) + Q4 (stack para puertos default):
   - Tabla dev/qa/prod con: URL base, DB, variables de entorno requeridas
   - Health check commands segun el stack detectado
   - Variables de entorno requeridas segun integraciones detectadas en Q5 (auth provider -> AUTH_*, payment -> STRIPE_*, etc.)

   Frontmatter YAML identico.

   > **El archivo generado DEBE incluir la siguiente advertencia al inicio del contenido** (después del frontmatter):
   > ```
   > > ⚠️ **Base Template** — valores placeholder inferidos por /genesis.
   > > URLs, puertos y variables de entorno reales: completar en /brainstorm.
   > ```

   a. Presentar, confirmar, crear en `.king/knowledge/environments.md`

   **Si merge mode activo (usuario eligio opcion b en PHASE 1):** verificar si `.king/knowledge/environments.md` ya existe antes de crear.

8. [ ] **Generar Agents Core**
   Para cada uno (developer, architect, qa, frontend):

   **Proceso de generacion:**
   a. Leer template base: `agents/templates/agent-radar-template.md`
   b. Personalizar secciones del template:
      - Reemplazar `{AGENT_NAME}` con nombre del agente
      - Reemplazar `{RESPONSIBILITIES}` con responsabilidades especificas
      - Reemplazar `{KNOWLEDGE}` con conocimiento inyectado (paso c)
   c. Inyectar knowledge (append al final del agente, en seccion "## Conocimiento Experto"):
      - Leer archivos de knowledge segun matriz (paso 1)
      - Usar version slim de `knowledge/_inject/` si existe
      - Si no existe slim, extraer secciones clave del archivo full
      - Formato: copiar contenido como subsecciones dentro del agente
   d. Presentar contenido propuesto al usuario
   e. Esperar confirmacion
   f. Crear archivo en `.claude/agents/{nombre}.md`

   **Ejemplo before/after:**
   ```
   BEFORE (template):
   ## Conocimiento Experto
   {KNOWLEDGE}

   AFTER (developer.md):
   ## Conocimiento Experto

   ### Testing Essentials
   (contenido de knowledge/_inject/testing-essentials.md)

   ### Git Mastery
   (contenido de knowledge/universal/git-mastery.md - secciones clave)

   ### Security Basics
   (contenido de knowledge/_inject/security-essentials.md - resumen)
   ```

9. [ ] **Generar Agents Especializados**
   Para cada agente detectado:
   - Mismo proceso que paso 7 (template + knowledge injection)
   - Knowledge especifico segun matriz del paso 1 (domain/ y stack/)
   - Presentar contenido propuesto
   - Esperar confirmacion
   - Crear archivo en `.claude/agents/{nombre}.md`

10. [ ] **Detectar y registrar Skills de Stack**

   Si existe `package.json`, detectar:
   - `react` -> Registrar `/react-best-practices`
   - Ecosystem (state, routing, forms, styling, ui)

   Detectar señales de blog/CMS en Q5 o en `package.json`:
   - `next`, `astro`, o `nuxt` en dependencies Y Q5 menciona "blog", "contenido", "artículos", "posts", "content" → agregar a CLAUDE.md:
     ```
     | Configurar blog headless con SEO | skills/blog-setup/SKILL.md |
     ```
   - Q5 menciona "CMS", "Contentful", "Sanity", "Strapi", "headless", "gestión de contenidos" → agregar a CLAUDE.md:
     ```
     | Integrar CMS headless (Contentful, Sanity, Strapi) | skills/headless-cms-setup/SKILL.md |
     ```
   - Si se detectan ambas señales → agregar ambas filas a CLAUDE.md (blog-setup primero, headless-cms-setup segundo)
   - Nota: genesis NO invoca estos skills directamente — solo registra las referencias para que el usuario los invoque cuando los necesite

   Crear configuracion en CLAUDE.md

11. [ ] **Resolver Library IDs con Context7**

   > **Pre-check de disponibilidad**: Intentar `resolve-library-id("test", "")` como llamada de prueba.
   > - Si tiene exito → continuar con la resolucion (comportamiento siguiente)
   > - Si falla o no hay respuesta → mostrar "Context7 no disponible — saltando resolucion de library IDs" y pasar al Step 11

   Si el proyecto tiene dependencias detectables (package.json, requirements.txt, etc.):

   a. Extraer librerias principales (max 10 mas relevantes)
   b. Para cada una: `resolve-library-id(nombre, "documentation for {nombre}")`
   c. Crear `.claude/knowledge/context7/library-registry.md` con tabla:
      ```markdown
      # Context7 Library Registry
      > Generado por /genesis. IDs pre-resueltos para consultas rapidas.

      | Library | Context7 ID | Resolved On |
      |---------|-------------|-------------|
      | react   | /facebook/react | YYYY-MM-DD |
      ```
   d. Presentar registry al usuario para confirmacion

   **Si Context7 no disponible (MCP no configurado):**
   ```
   Context7 MCP no detectado. Saltando resolucion de library IDs.
   Los agentes usaran knowledge estatico solamente.
   ```

12. [ ] **Inicializar pipeline SDD**

   - Verificar si `.king/sdd/config.yaml` existe
   - Si ya existe → mostrar "SDD ya inicializado — saltando" y continuar
   - Si NO existe → crear los siguientes artefactos:
     - `.king/sdd/config.yaml` con el template base, poblado con el stack detectado en Phase 1:
       ```yaml
       schema: spec-driven
       context: |
         Tech stack: {stack detectado en Phase 1}
         Architecture: {tipo de producto de Q2}
         Testing: {framework detectado, o "Manual"}
         Style: {linting detectado, o "Sin configuracion detectada"}
       rules:
         proposal:
           - Include rollback plan for risky changes
           - Identify affected modules
         specs:
           - Use Given/When/Then format for scenarios
           - Use RFC 2119 keywords
         design:
           - Document architecture decisions with rationale
         tasks:
           - Group by phase, use hierarchical numbering
         apply:
           - Follow existing code patterns
           tdd: false
           test_command: ""
         verify:
           test_command: ""
           build_command: ""
           coverage_threshold: 0
         archive:
           - Warn before merging destructive deltas
       ```
     - `.king/sdd/specs/` (directorio vacio)
     - `.king/sdd/archive/` (directorio vacio)

### CHECKPOINT
> Verificar antes de continuar

- [ ] CLAUDE.md creado y confirmado
- [ ] `.gitignore` creado (si no existía previamente) o preservado con warning (si ya existía)
- [ ] `.env.example` creado con secciones activas según integraciones Q5 (o preservado si ya existía)
- [ ] `.king/knowledge/stack.md` creado y confirmado
- [ ] `.king/knowledge/architecture.md` creado y confirmado
- [ ] `.king/knowledge/conventions.md` creado y confirmado
- [ ] `.king/knowledge/environments.md` creado y confirmado
- [ ] Todos los agents core creados
- [ ] Todos los agents especializados creados
- [ ] Skills de stack detectados y documentados
- [ ] `library-registry.md` creado (si Context7 disponible y dependencias detectadas)
- [ ] SDD pipeline inicializado (`.king/sdd/config.yaml` creado o ya existia)
- [ ] Si BATCH_MODE activo: resumen consolidado de todos los archivos creados mostrado al usuario

### OUTPUTS
- `CLAUDE.md`
- `.gitignore` (si no existía — generado desde template según stack detectado)
- `.env.example` (si no existía — generado desde `templates/env-example/base.env.example` con secciones Q5)
- `.king/knowledge/stack.md`
- `.king/knowledge/architecture.md`
- `.king/knowledge/conventions.md`
- `.king/knowledge/environments.md`
- `.claude/agents/developer.md`
- `.claude/agents/architect.md`
- `.claude/agents/qa.md`
- `.claude/agents/frontend.md`
- `.claude/agents/{especializados}.md` (segun deteccion)
- `.claude/knowledge/context7/library-registry.md` (si Context7 disponible)
- `.king/sdd/config.yaml` (si no existia)

### IF FAILS
> Si falla la generacion

```
Error en generacion de artefactos.
Archivos creados hasta el momento: {lista}
Archivos pendientes: {lista}

Para recuperar:
1. Revisar archivos creados
2. Ejecutar /genesis nuevamente
   Cuando pregunte por configuracion existente, elegir:
   b) Merge inteligente (preservar lo existente, solo agregar nuevo)
```

---

## PHASE 4: Setup

### GATE IN
> Condiciones para entrar

- [ ] PHASE 3 completada
- [ ] Artefactos principales creados

### MUST DO
> ⚠️ All actions are MANDATORY

> Configuraciones opcionales con confirmacion

1. [ ] **Preguntar sobre Git Worktrees**
   ```
   Deseas habilitar Git Worktrees para desarrollo aislado?

   Los worktrees permiten:
   - Ambientes permanentes (dev, qa, prod)
   - Un worktree por feature, sin stash/switch
   - Flujo GitFlow integrado

   a) Si, configurar worktrees
   b) No, prefiero flujo tradicional
   ```

2. [ ] **Si elige worktrees:**
   - Verificar repositorio Git existe
   - Si no existe, preguntar si inicializar
   - Ejecutar configuracion de worktrees:
     - Crear `.worktrees/environments/` (dev, qa, prod)
     - Crear `.worktrees/features/`
     - Inicializar branch `develop` si no existe
     - Actualizar `.gitignore`
   - Documentar en CLAUDE.md

3. [ ] **Configurar Hooks minimos adaptados al stack**

   Leer `.king/knowledge/stack.md` para identificar el stack detectado en Phase 1.
   Seleccionar la fila correspondiente de la tabla:

   | Stack detectado | Pre-commit command | Commit-msg |
   |-----------------|-------------------|------------|
   | Node.js / TypeScript | `npx eslint . && npx prettier --check .` | Conventional Commits (commitlint) |
   | Python | `black --check . && flake8 .` | Conventional Commits |
   | Go | `gofmt -l . && go vet ./...` | Conventional Commits |
   | Rust | `cargo fmt --check && cargo clippy -- -D warnings` | Conventional Commits |
   | Java / Maven | `mvn checkstyle:check` | Conventional Commits |
   | Java / Gradle | `./gradlew checkstyleMain` | Conventional Commits |
   | Otro / No detectado | `# TODO: reemplazar con comando de linting del stack` | Conventional Commits |

   > **Para Python**: asegurate de tener instalados `black` y `flake8` antes de activar el hook (`pip install black flake8`).

   - Presentar configuracion propuesta al usuario
   - Esperar aprobacion antes de crear los hooks

### CHECKPOINT
> Verificar antes de continuar

- [ ] Decision de worktrees tomada y aplicada
- [ ] Hooks configurados (si aprobados)

### OUTPUTS
- `.worktrees/` (si habilitado)
- Hooks en `.git/hooks/` o `.husky/` (si aprobado)
- CLAUDE.md actualizado con seccion de worktrees

### IF FAILS
> Si falla setup de worktrees

```
Error configurando worktrees: {error}
El proyecto puede continuar sin worktrees.
Puedes habilitarlos despues con: /worktree init
```

---

## PHASE 5: Onboarding

### GATE IN
> Condiciones para entrar

- [ ] PHASE 4 completada
- [ ] Infraestructura basica creada

### MUST DO
> ⚠️ All actions are MANDATORY

> Comunicar resultado y proximos pasos

0. [ ] **Inicializar registry si no existe**
   - Verificar si `.king/registry.md` existe
   - Si ya existe → no modificar, continuar
   - Si NO existe → crear `.king/registry.md` con template base:
     ```markdown
     # Registry — {nombre del proyecto}
     > Generado por /genesis. Actualizado por SessionStart hook.

     ## Workflows Activos

     _(sin workflows activos)_

     ## Historial Reciente

     | Sesion | Skill | Estado |
     |--------|-------|--------|
     | — | /genesis | completed |
     ```

1. [ ] **Mostrar resumen de genesis**
   ```
   Genesis completado. Tu proyecto esta configurado.

   Infraestructura creada:
      - CLAUDE.md (documentacion principal)
      - Knowledge Base: stack.md, architecture.md, conventions.md, environments.md
      - Agents Core: @developer, @architect, @qa, @frontend
      - Agents Especializados: {lista de detectados}
      - Skills de proyecto: {lista}
      - Worktrees: {habilitados|no configurados}
      - Context7: {X librerias registradas|no configurado}

   Tu equipo de agentes:
      - @developer: Implementacion de codigo
      - @architect: Decisiones de diseno
      - @qa: Testing y Security Gate
      - @frontend: WCAG, ARIA, usabilidad
      {Para cada agente especializado creado}
      - @{nombre}: {rol breve}

   Flujo de desarrollo:
      [OK] Genesis <- estas aqui
      [ ] Brainstorming
      [ ] Crear Issues
      [ ] Build Feature
      [ ] QA + Merge

   Proximo paso: /brainstorm para disenar tu primera feature
   ```

2. [ ] **Si worktrees habilitados, agregar:**
   ```
   Worktrees configurados:
      - dev   -> develop
      - qa    -> develop
      - prod  -> main (readonly)

      Usa /worktree create {feature} para desarrollo aislado
   ```

3. [ ] **Crear sesion de registro**
   Archivo: `.king/sessions/YYYY-MM-DD-genesis.md`
   - Al crear la sesion exitosamente: si `.king/.genesis-merge-mode` existe → eliminarlo

### CHECKPOINT
> Verificar antes de finalizar

- [ ] Usuario recibio resumen completo
- [ ] Sesion registrada
- [ ] Proximo paso comunicado

### OUTPUTS
- `.king/sessions/YYYY-MM-DD-genesis.md`

### IF FAILS
> No deberia fallar, pero si ocurre:

```
Genesis completado pero no se pudo crear sesion de registro.
La infraestructura esta lista. Proximo paso: /brainstorm
```

---

## RECOVERY PROCEDURE

> Si /genesis falla a mitad de ejecucion, seguir estos pasos para recuperar.

### Detectar Estado de Fallo

```bash
# Verificar que archivos fueron creados
ls -la CLAUDE.md 2>/dev/null && echo "CLAUDE.md: EXISTS" || echo "CLAUDE.md: MISSING"
ls -la .claude/agents/*.md 2>/dev/null | wc -l | xargs -I {} echo "Agents creados: {}"
ls -la .king/sessions/*-genesis.md 2>/dev/null && echo "Sesion: EXISTS" || echo "Sesion: MISSING"
```

### Escenarios de Fallo y Recuperacion

| Fase donde fallo | Estado parcial | Accion de recuperacion |
|------------------|----------------|------------------------|
| PHASE 1 (Discovery) | Nada creado | Simplemente re-ejecutar `/genesis` |
| PHASE 2 (Agent Selection) | Nada creado | Re-ejecutar `/genesis` |
| PHASE 3 (Generation) | Algunos archivos creados | Ver "Recuperar PHASE 3" abajo |
| PHASE 4 (Setup) | Agents creados, config parcial | Ver "Recuperar PHASE 4" abajo |
| PHASE 5 (Onboarding) | Todo creado | Solo comunicar proximo paso |

### Recuperar PHASE 3 (Generation)

Si genesis fallo durante la generacion de archivos:

1. **Identificar archivos faltantes:**
   ```bash
   # Archivos core esperados
   EXPECTED="developer architect qa frontend"
   for AGENT in $EXPECTED; do
     if [[ ! -f ".claude/agents/${AGENT}.md" ]]; then
       echo "FALTANTE: ${AGENT}.md"
     fi
   done

   # Knowledge files
   for KFILE in stack architecture conventions environments; do
     if [[ ! -f ".king/knowledge/${KFILE}.md" ]]; then
       echo "FALTANTE: .king/knowledge/${KFILE}.md"
     fi
   done
   ```

2. **Opciones de recuperacion:**

   **Opcion A: Re-ejecutar genesis con merge (recomendado)**
   ```
   /genesis
   # Cuando pregunte por configuracion existente, elegir:
   #   b) Merge inteligente (preservar lo existente, solo agregar nuevo)
   ```

   **Opcion B: Generar agentes faltantes manualmente**
   ```bash
   # 1. Copiar template
   cp agents/templates/agent-radar-template.md .claude/agents/{nombre}.md

   # 2. Editar y personalizar segun rol
   # 3. Inyectar knowledge relevante
   ```

   **Opcion C: Limpiar y re-ejecutar**
   ```bash
   # ADVERTENCIA: Esto elimina TODO lo generado
   rm -rf .claude/agents/*.md  # Preserva templates/
   rm -f CLAUDE.md
   rm -f .king/sessions/*-genesis.md

   # Luego re-ejecutar
   /genesis
   ```

### Recuperar PHASE 4 (Setup)

Si genesis fallo durante configuracion de worktrees o hooks:

1. **Verificar estado de worktrees:**
   ```bash
   git worktree list
   ls -la .worktrees/ 2>/dev/null
   ```

2. **Si worktrees estan corruptos:**
   ```bash
   # Limpiar worktrees huerfanos
   git worktree prune

   # Re-inicializar via skill
   /worktree init
   ```

3. **Si hooks no se configuraron:**
   ```bash
   # Los hooks son opcionales, se pueden agregar despues
   ```

### Preservar Progreso del Discovery

Si necesitas re-ejecutar genesis pero quieres preservar las respuestas del discovery:

1. **Antes de re-ejecutar**, guarda las respuestas en un archivo temporal:
   ```
   # Respuestas del discovery previo:
   1. Idea: {tu respuesta}
   2. Tipo: {tu respuesta}
   3. Prioridades: {tu respuesta}
   4. Stack: {tu respuesta}
   5. Contexto: {tu respuesta}
   ```

2. **Al re-ejecutar `/genesis`**, proporciona las mismas respuestas.

### Validar Recuperacion Exitosa

Despues de recuperar, verificar integridad:

```bash
# Checklist de validacion
echo "=== Validacion de Genesis ==="

# 1. CLAUDE.md
[[ -f "CLAUDE.md" ]] && echo "OK CLAUDE.md" || echo "FAIL CLAUDE.md"

# 2. Agents core
for AGENT in developer architect qa frontend; do
  [[ -f ".claude/agents/${AGENT}.md" ]] && echo "OK ${AGENT}.md" || echo "FAIL ${AGENT}.md"
done

# 3. Sesion registrada
[[ -n "$(ls .king/sessions/*-genesis.md 2>/dev/null)" ]] && echo "OK Sesion genesis" || echo "WARN Sin sesion (opcional)"

# 4. Estructura base (plugin)
[[ -d "agents/templates" ]] && echo "OK Templates" || echo "FAIL Templates"
[[ -d "rules" ]] && echo "OK Rules" || echo "FAIL Rules"

# 5. Knowledge base
for KFILE in stack architecture conventions environments; do
  [[ -f ".king/knowledge/${KFILE}.md" ]] && echo "OK knowledge/${KFILE}.md" || echo "WARN knowledge/${KFILE}.md (opcional si merge)"
done

echo "=== Fin validacion ==="
```

### Contactar Soporte

Si la recuperacion manual no funciona:

1. Documenta el error exacto que ocurrio
2. Lista los archivos que existen vs los esperados
3. Ejecuta `/audit --scope quick` para diagnostico
4. Reporta en: https://github.com/anthropics/claude-code/issues

---

## REFERENCE

> Informacion adicional. Esta seccion NO contiene acciones.

### Catalogo de Agentes

**Core (siempre se crean):**

| Agente | Rol | Template |
|--------|-----|----------|
| `@developer` | Implementacion de codigo | `.claude/agents/developer.md` |
| `@architect` | Decisiones de diseno | `.claude/agents/architect.md` |
| `@qa` | Quality Assurance | `.claude/agents/qa.md` |
| `@frontend` | UX y Accesibilidad | `.claude/agents/frontend.md` |

**Especializados (segun deteccion):**

| Agente | Cuando se activa |
|--------|------------------|
| `@security` | Pagos, datos sensibles, compliance |
| `@devops` | Containers, cloud, CI/CD |
| `@api` | APIs complejas, GraphQL, microservices |
| `@mobile` | Apps moviles |
| `@performance` | Alta escala, performance critico |

### Stacks Sugeridos por Tipo

**Web App (SPA):**
- Frontend: React/Next.js + TypeScript
- Styling: Tailwind CSS
- State: Zustand o React Query
- Testing: Vitest + Testing Library

**API/Backend:**
- Runtime: Node.js o Python
- Framework: Express/FastAPI
- DB: PostgreSQL + Redis
- Testing: Jest/Pytest + Supertest

**Mobile App:**
- Framework: React Native o Flutter
- State: Zustand/Riverpod
- Testing: Jest/Flutter test
- Activa: @mobile

**CLI Tool:**
- Runtime: Node.js o Go
- Parser: Commander.js o Cobra
- Testing: Jest/Go test

### React Ecosystem Detection

Si existe `package.json` con React:

```
zustand -> state: zustand
jotai -> state: jotai
@reduxjs/toolkit -> state: redux
react-router-dom -> routing: react-router
next -> routing: nextjs
@tanstack/react-query -> data: tanstack-query
swr -> data: swr
react-hook-form -> forms: react-hook-form
tailwindcss -> styling: tailwind
@radix-ui/* -> ui: radix
@headlessui/* -> ui: headless-ui
```

### Template de CLAUDE.md

```markdown
# {Nombre del Proyecto}

## Descripcion
{Descripcion breve del producto}

## Stack
- **Frontend**: {si aplica}
- **Backend**: {si aplica}
- **Base de datos**: {si aplica}

## Configuracion

issues:
  backend: {local|github}
  repo: {owner/repo si github}

## Equipo de Agentes

### Core
| Agente | Rol |
|--------|-----|
| @developer | Implementacion de codigo |
| @architect | Decisiones de diseno |
| @qa | Quality Assurance |
| @frontend | WCAG, ARIA, usabilidad |

### Especializados
| Agente | Rol | Activado por |
|--------|-----|--------------|
| @{nombre} | {rol} | {senal} |

## Convenciones
{Convenciones especificas del proyecto}

## Skills disponibles
{Lista de skills generados}
```

### Template de Sesion Genesis

```markdown
# Sesion: Genesis
Fecha: {ISO timestamp}
Skill: /genesis
Version: 2.0

---

## REQUIRED FIELDS

### Resumen
Configuracion inicial del proyecto {nombre}.

### Resultado
**COMPLETED**

### Archivos modificados
- [ ] `CLAUDE.md` (nuevo)
- [ ] `.claude/agents/developer.md` (nuevo)
- [ ] `.claude/agents/architect.md` (nuevo)
- [ ] `.claude/agents/qa.md` (nuevo)
- [ ] `.claude/agents/frontend.md` (nuevo)
{Para cada agente especializado}
- [ ] `.claude/agents/{nombre}.md` (nuevo)

### Proximo paso sugerido
/brainstorm

---

## OPTIONAL FIELDS

### Decisiones tomadas
- Stack: {stack elegido}
- Tipo: {tipo de producto}
- Prioridades: {orden}
- Worktrees: {habilitados|no configurados}

### Senales detectadas
{Lista de senales que activaron agentes}

### Equipo generado
**Core:** @developer, @architect, @qa, @frontend
**Especializados:** {lista con razon de activacion}

### Knowledge inyectado
{Que knowledge se inyecto en cada agent}

### Context7
{X librerias registradas | no configurado}
```

### Principios de Ejecucion

1. **Una pregunta a la vez** - No abrumar al usuario
2. **Validacion antes de crear** - Mostrar propuesta, esperar OK
3. **Deteccion inteligente** - Solo agentes necesarios
4. **Protocolo RADAR** - Todos los agentes razonan antes de actuar
5. **Knowledge embebido** - Agents con ~300+ lineas de expertise
6. **YAGNI** - Solo generar lo necesario para empezar
7. **Explicar el flujo** - Usuario entiende que sigue
