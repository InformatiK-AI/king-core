# Tasks — M-64 VS Code Extension (spec)

> Detalle en `mejora/planes-detallados/M12-developer-experience-tooling.md §6 (T41-T50)`. T49-T50 excluidas (código TS → repo externo).

## Apply
- [x] T41 `knowledge/universal/vscode-extension-spec.md` — propósito, arquitectura, comunicación con apex-core
- [x] T42 Spec Status Bar — datos, file watcher, estados de color, click
- [x] T43 Spec Command Palette — 8 comandos, invocación shell exec
- [x] T44 Spec Diff Viewer — diff de /build, anotaciones, Apply Fix
- [x] T45 Spec Coverage Gutters — formato coverage-report.json (M01), mapeo a líneas
- [x] T46 Spec A11y Warnings — axe-core, WCAG inline, link a regla
- [x] T47 Spec settings (`king.*`)
- [x] T48 Spec testing (VS Code Testing API, fixtures, casos por feature)
- [~] T49 package.json/extension.ts — EXCLUIDO (repo externo king-framework/vscode-extension)
- [~] T50 Status Bar TS impl — EXCLUIDO (repo externo)

## Verify
- [x] Cobertura Gherkin §7: 5 escenarios reflejados
- [x] Cross-ref a cli-architecture.md (backend apex-core)
- [x] CASTLE ≥ 85, pytest estructural verde
