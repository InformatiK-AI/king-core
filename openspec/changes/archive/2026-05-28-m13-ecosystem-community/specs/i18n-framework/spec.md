# Delta Spec — i18n-framework (M-96)

## ADDED Requirements

### Requirement: Knowledge doc `i18n-framework.md`
El framework SHALL publicar `knowledge/universal/i18n-framework.md` definiendo la estrategia de
internacionalización del framework mismo (no de proyectos usuario). El documento MUST cubrir: idiomas
target, estructura de archivos localizados, proceso de traducción, selección en runtime, targets de
cobertura por versión, tooling `extract`/`verify` y gestión de divergencias. El idioma canónico del
documento MUST ser español.

#### Scenario: Idiomas target están enumerados con prioridad
- **Given** `knowledge/universal/i18n-framework.md`
- **When** reviso la sección de idiomas target
- **Then** están los 5 idiomas: `es` (canónico), `en`, `pt`, `fr`, `ja`
- **And** cada idioma tiene una prioridad explícita y un mercado objetivo
- **And** el español está marcado como idioma primario / canónico

### Requirement: Estructura de archivos localizados
El documento SHALL especificar el formato de archivos localizados. El archivo canónico (`SKILL.md`
sin sufijo) MUST ser siempre español. Las traducciones MUST usar el sufijo `<base>.<lang>.<ext>`
(ej. `SKILL.en.md`, `SKILL.pt.md`, `SKILL.fr.md`) y vivir en el mismo directorio que su canónico.
La regla del canónico español como **fuente de verdad** MUST ser explícita.

#### Scenario: Estructura de archivos localizados es clara y consistente
- **Given** `knowledge/universal/i18n-framework.md`
- **When** reviso la sección de estructura de archivos
- **Then** el formato `SKILL.md` (canónico español), `SKILL.en.md`, `SKILL.pt.md`, `SKILL.fr.md` está documentado con ejemplos de árbol de directorios
- **And** la regla del canónico español como fuente de verdad está explícita

### Requirement: Proceso de traducción y revisión
El documento SHALL definir el proceso de traducción en etapas. El contenido nuevo MUST crearse primero
en español. Un canónico SHALL abrirse a traducción solo cuando es estable (`api_version >= 1.0.0` y no
`draft`). Toda traducción MUST ser revisada por un native speaker, con 2 approvals para `en`/`pt` y 1
para `fr`/`ja`. Las traducciones de `SKILL.md` MUST NOT cambiar la semántica de BLOCKING CONDITIONS ni
REQUIRED OUTPUTS. Ante duda en un BLOCKING CONDITION, el traductor SHALL mantener el texto original en español.

#### Scenario: Contenido en draft no se abre a traducción
- **Given** un skill con `api_version 0.9.0` marcado como `draft`
- **When** un contributor intenta enviar una traducción
- **Then** el proceso documentado indica que el canónico no es elegible para traducción aún
- **And** la traducción se rechaza hasta que el canónico alcance `api_version >= 1.0.0` y deje de ser draft

#### Scenario: Duda en BLOCKING CONDITION mantiene el original
- **Given** un contributor traduciendo un `SKILL.md` con un BLOCKING CONDITION ambiguo en el idioma target
- **When** consulta la regla de gestión de duda en `i18n-framework.md`
- **Then** la política indica mantener el texto original en español en el archivo traducido
- **And** la semántica del BLOCKING CONDITION queda preservada sin relajarse

### Requirement: Selección de idioma en runtime vía `KING_LANG`
El framework SHALL resolver el archivo a cargar según la variable de entorno `KING_LANG` (default `es`).
Cuando `KING_LANG=<lang>` y existe el archivo traducido, el runtime MUST cargar la traducción. Cuando la
traducción no existe, o el idioma no está soportado, el runtime MUST hacer fallback silencioso al canónico
español. El framework MUST NOT fallar por ausencia de traducción.

