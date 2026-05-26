# Framework de Decisión

Guía para determinar cuándo un agente debe decidir autónomamente, escalar, o colaborar.

---

## Principios generales

1. **Autonomía con responsabilidad**: Decide solo cuando tienes información suficiente
2. **Escalar temprano**: Ante duda, es mejor preguntar que asumir
3. **Colaborar proactivamente**: Involucra a otros agentes cuando su expertise ayuda

---

## Cuándo decidir autónomamente

| Condición | Acción |
|-----------|--------|
| Sigue patrones establecidos del proyecto | Decide |
| Impacto limitado (1-2 componentes) | Decide |
| Decisión fácilmente reversible | Decide |
| Best practice de industria clara | Decide |
| Ya hay consenso previo documentado | Decide |

---

## Cuándo escalar

| Situación | A quién |
|-----------|---------|
| Decisión afecta arquitectura | @architect o usuario |
| Impacto en múltiples módulos/equipos | Usuario |
| Requisito de seguridad o compliance | @security |
| Cambio que afecta infraestructura | @devops |
| Issue ambiguo o incompleto | Usuario |
| No puedo cumplir un requisito | Usuario |
| Decisión irreversible o de alto costo | Usuario |

---

## Cuándo colaborar con otros agentes

| Agente | Involucrar cuando |
|--------|-------------------|
| @architect | Diseño cross-module, nuevas dependencias, patrones |
| @developer | Validar feasibility de implementación |
| @qa | Definir estrategia de testing, verificaciones |
| @security | Código maneja datos sensibles, auth, crypto |
| @devops | Cambio afecta deployment o infraestructura |
| @api | APIs públicas o contratos entre servicios |

---

## Formato de escalamiento

```markdown
## Necesito validación

**Contexto:** {Breve descripción de la situación}

**Opciones identificadas:**
1. {Opción A}: {descripción}
2. {Opción B}: {descripción}

**Mi recomendación:** {Opción X} porque {razón}

**Por qué escalo:** {razón de no decidir autónomamente}
```

---

## Niveles de reversibilidad

| Nivel | Descripción | Ejemplos |
|-------|-------------|----------|
| Alta | Fácil de deshacer, bajo costo | Naming, estructura interna |
| Media | Requiere esfuerzo, costo moderado | Nueva dependencia, refactor |
| Baja | Difícil/costoso de revertir | Cambio de BD, API pública |
