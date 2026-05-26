# Knowledge Inject

Versiones compactas de knowledge para inyección lazy en skills y agents.

## Propósito

Los archivos en esta carpeta son versiones "slim" del knowledge completo,
optimizadas para carga lazy: se inyectan en agents durante `/genesis` o se
cargan on-demand por skills (como `/refine` en Deep mode) sin cargar el
documento completo. El constraint dominante es el presupuesto de tokens (ADR-002).

## Archivos disponibles

| Archivo | Tokens | Referencia / Consumidor |
|---------|--------|--------------------------|
| `security-essentials.md` | ~270 | Conocimiento de seguridad universal OWASP |
| `testing-essentials.md` | ~350 | `universal/testing.md` |
| `frontend-essentials.md` | ~390 | `universal/accessibility.md` |
| `context7-essentials.md` | ~265 | `context7/README.md` |
| `api-design-essentials.md` | ~440 | `universal/api-design.md` |
| `git-essentials.md` | ~315 | `universal/git-mastery.md` |
| `observability-essentials.md` | ~380 | `universal/observability.md` |
| `performance-essentials.md` | ~300 | `universal/performance.md` |
| `prompt-engineering-essentials.md` | ~400 | `skills/refine/DEEP-MODE.md` |
| `devops-essentials.md` | ~340 | `@devops` — GitFlow, worktrees, CI/CD, deploy |
| `mobile-essentials.md` | ~330 | `@mobile` — viewport, touch, offline, platform compat |
| `multi-tenancy.md` | ~350 | `skills/build/SKILL.md` — RLS, ABAC, tenant context. Solo contexto SaaS multi-tenant |
| `resilience-patterns.md` | ~450 | `skills/build/SKILL.md` — inyección condicional en integraciones con servicios externos |

## Uso

Durante `/genesis`, al crear agents:

```markdown
## 3. Conocimiento Experto

### Security
<!-- Inyectar de knowledge/_inject/security-essentials.md -->

### Testing
<!-- Inyectar de knowledge/_inject/testing-essentials.md -->
```

En skills con Deep mode (carga on-demand):

```markdown
<!-- DEEP-MODE.md carga al inicio -->
> Leer: knowledge/_inject/prompt-engineering-essentials.md
```

## Cuándo usar cada versión

| Contexto | Versión |
|----------|---------|
| Inyección en agent (/genesis) | `_inject/*.md` (slim) |
| Carga on-demand por skill | `_inject/*.md` (slim) |
| Consulta profunda | `universal/*.md` o `stacks/*/*.md` (completo) |
| Documentación | Links a versión completa |
