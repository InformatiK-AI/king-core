# SOC 2 (Service Organization Control 2)

> Ver `index.md` para tabla comparativa entre regulaciones y controles comunes.

## Trust Service Criteria

| Criteria | Description | Key controls |
|----------|-------------|--------------|
| **Security** | Protection against unauthorized access | Access controls, encryption, monitoring |
| **Availability** | System availability for operation | Uptime, disaster recovery, capacity |
| **Processing Integrity** | Complete, valid, timely processing | Input validation, error handling |
| **Confidentiality** | Protection of confidential info | Encryption, access restrictions |
| **Privacy** | Personal information handling | Privacy notices, consent, retention |

## Security Criteria Implementation

### CC6.1 - Logical Access
```javascript
const accessControl = {
  authentication: {
    method: 'multi-factor',
    factors: ['password', 'totp'],
    sessionTimeout: 30 * 60 // 30 minutes
  },
  authorization: {
    model: 'RBAC',
    roles: ['admin', 'developer', 'viewer'],
    permissions: permissionMatrix
  },
  reviews: {
    frequency: 'quarterly',
    process: 'manager_approval',
    documented: true
  }
};
```

### CC6.6 - System Operations
```javascript
const monitoring = {
  logging: {
    events: ['auth', 'access', 'changes', 'errors'],
    retention: '1 year',
    immutable: true
  },
  alerting: {
    channels: ['pagerduty', 'email'],
    escalation: true,
    responseTime: '15 minutes'
  },
  review: {
    frequency: 'daily',
    automated: true,
    anomalyDetection: true
  }
};
```

## Audit Evidence

**What to maintain:**
- Change management records
- Access reviews
- Incident reports
- Training records
- Vendor assessments
- Policy versions

## SOC 2 Checklist

- [ ] Scope defined
- [ ] Controls documented
- [ ] Policies written
- [ ] Evidence collection automated
- [ ] Access reviews scheduled
- [ ] Change management process
- [ ] Incident management process
- [ ] Vendor management process
- [ ] Training program
- [ ] Continuous monitoring
