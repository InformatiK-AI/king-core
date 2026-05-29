# King Hub — Spec del Marketplace

El King Hub es el marketplace oficial de skills del King Framework: el punto donde
terceros publican skills, los usuarios los descubren e instalan, y el ecosistema crece
sin requerir trabajo proporcional del equipo core. Este documento es la **spec completa**
del plugin `king-hub` y su CLI asociado.

> **Scope (M13).** M13 entrega **solo la spec**: arquitectura del plugin, schema del
> manifest, CLI, Quality Score, endpoints y governance. La implementación del backend
> (HTTP API en Go, PostgreSQL, S3) **NO** es parte de M13 — se especifica aquí para que
> el equipo arranque la implementación con el diseño resuelto y las dependencias satisfechas.

---

## §1 — Prerequisitos

Estos items DEBEN estar completos y estables antes de implementar el backend del hub:

| Prerequisito | Qué aporta al hub |
|---|---|
| **M-57** (Trust Model) | El hub implementa la policy de tiers, firma GPG y CRL definida en `trust-model.md`. |
| **M-62** (Contributor Experience) | El hub asume que los contributors publican con `/create-skill` mejorado y siguen `contributor-guide.md`. |
| **M-61** (Community Templates) | El hub aloja y verifica las 10 plantillas oficiales (`community-templates/01..10-*.md`). |
| **M11** (Framework Self-Quality) | El hub asume que los skills declaran `api_version` y siguen semver. |

El hub **no** redefine estas políticas: las consume. El Trust Tier proviene de
`trust-model.md`; el formato del manifest se valida contra el style/publishing guide de
`contributor-guide.md`; el catálogo de plantillas oficiales sale de `community-templates`.

---

## §2 — Arquitectura del Plugin `king-hub`

`king-hub` es un plugin nuevo, independiente de `king-core`. Estructura canónica:

```
king-hub/
├── PLUGIN.md                 # manifest del plugin (nombre, versión, descripción)
├── skills/
│   ├── hub-publish/          # /hub-publish: publicar skill en el hub
│   ├── hub-install/          # /hub-install: instalar skill desde el hub
│   ├── hub-search/           # /hub-search: buscar skills en el catálogo
│   └── hub-stats/            # /hub-stats: métricas propias como publicador
├── commands/
│   ├── hub-publish.md
│   ├── hub-install.md
│   └── hub-search.md
└── knowledge/
    └── hub-publishing-guide.md   # guía de publicación específica del hub
```

Los 4 skills son la cara del hub dentro de un proyecto King. El CLI `king-framework skill *`
(§4) es el contrato de bajo nivel sobre el que se apoyan estos skills.

---

## §3 — Schema del Manifest (`manifest.json`)

Cada skill publicado lleva un `manifest.json` en su raíz. Es el contrato de metadatos del
hub: campos requeridos, opcionales y derivados (calculados por el hub, no escritos por el autor).

### §3.1 — Campos y tipos

| Campo | Tipo | Req. | Descripción |
|---|---|:--:|---|
| `name` | `string` | Sí | Identificador namespaced `autor/skill-name`. El `autor` MUST coincidir con `author.github`. |
| `version` | `string` (semver) | Sí | Versión de **contenido** del skill, `MAJOR.MINOR.PATCH`. |
| `api_version` | `string` (semver) | Sí | Versión de **interfaz** del skill (ver `skill-versioning.md`). |
| `king_framework_version` | `string` (rango semver) | Sí | Rango de compatibilidad, p.ej. `">=2.0.0"`. |
| `author` | `object` | Sí | Identidad del publicador. Ver subcampos. |
| `author.github` | `string` | Sí | Usuario de GitHub del autor. Determina el namespace. |
| `author.gpg_key_id` | `string` | Sí | ID de la clave GPG con la que se firma el package (ver `trust-model.md`). |
| `trust_tier` | `integer` (1–4) | Sí | Tier de confianza: 1 Official, 2 Trusted, 3 Community, 4 Local. |
| `description` | `string` | Sí | Descripción del skill. SHOULD tener ≥ 100 caracteres (suma al Quality Score). |
| `tags` | `array<string>` | Sí | Etiquetas para búsqueda y filtrado, p.ej. `["testing", "go", "bubbletea"]`. |
| `castle_layers` | `array<string>` | Sí | Capas CASTLE que el skill cubre: subconjunto de `["C","A","S","T","L","E"]`. |
| `downloads` | `integer` | Derivado | Contador de instalaciones. Lo escribe el hub; inicia en `0`. |
| `rating` | `number \| null` | Derivado | Promedio de ratings (1.0–5.0). `null` si no hay ratings. |
| `published_at` | `string` (ISO 8601 UTC) | Derivado | Timestamp de publicación. Lo escribe el hub. |

