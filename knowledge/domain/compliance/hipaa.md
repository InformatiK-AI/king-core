# HIPAA (Health Insurance Portability and Accountability Act)

> Ver `index.md` para tabla comparativa entre regulaciones y controles comunes.

## Scope
- Covered entities: healthcare providers, plans, clearinghouses
- Business associates: cualquier proveedor que maneja PHI para covered entities
- PHI = Protected Health Information

## PHI Definition

**What is PHI:** Name + health condition; cualquiera de los 18 identifiers + health data.

**18 Identifiers:**
1. Names
2. Geographic data smaller than state
3. Dates (except year) related to individual
4. Phone numbers
5. Fax numbers
6. Email addresses
7. Social Security numbers
8. Medical record numbers
9. Health plan beneficiary numbers
10. Account numbers
11. Certificate/license numbers
12. Vehicle identifiers
13. Device identifiers
14. Web URLs
15. IP addresses
16. Biometric identifiers
17. Full-face photographs
18. Any other unique identifier

## Technical Safeguards (Required)

### Access Controls
```javascript
const accessControl = {
  roles: {
    'physician': ['read', 'write', 'prescribe'],
    'nurse': ['read', 'write'],
    'admin': ['read'],
    'billing': ['read:billing_only']
  },
  checkAccess: (user, resource, action) => {
    auditLog.record({ user: user.id, resource: resource.id, action, timestamp: Date.now() });
    return accessControl.roles[user.role].includes(action);
  }
};
```

### Encryption Requirements
```javascript
// Encryption at rest — AES-256
const encryptPHI = (data) => crypto.encrypt(data, {
  algorithm: 'aes-256-gcm',
  key: getKeyFromVault('phi-encryption-key')
});
// Encryption in transit — TLS 1.2+, HTTPS only, no HTTP fallback
```

### Audit Controls
```javascript
// All PHI access must be logged — retention: 6 years
const hipaaAuditLog = {
  record: async (event) => await db.insert('audit_log', {
    timestamp: new Date().toISOString(),
    user_id: event.userId,
    patient_id: event.patientId,
    action: event.action, // 'view', 'create', 'modify', 'delete', 'export'
    resource_type: event.resourceType,
    resource_id: event.resourceId,
    ip_address: event.ipAddress,
    success: event.success
  })
};
```

### Automatic Logoff
```javascript
const sessionConfig = {
  maxIdleTime: 15 * 60 * 1000, // 15 minutes
  checkIdle: (session) => {
    if (Date.now() - session.lastActivity > sessionConfig.maxIdleTime) {
      session.terminate();
      auditLog.record({ action: 'auto_logoff', reason: 'idle_timeout' });
    }
  }
};
```

## Business Associate Agreement (BAA)

Required with: cloud providers, SaaS applications, consultants, IT service providers.

**BAA Checklist:**
- [ ] All vendors identified
- [ ] BAA signed with each
- [ ] Vendor security assessed
- [ ] Annual review scheduled

## HIPAA Checklist

- [ ] PHI inventory completed
- [ ] Risk assessment performed
- [ ] Access controls implemented
- [ ] Encryption at rest and transit
- [ ] Audit logging configured
- [ ] Automatic logoff enabled
- [ ] BAAs with all associates
- [ ] Workforce training completed
- [ ] Incident response plan
- [ ] Disaster recovery plan
