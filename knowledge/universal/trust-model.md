# Trust Model — Firmas de Plugins y Modelo de Confianza

Documento fundacional de gobernanza del ecosistema King. Define cómo se establece y
verifica la confianza en un skill o plugin de terceros: cuatro tiers con criterios
objetivos, el proceso de firma GPG, el pipeline de scanning automático, la revocación
con CRL pública y la **invariante absoluta** de que ningún skill puede anular un gate
CASTLE Tier 1.

Es la política que el marketplace `king-hub` (M-56) implementa y que la experiencia de
contributor (M-62) referencia. El campo `trust_tier` del manifest de cada skill apunta al
tier definido aquí.

> Alcance: este documento es **policy + convención documental**. No instala ni ejecuta
> nada por sí mismo. El backend del king-hub (HTTP API, hosting de la CRL) queda fuera de
> scope; aquí se especifica para que su implementación encuentre el diseño resuelto.

---

## §1 — Los 4 Tiers de Confianza

El modelo usa cuatro tiers, ni más ni menos, porque cada uno resuelve una tensión distinta
entre **fricción de publicación** y **garantía para el consumidor**. Cada tier tiene un
badge visible en el marketplace.

| Tier | Nombre | Badge | Quién publica | Garantías |
|------|--------|-------|---------------|-----------|
| 1 | Official | Azul | La org `king-framework` en GitHub | Soporte LTS, deprecation policy completa, tests obligatorios |
| 2 | Trusted Partners | Verde | Organizaciones verificadas (empresa + acuerdo firmado) | Soporte declarado por la org, alineamiento con CASTLE Spec v1.0 |
| 3 | Community | Gris | Cualquier persona con cuenta GitHub verificada | Ninguna de soporte; rating y reviews de la comunidad como señal |
| 4 | Local | (sin badge) | El usuario en su propio entorno | Ninguna |

### Tier 1 — Official (badge azul)

- **Publicado por**: la organización `king-framework` en GitHub.
- **Requiere**: firma GPG del equipo core **y** merge en la rama `main` del repo oficial.
- **Ejemplos**: `king-core`, `king-content`, `king-infra`, `king-entrepreneur`, `king-mobile`.
- **Scanning**: automático (Semgrep + Trivy) **más** code review obligatorio del equipo core.
- **Garantías**: soporte LTS (ver `deprecation-policy.md`), deprecation policy completa,
  tests obligatorios. Es el nivel máximo de garantía, reservado a los plugins canónicos.

### Tier 2 — Trusted Partners (badge verde)

- **Publicado por**: organizaciones verificadas (empresa verificada + acuerdo de partner firmado).
- **Requiere**: firma GPG de la organización **más** review manual de 1 maintainer del equipo core.
- **Proceso de verificación**: pull request a `trusted-partners/` en el repo `king-hub` +
  **14 días** de review.
- **Scanning**: automático (Semgrep + Trivy) + revisión humana spot-check.
- **Garantías**: soporte declarado por la organización publicadora, alineamiento con CASTLE Spec v1.0.

### Tier 3 — Community (badge gris)

- **Publicado por**: cualquier persona con cuenta GitHub verificada.
- **Requiere**: firma GPG personal **más** scan automático sin errores críticos.
- **Proceso**: pull request a `community/` en el repo `king-hub` + CI automatizado + **7 días**
  de review por pares.
- **Scanning**: Semgrep + Trivy + Snyk OSS (sin errores `CRITICAL`).
- **Garantías**: ninguna de soporte. El rating y las reviews de la comunidad son la única señal
  de calidad. Es la **puerta de entrada masiva** del ecosistema.

### Tier 4 — Local (sin badge)

- **Publicado por**: el usuario en su propio entorno.
- **Requiere**: ningún requisito formal.
- **Uso**: desarrollo local, skills privados corporativos, pruebas, prototipos.
- **Scanning**: recomendado pero no obligatorio. Se puede ejecutar `king-framework skill verify --local`.
- **Garantías**: ninguna.

