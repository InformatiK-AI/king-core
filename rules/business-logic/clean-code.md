---
name: clean-code
description: "Principios de código limpio: naming, funciones pequeñas, sin efectos secundarios ocultos"
---

# Rule: Clean Code

**Severidad**: WARNING

## Naming
- Variables y funciones con nombres descriptivos (no abreviaturas)
- Funciones que hacen una cosa y la hacen bien
- Nombres que revelan intención, no implementación

## Funciones
- Una función = una responsabilidad
- Máximo 20-30 líneas (preferible menos)
- Parámetros: máximo 3 (si más, usar objeto)
- Sin efectos secundarios ocultos

## Comentarios
- El código debe ser autoexplicativo
- Comentar el "por qué", no el "qué"
- No comentar código muerto — eliminarlo

## Estructura
- Archivos < 300 líneas (preferible)
- Una clase/módulo por archivo
- Sin código duplicado (DRY)
