# Dependency Audit

## Propósito
Verificar que las dependencias del proyecto no tienen vulnerabilidades conocidas.

---

## Comandos por Stack

### Node.js (npm)

```bash
# Auditoría básica
npm audit

# Solo vulnerabilidades altas/críticas
npm audit --audit-level=high

# Formato JSON para parsing
npm audit --json

# Arreglar automáticamente
npm audit fix

# Force fix (puede romper semver)
npm audit fix --force
```

### Node.js (yarn)

```bash
# Auditoría
yarn audit

# Con nivel
yarn audit --level high

# Yarn 2+
yarn npm audit
```

### Node.js (pnpm)

```bash
# Auditoría
pnpm audit

# Con nivel
pnpm audit --audit-level high
```

### Python

```bash
# Con pip-audit
pip-audit

# Con safety
safety check

# Desde requirements.txt
pip-audit -r requirements.txt
safety check -r requirements.txt
```

### Rust

```bash
# Auditoría
cargo audit

# Con advisory DB actualizada
cargo audit --deny warnings
```

### Go

```bash
# Con govulncheck
govulncheck ./...

# Con nancy
go list -json -m all | nancy sleuth
```

### Ruby

```bash
# Con bundler-audit
bundle audit check --update
```

### PHP

```bash
# Con local-php-security-checker
local-php-security-checker
```

---

## Niveles de Severidad

> ⚠️ **FUENTE AUTORITATIVA**: Esta sección es la fuente única de verdad para severidades de dependencias.
> Otros documentos (incluyendo `SECURITY-GATE.md`) deben referenciar aquí, no duplicar.

| Nivel | Descripción | Acción |
|-------|-------------|--------|
| CRITICAL | Explotable remotamente, impacto severo | BLOQUEANTE |
| HIGH | Explotable con condiciones, impacto alto | BLOQUEANTE |
| MEDIUM | Requiere interacción, impacto moderado | WARNING |
| LOW | Difícil de explotar, impacto bajo | INFO |

### Contextual Severity Assessment (TABLA AUTORITATIVA)

La severidad de una vulnerabilidad depende del contexto donde se usa la dependencia:

| Severidad CVE | Tipo de dependencia | Severidad efectiva | Acción |
|--------------|--------------------|--------------------|--------|
| CRITICAL | production | **CRITICAL** | BLOQUEANTE |
| CRITICAL | devDependencies | **MEDIUM** | WARNING (no llega a producción) |
| HIGH | production | **HIGH** | WARNING (requiere justificación) |
| HIGH | devDependencies | **LOW** | INFO |
| MEDIUM | cualquiera | **MEDIUM** | INFO |
| LOW | cualquiera | **LOW** | INFO |

**Regla:** Solo vulnerabilidades CRITICAL en dependencias de producción son BLOQUEANTES por defecto.

### Outdated Dependency Detection

Además de CVEs, detectar dependencias abandonadas o deprecadas:

| Señal | Severidad | Acción |
|-------|-----------|--------|
| Última publicación > 2 años | WARNING | Evaluar alternativa |
| Marcado como deprecated en npm/PyPI | WARNING | Planificar migración |
| Sin mantenedores activos | INFO | Monitorear |
| Versión major detrás (ej: v2.x cuando existe v5.x) | INFO | Evaluar upgrade |

---

## Interpretación de Resultados

### npm audit output

```json
{
  "vulnerabilities": {
    "lodash": {
      "name": "lodash",
      "severity": "high",
      "via": [
        {
          "source": 1095782,
          "name": "lodash",
          "dependency": "lodash",
          "title": "Prototype Pollution",
          "url": "https://github.com/advisories/GHSA-...",
          "severity": "high",
          "range": "<4.17.21"
        }
      ],
      "fixAvailable": {
        "name": "lodash",
        "version": "4.17.21"
      }
    }
  },
  "metadata": {
    "vulnerabilities": {
      "critical": 0,
      "high": 1,
      "moderate": 2,
      "low": 0
    }
  }
}
```

### Decisiones

```
Si fixAvailable = true:
  → Actualizar a versión sugerida
  → npm audit fix

Si fixAvailable = false:
  → Buscar alternativa al paquete
  → Evaluar si la vulnerabilidad aplica a nuestro uso
  → Documentar excepción si no aplica
```

---

## Vulnerabilidades Comunes

### Prototype Pollution (JavaScript)

**Qué es:** Modificar `Object.prototype` permite inyectar propiedades en todos los objetos.

**Afecta:** lodash, merge-deep, hoek, etc.

**Mitigación si no puedes actualizar:**
```javascript
// No usar funciones afectadas con input de usuario
// O validar input antes de merge/extend
```

### ReDoS (Regular Expression DoS)

**Qué es:** Regex malformadas que causan backtracking exponencial.

