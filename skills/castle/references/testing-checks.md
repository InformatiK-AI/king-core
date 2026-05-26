# Capa T — Testing Checks

## T1: Strategy Validation
**Severidad**: WARNING
**Descripción**: Debe existir una estrategia de testing adecuada para los cambios.

### Checks:
- ¿Los cambios tienen tests asociados?
- ¿Los tests cubren los acceptance criteria del issue?
- ¿Se testean tanto happy paths como edge cases?
- ¿Se testean los error paths?

### Cómo verificar:
1. Listar ACs del issue/feature
2. Para cada AC, verificar que existe un test que lo valida
3. Verificar que hay tests de error handling

---

## T2: Coverage Trend
**Severidad**: WARNING
**Descripción**: La cobertura de tests no debe disminuir con cambios nuevos.

### Checks:
- Código nuevo tiene tests correspondientes
- No se eliminaron tests existentes sin justificación
- Tests de regresión existen para bugs corregidos

### Nota para King:
Evaluar cobertura de tests según el framework de testing configurado en el proyecto (ver CLAUDE.md).

### Cómo verificar:
1. Para cambios en pipeline (do* functions): verificar con test projects embebidos
2. Para cambios en servidor: verificar con curl/health endpoint
3. Documentar cualquier gap de cobertura

---

## T3: Critical Path Coverage
**Severidad**: BLOQUEANTE
**Descripción**: Los flujos críticos deben tener cobertura de testing.

### Flujos críticos de King:
1. Pipeline completo (6 fases) — verificable con test projects
2. callClaude() — respuesta exitosa y manejo de error
3. Proxy /api/claude — request/response cycle
4. Rate limiting — verificar que funciona
5. Health check — verificar que reporta correctamente

### Cómo verificar:
1. Para cada flujo crítico afectado por el cambio, verificar que hay forma de testear
2. Si no hay test automatizado, documentar procedimiento manual

---

## T4: Test Quality
**Severidad**: WARNING
**Descripción**: Los tests deben ser de calidad — no solo existir.

### Checks:
- Tests verifican comportamiento, no implementación
- Tests son determinísticos (no dependen de timing, red, etc.)
- Tests tienen nombres descriptivos
- Tests son independientes entre sí
- Tests no tienen lógica condicional interna

### Cómo verificar:
1. Revisar tests nuevos/modificados
2. Verificar que assertions son significativas
3. Verificar que tests pueden ejecutarse de forma aislada
