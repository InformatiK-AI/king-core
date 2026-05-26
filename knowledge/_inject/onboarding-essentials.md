---
inject: onboarding-essentials
version: 1.0
scope: universal
---

# Onboarding Essentials — Patrones de Detección de Persona

## Detección de Persona

El framework soporta dos personas principales. Detectar ANTES de mostrar contenido técnico.

| Señal | Persona probable |
|-------|-----------------|
| Menciona "quiero lanzar", "startup", "monetizar", "landing" | entrepreneur |
| Menciona "api", "código", "integrar", "deploy CI/CD" | developer |
| Primera vez usando el framework | → preguntar explícitamente |
| Sin señales claras | → preguntar (developer \| entrepreneur \| ambos) |

**Regla**: Detectar → confirmar → adaptar flujo. Nunca asumir sin confirmar.

## Progressive Disclosure

Revelar complejidad técnica solo cuando el usuario la necesita:

1. **Entrepreneur**: lenguaje de negocio primero. "Tu app va a aceptar pagos" (no: "configurando webhook endpoint")
2. **Developer**: lenguaje técnico completo. Mostrar comandos, archivos, configuraciones.
3. **Ambos**: iniciar con lenguaje de negocio, agregar detalle técnico como sección colapsable o nota.

**Anti-patrón**: Mostrar terminología técnica (JWT, OAuth, PKCE, RLS, DNS, TTL) a un entrepreneur sin contexto previo.

## Market Analysis Framework — TAM/SAM/SOM

Para `/validate-idea`, usar este framework conversacional:

| Pregunta | Objetivo |
|---------|----------|
| "¿Quién tiene el problema?" | Segmento de mercado |
| "¿Cuántas personas lo tienen?" | TAM estimado |
| "¿A cuántos podés llegar en 2 años?" | SAM realista |
| "¿Cuántos van a pagar en el año 1?" | SOM conservador |
| "¿Quién más lo resuelve hoy?" | Competidores directos |
| "¿Qué hacés diferente?" | Diferenciador |

**Output esperado**: Recomendación en lenguaje de negocio: PROCEDER / PIVOTAR / DESCARTAR con justificación de 1 párrafo.

## Lenguaje por Persona

| Técnico (developer) | De negocio (entrepreneur) |
|---------------------|--------------------------|
| "Configurar OAuth2+PKCE" | "Agregar login con Google" |
| "Deploy a Vercel con ENV vars" | "Publicar tu app online" |
| "Webhook con signature validation" | "Recibir notificaciones de pagos" |
| "JWT expiry de 15 min" | "Tu sistema de acceso seguro" |
