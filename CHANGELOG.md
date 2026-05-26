# Changelog

## [1.9.4] — 2026-05-26

### Fixes
- **frontmatter BOM**: eliminado UTF-8 BOM (`EF BB BF`) de 116 archivos `.md` en todo el ecosistema King (king-framework, king-entrepreneur, king-infra, king-content, king-ai, king-mobile, king-legal). El BOM impedía el parsing correcto del frontmatter YAML.
- **schema SDD**: normalizados 12 SKILL.md SDD del formato Gentleman-Skills (`license`, `metadata.author`, `metadata.version`) al formato King v2.0 (`version` top-level). Skills afectados: sdd-init, sdd-explore, sdd-propose, sdd-spec, sdd-design, sdd-tasks, sdd-apply, sdd-verify, sdd-archive, sdd-onboard, sdd-orchestrator, `_shared`.

---

## [1.9.3] — 2026-05-25

### Fixes
- **plugin.json**: corregido nombre del plugin de `king-framework` a `king-core`. Actualizados `homepage`, `repository` y `description` para apuntar al repo correcto.

---

## [1.9.2] — 2026-05-25

### Fixes
- **commit**: eliminada atribución de co-authoring (`Co-Authored-By: Claude`) del skill `/commit`. El skill respeta la convención del usuario definida en `CLAUDE.md`.

---

## [1.9.1] — 2026-05-25

- Initial release de king-core: 47 skills, 10 agentes, pipeline SDLC completo (genesis → brainstorm → plan → build → review → qa → merge → release).
