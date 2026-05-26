---
name: dependency-security
description: "Reglas de seguridad para dependencias del proyecto"
---

# Rule: Dependency Security

**Alcance**: `package.json`, `package-lock.json`, `node_modules`
**Severidad**: WARNING (escalación a BLOQUEANTE si hay CRITICAL)

## Directivas

1. Ejecutar `npm audit` antes de cada release
2. NO instalar dependencias con vulnerabilidades CRITICAL o HIGH conocidas
3. Preferir dependencias con mantenimiento activo (última publicación < 6 meses)
4. Minimizar dependencias — evaluar si la funcionalidad se puede implementar sin paquete adicional
5. `package-lock.json` DEBE comittearse siempre
6. NO usar dependencias con licencias copyleft incompatibles (proyecto propietario)
7. Al agregar dependencia nueva: documentar justificación en el commit message
