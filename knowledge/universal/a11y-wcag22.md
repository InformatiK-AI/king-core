# WCAG 2.2 AA — Accessibility Gate (CASTLE S Sub-Score)

## Qué es WCAG 2.2 AA

WCAG (Web Content Accessibility Guidelines) 2.2 AA es el estándar internacional de accesibilidad web. El nivel AA es el umbral legal en muchos países (EU Accessibility Act, ADA en EE.UU., LPDP en Latinoamérica). En el framework CASTLE, las violaciones de accesibilidad impactan directamente el **S sub-score** (Security/Quality layer).

Formula del S sub-score en CASTLE:
```
score = max(0, 100 - (critical_count * 25) - (serious_count * 10))
```

---

## Los 4 Principios POUR

| Principio | Descripción | Criterios clave |
|-----------|-------------|-----------------|
| **Perceivable** | La información debe ser presentable de formas que los usuarios puedan percibir | 1.1.1 alt text, 1.4.3 contrast |
| **Operable** | Los componentes de la UI deben ser operables por todos | 2.1.1 keyboard, 2.4.6 headings |
| **Understandable** | La información y operación de la UI debe ser comprensible | 3.1.1 language, 3.3.1 error ID |
| **Robust** | El contenido debe ser interpretable por tecnologías de asistencia | 4.1.2 name/role/value |

---

## Criterios más comunes que falla un proyecto web

| Criterio | Nivel | Descripción | Violación típica |
|----------|-------|-------------|------------------|
| **1.1.1** Non-text Content | A | Todo contenido no textual tiene alternativa textual | `<img>` sin `alt` |
| **1.4.3** Contrast (Minimum) | AA | Ratio de contraste mínimo 4.5:1 (normal) / 3:1 (large) | Texto gris sobre blanco |
| **2.4.6** Headings and Labels | AA | Headings y labels son descriptivos | Salto h1→h3, botones sin nombre |
| **4.1.2** Name, Role, Value | A | Todos los componentes de UI tienen nombre, rol y valor accesibles | `<div onClick>` sin `role` |

---

## Schema de `.king/accessibility.yaml`

```yaml
standard: wcag_2_2_aa
enforcement: block   # block | warn
exceptions:
  - element: "img[src=legacy-logo.png]"
    wcag: "1.1.1"
    approved_by: "arch-team"
    expires: "2025-12-31"
    reason: "Legacy asset pending redesign Q4 2025"
```

El campo `exceptions` permite registrar falsos positivos o deudas técnicas aprobadas formalmente. Cada excepción **requiere**:
- `approved_by`: nombre del responsable técnico que aprobó la excepción
- `expires`: fecha de expiración (formato ISO 8601: `YYYY-MM-DD`)
- `reason`: justificación técnica o de negocio

---

## Bypass auditado: cómo registrar excepciones

Una excepción justificada NO es ignorar el problema — es documentar que el equipo lo conoce, lo acepta temporalmente, y tiene un plan de resolución.

**Proceso correcto**:
1. Ejecutar `/a11y-audit` y verificar la violation
2. Confirmar que es un falso positivo O que existe un plan de fix con fecha
3. Agregar la excepción en `.king/accessibility.yaml` con `approved_by` + `expires` + `reason`
4. Registrar en el commit message: `fix(a11y): document approved exception for {element} until {expires}`
5. El campo `expires` es revisado automáticamente: una excepción vencida vuelve a ser tratada como violation activa

**Anti-patrón**: Agregar `enforcement: warn` para silenciar todas las violations. Esto anula el gate y el CASTLE S sub-score pierde significado.

---

## Recursos

- WCAG 2.2: https://www.w3.org/TR/WCAG22/
- Contrast checker: https://webaim.org/resources/contrastchecker/
- Skill: `skills/a11y-audit/SKILL.md`
- Skill: `skills/a11y-fix/SKILL.md`