> **Por qué Tier 4 sin fricción**: es la mitigación deliberada del riesgo de que el modelo de
> confianza frene la adopción. El desarrollo local y los skills privados corporativos **nunca**
> pagan el costo de publicación. La fricción se introduce solo cuando se quiere distribuir
> públicamente bajo un badge.

---

## §2 — Firma GPG

La firma GPG es la base criptográfica de la confianza: vincula cada package publicado con una
identidad verificable y permite al cliente detectar manipulación antes de instalar.

### §2.1 — Generación del par de claves

```bash
gpg --full-generate-key
# Tipo:       RSA and RSA
# Tamaño:     4096 bits
# Expiración: 2 años (renovable)
# Email:      DEBE coincidir con el email del GitHub verificado del autor
```

Reglas:

- El algoritmo es **RSA 4096 bits**. Claves menores a 4096 bits son rechazadas por el validador.
- La clave tiene una **expiración de 2 años** y debe renovarse antes de vencer. Una clave
  expirada invalida toda firma producida con ella a partir de la fecha de expiración.
- El **email de la clave debe coincidir** con el email de la cuenta de GitHub verificada del autor.
  Esta correspondencia es la que vincula la firma con el tier declarado.

### §2.2 — Firma de un skill package

```bash
# 1. Empaquetar el skill
king-framework skill pack ./mi-skill/ --out mi-skill-v1.0.0.tar.gz

# 2. Firmar (firma desprendida, ASCII-armored)
gpg --armor --detach-sign mi-skill-v1.0.0.tar.gz
# Genera: mi-skill-v1.0.0.tar.gz.asc

# 3. Verificar localmente ANTES de publicar
king-framework skill verify mi-skill-v1.0.0.tar.gz
```

El artefacto publicado es siempre el par `(<package>.tar.gz, <package>.tar.gz.asc)`. La firma es
**desprendida** (detached) y **ASCII-armored** (`.asc`).

### §2.3 — Verificación en el cliente

Al instalar cualquier skill, el CLI ejecuta una cadena de verificación **antes** de escribir un
solo archivo en el sistema:

```bash
king-framework skill install autor/mi-skill
# → descarga el .tar.gz + el .asc
# → verifica la firma GPG contra keyserver.ubuntu.com / keys.openpgp.org
# → verifica que la clave GPG corresponde al tier declarado en el manifest
# → si todo pasa: muestra el badge del tier y completa la instalación
# → si algo falla: BLOQUEA la instalación con un error explícito y NO escribe nada
```

Secuencia exacta de verificación en el cliente:

1. **Descarga** del package y su firma desprendida.
2. **Resolución de la clave pública** del autor contra los keyservers públicos
   (`keyserver.ubuntu.com`, `keys.openpgp.org`).
3. **Verificación criptográfica** de la firma contra el package descargado.
4. **Verificación de no-expiración** de la clave a la fecha de la firma.
5. **Verificación de correspondencia tier ↔ clave**: la clave que firmó debe corresponder al
   tier declarado en el manifest (clave del equipo core para Tier 1, de la org para Tier 2,
   personal para Tier 3).
6. **Verificación contra la CRL** (ver §4) si se pasa `--check-revocation`.

