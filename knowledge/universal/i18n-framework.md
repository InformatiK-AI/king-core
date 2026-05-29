# i18n del Framework King — Convención y Estrategia

Este documento define la estrategia de internacionalización (i18n) del **framework King en sí mismo**: los idiomas en que se publican sus skills y knowledge, el proceso de traducción, las convenciones de archivos localizados y la selección de idioma en runtime.

> No confundir con el skill `i18n/l10n` existente, que internacionaliza los **proyectos del usuario**. Ese skill NO se modifica. Este documento es sobre el contenido del framework: `SKILL.md`, knowledge docs y mensajes que el equipo core y los contributors mantienen.

---

## Idiomas target

El framework prioriza cinco idiomas según audiencia y mercado. El orden de prioridad determina qué se traduce primero y cuántas revisiones requiere.

| Prioridad | Código | Idioma | Variante | Mercado objetivo |
|-----------|--------|--------|----------|------------------|
| 1 | `es` | Español | Neutro (no voseo, no rioplatense) | Idioma **primario** del framework |
| 2 | `en` | Inglés | Internacional | Máxima audiencia global |
| 3 | `pt` | Portugués | Brasil | LATAM |
| 4 | `fr` | Francés | Estándar | Europa / África francófona |
| 5 | `ja` | Japonés | Estándar | Asia |

El español neutro es la lengua canónica. Toda decisión de diseño, todo BLOCKING CONDITION y todo REQUIRED OUTPUT se escribe primero en español y de ahí se deriva.

---

## Política de idioma en skills y knowledge

El contenido de skills y knowledge se mantiene en español (idioma primario). Las traducciones viven **junto al canónico**, en el mismo directorio, identificadas por un sufijo de código de idioma.

### Estructura de archivos localizados

```
skills/
└── create-skill/
    ├── SKILL.md         # español (canónico, fuente de verdad)
    ├── SKILL.en.md      # inglés (traducción derivada)
    ├── SKILL.pt.md      # portugués (traducción derivada)
    ├── SKILL.fr.md      # francés (traducción derivada)
    └── SKILL.ja.md      # japonés (traducción derivada)
```

El mismo patrón aplica a knowledge docs:

```
knowledge/universal/
├── castle-spec-v1.md       # español (canónico)
├── castle-spec-v1.en.md    # inglés
└── castle-spec-v1.pt.md    # portugués
```

### Reglas de la convención

| Regla | Detalle |
|-------|---------|
| Canónico = sin sufijo | El archivo `SKILL.md` (sin código de idioma) es **siempre español**. |
| Sufijo = `<base>.<lang>.<ext>` | El código de idioma se inserta antes de la extensión: `SKILL.en.md`, no `SKILL.md.en` ni `en/SKILL.md`. |
| Fuente de verdad | Si hay conflicto entre el canónico y una traducción, **gana el español**. La traducción se corrige, nunca al revés. |
| Derivación obligatoria | Una traducción siempre deriva de una versión concreta del canónico (se registra qué `api_version` tradujo). |
| Co-ubicación | La traducción vive en el mismo directorio que su canónico, nunca en un árbol paralelo. |

La traducción NUNCA es autoritativa. Es una vista localizada de la verdad española.

---

## Proceso de traducción

Una traducción atraviesa cinco etapas, desde que el contenido en español se estabiliza hasta que se mergea la traducción revisada.

1. **Crear en español.** Todo contenido nuevo (skill o knowledge) se escribe primero en español. No se acepta una traducción de contenido que aún no existe en canónico.
2. **Estabilizar.** El canónico se abre a traducción solo cuando es estable: `api_version >= 1.0.0` y no marcado como `draft`. Traducir contenido en borrador genera retrabajo garantizado.
3. **Enviar PR.** Cualquier contributor puede enviar un PR con la traducción al repo `king-core`. El PR DEBE incluir el archivo localizado completo y declarar la versión del canónico que tradujo.
4. **Revisar por native speaker.** La traducción la revisa un hablante nativo del idioma target. El número de approvals depende de la prioridad del idioma:

   | Idioma | Approvals requeridos |
   |--------|----------------------|
   | `en` | 2 (alta audiencia, mayor escrutinio) |
   | `pt` | 2 |
   | `fr` | 1 |
   | `ja` | 1 |

