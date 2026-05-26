# Communication Flowchart

## Propósito
Diagrama visual de qué skills invocan a qué agentes y cómo fluye la comunicación.

---

## Skill → Agent Invocations

```
                         AGENTS
SKILLS               Core                    Especializados (si activos)
                 dev  arch  qa  ux    sec  devops  api  perf  ml  mobile
                 ---  ----  --  --    ---  ------  ---  ----  --  ------
/genesis          .    .    .    .     ?     ?      ?    ?     ?    ?
                                      └── Deteccion de senales en discovery
                                          Solo activa agentes necesarios

/brainstorm    .    X    .    ?     ?     ?      ?    ?     ?    ?
                       │         └── Segun senales detectadas en diseno
                       └── Siempre: decisiones de arquitectura

/frontend-design  X    .    .    X     .     .      .    .     .    .
                  │              │
                  │              └── Patrones a11y para UI
                  └── Implementacion de codigo visual

/build    X    ?    .    ?     ?     ?      ?    ?     ?    ?
                  │    │         └── Si feature tiene UI
                  │    └── Si decision arquitectonica necesaria
                  └── Siempre: implementacion principal

/review      X    X    X    .     .     .      .    .     .    .
                  │    │    │
                  │    │    └── Verifica calidad
                  │    └── Revisa arquitectura
                  └── Revisa implementacion

/qa               .    .    X    ?     ?     .      .    .     .    .
                            │    │     │
                            │    │     └── Deep review (--env qa + @security activo)
                            │    └── Full WCAG audit (--env qa + UI)
                            └── Siempre: testing + Security Gate basico

/merge            .    .    .    .     .     .      .    .     .    .
                  └── Verifica sesion QA (no invoca agentes directamente)

/promote          .    .    .    .     .     ?      .    .     .    .
                                             │
                                             └── Verificacion infra (--to prod)

/release          .    .    .    .     .     .      .    .     .    .
                  └── Proceso automatizado (no invoca agentes directamente)

/create-endpoint  .    .    .    .     .     .      ?    .     .    .
                                                   │
                                                   └── Review de endpoint (si activo)

/generate-comp    .    .    .    .     .     .      .    .     .    .
                  └── Genera segun template (no invoca agentes)

/add-test         .    .    .    .     .     .      .    .     .    .
                  └── Genera segun piramide (no invoca agentes)

Leyenda: X = siempre invoca  ? = condicional (segun senales)  . = no invoca
```

---

## Flujo de Comunicación entre Agentes

```
                    ┌──────────────────┐
                    │     USUARIO      │
                    └────────┬─────────┘
                             │
            ┌────────────────┼────────────────┐
            │                │                │
            ▼                ▼                ▼
     ┌──────────┐    ┌──────────┐    ┌──────────────┐
     │@developer│◄──►│@architect│    │@frontend     │
     └────┬─────┘    └────┬─────┘    └──────┬───────┘
          │               │                 │
          │  Contratos:   │                 │
          │  dev-arch     │                 │
          │  dev-qa       │                 │
          │  dev-security │                 │
          │  dev-ux       │                 │
          │               │                 │
          ▼               │                 │
     ┌──────────┐         │                 │
     │   @qa    │◄────────┘                 │
     └────┬─────┘                           │
          │                                 │
          │  Contrato: qa-security          │
          │                                 │
          ▼                                 │
     ┌──────────┐                           │
     │@security │◄──────────────────────────┘
     └──────────┘      (via /qa --env qa)

     Especializados (invocados bajo demanda):
     ┌──────────┐ ┌──────────┐ ┌──────────┐
     │ @devops  │ │  @perf   │ │  @api    │
     └──────────┘ └──────────┘ └──────────┘
     ┌──────────┐ ┌──────────┐
     │   @ml    │ │ @mobile  │
     └──────────┘ └──────────┘
```

---

## Contratos Bidireccionales

```
@developer ◄────────► @architect        contracts/developer-architect.md
    │                                   Pre-Decision, Quick Consultation
    │
    ├──────────────► @qa                contracts/developer-qa.md
    │   ◄──────────                     QA Feedback, Fix Submission, Re-test
    │
    ├──────────────► @security          contracts/developer-security.md
    │   ◄──────────                     Pre-Implementation, Remediation
    │
    └──────────────► @frontend  contracts/developer-ux-accessibility.md
        ◄──────────                     A11y Consultation, WCAG Findings

@qa ────────────────► @security         contracts/qa-security.md
    ◄──────────────                     Deep Review, Finding Reports
```

---

## Flujo Completo de un Feature

```
/brainstorm ──► @architect (siempre)
       │           @security, @mobile, @perf, @api... (si senales)
       ▼
/create-issues ──► (sin agentes)
       ▼
/build ──► @developer (siempre)
       │           @architect (si decision necesaria)
       │           @frontend (si UI)
       ▼
/review   ──► @developer + @architect + @qa
       ▼
/qa            ──► @qa (siempre)
       │           @security (Security Gate basico)
       ▼
/merge         ──► (verifica QA, sin agentes)
       ▼
/promote --qa  ──► (verificaciones, @devops si infra)
       ▼
/qa --env qa   ──► @qa (full suite)
       │           @security (deep review)
       │           @frontend (full WCAG audit)
       ▼
/release       ──► (automatizado)
       ▼
/promote --prod──► (@devops si disponible)
```

---

## Ver también

- **Escalation Matrix**: `agents/_common/escalation-matrix.md`
- **Context Handoff**: `agents/_common/context-handoff.md`
- **Agent Signals**: `skills/_common/agent-signals.md`
- **LOAD-INDEX**: `king-framework/LOAD-INDEX.md`
