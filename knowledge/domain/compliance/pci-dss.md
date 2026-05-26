# PCI-DSS (Payment Card Industry Data Security Standard)

> Ver `index.md` para tabla comparativa entre regulaciones y controles comunes.

## Scope
- Aplica a cualquier entidad que procesa, almacena o transmite datos de tarjeta
- 12 requisitos principales
- 4 niveles según volumen de transacciones

## Los 12 Requisitos

| # | Requisito | Implementación |
|---|-----------|----------------|
| 1 | Firewall | Network segmentation |
| 2 | No vendor defaults | Change default passwords |
| 3 | Protect stored data | Encryption at rest |
| 4 | Encrypt transmission | TLS 1.2+ |
| 5 | Anti-malware | Endpoint protection |
| 6 | Secure development | SDLC security |
| 7 | Restrict access | Need-to-know basis |
| 8 | Authenticate users | Strong auth, MFA |
| 9 | Physical security | Facility controls |
| 10 | Monitor access | Logging, audit trails |
| 11 | Test regularly | Vulnerability scans, pentests |
| 12 | Security policies | Documentation |

## Scope Reduction (HIGHLY RECOMMENDED)

```javascript
// MAL — en scope PCI
const processPayment = async (payment) => {
  const cardNumber = payment.cardNumber; // PCI scope!
  const cvv = payment.cvv; // NEVER store
};

// BIEN — fuera de scope
const processPayment = async (tokenizedPayment) => {
  const paymentToken = tokenizedPayment.token; // Token from Stripe/PayPal
  return stripe.charges.create({
    source: paymentToken,
    amount: tokenizedPayment.amount
  });
};
```

```html
<!-- Card input en iframe del provider — card data nunca toca tu servidor -->
<div id="card-element"><!-- Stripe/PayPal iframe renders here --></div>
```

## Cardholder Data

| Data | Storage allowed | Protection required |
|------|-----------------|---------------------|
| PAN (card number) | Yes | Encrypted or masked |
| Cardholder name | Yes | Encrypted if with PAN |
| Expiration | Yes | Encrypted if with PAN |
| CVV/CVC | **NEVER** | Never store |
| PIN | **NEVER** | Never store |
| Full magnetic stripe | **NEVER** | Never store |

```javascript
// Only show first 6 and last 4
const maskPAN = (pan) => pan.slice(0, 6) + '******' + pan.slice(-4);
```

## Logging Requirements

```javascript
const pciLog = (event) => {
  // NEVER log: Full PAN, CVV, PIN, Full track data
  logger.info({
    timestamp: new Date().toISOString(),
    user_id: event.userId,
    action: event.action,
    resource: event.resource,
    result: event.success ? 'success' : 'failure',
    ip: event.ipAddress,
    card_last_four: event.cardLastFour
  });
};
```

## PCI-DSS Checklist

- [ ] Scope defined and minimized
- [ ] Card data tokenized (recommended)
- [ ] Encryption at rest
- [ ] TLS 1.2+ for transmission
- [ ] Access controls implemented
- [ ] Logging configured
- [ ] Vulnerability scans scheduled
- [ ] Penetration testing annual
- [ ] Security awareness training
- [ ] Incident response plan