Reglas de tipos:

- `version` y `api_version` MUST ser semver válido (`MAJOR.MINOR.PATCH`). Un `api_version`
  inválido cuesta 15 puntos de Quality Score (§5).
- `castle_layers` MUST ser un array no vacío de letras del conjunto CASTLE. Declararlas suma
  15 puntos de Quality Score.
- Los campos **derivados** (`downloads`, `rating`, `published_at`) NO los escribe el autor:
  si vienen en el manifest enviado, el hub los ignora y los recalcula.

### §3.2 — Ejemplo de manifest válido completo

```json
{
  "name": "gentlemandots/go-testing",
  "version": "1.2.3",
  "api_version": "1.2.3",
  "king_framework_version": ">=2.0.0",
  "author": {
    "github": "gentlemandots",
    "gpg_key_id": "ABCD1234EF567890"
  },
  "trust_tier": 3,
  "description": "Patrones de testing para proyectos Go, incluyendo testing de TUIs con Bubbletea y teatest. Cubre table-driven tests, golden files, y coverage gates para CASTLE.",
  "tags": ["testing", "go", "bubbletea"],
  "castle_layers": ["T", "L"],
  "downloads": 0,
  "rating": null,
  "published_at": "2026-05-28T00:00:00Z"
}
```

---

## §4 — CLI Commands

El hub expone 7 comandos a través del CLI `king-framework skill` (provisto por Apex Core,
M12). Cada comando declara sintaxis, flags y output esperado.

### §4.1 — `search`

Busca skills en el catálogo. Solo devuelve skills con Quality Score ≥ 40 (§5).

```
king-framework skill search <query> [--tags X,Y] [--tier 1-4] [--sort downloads|rating|date]
```

| Flag | Descripción |
|---|---|
| `--tags X,Y` | Filtra por etiquetas (AND). |
| `--tier 1-4` | Filtra por trust tier máximo aceptado. |
| `--sort` | Orden de resultados: `downloads` (def.), `rating` o `date`. |

Output esperado:

```
$ king-framework skill search testing --tags go --sort rating
TIER  NAME                          VER     ★    DLs    DESCRIPTION
[T3]  gentlemandots/go-testing      1.2.3   4.8  1.2k   Patrones de testing para Go con Bubbletea…
[T2]  king/contract-test            2.0.1   4.6  8.4k   Contract testing con Pact para microservicios…
2 resultados (Quality Score ≥ 40).
```

### §4.2 — `install`

Instala un skill desde el hub. Verifica firma GPG y compatibilidad antes de escribir.

```
king-framework skill install <autor/skill-name> [--version X.Y.Z] [--trust-threshold 3] [--force]
```

| Flag | Descripción |
|---|---|
| `--version X.Y.Z` | Instala una versión concreta (def.: la más reciente). |
| `--trust-threshold N` | Rechaza skills con `trust_tier` > N. |
| `--force` | Procede pese a incompatibilidad de `king_framework_version` (§7). |

Output esperado:

```
$ king-framework skill install gentlemandots/go-testing
Resolviendo gentlemandots/go-testing@1.2.3 … OK
Verificando firma GPG (ABCD1234EF567890) … válida ✓
Tier: [T3] Community  ·  Compat: >=2.0.0 (actual 2.3.1) ✓
Instalado en skills/go-testing/ ✓
```