5. **Preservar la semántica crítica.** Las traducciones de `SKILL.md` NO deben cambiar la semántica de **BLOCKING CONDITIONS** ni de **REQUIRED OUTPUTS**. La estructura, el número y el orden de estas secciones se mantienen idénticos al canónico.

### Regla de oro ante la duda

> **Si hay duda en cómo traducir un BLOCKING CONDITION, se mantiene el texto original en español.**

Es preferible un BLOCKING CONDITION en español dentro de un archivo traducido que una traducción ambigua que relaje el invariante. Un gate mal traducido es un gate roto. La duda se resuelve a favor del original, y el revisor nativo decide después si existe una traducción inequívoca.

---

## Selección de idioma en runtime

El framework respeta la variable de entorno **`KING_LANG`** para elegir qué versión de un archivo cargar.

| Valor de `KING_LANG` | Comportamiento |
|----------------------|----------------|
| (no definida) | Default `es` → carga el canónico `SKILL.md`. |
| `es` | Carga el canónico `SKILL.md`. |
| `en` y existe `SKILL.en.md` | Carga la traducción inglesa. |
| `en` y NO existe `SKILL.en.md` | **Fallback** al canónico `SKILL.md` (español). |
| Idioma no soportado (ej. `de`) | **Fallback** al canónico `SKILL.md`. Nunca falla por idioma inexistente. |

### Algoritmo de resolución

```
resolver(archivo_base, KING_LANG):
    si KING_LANG vacío o == "es":
        return archivo_base                      # SKILL.md
    candidato = inserta_sufijo(archivo_base, KING_LANG)   # SKILL.en.md
    si existe(candidato):
        return candidato
    return archivo_base                          # fallback al canónico
```

El fallback es silencioso y total: ante cualquier traducción ausente o idioma desconocido, el framework sirve el español. Esto garantiza que **King nunca se queda sin contenido** por una traducción faltante.

> **Dependencia técnica:** la resolución en runtime requiere soporte de Apex Core (lectura de `KING_LANG` y resolución de sufijos). Esa implementación es trabajo de M12 o posterior. Este documento define la convención; el runtime la consume.

---

## Cobertura de traducción — targets por versión

La cobertura de traducción crece de forma escalonada por release. Los targets son **porcentuales y por idioma**, medidos sobre los skills core del framework.

| Versión | `en` (inglés) | `pt` (portugués) | `fr` (francés) | `ja` (japonés) |
|---------|---------------|------------------|----------------|----------------|
| **v2.5** | 80% | — | — | — |
| **v3.0** | 100% | 50% | — | — |
| **v3.5** | 100% | 100% | 50% | — |
| **v4.0** | **100%** | **100%** | **100%** | **100%** |

Lectura de la tabla:

- **v2.5** — skills core en inglés al 80%. Primer hito de internacionalización real.
- **v3.0** — inglés completo (100%) y portugués arrancando (50%).
- **v3.5** — inglés y portugués completos; francés a la mitad.
- **v4.0** — **todos los idiomas target al 100%.** Estado de paridad total.

La cobertura se mide como: `skills_traducidos_y_revisados / total_skills_core * 100`, redondeado hacia abajo. Un skill cuenta como traducido solo si pasó la revisión por native speaker (no basta con el PR abierto).

---

## Tooling de traducción asistida

El CLI `king-framework` ofrece dos subcomandos bajo `i18n` para asistir a los contributors. Ninguno de los dos traduce automáticamente: solo andamian y verifican.

### `i18n extract` — genera el esqueleto de traducción

```
king-framework i18n extract <skill> --lang <code>
```

- Genera `SKILL.<lang>.md` a partir del canónico.
- Copia el contenido en español y coloca un marcador **`{{TRANSLATE}}`** al inicio de cada sección traducible.
- El contributor reemplaza cada marcador con la traducción de esa sección.
- **No toca** las secciones BLOCKING CONDITIONS ni REQUIRED OUTPUTS más allá de marcarlas; el contributor debe respetar la regla de oro (ante duda, mantener el original).
- Registra en el archivo generado la `api_version` del canónico desde el que se extrajo (base de comparación para `verify`).

