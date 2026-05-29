# Error Recovery Patterns — Conversational Error Recovery (M-83)

Catálogo de patrones de recuperación conversacional que consume el hook `Stop`
`hooks/error-recovery/error-recovery.sh`. Cuando una sesión termina con un error
bloqueante en el output o en `.king/registry.md`, el hook detecta el patrón,
interpola las variables del template y ofrece al usuario **3 opciones ejecutables**
para recuperarse sin perder contexto.

## Contrato del schema

Cada patrón es una entrada YAML con tres campos obligatorios:

- `error`: identificador único del patrón (`castle-breached-security`, `build-fail`,
  `test-fail`, `lint-fail`, `secret-detectado`).
- `detector`: cómo se reconoce el error.
  - `type`: siempre `keyword` (match por expresión regular sobre texto).
  - `source`: dónde se busca (`registry.md` o `session-output`).
  - `pattern`: expresión regular que dispara el patrón.
- `template`: bloque de texto que se emite al usuario. Contiene placeholders
  (`{files}`, `{error_message}`, etc.) y exactamente **3 opciones** marcadas
  `[1]`, `[2]`, `[3]`, cada una con una acción ejecutable (comando King o git).

> El hook hace **no-op silencioso** si ningún detector hace match: el `Stop`
> normal del usuario no se ve afectado.

## Patrones

```yaml
- error: castle-breached-security
  detector:
    type: keyword
    source: registry.md
    pattern: 'CASTLE BREACHED.*layer.*S'
  template: |
    ► CASTLE BREACHED — Layer S
    El skill /castle detectó vulnerabilidades críticas en: {files}
    Tenés 3 opciones:
      [1] /fix --target security — King genera los fixes y los propone para review
      [2] /castle --layer S --detail — auditoría detallada con guía de remediación
      [3] Escalar a @security — revisión manual de los findings

- error: build-fail
  detector:
    type: keyword
    source: session-output
    pattern: 'build failed|compilation error|TS[0-9]+'
  template: |
    ► Build fallido
    Error: {error_summary}
    Tenés 3 opciones:
      [1] /fix --error "{error_message}" — fix directo
      [2] Mostrar el contexto completo del error para analizarlo juntos
      [3] Revertir al último commit estable (git stash)

- error: test-fail
  detector:
    type: keyword
    source: session-output
    pattern: '[0-9]+ (test|spec)s? (failed|failing)|FAIL '
  template: |
    ► Tests fallando — {fail_count} de {total_count} tests
    Módulo afectado: {test_file}
    Tenés 3 opciones:
      [1] /fix --test "{test_file}" — King analiza el failure y propone fix
      [2] /qa --focus {module} — QA completo sobre el módulo
      [3] Ver el diff desde el último test verde

- error: lint-fail
  detector:
    type: keyword
    source: session-output
    pattern: '[0-9]+ (error|warning)s?.*lint|eslint|golangci'
  template: |
    ► Lint fallando — {warnings} warnings, {errors} errors
    Archivos afectados: {files}
    Tenés 3 opciones:
      [1] Auto-fix lint errors — ejecuta linter con --fix
      [2] /review --focus lint — revisión con contexto de arquitectura
      [3] Mostrar los {errors} errores bloqueantes para resolverlos manualmente

- error: secret-detectado
  detector:
    type: keyword
    source: session-output
    pattern: 'BLOCKED: Hardcoded secret|secret detectado|secret pattern'
  template: |
    ► ALERTA CRÍTICA — Secret detectado en código
    Archivo: {file}, línea {line}
    Tenés 3 opciones:
      [1] Eliminar ahora + rotar el secret — King guía el proceso completo
      [2] Mover a variable de entorno — King genera el refactor seguro
      [3] Marcar como false positive — si es un valor de ejemplo sin valor real
```

## Placeholders

| Placeholder       | Significado                                            | Patrón(es)                |
| ----------------- | ------------------------------------------------------ | ------------------------- |
| `{files}`         | Archivos afectados                                     | castle-breached-security, lint-fail |
| `{error_summary}` | Resumen corto del error                                | build-fail                |
| `{error_message}` | Mensaje de error completo (para `/fix --error`)        | build-fail                |
| `{fail_count}`    | Cantidad de tests fallando                             | test-fail                 |
| `{total_count}`   | Cantidad total de tests                                | test-fail                 |
| `{test_file}`     | Archivo de test afectado                               | test-fail                 |
| `{module}`        | Módulo afectado (para `/qa --focus`)                   | test-fail                 |
| `{warnings}`      | Cantidad de warnings de lint                           | lint-fail                 |
| `{errors}`        | Cantidad de errores de lint bloqueantes               | lint-fail                 |
| `{file}`          | Archivo donde se detectó el secret                     | secret-detectado          |
| `{line}`          | Línea donde se detectó el secret                       | secret-detectado          |

Si una variable no puede resolverse desde el output, el hook deja el placeholder
sin interpolar (degradación elegante) en lugar de fallar.