#### Scenario: Carga traducción cuando existe
- **Given** `KING_LANG=en` y un skill con `SKILL.en.md` presente
- **When** el runtime resuelve el archivo del skill
- **Then** carga `SKILL.en.md`

#### Scenario: Fallback al canónico cuando la traducción falta
- **Given** `KING_LANG=en` y un skill sin `SKILL.en.md`
- **When** el runtime resuelve el archivo del skill
- **Then** carga el canónico `SKILL.md` en español
- **And** no emite error por la traducción ausente

### Requirement: Targets de cobertura por versión
El documento SHALL definir targets de cobertura de traducción por versión, **porcentuales y por idioma**,
para v2.5, v3.0, v3.5 y v4.0. King v4.0 MUST tener target de 100% en todos los idiomas target.

#### Scenario: Targets de cobertura por versión están definidos
- **Given** la sección de targets en `i18n-framework.md`
- **When** reviso los hitos de versión
- **Then** hay targets definidos para v2.5, v3.0, v3.5, y v4.0
- **And** los targets son porcentuales y por idioma
- **And** King v4.0 tiene target de 100% en todos los idiomas

### Requirement: Tooling de traducción asistida (`extract` / `verify`)
El documento SHALL especificar dos subcomandos del CLI bajo `king-framework i18n`. `extract <skill> --lang <code>`
SHALL generar `SKILL.<lang>.md` con el contenido en español y marcadores `{{TRANSLATE}}` por sección, registrando
la `api_version` del canónico de origen. `verify <skill> --lang <code>` SHALL verificar que la traducción tiene
todas las secciones del canónico y reportar secciones faltantes o desactualizadas. `verify` MUST NOT modificar
ningún archivo.

#### Scenario: extract genera esqueleto con marcadores
- **Given** un skill canónico estable `SKILL.md`
- **When** ejecuto `king-framework i18n extract mi-skill --lang en`
- **Then** genera `SKILL.en.md` con el contenido en español y un marcador `{{TRANSLATE}}` por sección
- **And** registra la `api_version` del canónico desde el que se extrajo

#### Scenario: verify detecta secciones desactualizadas sin modificar archivos
- **Given** un `SKILL.en.md` traducido de un `SKILL.md` v1.0.0
- **And** el `SKILL.md` canónico fue actualizado a v1.1.0 con una nueva sección
- **When** ejecuto `king-framework i18n verify mi-skill --lang en`
- **Then** el comando reporta que `SKILL.en.md` está desactualizado
- **And** muestra qué secciones del canónico no están presentes en la traducción
- **And** no modifica ningún archivo

### Requirement: Gestión de divergencias del canónico
El documento SHALL definir el flujo de divergencias. Un bump MINOR o MAJOR del `api_version` del canónico
SHALL marcar sus traducciones como `outdated` en king-hub (si están publicadas). El contributor de cada
traducción afectada MUST recibir notificación vía GitHub Issue automático con el diff de los cambios a
incorporar. Un bump PATCH MUST NOT disparar el flujo. Ante conflicto irresoluble, el canónico español
SHALL ser la fuente de verdad.

#### Scenario: Bump MINOR marca traducciones como outdated y notifica
- **Given** un canónico `SKILL.md` con traducciones publicadas en king-hub
- **When** el canónico sube de `api_version` 1.1.0 a 1.2.0 (MINOR)
- **Then** las traducciones se marcan como `outdated` en king-hub
- **And** cada contributor de traducción recibe un GitHub Issue automático con el diff de los cambios

#### Scenario: Bump PATCH no dispara el flujo de divergencias
- **Given** un canónico `SKILL.md` con traducciones publicadas
- **When** el canónico sube de `api_version` 1.2.0 a 1.2.1 (PATCH, solo typos)
- **Then** las traducciones NO se marcan como `outdated`
- **And** no se genera ningún GitHub Issue de divergencia

> Set Gherkin de referencia: M13 §7 (Feature: i18n del framework King), líneas 1444-1463.