Si **cualquier** paso 2-6 falla, la instalación se rechaza con un error explícito y **no se
escribe ningún archivo** en el sistema del usuario (fallo atómico, sin estado parcial). El
mensaje de error indica la causa exacta (p.ej. "firma GPG inválida", "clave expirada el
2026-01-15", "clave no corresponde al tier 1 declarado", "package revocado: ver CRL").

---

## §3 — Scanning Automático

El pipeline de scanning corre en el CI del repo `king-hub` para **cada PR de publicación**.
Reutiliza las mismas herramientas (Semgrep, Trivy) del workflow `framework-quality.yml`
(M11/M-75), evitando duplicar configuración de seguridad.

| Herramienta | Qué detecta | Bloquea si | Tiers |
|-------------|-------------|------------|-------|
| **Semgrep** (rulesets community + python + yaml) | Patrones de código malicioso, `eval` sin sanitizar, secrets hardcodeados | Severidad `ERROR` | 1, 2, 3 |
| **Trivy** | CVEs en las dependencias declaradas por el skill | `CRITICAL` o `HIGH` sin fix disponible | 1, 2, 3 |
| **Snyk OSS** | Vulnerabilidades en packages referenciados | `CRITICAL` | 3 (solo) |
| **CASTLE gate-override checker** (custom) | Intento de sobrescribir o anular un gate core del framework | **Siempre bloquea** | 1, 2, 3 |
| **GPG signature validator** | Firma válida y clave no expirada | Firma inválida o ausente | 1, 2, 3 |

Notas por tier:

- **Tier 1** añade, sobre el scan automático, **code review humano obligatorio** del equipo core.
- **Tier 2** añade **revisión humana spot-check** de 1 maintainer (14 días).
- **Tier 3** añade **review por pares** (7 días) y es el único que ejecuta **Snyk OSS**.
- **Tier 4** no pasa por el pipeline (es local); el scan es recomendado vía `skill verify --local`.

### §3.1 — INVARIANTE ABSOLUTA: no-gate-override

> **Ningún skill puede declarar, en ninguna circunstancia, que sobrescribe, deshabilita o anula
> un gate CASTLE Tier 1 del framework.** Esta invariante NO es negociable y NO tiene excepciones.

El `CASTLE gate-override checker` verifica que el `SKILL.md` del skill propuesto **no contiene
instrucciones que anulen un `BLOCKING CONDITION` de cualquier skill Tier 1** de `king-core`.

Casos que el checker bloquea **siempre** (lista no exhaustiva):

- Instrucciones que indiquen ignorar, saltar, o desactivar un `BLOCKING CONDITION`,
  un gate de veto CASTLE, o un quality gate de un skill Tier 1.
- Cualquier uso de `continue-on-error: true` aplicado a un step que ejecuta un gate CASTLE
  Tier 1 (los gates Tier 1 **nunca** pueden ser `continue-on-error`).
- Reescritura, parche o "monkey-patch" de un hook de bloqueo de `king-core`
  (p.ej. `coverage-emit.sh`, `emit-check`, los hooks de seguridad).
- Bajar un threshold numérico de un gate Tier 1 por debajo de su mínimo definido en `castle-spec-v1.md`.

Por qué es la defensa primaria: un marketplace abierto sin esta invariante sería un vector de
ataque directo. Un skill malicioso de Tier 3 podría, una vez instalado, **neutralizar las
defensas CASTLE** del framework del usuario (coverage gate, security gate, etc.) y abrir la
puerta a cualquier otro ataque. El gate-override checker corta esa vía en la publicación.

**Comportamiento del checker en CI**: cuando detecta una violación, el check **falla** con el
error `Gate override detected in SKILL.md`, el PR de publicación **no puede ser mergeado**, y el
autor recibe **feedback específico señalando la línea exacta** del `SKILL.md` que viola la
invariante.

---

## §4 — Revocación

Si un skill es comprometido o viola las reglas **después** de publicado, debe poder retirarse
del ecosistema rápidamente. El SLA de revocación es **< 48 horas** para Tier 3.

| Tier | Quién puede revocar | Proceso | SLA |
|------|---------------------|---------|-----|
| 1 y 2 | El equipo core | `king-framework skill revoke <autor>/<skill>` (inmediato) | Inmediato |
| 3 | El equipo core, tras proceso comunitario | Issue en el repo `king-hub` + votación de **3 maintainers** | **< 48 h** |

### §4.1 — Efectos de una revocación

Al revocar un skill:

1. El **hash del package** comprometido se añade a la **CRL** (Certificate Revocation List)
   pública, publicada en `hub.kingframework.dev/crl`.
2. El skill **desaparece de los resultados de búsqueda** del marketplace.
3. Los clientes que intenten **instalar** ese package reciben un **error de revocación** y la
   instalación se aborta.

### §4.2 — La CRL (Certificate Revocation List)

- Es una lista pública de hashes de packages revocados, alojada en `hub.kingframework.dev/crl`.
- Identifica packages por **hash del package**, no por nombre de skill (una versión específica
  puede revocarse sin revocar el skill entero).
- Los clientes la consultan al instalar cuando se ejecuta:

  ```bash
  king-framework skill update --check-revocation
  ```

- Es el paso 6 de la cadena de verificación del cliente (§2.3). Un package presente en la CRL
  hace que la instalación falle con un error de revocación explícito.

---

## §5 — Integración con el Marketplace (M-56)

Este `trust-model.md` es la **política**; el backend del `king-hub` (M-56) es la
**implementación**. La relación entre ambos:

- El campo `trust_tier` del **manifest** de cada skill referencia el tier (1-4) declarado y
  verificado según las reglas de §1.
- La **UI del marketplace** muestra el **badge** correspondiente al tier (azul/verde/gris/sin badge).
- El pipeline de scanning de §3 es el que ejecuta el CI del `king-hub` para aprobar o rechazar
  cada PR de publicación.
- La CRL de §4 vive en la infraestructura del `king-hub`; el cliente la consulta vía CLI.

El tier **no es auto-declarado libremente**: el publicador declara un `trust_tier` en el
manifest, pero el pipeline **verifica** que la firma GPG, el proceso de review y el origen del
package corresponden efectivamente al tier declarado. Una declaración de Tier 1 firmada con una
clave personal (no la del equipo core) es rechazada.

---

## §6 — Resumen del flujo de publicación a instalación

1. **Autor**: empaqueta (`skill pack`), firma (`gpg --detach-sign`), verifica local (`skill verify`).
2. **Autor**: abre PR a `community/` (Tier 3), `trusted-partners/` (Tier 2) o merge en `main`
   (Tier 1) del repo `king-hub`.
3. **CI del king-hub**: corre el pipeline de scanning (§3) — Semgrep, Trivy, [Snyk], gate-override
   checker, GPG validator. Si el gate-override checker o el GPG validator fallan, el PR no se mergea.
4. **Review humano** según tier (core obligatorio para T1; spot-check 14 días T2; pares 7 días T3).
5. **Publicación**: el manifest queda con su `trust_tier` verificado y el badge correspondiente.
6. **Cliente**: `skill install` descarga package + `.asc`, verifica firma contra keyservers,
   verifica correspondencia tier↔clave, consulta CRL (con `--check-revocation`), y solo entonces
   instala mostrando el badge. Cualquier fallo aborta sin escribir nada.
7. **Post-publicación**: si se compromete, `skill revoke` añade el hash a la CRL pública en
   < 48 h (Tier 3) y el skill desaparece de búsqueda.

---

## §7 — Ver también

- `knowledge/universal/king-hub-spec.md` — spec del marketplace; define el manifest schema con el
  campo `trust_tier` y los 7 CLI commands (incluido `install`, `verify`, `publish`).
- `knowledge/universal/contributor-guide.md` — publishing guide; referencia este documento para el
  proceso de firma y los requisitos de Tier 3.
- `knowledge/universal/castle-spec-v1.md` — define los gates CASTLE y sus `BLOCKING CONDITION`s que
  la invariante de §3.1 protege.
- `knowledge/universal/deprecation-policy.md` — garantías de soporte LTS de Tier 1.
- `skills/create-skill/SKILL.md` — checklist de publicación Tier 3 que aplica este modelo.
