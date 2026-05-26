# Capa A — Architecture Checks

## A1: ADR Compliance
**Severidad**: WARNING
**Descripción**: El código debe seguir las decisiones arquitectónicas documentadas.

### Checks:
- La arquitectura `{Client} → {Proxy/Server} → {External Service}` se mantiene según los ADRs del proyecto
- No se agregan capas intermedias sin ADR
- La estructura de módulos/archivos es coherente con la arquitectura documentada
- Las funciones están en las secciones correctas según la tabla de líneas

### Cómo verificar:
1. Verificar que nuevos flujos de datos siguen la arquitectura establecida en los ADRs del proyecto
2. Verificar que los módulos mantienen su organización según la arquitectura del proyecto
3. Si se propone un cambio arquitectónico, debe documentarse como ADR

---

## A2: Dependency Direction
**Severidad**: BLOQUEANTE
**Descripción**: Las dependencias deben fluir en una sola dirección: UI → Logic → Data.

### Checks:
- El frontend no accede directamente al servicio externo (siempre via la capa de servidor/proxy del proyecto)
- Los módulos del servidor no importan código del módulo cliente
- Las funciones de pipeline (según las convenciones de nombrado del proyecto) no acceden directamente al DOM
- Las funciones puras (según las convenciones de nombrado del proyecto) no tienen side effects

### Cómo verificar:
1. Buscar importaciones/referencias cruzadas entre los módulos cliente y servidor del proyecto
2. Verificar que las funciones de pipeline solo llaman a las funciones de acceso al servicio externo y no manipulan estado UI directamente
3. Verificar que las funciones puras del proyecto son puras (sin side effects)

---

## A3: Pattern Consistency
**Severidad**: WARNING
**Descripción**: El código nuevo debe seguir los patrones establecidos.

### Checks:
- Las nuevas funciones respetan las convenciones de nombrado del proyecto (prefijos, sufijos u otras convenciones documentadas)
- Los nuevos módulos siguen la estructura de carpetas y organización establecida
- El estilo de código es consistente con el resto del proyecto

### Cómo verificar:
1. Revisar nombres de funciones nuevas contra las convenciones de nombrado del proyecto
2. Verificar que la organización de archivos sigue los patrones existentes

---

## A4: Coupling Analysis
**Severidad**: WARNING
**Descripción**: Los módulos no deben tener acoplamiento excesivo.

### Checks:
- Funciones con más de 5 parámetros → señal de acoplamiento
- Funciones que acceden a más de 3 estados globales → señal de acoplamiento
- Cambios en una función que requieren cambios en >3 lugares → alto coupling
- Componentes UI que mezclan lógica de negocio y presentación

### Cómo verificar:
1. Contar parámetros de funciones nuevas/modificadas
2. Contar referencias a estado global (useState)
3. Evaluar si la función tiene responsabilidad única

---

## A5: Token Budget Compliance
**Severidad**: WARNING (nunca BLOQUEANTE)
**Owner**: @architect
**Descripción**: Los skills, agents y rules deben mantener su token budget dentro de los umbrales definidos. Un exceso no bloquea el flujo, pero es señal de que el componente debe modularizarse.

### Checks:
- Ningún skill entry supera el umbral de warning configurado (default: 2000 tokens)
- Ningún agent supera el umbral de warning (default: 1500 tokens)
- Ningún rule supera el umbral de warning (default: 500 tokens)
- LOAD-INDEX.md refleja los tokens actuales de todos los componentes del proyecto

### Cómo verificar:
→ Ejecutar `rules/token-budget-gate.md` y reportar el resultado en este check.
→ Si LOAD-INDEX.md no existe o está desactualizado: marcar A5 como WARN (no FAIL).
→ Si el gate retorna PASS: marcar A5 como PASS.
→ Si el gate retorna WARN o FAIL: marcar A5 como WARN (la severidad de A5 es siempre WARNING).
→ Un WARN en A5 contribuye a veredicto CASTLE CONDITIONAL — nunca a BREACHED.

Thresholds configurables en `.king/token-budget.yaml` (ver template en `templates/token-budget.yaml`).
