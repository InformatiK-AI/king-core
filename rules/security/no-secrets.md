---
name: no-secrets
description: "Prohibir hardcoding de secrets y credenciales en el código"
---

# Rule: No Secrets

**Alcance**: Todo el código del proyecto
**Severidad**: BLOQUEANTE

## Directivas

1. NUNCA hardcodear `ANTHROPIC_API_KEY`, tokens, passwords, o cualquier credencial en código fuente
2. Todas las credenciales DEBEN venir de variables de entorno (archivo `.env`)
3. El archivo `.env` NUNCA debe comittearse a git (verificar `.gitignore`)
4. Los archivos `.env.example` NUNCA deben contener valores reales — solo placeholders
5. En `client/`: NUNCA acceder a API keys directamente — siempre via proxy `/api/claude`

## Patrones prohibidos
- `sk-ant-*` en cualquier archivo de código
- `API_KEY = "valor"` o `API_KEY = 'valor'` hardcodeado
- `password = "..."` con valores reales
- `token = "..."` con valores reales
- `secret = "..."` con valores reales

## Excepción
- `.env.example` puede contener `ANTHROPIC_API_KEY=your-key-here` como placeholder documentativo
