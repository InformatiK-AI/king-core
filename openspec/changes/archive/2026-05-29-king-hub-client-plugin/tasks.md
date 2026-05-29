# Tasks — King Hub plugin cliente

> Fase: sdd-tasks.

## B0 — Estructura
- [x] git init king-hub + .gitignore + CHANGELOG + .claude-plugin/plugin.json (requires king-framework).
- [x] Copiar skills/_shared de king-core.

## B1 — Skills + commands
- [x] hub-search/SKILL.md + REFERENCE.md (search QS≥40, CLI+fallback HTTP).
- [x] hub-install/SKILL.md + REFERENCE.md (cadena GPG 6 pasos, fallo atómico).
- [x] hub-publish/SKILL.md + REFERENCE.md (validar manifest + firmar + publicar).
- [x] hub-stats/SKILL.md + REFERENCE.md (métricas del publicador).
- [x] commands/{hub-search,hub-install,hub-publish,hub-stats}.md.

## B2 — Knowledge
- [x] knowledge/hub-publishing-guide.md (checklist Tier 3, GPG, verify, SLA, endpoint).

## B3 — Verify
- [x] audit_self --scope king-hub/skills → 75.70 (≥75) PASS.
- [x] check_api_version (4 skills) → EXIT 0.
- [x] plugin.json JSON válido.

## B4 — Archive
- [x] SDD change archivado; state.yaml + verify-report.
- [ ] Commits locales (king-hub + king-core); push diferido a confirmación del usuario.
