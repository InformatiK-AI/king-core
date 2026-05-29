# Delta Spec — skill-certification (M-60, parte curriculum · Change A)

Esta capability cubre **únicamente** el curriculum de certificación dentro de `king-core`.
El skill `/certification` y su comando viven en king-content (Change B) y NO forman parte de
este delta.

Fuente de verdad: `mejora/planes-detallados/M13-ecosystem-community-distribution.md`
(§ M-60 líneas 367-505, acceptance Gherkin §7 líneas 1331-1355).

## ADDED Requirements

### Requirement: Knowledge `certification-curriculum.md`

El framework SHALL proveer `knowledge/universal/certification-curriculum.md` como fuente de
verdad del programa de certificación. El documento MUST estar en español canónico, sin
frontmatter, con encabezado `#` y secciones `##`. MUST documentar las tres credenciales
KFCD, KFCA y KFCSA con su nivel, requisito previo, formato de evaluación, badge (LinkedIn +
Credly) y validez.

#### Scenario: Las tres credenciales están documentadas con sus atributos
- **Given** el archivo `knowledge/universal/certification-curriculum.md`
- **When** reviso la sección de certificaciones
- **Then** existen KFCD, KFCA y KFCSA
- **And** cada una declara nivel, requisito previo, formato de evaluación, badge y validez

### Requirement: Temario KFCD con 8 módulos que suman 100%

El curriculum SHALL definir exactamente **8 módulos** para el KFCD cuyos pesos SHALL sumar
**100%** (10 + 10 + 15 + 15 + 15 + 10 + 15 + 10). Cada skill core del framework (genesis,
build, release, deploy, audit, plan, etc.) MUST aparecer referenciado en al menos un módulo.
El documento SHALL incluir una tabla de trazabilidad skill core → módulo que haga auditable
esa regla de cobertura.

#### Scenario: KFCD curriculum cubre todo el framework
- **Given** el archivo `knowledge/universal/certification-curriculum.md`
- **When** cuento los módulos del KFCD
- **Then** hay exactamente 8 módulos con pesos que suman 100%
- **And** cada skill core del framework (genesis, build, release, deploy, audit, etc.) aparece en al menos un módulo

#### Scenario: La tabla de trazabilidad no deja skills core huérfanos
- **Given** la tabla de trazabilidad skill core → módulo
- **When** verifico cada skill core invocable de king-core
- **Then** cada uno tiene asignado al menos un módulo
- **And** los skills auxiliares internos (no invocables) quedan explícitamente excluidos

### Requirement: Temario KFCA con 4 módulos adicionales al 25%

El curriculum SHALL definir **4 módulos KFCA** (A1 Arquitectura, A2 Skills Avanzados,
A3 Enterprise/Compliance, A4 Governance), cada uno con peso **25%**, que SHALL sumar 100%.
El KFCA MUST declarar al KFCD como prerequisito y los módulos NO deben repetir el temario
base, sino profundizarlo.

#### Scenario: KFCA tiene 4 módulos de 25% sobre KFCD
- **Given** la sección KFCA del curriculum
- **When** cuento los módulos adicionales
- **Then** hay exactamente 4 módulos
- **And** cada uno pesa 25% y la suma es 100%
- **And** el KFCD figura como requisito previo del KFCA

### Requirement: KFCSA — criterios de portfolio con criterios obligatorios

El curriculum SHALL definir la evaluación KFCSA como review de un portfolio de **3 skills**
publicados en el hub (Tier 3 mínimo). MUST especificar 6 criterios de review por skill y un
umbral de **score ≥ 4/6** por skill. Los criterios **3 (Testing), 4 (Documentation) y
5 (Trust Model compliance)** MUST estar marcados como obligatorios: un skill que falle
cualquiera de ellos NO aprueba aunque alcance 4 puntos. El proceso de portfolio review por
el equipo core MUST estar documentado.

#### Scenario: KFCSA requiere portfolio de 3 skills publicados
- **Given** un developer con 3 skills Tier 3 publicados en el hub
- **When** consulta los criterios de KFCSA en `certification-curriculum.md`
- **Then** los criterios especifican claramente que se requieren 3 skills con score >= 4/6
- **And** los criterios 3 (testing), 4 (documentation) y 5 (trust model compliance) son marcados como obligatorios
- **And** el proceso de portfolio review por el equipo core está documentado

#### Scenario: Un skill sin un criterio obligatorio no aprueba
- **Given** un skill del portfolio con score 4/6 pero sin los 5 scenarios Gherkin (criterio 3)
- **When** se aplica el umbral de aprobación KFCSA
- **Then** el skill NO aprueba por ausencia de un criterio obligatorio
- **And** el portfolio completo queda invalidado si ese skill no se reemplaza

### Requirement: Contrato de insumo para el skill `/certification`

El curriculum SHALL servir como única fuente de temario para el skill `/certification`
(king-content, Change B): MUST documentar las fases que el skill consume (Diagnóstico →
Study Plan → Mock Exam → Review → Portfolio Prep) sin implementarlas. El curriculum SHALL ser
actualizable de forma independiente del skill, de modo que la evolución de un skill del
framework se refleje actualizando la tabla de trazabilidad sin tocar `/certification`.

#### Scenario: El curriculum define el contrato del study plan
- **Given** la sección de integración con `/certification`
- **When** reviso las fases declaradas
- **Then** incluye Diagnóstico, Study Plan, Mock Exam, Review y Portfolio Prep
- **And** especifica que el Study Plan ordena módulos por prioridad, estima tiempo por módulo y reporta un porcentaje de preparación
- **And** aclara que el skill se entrega en king-content (Change B), no en este Change A

### Requirement: Codificación UTF-8 sin BOM

El documento `certification-curriculum.md` MUST escribirse en UTF-8 sin BOM, consistente con
la convención de king-core (`.gitattributes` eol=lf, fix de BOM v1.9.4).

#### Scenario: El archivo no contiene BOM
- **Given** el archivo `knowledge/universal/certification-curriculum.md`
- **When** inspecciono los primeros bytes
- **Then** no hay marca de orden de bytes (EF BB BF) al inicio del archivo

> Set Gherkin completo de referencia: M13 §7 (Feature: Skill Certification Program KFCD/KFCA/KFCSA, líneas 1331-1355).
> El escenario "/certification genera study plan personalizado" se satisface en el Change B (king-content); aquí solo se fija su contrato de insumo.
