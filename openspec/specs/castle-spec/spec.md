# Delta Spec — castle-spec (M-21)

## ADDED Requirements

### Requirement: Knowledge `castle-spec-v1.md` con las 6 capas y gates de veto

El framework SHALL proveer `knowledge/universal/castle-spec-v1.md` que define las 6 capas CASTLE
(**C** Code Quality, **A** Architecture, **S** Security, **T** Testing, **L** Logging &
Observability, **E** Excellence). Cada capa MUST especificar **al menos 4 métricas con threshold
numérico** y exactamente **un gate de veto** con la condición binaria que lo activa. Las condiciones
de veto MUST ser binarias (se activan o no, sin zona gris) y SHALL ser verificables en CI. El
documento SHALL escribirse en español canónico, en UTF-8 sin BOM y sin frontmatter.

#### Scenario: Las 6 capas tienen thresholds objetivos y gates de veto
- **Given** el archivo `knowledge/universal/castle-spec-v1.md`
- **When** reviso cada una de las 6 capas (C, A, S, T, L, E)
- **Then** cada capa tiene al menos 4 métricas con threshold numérico
- **And** cada capa especifica su gate de veto con la condición exacta que lo activa
- **And** las condiciones de veto son binarias (se activa o no se activa, sin grises)

### Requirement: Contratos bilaterales con formato y ejemplos

El documento SHALL definir el concepto de **contrato bilateral CASTLE** —acuerdo entre dos
componentes que declara qué CASTLE layers cada uno **garantiza** y cuáles **requiere** del otro—,
con un formato explícito (`Garantiza` / `Requiere` / `Violación`) y **al menos 2 ejemplos** de
contratos concretos. La regla de violación de cada contrato MUST ser binaria (bloquea integración
o no la bloquea).

#### Scenario: El formato de contrato bilateral es explícito y ejemplificado
- **Given** la sección de Contratos Bilaterales en `castle-spec-v1.md`
- **When** reviso el formato y los ejemplos
- **Then** existe un formato con los campos `Garantiza`, `Requiere` y `Violación`
- **And** hay al menos 2 ejemplos de contratos entre componentes
- **And** la condición de `Violación` de cada ejemplo es binaria (bloquea integración o no)

### Requirement: Mappings de compliance SOC2 / ISO 27001:2022 / NIST 800-53

El documento SHALL incluir tablas de mapping hacia tres estándares de compliance, con **al menos 5
controles mapeados por estándar**. Cada fila MUST contener: **control ID**, **CASTLE Layer** que lo
cubre y el **gate específico** que produce la evidencia. El documento MUST incluir un **disclaimer
explícito** indicando que los mappings son orientativos y NO constituyen una certificación regulada,
asesoría legal ni de compliance.

#### Scenario: Mappings SOC2/ISO/NIST son verificables
- **Given** las tablas de mappings en `castle-spec-v1.md`
- **When** cuento los controles mapeados por estándar
- **Then** SOC2 Type II tiene al menos 5 controles mapeados con la capa CASTLE y el gate específico
- **And** ISO 27001:2022 tiene al menos 5 controles mapeados
- **And** NIST 800-53 tiene al menos 5 controles mapeados
- **And** cada fila de mapping tiene: control ID, CASTLE Layer y gate específico

#### Scenario: Disclaimer legal de los mappings presente
- **Given** la sección de Mappings de Compliance en `castle-spec-v1.md`
- **When** reviso el texto introductorio de los mappings
- **Then** existe un disclaimer explícito que indica que los mappings son orientativos
- **And** el disclaimer aclara que pasar CASTLE no equivale a una certificación SOC2/ISO/NIST regulada

### Requirement: Certificaciones CASTLE (reviewer y proyecto)

El documento SHALL definir dos certificaciones: **CASTLE Certified Reviewer** (personas, requisito
de examinar ≥ 3 proyectos con reports verificables) y **CASTLE-Compliant Project** (proyectos,
requisito de CI que verifica las 6 capas automáticamente). La certificación de proyecto MUST ser un
estado vivo: SHALL revocarse automáticamente si una gate de veto falla en producción.

#### Scenario: Las dos certificaciones están definidas con su requisito
- **Given** la sección de Certificaciones CASTLE en `castle-spec-v1.md`
- **When** reviso las certificaciones
- **Then** CASTLE Certified Reviewer especifica el requisito de examinar al menos 3 proyectos
- **And** CASTLE-Compliant Project especifica CI que verifica las 6 capas automáticamente
- **And** la certificación de proyecto se revoca automáticamente si una gate falla en producción

### Requirement: Governance formal del estándar

El documento SHALL definir la governance del estándar CASTLE Spec como proyecto open source bajo
licencia CC BY 4.0, gobernado por un Technical Committee. El proceso de cambios MUST exigir: una RFC
pública, un **comment period de 60 días**, **aprobación de 2/3** (supermayoría) del Technical
Committee, y un bump de versión. El documento SHALL garantizar **explícitamente** la
retrocompatibilidad por MAJOR version: un proyecto v1.0-compliant SHALL pasar la auditoría de
cualquier spec con el mismo MAJOR, y los cambios MINOR MUST solo añadir gates opcionales.

#### Scenario: El estándar tiene governance formal
- **Given** la sección de Governance en `castle-spec-v1.md`
- **When** reviso el proceso de cambios
- **Then** está documentado el período de 60 días de comment period
- **And** la regla de 2/3 del Technical Committee está especificada
- **And** la retrocompatibilidad por MAJOR version está garantizada explícitamente

#### Scenario: La política de versionado limita los cambios MINOR
- **Given** la subsección de retrocompatibilidad y versionado en `castle-spec-v1.md`
- **When** reviso qué puede cambiar en un bump MINOR frente a un MAJOR
- **Then** los cambios MINOR solo añaden gates opcionales (SOFT u opt-in) sin endurecer thresholds existentes
- **And** únicamente un cambio MAJOR puede endurecer thresholds o añadir gates de veto nuevos

### Requirement: Implementación de referencia identificada

El documento SHALL identificar a **King Framework (v2.0+)** como la implementación de referencia del
estándar y SHALL incluir una tabla de implementaciones de referencia abierta a contribuciones
externas. La spec MUST permanecer independiente de framework, lenguaje y plataforma.

#### Scenario: King se declara implementación de referencia
- **Given** la sección de Implementaciones de Referencia en `castle-spec-v1.md`
- **When** reviso la tabla de implementaciones
- **Then** King Framework figura como implementación de referencia con status v2.0+
- **And** la tabla deja explícito que se aceptan contribuciones de otras implementaciones
