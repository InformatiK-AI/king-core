# Context Handoff Standard

> **Token budget note**: Este archivo (~1800 tokens) excede el umbral warning (1500)
> por incluir template completo + ejemplo ilustrativo. Justificado: el ejemplo
> concreto (@developer → @architect) es crítico para que los agentes generen
> handoffs correctos sin consultar documentación adicional.

## Propósito
Define el formato estándar para transferir contexto entre agentes durante escalaciones y handoffs.

---

## Estructura del Handoff

### 1. Origin Fields (Quién envía)

```yaml
origin:
  agent: "@developer"           # Agente que inicia el handoff
  skill: "/build"       # Skill en ejecución (si aplica)
  phase: "implementation"       # Fase dentro del skill
  issue: "#123"                 # Issue relacionado (si aplica)
  timestamp: "2026-02-05T10:30:00Z"
  session: "sessions/2026-02-05-build-123.md"
```

### 2. State Fields (Estado actual)

```yaml
state:
  completed:
    - "Diseño de componentes completado"
    - "Tests unitarios escritos"
    - "Integración con API lista"
  pending:
    - "Decisión de arquitectura para caché"
    - "Validación de patrones de accesibilidad"
  blockers:
    - type: "decision_needed"
      description: "Requiere decisión sobre estrategia de caché"
      options: ["Redis", "In-memory", "File-based"]
  worktree: ".worktrees/features/feature-123-auth"  # Si aplica
  branch: "feature/123-auth-login"
```

### 3. Artifacts (Artefactos relevantes)

```yaml
artifacts:
  files_modified:
    - path: "src/features/auth/login.tsx"
      changes: "Componente de login implementado"
    - path: "src/features/auth/types.ts"
      changes: "Tipos de autenticación definidos"
  files_to_modify:
    - path: "src/services/cache.ts"
      reason: "Pendiente decisión de arquitectura"
  decisions_made:  # (ejemplo ilustrativo)
    - id: "ADR-007"
      summary: "Usar JWT para autenticación"
      path: "king-framework/docs/architecture/ADR-007-jwt-auth.md"
  tests:
    - path: "src/features/auth/__tests__/login.test.tsx"
      status: "passing"
      coverage: "85%"
```

### 4. For Next Agent (Qué se necesita)

```yaml
for_next_agent:
  request: "Evaluar estrategia de caché para sesiones de usuario"
  context: |
    El componente de login necesita almacenar tokens de sesión.
    Actualmente consideramos tres opciones con trade-offs diferentes.
    Necesitamos decisión arquitectónica antes de continuar.
  options:
    - name: "Redis"
      pros: ["Distribuido", "TTL nativo", "Alta performance"]
      cons: ["Infraestructura adicional", "Costo"]
    - name: "In-memory"
      pros: ["Simple", "Sin dependencias"]
      cons: ["No persiste", "No distribuido"]
    - name: "File-based"
      pros: ["Persiste", "Simple"]
      cons: ["Lento", "No distribuido"]
  urgency: "HIGH"  # CRITICAL | HIGH | MEDIUM | LOW
  expected_output: "ADR con decisión y justificación"
  return_to: "@developer"
  return_context: "Continuar implementación de caché según decisión"
```

---

## Template Completo

```yaml
# Context Handoff
# From: @{origin_agent} → To: @{target_agent}
# Date: {ISO timestamp}

origin:
  agent: "@{agent}"
  skill: "/{skill}"
  phase: "{phase}"
  issue: "#{number}"
  timestamp: "{ISO}"
  session: "{path}"

state:
  completed:
    - "{item}"
  pending:
    - "{item}"
  blockers:
    - type: "{type}"
      description: "{description}"
  worktree: "{path}"
  branch: "{branch}"

artifacts:
  files_modified:
    - path: "{path}"
      changes: "{description}"
  files_to_modify:
    - path: "{path}"
      reason: "{reason}"
  decisions_made:
    - id: "{ADR-id}"
      summary: "{summary}"

for_next_agent:
  request: "{what you need}"
  context: |
    {detailed context}
  options:
    - name: "{option}"
      pros: ["{pro}"]
      cons: ["{con}"]
  urgency: "{level}"
  expected_output: "{what you expect back}"
  return_to: "@{agent}"
  return_context: "{what to do with the response}"
```

---

## Ejemplo Completo: @developer → @architect