### §4.3 — `update`

Actualiza skills instalados a la última versión compatible.

```
king-framework skill update [--all] [<autor/skill-name>]
```

| Flag | Descripción |
|---|---|
| `--all` | Actualiza todos los skills instalados desde el hub. |
| `<autor/skill-name>` | Actualiza solo el skill indicado. |

Output esperado:

```
$ king-framework skill update --all
gentlemandots/go-testing  1.2.3 → 1.3.0  ✓
king/contract-test        2.0.1 (sin cambios)
1 skill actualizado, 1 al día.
```

### §4.4 — `publish`

Publica un skill local en el hub. Requiere firma GPG válida y pasa el scanning del hub.

```
king-framework skill publish <path> --tier 3
```

| Flag | Descripción |
|---|---|
| `--tier N` | Tier solicitado. Downgrade es libre; upgrade requiere re-review (§6). |

Output esperado:

```
$ king-framework skill publish ./skills/go-testing --tier 3
Validando manifest.json … OK
Firmando package con GPG (ABCD1234EF567890) … OK
Subiendo a hub.kingframework.dev … OK
Quality Score calculado: 78/100 ✓ (umbral búsqueda: 40)
Publicado: gentlemandots/go-testing@1.2.3 [T3]
```

### §4.5 — `info`

Muestra el detalle de un skill: versiones, metadatos, Quality Score y tier.

```
king-framework skill info <autor/skill-name>
```

Output esperado:

```
$ king-framework skill info gentlemandots/go-testing
gentlemandots/go-testing
  Tier:           [T3] Community
  Última versión: 1.3.0  (api_version 1.3.0)
  Compat:         >=2.0.0
  Quality Score:  78/100
  CASTLE layers:  T, L
  Descargas:      1.243   ·   Rating: 4.8 (37 reviews)
  Versiones:      1.3.0, 1.2.3, 1.2.0, 1.0.0
  Publicado:      2026-05-28
```

### §4.6 — `verify`

Verifica **localmente** la firma GPG y el scanning de un package antes de publicar o instalar.
No requiere conexión al hub.

```
king-framework skill verify <path>
```

Output esperado:

```
$ king-framework skill verify ./skills/go-testing
Firma GPG … válida (ABCD1234EF567890) ✓
Gate-override-checker … sin overrides de CASTLE ✓
Manifest schema … completo (12/12 campos) ✓
Quality Score estimado: 78/100
Verificación OK.
```

### §4.7 — `uninstall`

Elimina un skill instalado del proyecto.

```
king-framework skill uninstall <autor/skill-name>
```

Output esperado:

```
$ king-framework skill uninstall gentlemandots/go-testing
Eliminando skills/go-testing/ … OK
Desinstalado gentlemandots/go-testing.
```

### §4.8 — Resumen

| # | Command | Propósito |
|---|---|---|
| 1 | `search` | Buscar y filtrar el catálogo (Quality Score ≥ 40). |
| 2 | `install` | Instalar con verificación GPG + compatibilidad. |
| 3 | `update` | Actualizar skills a la última versión compatible. |
| 4 | `publish` | Publicar firmando con GPG y pasando el scanning. |
| 5 | `info` | Ver detalle, versiones, score y tier. |
| 6 | `verify` | Verificar firma y scanning localmente. |
| 7 | `uninstall` | Eliminar un skill instalado. |

---

## §5 — Quality Score

El Quality Score es una **métrica determinista**: mismo input produce siempre el mismo score.
No usa ML ni juicio humano. Se calcula automáticamente al publicar y se **recalcula
semanalmente** (porque el componente de rating cambia con nuevas reviews).

### §5.1 — Fórmula

