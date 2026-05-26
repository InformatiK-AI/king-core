# GDPR (General Data Protection Regulation)

> Ver `index.md` para tabla comparativa entre regulaciones y controles comunes.

## Scope
- Aplica a datos de ciudadanos de la EU
- Sin importar dónde esté la empresa
- Multas: hasta 4% de revenue global o €20M

## Principios Fundamentales

| Principio | Descripción | Implementación técnica |
|-----------|-------------|----------------------|
| **Lawfulness** | Base legal para procesar datos | Consent management, legitimate interest docs |
| **Purpose limitation** | Usar datos solo para propósito declarado | Data tagging, access controls |
| **Data minimization** | Solo recolectar lo necesario | Schema design, validation |
| **Accuracy** | Datos correctos y actualizados | Update mechanisms, user verification |
| **Storage limitation** | No retener más de lo necesario | Data retention policies, auto-delete |
| **Integrity & confidentiality** | Proteger datos | Encryption, access controls |
| **Accountability** | Poder demostrar compliance | Audit logs, documentation |

## Derechos del Usuario (Technical Implementation)

### Right to Access (Art. 15)
```javascript
// API endpoint para data export
GET /api/user/data-export

// Response: All user data in portable format
{
  "user_profile": { ... },
  "activity_history": [ ... ],
  "preferences": { ... },
  "exported_at": "2024-01-15T10:30:00Z",
  "format": "JSON"
}
```

**Checklist:**
- [ ] Endpoint de export implementado
- [ ] Incluye TODOS los datos del usuario
- [ ] Formato portable (JSON, CSV)
- [ ] Response dentro de 30 días

### Right to Erasure / Right to be Forgotten (Art. 17)
```javascript
// API endpoint para deletion
DELETE /api/user/me

// Proceso de borrado
1. Soft delete (mark as deleted)
2. Anonymize in analytics
3. Remove from backups (within retention period)
4. Notify third parties
5. Hard delete after grace period
```

**Checklist:**
- [ ] Proceso de borrado documentado
- [ ] Borrado de todos los sistemas
- [ ] Notificación a procesadores terceros
- [ ] Auditoría del borrado
- [ ] Excepciones documentadas (legal holds)

### Right to Rectification (Art. 16)
```javascript
PATCH /api/user/profile
{
  "name": "Corrected Name",
  "email": "correct@email.com"
}
```

### Right to Data Portability (Art. 20)
```javascript
GET /api/user/data-export?format=json
// Formatos sugeridos: JSON, CSV, XML
```

## Consent Management

```javascript
// Consent record structure
{
  "user_id": "123",
  "consents": [
    {
      "purpose": "marketing_emails",
      "granted": true,
      "timestamp": "2024-01-15T10:30:00Z",
      "version": "privacy_policy_v2",
      "method": "explicit_checkbox",
      "ip_address": "192.168.1.1"
    }
  ]
}
```

**Implementation:**
- Granular consents (not bundled)
- Easy withdrawal mechanism
- Proof of consent stored
- Version tracking of policies

## Data Processing Agreement (DPA)

**Required with third parties:** Cloud providers, analytics, email services, payment processors.

## Breach Notification

**Timeline:** 72 hours to notify authority; "without undue delay" to affected users.

```javascript
const handleBreach = async (breach) => {
  const severity = assessBreachSeverity(breach);
  await logBreachDetails(breach);
  await notifyDPO(breach);
  if (severity === 'high') await notifyAuthority(breach, { within: '72h' });
  if (requiresUserNotification(severity)) await notifyAffectedUsers(breach);
};
```

## GDPR Checklist

- [ ] Data inventory completed
- [ ] Legal basis documented for each processing
- [ ] Privacy policy updated
- [ ] Consent mechanism implemented
- [ ] Data export functionality
- [ ] Data deletion functionality
- [ ] Breach notification process
- [ ] DPA with all processors
- [ ] Cookie consent (if applicable)
- [ ] DPO designated (if required)
