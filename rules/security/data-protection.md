---
name: data-protection
description: "Reglas de protección de datos y PII"
---

# Rule: Data Protection

**Alcance**: Todo el proyecto
**Severidad**: BLOQUEANTE

## Directivas

1. El código fuente del usuario enviado a Claude API se procesa en tránsito — NO almacenar en servidor
2. NO loggear el contenido completo de requests del usuario en logs del servidor
3. Stats en memoria se resetean al reiniciar — NO persistir datos de uso que contengan PII
4. En reportes PDF/export: NO incluir API keys, tokens, ni metadata sensible del sistema
5. Los paradigm maps son datos públicos de lenguajes — no contienen información sensible
6. Si se implementa autenticación en el futuro:
   - Passwords DEBEN hashearse (bcrypt, mínimo 10 rounds)
   - Tokens DEBEN tener expiración
   - Sessions DEBEN poder invalidarse
7. Error messages al cliente NUNCA deben incluir paths del servidor, stack traces, o configuración interna
