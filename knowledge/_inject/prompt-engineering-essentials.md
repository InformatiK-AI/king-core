# Prompt Engineering Essentials (para inyección)

> Versión compacta para inyección lazy en skills. Referencia completa: `skills/refine/DEEP-MODE.md`

## Template Óptimo Sonnet (XML+Markdown híbrido)

```xml
<role>[experto en X con contexto relevante]</role>
<context>[situación actual, constraints, stack]</context>
<instructions>[pasos numerados / bullets precisos]</instructions>
<output_format>[schema o ejemplo exacto del output esperado]</output_format>
```

## Top 7 Técnicas PE

| Técnica | Señal de aplicación |
|---------|---------------------|
| Role Priming | Sin rol definido en el prompt |
| XML Tags | Instrucciones con múltiples secciones |
| Few-Shot contrastivo | Output esperado inconsistente o ambiguo |
| Output Schema explícito | Sin formato de salida especificado |
| Constraints con prioridad | Múltiples requisitos sin orden de importancia |
| Decomposición secuencial | Tarea compleja con múltiples pasos dependientes |
| Negative Constraints | Riesgo de alucinación o desviación del scope |

## Señales de Prompt Vago

- Sin verbo imperativo: "quiero..." en lugar de "implementa..." / "genera..."
- Scope ambiguo: múltiples tareas sin delimitar en un solo prompt
- Sin formato de output especificado (tabla, JSON, código, prosa)
- Contexto implícito: asume conocimiento del stack o arquitectura sin declararlo
- Prompt sobrecargado: > 3 objetivos distintos sin priorizar

## Anti-patterns Sonnet

- **Wall of text**: sin estructura → Sonnet prioriza arbitrariamente
- **Context dump**: código completo sin señalar qué parte importa
- **Doble negación**: "no ignores X" → reformular en positivo directo
- **Sycophancy bait**: elogios excesivos → reduce especificidad del output
- **"Be creative"**: sin guardrails ni stop condition → output diverge
- **Sin ownership**: "¿podrías...?" → imperativo directo produce mejor resultado

## CoT Condicional

| Complejidad | Instrucción |
|-------------|-------------|
| LOW (1 paso claro) | Respuesta directa, sin CoT |
| MEDIUM (2-4 pasos) | "Think step by step before responding" |
| HIGH (5+ pasos / trade-offs) | RADAR explícito o CoT estructurado numerado |

## SQS — Structural Quality Score (0-10)

| Dimensión | Peso | Evalúa |
|-----------|------|--------|
| Especificidad | 2x | Verbo imperativo claro, scope delimitado |
| Estructura | 2x | XML tags / bullets numerados / secciones |
| Constraints | 1.5x | Límites explícitos (tokens, formato, exclusiones) |
| Output Format | 1.5x | Schema o ejemplo del output esperado |
| Context Ratio | 1x | Solo contexto relevante, sin context dump |

`SQS = (Σ score_i × peso_i) / 8 × 10` · `score_i`: 0=ausente, 0.5=parcial, 1=cumple
Baseline: prompt vago ≈ 2-3 · bien estructurado ≈ 7-8 · óptimo ≈ 9-10

## Checklist Pre-Prompt

- [ ] Verbo imperativo definido (implementa, genera, analiza, refactoriza...)
- [ ] Rol declarado (`<role>` o equivalente con dominio y contexto)
- [ ] Output format especificado (tabla, JSON, código, prosa, lista)
- [ ] Al menos 1 constraint explícito (tokens, exclusiones, formato, alcance)
- [ ] Solo contexto relevante incluido (sin context dump ni sycophancy)