```
Quality Score = min(100,                     # cap explícito: el techo es 100
    (gherkin_scenarios >= 5      ? 20 : 0)   # cobertura de escenarios
  + (api_version_semver_valid    ? 15 : 0)   # interfaz versionada
  + (castle_layers_declared      ? 15 : 0)   # capas CASTLE declaradas
  + (description_length >= 100   ? 10 : 0)   # descripción sustancial
  + (has_references_dir          ? 10 : 0)   # carpeta references/ presente
  + (rating_avg * 6)                         # máx 30  (5.0 * 6)
  + (tier == 1 ? 20 : tier == 2 ? 10 : 0)    # bonus por tier
)
```

| Componente | Condición | Puntos |
|---|---|--:|
| Escenarios Gherkin | `>= 5` | 20 |
| `api_version` semver válido | sí | 15 |
| `castle_layers` declaradas | array no vacío | 15 |
| Descripción | `>= 100` caracteres | 10 |
| Carpeta `references/` | presente | 10 |
| Rating promedio | `rating_avg * 6` | máx **30** |
| Bonus por tier | T1 → 20, T2 → 10, T3/T4 → 0 | máx 20 |

### §5.2 — Topes y umbrales

- **Score máximo: 100** (cap explícito `min(score, 100)`). Los componentes base suman 70
  (20 gherkin + 15 api + 15 castle + 10 desc + 10 references) y el rating aporta como máximo
  30 (5.0 × 6), de modo que un skill perfecto en todo lo demás **ya alcanza 100 sin bonus de
  tier**. El bonus de tier (T1 +20, T2 +10) no puede superar el cap de 100: se aplica dentro de
  ese techo y sólo eleva el score de skills que aún no llegan al máximo.
- **Score mínimo para búsqueda: 40.** Un skill con score < 40 **no** aparece en `search`,
  aunque sí en `info` por su nombre exacto.

### §5.3 — Determinismo del umbral mínimo

Un skill con **solo las características mínimas** alcanza exactamente el umbral de búsqueda:

| Característica mínima | Puntos |
|---|--:|
| `api_version` semver válido | 15 |
| `castle_layers` declaradas | 15 |
| 5 escenarios Gherkin | 20 |
| Total | **50** |

Con `api_version` válido + CASTLE layers + ≥ 5 Gherkin, el score es **50 ≥ 40** sin necesidad
de rating, descripción larga ni carpeta `references/`. Es decir, un skill Tier 3 técnicamente
correcto **siempre** es buscable. Esto satisface el invariante DoD: "un skill con solo las
características mínimas obtiene al menos 40".

### §5.4 — Ortogonalidad con Trust Tier

Quality Score y Trust Tier son **dimensiones ortogonales**:

- **Trust Tier** mide *quién publica y cómo se verificó* (procedencia + firma GPG).
- **Quality Score** mide *qué tan bueno es el skill* (cobertura de tests, docs, rating).

Un skill Tier 3 (Community) con tests exhaustivos y rating alto puede tener **mejor**
Quality Score que un Tier 2. El bonus por tier (+20 T1, +10 T2) premia la procedencia
verificada, pero no domina el score: un Tier 3 excelente supera a un Tier 1 mediocre.

---

## §6 — Backend Architecture (implementación futura)

> Esta sección especifica el backend para la implementación posterior. **No se implementa en M13.**
>
> **Hosting decidido (A7.1, 2026-05-29)**: **Railway** (primaria; Fly.io runner-up) — compute Go always-on +
> Railway Postgres + Railway Buckets (egress $0, descargas vía presigned URL 302). Ver `king-hub-hosting-adr.md`.

### §6.1 — Stack y endpoint base

```
API:          HTTP REST (Go chi)
Catálogo:     PostgreSQL  (skills, versiones, ratings, autores)
Packages:     S3-compatible (artefactos firmados)
Endpoint base: https://hub.kingframework.dev/api/v1/
```

### §6.2 — Endpoints clave