Ejemplo:

```
$ king-framework i18n extract create-skill --lang en
✓ Generado skills/create-skill/SKILL.en.md (derivado de api_version 1.2.0)
  12 secciones marcadas con {{TRANSLATE}}
  2 secciones críticas (BLOCKING CONDITIONS, REQUIRED OUTPUTS) preservadas en español
```

### `i18n verify` — valida completitud y vigencia

```
king-framework i18n verify <skill> --lang <code>
```

- Verifica que la traducción tenga **todas** las secciones del canónico.
- Reporta **secciones faltantes** (presentes en el canónico, ausentes en la traducción).
- Reporta **secciones desactualizadas**: cuando el canónico cambió de `api_version` *después* de que se generó la traducción.
- Reporta marcadores `{{TRANSLATE}}` sin reemplazar (traducción incompleta).
- **NO modifica ningún archivo.** Es solo lectura: emite un reporte y un código de salida (0 = al día, distinto de 0 = problemas).

Ejemplo con traducción desactualizada:

```
$ king-framework i18n verify create-skill --lang en
✗ SKILL.en.md está DESACTUALIZADO
  Traducido de: api_version 1.0.0
  Canónico actual: api_version 1.1.0
  Secciones del canónico ausentes en la traducción:
    - "## Phase 4 — Publish Checklist" (añadida en 1.1.0)
  Acción sugerida: re-extraer las secciones nuevas y traducirlas.
  (no se modificó ningún archivo)
```

---

## Gestión de divergencias

Cuando el canónico español cambia, las traducciones quedan potencialmente desfasadas. La política define cómo se detecta y comunica ese desfase.

### Disparador

Un bump **MINOR** o **MAJOR** del `api_version` del canónico (no PATCH) marca todas sus traducciones como candidatas a desactualización. Un PATCH (typo, reformulación menor sin cambio de comportamiento) no dispara el flujo.

### Marcado y notificación

1. Las traducciones afectadas se marcan como **`outdated`** en king-hub (si están publicadas ahí).
2. El contributor original de cada traducción recibe una **notificación vía GitHub Issue automático**.
3. El Issue incluye el **diff** de los cambios del canónico a incorporar y la `api_version` objetivo.
4. Mientras la traducción esté `outdated`, el runtime sigue sirviéndola (con fallback disponible), pero el hub la señala visiblemente como desfasada.

### Resolución

El contributor actualiza la traducción, corre `king-framework i18n verify` hasta que reporte "al día", y abre un PR de actualización. Una vez mergeado y revisado, se levanta el flag `outdated`.

> **Recordatorio de jerarquía:** ante cualquier conflicto irresoluble entre canónico y traducción, el español es la fuente de verdad. La traducción se ajusta al canónico, jamás al contrario.

---

## Resumen operativo

| Pregunta | Respuesta |
|----------|-----------|
| ¿Cuál es el idioma canónico? | Español neutro (`es`). |
| ¿Dónde viven las traducciones? | Junto al canónico, con sufijo `<base>.<lang>.<ext>`. |
| ¿Quién manda en un conflicto? | El canónico español, siempre. |
| ¿Cómo elijo idioma en runtime? | Variable `KING_LANG`; fallback silencioso al español. |
| ¿Cómo arranco una traducción? | `king-framework i18n extract <skill> --lang <code>`. |
| ¿Cómo verifico que está completa? | `king-framework i18n verify <skill> --lang <code>` (no modifica nada). |
| ¿Qué hago si dudo al traducir un gate? | Mantener el original en español. |
| ¿Cuándo todos los idiomas llegan al 100%? | En King v4.0. |

---

## See Also

- `knowledge/universal/skill-versioning.md` — reglas de bump de `api_version` que disparan la gestión de divergencias.
- `knowledge/universal/deprecation-policy.md` — política de cambios que afecta la vigencia de las traducciones.
- Skill `i18n/l10n` — internacionalización de **proyectos del usuario** (no del framework); no se modifica con esta convención.
- M12 — soporte de runtime para `KING_LANG` en Apex Core.