```yaml
# Context Handoff
# From: @developer → To: @architect
# Date: 2026-02-05T10:30:00Z

origin:
  agent: "@developer"
  skill: "/build"
  phase: "implementation"
  issue: "#123"
  timestamp: "2026-02-05T10:30:00Z"
  session: "sessions/2026-02-05-build-123.md"

state:
  completed:
    - "Componente LoginForm implementado"
    - "Validación de email/password"
    - "Integración con AuthService"
    - "Tests unitarios (85% coverage)"
  pending:
    - "Estrategia de caché para tokens"
    - "Refresh token flow"
  blockers:
    - type: "architecture_decision"
      description: "Necesito decisión sobre dónde almacenar tokens de sesión"
      impact: "Bloquea implementación de remember-me y refresh tokens"
  worktree: ".worktrees/features/feature-123-auth"
  branch: "feature/123-auth-login"

artifacts:
  files_modified:
    - path: "src/features/auth/LoginForm.tsx"
      changes: "Formulario de login con validación"
    - path: "src/features/auth/AuthService.ts"
      changes: "Servicio de autenticación con JWT"
    - path: "src/features/auth/types.ts"
      changes: "Interfaces User, Session, AuthResponse"
  files_to_modify:
    - path: "src/services/TokenStorage.ts"
      reason: "Pendiente decisión de almacenamiento"
  decisions_made:
    - id: "local-001"
      summary: "Usar JWT en lugar de sessions server-side"

for_next_agent:
  request: "Decisión arquitectónica: estrategia de almacenamiento de tokens"
  context: |
    Necesito almacenar JWT tokens para:
    1. Acceso rápido en cada request
    2. Soporte de "remember me" (persistencia)
    3. Refresh token rotation

    El proyecto actualmente no tiene Redis ni otro sistema de caché.
    Consideraciones de seguridad: tokens sensibles, XSS prevention.
  options:
    - name: "localStorage + httpOnly cookie"
      pros: ["Simple", "Funciona offline", "Sin infra adicional"]
      cons: ["XSS vulnerable (localStorage)", "CSRF para cookies"]
    - name: "Redis"
      pros: ["Seguro", "TTL automático", "Escalable"]
      cons: ["Nueva dependencia", "Setup adicional"]
    - name: "In-memory + Refresh via API"
      pros: ["Más seguro", "Sin persistencia de tokens"]
      cons: ["Re-auth en refresh de página"]
  urgency: "HIGH"
  expected_output: |
    ADR con:
    - Decisión clara
    - Justificación de trade-offs
    - Patrón de implementación sugerido
  return_to: "@developer"
  return_context: "Implementar TokenStorage según patrón decidido"
```

---

## Respuesta del Agente Receptor

Cuando un agente recibe un handoff, debe responder con:

```yaml
# Response to Handoff
# From: @architect → To: @developer
# Date: 2026-02-05T11:00:00Z
# In response to: handoff-2026-02-05T10:30:00Z

response:
  decision: "In-memory + Refresh via API"
  justification: |
    1. Seguridad: No persistir tokens sensibles
    2. UX: Refresh silencioso via refresh token en httpOnly cookie
    3. Simplicidad: No requiere infraestructura adicional

  implementation_guidance:
    pattern: "Dual-token pattern"
    access_token: "In-memory (variable/context)"
    refresh_token: "httpOnly secure cookie"
    flow: |
      1. Login → Recibe access + refresh
      2. Access en memoria para API calls
      3. Refresh en cookie para renovación silenciosa
      4. Page refresh → Llama /refresh endpoint

  adr_created: "king-framework/docs/architecture/ADR-008-token-storage.md"  # (ejemplo ilustrativo)

  additional_notes:
    - "Considerar añadir CSP headers para XSS mitigation"
    - "Implementar token rotation en refresh"

return_context_confirmed: true
next_steps_for_developer:
  - "Implementar TokenContext para access token"
  - "Crear useAuth hook con refresh logic"
  - "Configurar axios interceptor para auto-refresh"
```

---

## Cuándo Usar Handoff

| Situación | Handoff necesario |
|-----------|-------------------|
| Decisión arquitectónica | Sí → @architect |
| Vulnerability detectada | Sí → @security |
| WCAG violation | Sí → @frontend |
| Trade-off complejo | Sí → Agente especializado |
| Pregunta simple | No → Consultar documentación |
| Bug trivial | No → Resolver directamente |

---

## Timeout y Fallback Protocol

### Timeout por urgencia

| Urgencia | Timeout | Accion si expira |
|----------|---------|------------------|
| CRITICAL | 1 turno | Escalar a usuario directamente |
| HIGH | 2 turnos | Reintentar 1 vez, luego escalar a usuario |
| MEDIUM | 3 turnos | Documentar bloqueo en sesion, continuar con alternativa |
| LOW | Sin limite | Documentar como pendiente, no bloquea |

### Fallback si receptor no disponible

1. **Agente especializado no activado en /genesis**: El agente core mas cercano asume (ej: si @security no existe, @qa ejecuta Security Gate basico)
2. **Agente no responde en timeout**: Documentar en sesion con formato:
   ```yaml
   handoff_timeout:
     target: "@{agent}"
     urgency: "{level}"
     action_taken: "Escalado a usuario / Continuado con alternativa"
   ```
3. **Conflicto entre agentes**: @architect tiene decision final en temas de diseño. Para seguridad, @security tiene veto.

---

## Integracion con Escalation Matrix

Este formato se usa en conjunto con `agents/_common/escalation-matrix.md`.

La matrix define **cuando** escalar; este documento define **como** transferir el contexto.
