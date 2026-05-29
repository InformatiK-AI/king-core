# Contributor Guide — King Framework

Guía de referencia para quien contribuye skills al ecosistema King. Define el estándar de
estilo, el proceso de testing y la ruta de publicación al King Hub. King es canónico en
español: este documento y todo skill que se contribuya se escriben en español.

---

## Style Guide para Skills

### Naming

- **kebab-case siempre**: `database-migration`, nunca `DatabaseMigration` ni `db_migration`.
- **Verbo-sustantivo** cuando describe una acción: `create-skill`, `deploy-app`, `run-tests`.
- **Sustantivo** cuando describe un artefacto: `test-plan`, `castle-report`.
- **Máximo 3 palabras**. Si necesitas más, probablemente son 2 skills distintos.

| Caso | Correcto | Incorrecto |
|------|----------|------------|
| Acción | `migrate-database` | `DatabaseMigration` |
| Artefacto | `test-plan` | `the_test_plan_generator` |
| Separador | `api-contract-first` | `api_contract_first` |

### Idioma

- Todo el contenido en **español** (norma canónica del framework King).
- **Excepción**: código, paths, nombres de comandos y de herramientas van siempre en inglés.
- Términos técnicos en inglés cuando no hay traducción natural: "pipeline", "scaffolding", "gate".
- No se usa voseo ni regionalismos: español neutro estándar.

### Estructura de fases

- **Mínimo 3 fases, máximo 7**. Menos de 3 no justifica un skill; más de 7 indica que debes dividir.
- Cada fase declara: **nombre** + **GATE IN** (prerequisito) + **MUST DO** (pasos) + **CHECKPOINT** (criterio de éxito).
- **GATE IN** es verificable en menos de 5 segundos: "¿Existe el archivo X?", no "¿El código está listo?".
- **CHECKPOINT** es binario: pasó o no pasó. Nunca "debería funcionar".
- Cada fase incluye **IF FAILS** con la acción de recuperación explícita.

| Elemento | Pregunta que responde | Forma |
|----------|-----------------------|-------|
| GATE IN | ¿Puedo entrar a esta fase? | Checkbox verificable en < 5s |
| MUST DO | ¿Qué hago, en orden? | Lista numerada con checkboxes |
| CHECKPOINT | ¿Terminé bien? | Verificación binaria |
| IF FAILS | ¿Cómo me recupero? | Mensaje de error + acción |

> La anatomía completa de un skill v2.0 está en `skills/_shared/skill-anatomy.md`.

### Descripción para auto-triggering

- Al menos **5 frases trigger** distintas en el campo `description` del frontmatter.
- Incluir sinónimos y variaciones naturales del idioma.
- La descripción es lo único que el orquestador lee para decidir si carga el skill: invierte en ella.

Ejemplo para `create-skill`:

```
"crear un skill nuevo" / "agregar un workflow" / "definir un nuevo flujo
de trabajo automatizado" / "extender el framework con nueva funcionalidad" /
"meta-skill para crear skills"
```

### Capas CASTLE

- Declarar **explícitamente** qué capas toca el skill, con el formato `C·A·S·T·L·E`.
- Letra en mayúscula si la capa aplica, `·` si no aplica.
- Ejemplo: `_·A·S·_·L·_` significa que el skill toca **A**rchitecture, **S**ecurity y **L**ogging.

| Letra | Capa | El skill la toca si… |
|-------|------|----------------------|
| C | Contracts | define o valida contratos (API, schemas, eventos) |
| A | Architecture | modifica estructura, dependencias o patrones |
| S | Security | toca auth, secretos, permisos o superficie de ataque |
| T | Testing | genera o exige tests / cobertura |
| L | Logging | emite observabilidad, trazas o métricas |
| E | Environment | depende de configuración por ambiente |

> Detalle de cada capa en `knowledge/universal/castle-spec-v1.md` y `skills/_shared/castle-capas.md`.

### Reporte final

- **Todo skill debe producir un reporte legible al finalizar.**
- Formato mínimo: resumen de lo hecho, archivos creados/modificados, próximos pasos.
- Si el skill falla, el reporte debe indicar **qué falló** y **cómo recuperarse**.
- El formato canónico del envelope de ejecución está en `skills/_shared/skill-envelope.md`.

---

## Testing Guide para Skills

- Incluir al menos **5 scenarios Gherkin** en un archivo `TESTS.md` adjunto al skill, o en la
  sección de scenarios del propio `SKILL.md`. Este es el umbral que el Quality Score exige para
  que el skill sea buscable (king-hub-spec §5) y el que pide el criterio 3 de KFCSA.
- Los scenarios cubren obligatoriamente:
  1. **Happy path** — el flujo principal con entrada válida.
  2. **Caso de error conocido** — entrada inválida o estado bloqueante.
  3. **Idempotencia** — correr el skill dos veces no rompe nada ni duplica artefactos.
- Para publicación **Tier 3 o superior**, los **5 scenarios Gherkin** son **requisito obligatorio**, no recomendación: con menos de 5 el Quality Score cae a 30 (15 api + 15 castle, 0 Gherkin) y el skill queda invisible en `search`.

Formato de cada scenario (Given/When/Then):

```gherkin
Scenario: Nombre descriptivo del caso
  Given el estado inicial verificable
  When la acción que ejecuta el contributor
  Then el resultado observable
  And la verificación adicional
```

---

## Publishing Guide

El proceso completo de firma y publicación por tier vive en
`knowledge/universal/trust-model.md`. Resumen de la ruta Tier 3 (Community):

1. Verificar la **Checklist de Publicación (Tier 3 Hub)** del skill `/create-skill`.
2. Generar y registrar la **clave GPG** del publicador en un keyserver público.
3. Empaquetar y **firmar** el skill: `gpg --armor --detach-sign mi-skill-v{version}.tar.gz`.
4. Abrir PR contra `community/` en el repo `king-framework/king-hub` con package `.tar.gz`,
   firma `.asc` y `manifest.json`.
5. Esperar a que el CI del hub pase (Semgrep + Trivy + GPG verify).

> El detalle de tiers, CRL, revocación e invariante de no-gate-override está en
> `knowledge/universal/trust-model.md`.

---

## Recognition Program

| Programa | Qué es | Dónde ocurre |
|----------|--------|--------------|
| **Contributors page** | Lista automática desde PRs mergeados | `hub.kingframework.dev/contributors` |
| **Skill of the month** | Elegido por maintainers | Home del hub + post en Discord |
| **Annual awards (KingCon)** | Most Downloaded, Best Quality Score, Most Innovative, Best Documentation | Evento anual |
| **Speaker opportunities** | Contributors de Tier 2+ invitados a presentar | KingCon |
| **Tier promotion** | 3+ skills Tier 3 bien mantenidos pueden solicitar Tier 2 | Proceso de review del equipo core |

---

## Cómo conseguir ayuda

- **Discord**: canal `#skill-development`.
- **Issues**: en `king-framework/king-hub` con label `question`.
- **Inspiración**: ver `hub.kingframework.dev/contributors` y el Skill of the month.

---

## Ver también

- `skills/create-skill/SKILL.md` — scaffolding automatizado y checklist de publicación Tier 3.
- `knowledge/universal/trust-model.md` — modelo de confianza, firmas GPG y proceso por tier.
- `knowledge/universal/skill-versioning.md` — convención de `api_version` y reglas de bump.
- `skills/_shared/skill-anatomy.md` — anatomía canónica de un skill v2.0.
- `skills/_templates/skill-template-v2.md` — plantilla base para nuevos skills.
