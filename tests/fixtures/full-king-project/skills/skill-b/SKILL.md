---
name: skill-b
version: 1.5
api_version: 1.0.0
description: "Secondary skill with cross-reference to skill-a."
---

# Skill B

## Instructions

This skill extends skill-a. Load skill-a first before using skill-b.

## Prerequisites

- Requires [skill-a](../skill-a/SKILL.md) to be loaded

## Examples

```bash
/load-skill skill-a
/load-skill skill-b
/audit run --extended
```
