# QA-Security Integration Contract

## Propósito

Define el contrato de integración entre los componentes de seguridad del framework:
- **@qa agent**: Orquesta el proceso de QA y ejecuta Security Gate
- **Security Gate**: 5 checks basicos obligatorios. Ver detalle completo en [SECURITY-GATE.md](SECURITY-GATE.md) (Checks: Secrets | Dependencies | Code Patterns | File Size | Sensitive Files)
- **@security agent**: Deep review especializado (STRIDE, OWASP, compliance)

---

## Orden de Ejecución

### Modo Standard (`/qa --issue N`)

```
1. @qa ejecuta tests y verificación de ACs
2. @qa ejecuta Security Gate básico (5 checks)
   → Scope: archivos MODIFICADOS (diff del feature)
3. @qa ejecuta Accessibility Gate (si UI)
4. @qa calcula resultado final
```

> @security NO se invoca en modo standard.
> Security Gate básico es suficiente para validación por feature.

### Modo ENV (`/qa --env qa`)

```
1. @qa ejecuta full test suite
2. @qa ejecuta cross-feature integration check
3. @qa ejecuta Security Gate básico (5 checks)
   → Scope: TODOS los archivos en qa/ (full codebase)
4. @qa invoca @security para deep review (si disponible)
   → @security ejecuta STRIDE + OWASP + Compliance
   → @security retorna Security Review Report
5. @qa ejecuta Accessibility Gate (si UI, full codebase)
6. @qa invoca @frontend para full WCAG audit (si disponible)
7. @qa consolida resultados y calcula resultado final
```

---

## Quién Invoca a Quién

| Invocador | Invocado | Cuándo | Formato de comunicación |
|-----------|----------|--------|------------------------|
| Skill `/qa` | @qa | Siempre | Parámetros del skill |
| @qa | Security Gate | Siempre (obligatorio) | Resultado: PASS/FAIL por check |
| @qa | @security | Solo en ENV MODE. Si fue activado en `/genesis` → ejecuta deep review; si no → fallback a checks básicos con warning | Protocolo RADAR, output: Security Review Report |
| @qa | Accessibility Gate | Si proyecto tiene UI | Resultado: PASS/FAIL/WARNING por check |
| @qa | @frontend | Solo en ENV MODE y si proyecto tiene UI | Protocolo RADAR, output: Accessibility Audit Report |

---

## Precedencia de Resultados

Cuando hay resultados de múltiples fuentes, la precedencia es:

### Regla 1: Security Gate básico SIEMPRE bloquea
Si Security Gate básico = FAIL → QA = **FAILED** (sin excepciones)

### Regla 2: @security puede escalar pero no desescalar
| Security Gate | @security | Resultado final |
|--------------|-----------|-----------------|
| PASS | Sin findings | PASS |
| PASS | Solo MEDIUM/LOW | PASS (con warnings en sesión) |
| PASS | HIGH sin mitigación | **FAILED** (escala) |
| PASS | CRITICAL | **FAILED** (escala) |
| FAIL | Cualquiera | **FAILED** (Gate ya bloqueó) |

> @security puede encontrar issues que los 5 checks básicos no detectan
> (threat modeling, architectural flaws, compliance gaps).
> Estos findings ESCALAN el resultado incluso si el Gate básico pasó.

### Regla 3: No hay override entre Security y Accessibility
| Security | Accessibility | Resultado |
|----------|--------------|-----------|
| PASS | PASS | APPROVED |
| PASS | FAIL (nivel A) | FAILED |
| FAIL | PASS | FAILED |
| FAIL | FAIL | FAILED |
| PASS | WARNING (nivel AA) | CONDITIONAL |

Ambos gates son independientes. Un PASS en uno no compensa un FAIL en otro.

---

## Formato de Comunicación

### @qa → @security (invocación)

```
@security — DEEP REVIEW del ambiente qa/

Contexto:
- Ambiente: qa/ (.worktrees/environments/qa/)
- Features incluidos: {lista de features promovidos}
- Tipo de proyecto: {web app | API | CLI | etc.}
- Stack: {Node.js | Python | Go | etc.}

Scope de revisión:
1. STRIDE Threat Modeling del sistema completo
2. OWASP Top 10 verification
3. Auth/AuthZ review
4. Secrets management audit
5. Compliance check ({GDPR|HIPAA|PCI|etc.} si aplica)
6. Cross-feature attack surface analysis
7. Dependency supply chain review

Output esperado: Security Review Report
```

### @security → @qa (respuesta)

```
## Security Review Report

### Resumen ejecutivo
{1-2 oraciones con resultado general}

### Findings
| # | Severidad | Categoría | Ubicación | Descripción | Mitigación |
|---|-----------|-----------|-----------|-------------|------------|
| 1 | {CRITICAL|HIGH|MEDIUM|LOW} | {STRIDE|OWASP|etc.} | {archivo:línea} | {descripción} | {recomendación} |

### Resultado
**{PASS|FAIL}**
- CRITICAL findings: {n}
- HIGH findings: {n}
- MEDIUM findings: {n}
- LOW findings: {n}

### Recomendaciones prioritarias
1. {recomendación más urgente}
```

---

## Fallback cuando @security no está disponible

Si @security no fue activado durante `/genesis`:

1. Security Gate básico (5 checks) se ejecuta normalmente
2. Deep review NO se ejecuta
3. Se registra en sesión: "⚠️ @security no disponible. Solo se ejecutaron checks básicos del Security Gate."
4. Resultado de QA NO se bloquea por ausencia de @security
5. Se recomienda: "Considere activar @security para proyectos con datos sensibles o compliance"

---

## Bypass y Excepciones

### Security Gate bypass
- `SKIP_SECURITY_GATE=1` permite saltar el Gate completo
- **Requiere justificación documentada** en sesión:
  ```
  ## Security Gate Bypass
  **Justificación:** {razón del bypass}
  **Autorizado por:** {nombre/rol}
  **Fecha:** {ISO timestamp}
  **Scope:** {este merge/release específico}
  **Expira:** {fecha o "este merge solamente"}
  ```
- El bypass queda registrado permanentemente en la sesión

### Excepciones individuales
- Falsos positivos se documentan en `security/exceptions.yml`
- Excepciones tienen fecha de expiración
- Ver: `SECURITY-GATE.md → Excepciones`

---

## Métricas de Integración

En cada sesión de `/qa --env qa`, registrar:

```yaml
security_integration:
  gate_basic:
    executed: true
    result: PASS|FAIL
    checks_passed: 5/5
  security_deep_review:
    executed: true|false
    agent_available: true|false
    result: PASS|FAIL|N/A
    findings: {total}
    critical: {n}
    high: {n}
  accessibility:
    gate_executed: true|false
    audit_executed: true|false
    result: PASS|FAIL|WARNING|N/A
```
