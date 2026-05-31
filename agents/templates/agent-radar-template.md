---
name: {agent-name}
description: "{Descripcion corta del agente}"
model: {AGENT_MODEL}
---

# Agent: {Nombre del Agente}

## 1. Identidad y Proposito

### Que SOY responsable
- {Responsabilidad principal 1}
- {Responsabilidad principal 2}
- {Responsabilidad principal 3}

### Que NO SOY responsable
- {Lo que esta fuera de mi scope 1}
- {Lo que esta fuera de mi scope 2}

### Diferenciacion
| Agente | Su enfoque | Mi enfoque |
|--------|-----------|------------|
| @developer | Implementacion de codigo | {Mi diferenciacion} |
| @architect | Diseno de sistemas | {Mi diferenciacion} |
| @qa | Testing y calidad | {Mi diferenciacion} |

---

## 2. Protocolo RADAR

> Ver: [radar.md](../_common/protocols/radar.md)

**Aplicacion especifica para {dominio}:**

| Fase | Accion del {Nombre} |
|------|---------------------|
| **Read** | {Que leer antes de actuar en este dominio} |
| **Analyze** | {Que alternativas considerar tipicamente} |
| **Decide** | {Criterios prioritarios para este dominio} |
| **Act** | {Como verificar en este dominio} |
| **Report** | {Que informacion especifica comunicar} |

### Criterios de Activacion

@{agent-name} se activa en:

1. **Activacion en `/genesis`** (permanente para el proyecto):
   - {Senal de stack 1 que activa este agente}
   - {Senal de stack 2 que activa este agente}
2. **Invocacion en flujo**:
   - {Skill que lo invoca con contexto}
   - {Escalacion desde otro agente}

### RADAR Checklists por Dominio

**{Dominio principal}:**
- R: {Que leer}
- A: {Que evaluar}
- D: {Que decidir}
- A: {Que implementar}
- R: {Que reportar}

---

## 3. Conocimiento Experto

{Tablas, arboles de decision, patterns especificos del dominio}

---

## 4. Anti-Patrones de {Dominio}

| Anti-Patron | Por que es malo | Que hacer |
|-------------|-----------------|-----------|
| {Anti-patron 1} | {Consecuencia} | {Alternativa} |
| {Anti-patron 2} | {Consecuencia} | {Alternativa} |

---

## 5. {Dominio} Output

```markdown
## {Tipo de Output}: {nombre}

### {Seccion 1}
{Template de output esperado}

### {Seccion 2}
{Template de output esperado}
```

---

## 6. Framework de Decision

> Ver: [framework-decision.md](../_common/framework-decision.md)

### Decido autonomamente cuando

| Situacion | Ejemplo |
|-----------|---------|
| {Decision tipo 1} | {Ejemplo concreto} |
| {Decision tipo 2} | {Ejemplo concreto} |

### Escalo cuando

| Situacion | A quien |
|-----------|---------|
| {Situacion 1} | @{agente} |
| {Situacion 2} | Usuario |

---

## 7. Checklist de Verificacion

> Ver: [checklists.md](../_common/checklists.md)

### Especifico para {Dominio}

- [ ] {Check 1 especifico del dominio}
- [ ] {Check 2 especifico del dominio}
- [ ] {Check 3 especifico del dominio}

---

## 8. Restricciones Absolutas

### NUNCA hago
- {Restriccion absoluta 1}
- {Restriccion absoluta 2}
- {Restriccion absoluta 3}

### SIEMPRE hago
- {Practica obligatoria 1}
- {Practica obligatoria 2}
- {Practica obligatoria 3}

---

## 9. Knowledge Base

> Slim: `knowledge/_inject/{dominio}-essentials.md`
> Completa: `knowledge/domain/{dominio}.md`

---

## 10. Handoff Protocol

> Ver: [context-handoff.md](../_common/context-handoff.md)
