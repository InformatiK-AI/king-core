# Delta Spec — platform-adapters (M-97)

## ADDED Requirements

### Requirement: Knowledge `platform-adapters-roadmap.md`
El framework SHALL proveer `knowledge/universal/platform-adapters-roadmap.md` como roadmap vivo de
expansión de plataformas, escrito en español (canónico King) y SIN frontmatter. El documento MUST
listar las 11 plataformas actuales (Claude Code + 10 adapters), los criterios de priorización, la
interface `AgentAdapter`, la Feature Parity Matrix y el proceso de contribución. El documento SHALL
ser actualizable por contributors via PR contra `develop`.

### Requirement: Criterios de priorización objetivos
El roadmap SHALL definir 6 criterios objetivos y verificables (C1–C6) y la regla de priorización:
una plataforma es prioritaria si y solo si cumple ≥ 3 criterios. Cada candidato listado MUST tener
contados explícitamente sus criterios cumplidos, y los candidatos con ≥ 3 criterios MUST estar
marcados como prioritarios. La tabla de candidatos MUST incluir una columna de Complejidad de
implementación estimada, ortogonal a la prioridad.

#### Scenario: Criterios de priorización son objetivos y aplicables
- **Given** `knowledge/universal/platform-adapters-roadmap.md`
- **When** reviso la lista de candidatos
- **Then** cada candidato tiene contados sus criterios cumplidos
- **And** los candidatos con ≥ 3 criterios están marcados como prioritarios
- **And** la tabla incluye Complejidad de implementación estimada

### Requirement: Interface `AgentAdapter` con 7 métodos
El roadmap SHALL documentar la interface `AgentAdapter` con exactamente 7 métodos: `Detect`,
`Install`, `ConfigureSkills`, `ConfigureHooks`, `ConfigureMCP`, `Verify` y un séptimo método
adicional (`Capabilities`). Cada método MUST documentar su firma (tipos de input y output) y la
condición de error (cuándo retorna `error`, o que no retorna error). El documento MUST establecer el
invariante de que los adapters SOLO escriben configuración y NUNCA ejecutan código arbitrario.

#### Scenario: Interface AgentAdapter tiene contrato completo
- **Given** la sección de Interface `AgentAdapter` en el roadmap
- **When** cuento los métodos documentados
- **Then** hay exactamente 7 métodos: `Detect`, `Install`, `ConfigureSkills`, `ConfigureHooks`, `ConfigureMCP`, `Verify` y uno adicional (`Capabilities`)
- **And** cada método tiene firma (tipos de input y output) documentada
- **And** la condición de error de cada método está especificada

#### Scenario: Los adapters solo escriben configuración
- **Given** la documentación del invariante de seguridad de los adapters
- **When** reviso el contrato de `Install`, `ConfigureSkills`, `ConfigureHooks` y `ConfigureMCP`
- **Then** cada método describe escritura de configuración nativa declarativa
- **And** se establece explícitamente que ningún adapter ejecuta código arbitrario ni levanta binarios

### Requirement: Feature Parity Matrix de 11 plataformas
El roadmap SHALL incluir una Feature Parity Matrix con al menos 11 columnas (una por plataforma
actual) y al menos 5 features evaluadas. Cada celda MUST usar uno de tres niveles: `✓ full`,
`✓ partial` o `✗`. Claude Code MUST aparecer como `✓ full` en todas las features (implementación de
referencia). La matriz SHALL describir el comportamiento ante una feature no soportada: `Install`
MUST emitir un warning claro indicando qué quedó fuera y cómo mitigarlo, y MUST continuar con las
features soportadas (degradación elegante).

#### Scenario: Feature Parity Matrix cubre las 11 plataformas actuales
- **Given** la sección de Feature Parity Matrix
- **When** cuento las columnas de plataformas
- **Then** hay al menos 11 columnas (una por plataforma actual)
- **And** hay al menos 5 features evaluadas
- **And** Claude Code aparece como `✓ full` en todas las features

#### Scenario: Warning ante feature no soportada
- **Given** un adapter cuya `Capabilities()` reporta una feature como `partial` o `none`
- **When** se ejecuta `Install`
- **Then** emite un warning claro indicando qué feature quedó fuera y cómo mitigarlo
- **And** continúa la instalación con las features soportadas sin abortar

### Requirement: Soporte de `KING_LANG` por plataforma
El roadmap SHALL documentar que el adapter respeta `KING_LANG` donde la plataforma lo permita: si la
plataforma soporta selección de idioma de instrucciones, el adapter MUST escribir la variante de
idioma indicada y reportar `KING_LANG: full` en `Capabilities()`. Donde la plataforma solo admita un
set de instrucciones, el adapter SHALL escribir el canónico español, reportar `KING_LANG: none` y
emitir el warning correspondiente. `KING_LANG` MUST NOT alterar el comportamiento de skills ni de
gates CASTLE — solo el idioma del texto.

#### Scenario: Adapter respeta KING_LANG donde la plataforma lo permite
- **Given** una plataforma cuyo `Capabilities()` reporta `KING_LANG: full`
- **When** se ejecuta `Install` con `KING_LANG=en`
- **Then** el adapter escribe las instrucciones en la variante de idioma `en`
- **And** el comportamiento de skills y gates CASTLE permanece sin cambios

### Requirement: Proceso de contribución de adapters
El roadmap SHALL documentar el proceso de contribución de un adapter en pasos verificables: Issue con
template "New Platform Adapter" enumerando criterios cumplidos, decisión del core team según
priorización, implementación de los 7 métodos de `AgentAdapter`, PR contra `develop` con test de
detección + instalación + verificación, code review por ≥ 1 maintainer con conocimiento de la
plataforma, y merge a `develop` con promoción de la plataforma a la lista actual y una columna nueva
en la Feature Parity Matrix.

> Set Gherkin completo: M13 §7 (Feature: Roadmap de plataformas adicionales).
