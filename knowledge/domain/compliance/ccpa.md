# CCPA (California Consumer Privacy Act)

> Ver `index.md` para tabla comparativa entre regulaciones y controles comunes.

## Scope

- Aplica a empresas que hacen negocios en California Y cumplen al menos uno de:
  - Ingresos anuales > $25M
  - Compra/vende/recibe datos de 100,000+ consumidores o dispositivos por año
  - Obtiene más del 50% de ingresos de venta de datos personales
- Protege a **residentes de California**, independientemente de dónde esté la empresa
- Ampliado por **CPRA** (California Privacy Rights Act, vigente desde 2023): agrega datos sensibles, corrección, limitación de uso
- Multas: hasta $2,500 por violación no intencional, $7,500 por violación intencional

## Principios Fundamentales

| Principio | Descripción | Implementación técnica |
|-----------|-------------|----------------------|
| **Transparency** | Informar qué datos se recopilan y con qué fin | Privacy Policy actualizada anualmente |
| **Right to Know** | Consumidor puede saber qué datos tiene la empresa sobre él | Data access endpoint / export |
| **Right to Delete** | Consumidor puede pedir eliminación de sus datos | Proceso de borrado documentado |
| **Right to Opt-Out** | Opt-out de venta de datos personales | "Do Not Sell My Personal Information" link |
| **Right to Non-Discrimination** | No penalizar por ejercer derechos CCPA | No degradar servicio por opt-out |
| **Right to Correct (CPRA)** | Corregir datos personales inexactos | Update endpoint |
| **Right to Limit (CPRA)** | Limitar uso de datos sensibles | Sensitive data controls |

## Derechos del Consumidor

### Right to Know / Access (§1798.100)

**Qué revelar:**
- Categorías de datos personales recopilados
- Fuentes de recopilación
- Propósito comercial del uso
- Terceros con quienes se comparten
- Datos específicos recopilados (request individual)

**Checklist:**
- [ ] Endpoint o formulario de acceso a datos implementado
- [ ] Respuesta dentro de 45 días (extensión de 45 días adicionales si necesario, con aviso)
- [ ] Verificación de identidad antes de revelar datos
- [ ] Formato portable y usable

### Right to Delete (§1798.105)

**Excepciones al borrado (empresa puede negarse si datos necesarios para):**
- Completar una transacción pendiente
- Cumplir obligación legal
- Ejercer libertad de expresión
- Investigación científica/estadística de interés público
- Detectar incidentes de seguridad

**Checklist:**
- [ ] Proceso de borrado en todos los sistemas documentado
- [ ] Excepciones documentadas y aplicadas correctamente
- [ ] Notificación a proveedores de servicio del borrado
- [ ] Respuesta dentro de 45 días

### Right to Opt-Out of Sale (§1798.120)

- La Privacy Policy DEBE incluir enlace "Do Not Sell or Share My Personal Information"
- Enlace visible en la homepage y en la Privacy Policy
- Consumidores menores de 16 años: opt-in requerido (no opt-out)
- Efectivo dentro de 15 días hábiles

### Right to Non-Discrimination (§1798.125)

La empresa NO puede:
- Negar bienes o servicios
- Cobrar precios diferentes
- Proveer nivel de calidad diferente
- Sugerir que recibirá trato diferente

Excepción: puede ofrecer incentivos financieros si son razonablemente relacionados al valor de los datos.

### Right to Correct (CPRA — §1798.106)

- Consumidor puede solicitar corrección de datos personales inexactos
- Empresa debe hacer esfuerzos comercialmente razonables para corregir
- Respuesta dentro de 45 días

### Right to Limit Use of Sensitive Personal Information (CPRA — §1798.121)

**Datos sensibles** (lista no exhaustiva):
- Número de Seguro Social, pasaporte, licencia de conducir
- Datos financieros de cuentas bancarias, tarjetas de crédito
- Credenciales de cuenta (username/password)
- Datos de geolocalización precisa
- Contenido de comunicaciones privadas
- Datos genéticos, biométricos, de salud, sexuales/orientación sexual
- Origen racial o étnico, opiniones políticas, creencias religiosas

La empresa debe limitarse a usar datos sensibles solo para los propósitos necesarios para el servicio.

## Obligaciones del Business

### Privacy Policy (§1798.130)

La Privacy Policy DEBE incluir:
- [ ] Lista de categorías de datos personales recopilados en los últimos 12 meses
- [ ] Propósito de la recopilación de cada categoría
- [ ] Categorías de terceros con quienes se comparten datos
- [ ] Derechos CCPA del consumidor y cómo ejercerlos
- [ ] Enlace "Do Not Sell or Share My Personal Information" (si aplica)
- [ ] Datos de contacto para solicitudes (mínimo 2 métodos: toll-free phone + website/email)
- [ ] Fecha de última actualización (actualizar al menos anualmente)

### Aviso al Momento de Recopilación (§1798.100(b))

Antes de recopilar datos, informar:
- Categorías de datos personales a recopilar
- Propósito(s) del uso

### Data Service Providers (Proveedores de Servicio)

A diferencia de GDPR (DPA), CCPA requiere un contrato de proveedor de servicio que prohíba al proveedor:
- Vender los datos personales
- Retener, usar o divulgar datos para propósito diferente al contrato
- Combinar datos con datos de otras fuentes sin autorización

**Nota**: CCPA no requiere un DPA formal con cláusulas Art. 28 como GDPR. El contrato de proveedor de servicio es suficiente.

## Requisitos de Cookie Policy (CalOPPA)

**California Online Privacy Protection Act (CalOPPA)** requiere:

- [ ] Privacy Policy visible y accesible
- [ ] Descripción del proceso para notificar cambios a la política
- [ ] Descripción de cómo responde a señales "Do Not Track"
- [ ] Listar terceras partes que pueden rastrear al usuario en el sitio

**Cookies y tracking:**
- No existe en California un requisito de banner de consentimiento previo como en EU ePrivacy
- Sí requiere transparencia sobre cookies de tracking usadas para venta de datos
- Si cookies de terceros venden datos → incluir en "Do Not Sell" opt-out

## Estructura de Penalidades

| Tipo | Monto | Quién puede actuar |
|------|-------|-------------------|
| Violación no intencional | $2,500 por violación | California Attorney General |
| Violación intencional | $7,500 por violación | California Attorney General |
| Data breach (datos de login sin cifrar) | $100-$750 por consumidor por incidente | Consumidores (private right of action) |

- Período de cura de **30 días** (CCPA original) — empresas pueden remediar antes de multa
- CPRA eliminó el período de cura para violaciones de derechos de privacidad

## CCPA Checklist de Implementación

### Privacy Policy
- [ ] Cubre las 11 categorías de datos personales (ver §1798.140(o))
- [ ] Actualizada en los últimos 12 meses
- [ ] Enlace "Do Not Sell or Share" visible en homepage (si aplica)
- [ ] Dos métodos de contacto para solicitudes

### Derechos del Consumidor
- [ ] Proceso de acceso a datos (45 días de respuesta)
- [ ] Proceso de borrado documentado con excepciones
- [ ] Mecanismo de opt-out de venta/compartición de datos
- [ ] Sin discriminación por ejercer derechos

### Contratos con Proveedores
- [ ] Contratos de proveedor de servicio actualizados con cláusulas CCPA
- [ ] Prohibición de venta de datos a terceros por parte del proveedor

### Técnico
- [ ] Verificación de identidad para solicitudes de acceso/borrado
- [ ] Registro de solicitudes de consumidores (tracking de cumplimiento)
- [ ] Proceso para menores de 16 años (opt-in para venta de datos)