| Método | Ruta | Propósito |
|---|---|---|
| `GET` | `/skills` | Search + filter (mapea a `skill search`). |
| `GET` | `/skills/{autor}/{name}` | Detalle + versiones (mapea a `skill info`). |
| `POST` | `/skills` | Publish — requiere verificación GPG (mapea a `skill publish`). |
| `GET` | `/skills/{autor}/{name}/download/{version}` | Descarga del package firmado (mapea a `skill install`). |
| `POST` | `/skills/{autor}/{name}/rate` | Enviar rating (alimenta `rating_avg`). |
| `GET` | `/crl` | Certificate Revocation List, JSON firmado por el equipo core. |

### §6.3 — Reglas de negocio

- Un skill **no** puede sobrescribir otro del mismo namespace salvo que sea el **mismo autor**
  (`author.github` debe coincidir con el dueño del namespace).
- **Downgrade** de tier es libre; **upgrade** de tier requiere re-review (§ trust-model.md).
- **Rate limiting**: 100 installs/min por IP; 10 publishes/día por cuenta.
- La **CRL** se sirve en `/crl` como JSON firmado por el equipo core. Los clientes la consultan
  en `install` y rechazan packages cuyo hash esté revocado (ver `trust-model.md`).

---

## §7 — Compatibility Matrix

El hub verifica automáticamente que `king_framework_version` del manifest sea compatible
con la versión del framework del usuario al instalar:

- **Compatible** → instalación procede sin avisos.
- **Incompatible** → **WARNING, no bloqueo**. El usuario puede forzar con `--force`.

Ejemplo de WARNING:

```
$ king-framework skill install autor/skill-legacy
ADVERTENCIA: skill requiere king_framework_version ">=3.0.0" pero tu versión es 2.3.1.
La instalación puede no funcionar. Usa --force para proceder bajo tu responsabilidad.
```

La política deliberada es **avisar, no bloquear**: el usuario es soberano sobre su entorno,
pero la advertencia hace explícito el riesgo.

---

## §8 — Governance

- **Namespaces**: un namespace `autor/*` pertenece al `author.github` que publica primero.
  Solo ese autor (verificado por GPG) puede publicar bajo ese namespace.
- **Calidad mínima**: el umbral de 40 en Quality Score mantiene el catálogo de búsqueda libre
  de spam (mitigación R-07). Ratings y reviews refinan la curaduría de forma orgánica.
- **Revocación**: el equipo core puede revocar un skill comprometido añadiendo su hash a la CRL.
  Los clientes rechazan la instalación de packages revocados y el skill desaparece de `search`.
- **Cambios al schema del manifest**: siguen la política de versionado y deprecación del
  framework (`skill-versioning.md`, `deprecation-policy.md`) — campos nuevos son aditivos
  (MINOR); remover o renombrar campos es MAJOR con período de 6 meses.

---

## §9 — Integración con GitHub Ops

La **implementación futura** del hub reutiliza `king-core/skills/github-ops/SKILL.md` para:

- Crear el repo `king-framework/king-hub` con la estructura del §2.
- Configurar GitHub Actions del repo hub (CI de publicación + scanning).
- Configurar GitHub Environments para `staging`/`production` del hub.
- Proteger branches del repo hub siguiendo el GitFlow de King.

El scanning del CI ejecuta el `gate-override-checker` (ver `trust-model.md`): cualquier
`SKILL.md` que intente anular un BLOCKING CONDITION de king-core falla el check y el PR de
publicación **no** puede mergearse.

---

## §10 — Ver También

- `knowledge/universal/trust-model.md` (M-57) — tiers, firma GPG, scanning pipeline, CRL,
  invariante de no-gate-override. El hub **implementa** esta policy.
- `knowledge/universal/contributor-guide.md` (M-62) — style/testing/publishing guide que el
  hub asume que los publicadores siguen.
- `knowledge/universal/community-templates/` (M-61) — las 10 plantillas oficiales alojadas y
  verificadas por el hub.
- `knowledge/universal/skill-versioning.md` — semver de `api_version`, base del Quality Score.
- `knowledge/universal/deprecation-policy.md` — política aplicada a cambios del schema del manifest.
