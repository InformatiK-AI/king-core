# Brainstorming Skill

## Overview

The **Brainstorming** skill helps turn ideas into fully formed designs and specs through collaborative dialogue. **MUST be used before any creative work** - creating features, building components, adding functionality, or modifying behavior.

## Process

### Understanding the Idea

- Check project context (files, docs, commits)
- Ask questions **one at a time**
- Prefer multiple choice when possible
- Focus on: purpose, constraints, success criteria

### Exploring Approaches

- Propose 2-3 different approaches with trade-offs
- Lead with recommended option and explain why

### Presenting the Design

- Present design in sections of **200-300 words**
- Ask after each section if it looks right
- Cover: architecture, components, data flow, error handling, testing
- Go back and clarify when needed

## Output Location

- **Modo PROYECTO**: `.king/docs/architecture/001-{proyecto}-arquitectura.md`
- **Modo FEATURE**: `.king/docs/features/{feature}/design.md`

## Design Document Template

```markdown
# Design: {Feature Name}

## Overview

{Brief description and goals}

## Approach

{Chosen approach and rationale}

## Architecture

{High-level architecture decisions}

## Components

{Key components and responsibilities}

## Data Flow

{How data moves through the system}

## Error Handling

{Error scenarios and handling strategy}

## Testing Strategy

{How this will be tested}
```

## Key Principles

- **One question at a time** - Don't overwhelm
- **Multiple choice preferred** - Easier to answer
- **YAGNI ruthlessly** - Remove unnecessary features
- **Explore alternatives** - Always propose 2-3 approaches
- **Incremental validation** - Present in sections, validate each

## Files

| File           | Description                          |
| -------------- | ------------------------------------ |
| `SKILL.md`     | Main skill definition                |
| `README.md`    | This documentation file              |
| `PHASES.md`    | Phase-by-phase execution detail      |
| `REFERENCE.md` | Templates, output formats, and notes |

## Related Skills & Agents

- `/create-issues` - Convierte diseño en issues accionables
- `/build` - Implementa features desde issues

## Version

- **Version:** v3.0
- **Last Updated:** 2026-03-26
