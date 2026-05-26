# Compliance — Índice

> Guías de compliance por regulación. Cargar solo el archivo relevante al proyecto
> en lugar de todas las regulaciones. Ver `Common Technical Controls` más abajo.

## Cuándo aplicar cada regulación

| Regulación | Archivo | Cuándo aplica |
|-----------|---------|--------------|
| GDPR | `gdpr.md` | Proyectos con usuarios de la UE o datos personales de cualquier región |
| CCPA / CPRA | `ccpa.md` | Proyectos con usuarios en California (US) o empresas con ingresos > $25M |
| PCI-DSS | `pci-dss.md` | Proyectos que procesan, almacenan o transmiten datos de tarjeta |
| HIPAA | `hipaa.md` | Proyectos con datos de salud (covered entities o business associates, US) |
| SOC 2 | `soc2.md` | SaaS B2B con requisitos de auditoría de clientes enterprise |

---

## Common Technical Controls (Aplica a todas las regulaciones)

### Encryption Standards

| Use Case | Algorithm | Key Size |
|----------|-----------|----------|
| Data at rest | AES-256-GCM | 256 bits |
| Data in transit | TLS 1.2+ | - |
| Password storage | Argon2id, bcrypt | - |
| Signatures | RSA-2048+ o ECDSA P-256 | - |

### Logging Requirements (All Regulations)

```javascript
// Compliance-ready logging
const complianceLog = {
  required_fields: [
    'timestamp',      // ISO 8601
    'user_id',        // Who
    'action',         // What
    'resource',       // On what
    'result',         // Success/failure
    'ip_address',     // From where
    'session_id'      // Session tracking
  ],

  retention: {
    'GDPR': '3 years',
    'HIPAA': '6 years',
    'PCI': '1 year',
    'SOC2': '1 year'
  },

  protection: {
    immutable: true,
    encrypted: true,
    access_controlled: true
  }
};
```

### Data Retention

| Regulation | General retention | Notes |
|------------|-------------------|-------|
| GDPR | Minimum necessary | Purpose-specific |
| HIPAA | 6 years | From creation or last use |
| PCI-DSS | 1 year logs | Card data: don't store |
| SOC 2 | 1 year evidence | Audit period + 1 |
