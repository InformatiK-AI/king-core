# Checklists Comunes

Checklists estándar aplicables a todos los agentes del framework.

---

## Antes de empezar cualquier tarea

- [ ] Leí y entendí el request completo
- [ ] Identifiqué el objetivo real (no solo la tarea aparente)
- [ ] Conozco las restricciones (explícitas e implícitas)
- [ ] Tengo acceso a los archivos/recursos necesarios
- [ ] Sé qué agentes pueden ayudarme si lo necesito

## Pre-checks de Validación (OBLIGATORIO)

> Antes de ejecutar cualquier operación, verificar pre-checks del skill.
> Referencia: `validation/VALIDATION.md`

- [ ] Pre-checks del skill ejecutados (ver VALIDATION.md → Checklist por Skill)
- [ ] Checks BLOQUEANTES pasaron (si fallan → NO continuar)
- [ ] Checks WARNING revisados (si fallan → preguntar si continuar)
- [ ] Security Gate configurado (si el skill lo requiere)

---

## Durante la ejecución

- [ ] Estoy siguiendo el protocolo RADAR
- [ ] Documenté mis decisiones y el razonamiento
- [ ] Verifico cada paso antes de continuar
- [ ] Mantengo el trabajo en estado recoverable
- [ ] No me desvío del scope original

---

## Antes de completar

- [ ] Logré el objetivo definido
- [ ] Todas las verificaciones relevantes pasaron
- [ ] Documenté decisiones y trade-offs
- [ ] Comuniqué resultado claramente
- [ ] Sugerí próximos pasos

---

## Validación final

- [ ] Mi trabajo es consistente con el proyecto existente
- [ ] No introduje deuda técnica innecesaria
- [ ] No comprometí seguridad
- [ ] El resultado es mantenible
- [ ] Otro agente podría continuar mi trabajo sin contexto adicional

---

## Checklist de lectura (Read)

- [ ] Leí el issue/request completo
- [ ] Entiendo el objetivo, no solo la tarea
- [ ] Conozco las restricciones
- [ ] Revisé archivos relacionados
- [ ] Identifiqué dependencias

---

## Checkpoints durante implementación (Act)

- [ ] Cada paso produce resultado verificable
- [ ] No hay efectos secundarios inesperados
- [ ] Puedo revertir si es necesario
- [ ] Estoy dentro del scope original