**Afecta:** Muchas librerías de validación.

**Mitigación:**
```javascript
// Timeout en operaciones de regex
// Limitar longitud de input
```

### Path Traversal

**Qué es:** Acceso a archivos fuera del directorio permitido.

**Afecta:** Librerías de archivos estáticos, compresión.

**Mitigación:**
```javascript
// Validar paths antes de operaciones
const safePath = path.resolve(baseDir, userInput);
if (!safePath.startsWith(baseDir)) {
  throw new Error('Invalid path');
}
```

### SQL Injection

**Qué es:** Inyectar SQL via inputs no sanitizados.

**Afecta:** ORMs con vulnerabilidades, query builders.

**Mitigación:**
- Usar prepared statements
- Actualizar ORM

---

## Reporte de Auditoría

### Formato

```
🔍 Dependency Audit Report
═══════════════════════════════════════════════════════

Stack: Node.js
Package Manager: npm
Total dependencies: 245
Direct: 15 | Transitive: 230

Vulnerabilities Found:
─────────────────────────────────────────────────────────
CRITICAL: 0
HIGH: 1
MEDIUM: 3
LOW: 2
─────────────────────────────────────────────────────────

┌────────────────────────────────────────────────────────┐
│ ⛔ HIGH: lodash - Prototype Pollution                  │
├────────────────────────────────────────────────────────┤
│ Versión instalada: 4.17.20                             │
│ Versión parcheada: 4.17.21                             │
│ CVE: CVE-2021-23337                                    │
│ GHSA: GHSA-35jh-r3h4-6jhm                             │
│                                                        │
│ Dependencia de: my-app > some-lib > lodash             │
│                                                        │
│ Fix disponible: ✅                                     │
│ Comando: npm update lodash                             │
└────────────────────────────────────────────────────────┘

┌────────────────────────────────────────────────────────┐
│ ⚠️ MEDIUM: axios - SSRF                                │
├────────────────────────────────────────────────────────┤
│ Versión instalada: 0.21.0                              │
│ Versión parcheada: 0.21.2                              │
│                                                        │
│ Fix disponible: ✅                                     │
│ Comando: npm update axios                              │
└────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════
Resultado: ⛔ BLOQUEADO (1 HIGH vulnerability)

Acciones requeridas:
1. npm audit fix
2. Si persiste, npm update lodash
3. Verificar con npm audit
4. Ejecutar /qa de nuevo
```

---

## Excepciones

### Cuándo permitir excepción

1. **No hay fix disponible**
   - El maintainer no ha publicado parche
   - Documentar issue de tracking

2. **Vulnerabilidad no aplica**
   - No usamos la función afectada
   - Nuestro uso no expone la vulnerabilidad

3. **Dependencia transitiva sin control**
   - Esperando que dependencia directa actualice
   - Abrir PR en la dependencia

### Documentar excepción

```yaml
# security/exceptions.yml
dependencies:
  - package: "lodash"
    version: "4.17.20"
    vulnerability: "CVE-2021-23337"
    severity: "high"
    reason: |
      No usamos _.merge con input de usuario.
      Todas las llamadas a lodash son con objetos controlados.
    mitigations:
      - "Input validado antes de procesamiento"
      - "Objetos creados internamente, no de request"
    tracking: "https://github.com/lodash/lodash/issues/..."
    expires: "2026-06-01"
    approved_by: "security-team"
```

---

## Automatización

### Pre-commit hook

```bash
#!/bin/sh
# .git/hooks/pre-commit

npm audit --audit-level=critical
if [ $? -ne 0 ]; then
  echo "❌ Critical vulnerabilities found"
  echo "Run 'npm audit' for details"
  exit 1
fi
```

### CI/CD

```yaml
# GitHub Actions
security:
  runs-on: ubuntu-latest
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: npm ci
    - run: npm audit --audit-level=high
```

### Renovate/Dependabot

```json
// renovate.json
{
  "extends": ["config:base"],
  "vulnerabilityAlerts": {
    "enabled": true,
    "labels": ["security"]
  },
  "schedule": ["every weekend"]
}
```

---

## Checklist

### Por PR
- [ ] npm audit sin CRITICAL/HIGH
- [ ] Si hay excepciones, están documentadas
- [ ] Dependencias actualizadas si hay fix

### Mantenimiento regular
- [ ] Audit semanal programado
- [ ] Dependabot/Renovate configurado
- [ ] Excepciones revisadas mensualmente
- [ ] Dependencias sin usar removidas

### Si se encuentra vulnerabilidad
- [ ] Evaluar si aplica a nuestro uso
- [ ] Si aplica, actualizar inmediatamente
- [ ] Si no aplica, documentar excepción
- [ ] Notificar a equipo si es crítica
