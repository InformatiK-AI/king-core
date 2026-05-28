---
name: subdimensions
part-of: audit
---

# Audit Sub-Dimensions (v1.0)

> Archivo parte de: `skills/audit/SKILL.md`
> Contiene: Catálogo de 25 sub-dimensiones, pesos parciales, criterios de scoring y clasificación autofix

---

## Sub-Dimension Catalog

| ID | Name | Parent Dimension | Weight % | Score Criteria (0.0–1.0) | Autofix Class | Notes |
|----|------|-----------------|----------|--------------------------|---------------|-------|
| I-01 | metadata-completeness | Inventory | 8% | 1.0 if all required frontmatter fields present (name, version, description); 0.5 if ≥50% present; 0.0 if absent | auto | |
| I-02 | description-quality | Inventory | 4% | 1.0 if description is non-empty and ≥10 words; 0.5 if present but short (<10 words); 0.0 if absent or placeholder | guided | |
| I-03 | author-present | Inventory | 4% | 1.0 if `author` field present and non-empty; 0.0 if absent | auto | |
| I-04 | license-declared | Inventory | 4% | 1.0 if `license` field present and non-empty; 0.0 if absent | auto | |
| F-01 | directory-structure | Format | 6% | 1.0 if all required directories exist per plugin manifest; 0.5 if ≥50% present; 0.0 if <50% | guided | |
| F-02 | entrypoint-exists | Format | 6% | 1.0 if declared entrypoint file exists and is non-empty; 0.0 if missing or empty | auto | |
| F-03 | skill-file-present | Format | 5% | 1.0 if `SKILL.md` exists in skill root; 0.0 if absent | auto | |
| F-04 | api-version-present | Format | 0%* | 1.0 if `api_version` field present in frontmatter; 0.0 if absent | auto | *WARNING-only — pending M-71 (api_version field). Weight 0% — does NOT contribute to health_score. |
| F-05 | frontmatter-validity | Format | 3% | 1.0 if frontmatter parses as valid YAML with no syntax errors; 0.5 if present but has warnings; 0.0 if malformed or absent | guided | |
| X-01 | command-declarations | Cross-refs | 7% | 1.0 if all commands declared in manifest are present in skill files; 0.5 if ≥50% declared; 0.0 if <50% | manual | |
| X-02 | command-descriptions | Cross-refs | 5% | 1.0 if all declared commands have non-empty descriptions; 0.5 if ≥50% have descriptions; 0.0 if <50% | guided | |
| X-03 | command-examples | Cross-refs | 4% | 1.0 if ≥1 usage example per command; 0.5 if some commands have examples; 0.0 if no examples | guided | |
| X-04 | hook-declarations | Cross-refs | 4% | 1.0 if all declared hooks resolve to existing handler files; 0.5 if ≥50% resolve; 0.0 if <50% | manual | |
| Q-01 | test-coverage-declared | Instructions quality | 5% | 1.0 if test coverage target declared in project config; 0.5 if partially declared; 0.0 if absent | guided | |
| Q-02 | test-runner-present | Instructions quality | 4% | 1.0 if test runner config file exists (jest.config.*, vitest.config.*, etc.); 0.0 if absent | auto | |
| Q-03 | changelog-present | Instructions quality | 3% | 1.0 if `CHANGELOG.md` or `HISTORY.md` exists and is non-empty; 0.0 if absent or empty | guided | |
| Q-04 | version-bump-consistency | Instructions quality | 3% | 1.0 if version in frontmatter matches version in package.json/manifest; 0.5 if one source missing; 0.0 if mismatch | manual | |
| C-01 | readme-present | Communication | 5% | 1.0 if `README.md` exists and is ≥50 lines; 0.5 if present but <50 lines; 0.0 if absent | guided | |
| C-02 | usage-examples-documented | Communication | 4% | 1.0 if README contains ≥1 usage example block (code fence); 0.5 if prose examples only; 0.0 if no examples | guided | |
| C-03 | api-reference-present | Communication | 3% | 1.0 if API reference section exists in docs or README; 0.5 if partial reference; 0.0 if absent | guided | |
| C-04 | inline-comments-quality | Communication | 3% | 1.0 if inline comments cover non-obvious logic (≥20% of complex blocks); 0.5 if sparse; 0.0 if absent | manual | |
| E-01 | install-script-present | Efficiency | 3% | 1.0 if install script exists (`install.sh`, `Makefile install`, or package manager equivalent); 0.0 if absent | auto | |
| E-02 | uninstall-script-present | Efficiency | 3% | 1.0 if uninstall/cleanup script exists; 0.0 if absent | guided | |
| E-03 | dependency-manifest | Efficiency | 2% | 1.0 if dependency manifest exists (package.json, requirements.txt, Gemfile, etc.) and is non-empty; 0.0 if absent | auto | |
| E-04 | upgrade-notes-present | Efficiency | 2% | 1.0 if CHANGELOG or UPGRADE.md contains upgrade/migration notes for latest version; 0.5 if partial; 0.0 if absent | guided | |

---

## Weight Arithmetic

| Group | IDs | Partial Weights | Group Total |
|-------|-----|-----------------|-------------|
| Inventory (I) | I-01, I-02, I-03, I-04 | 8 + 4 + 4 + 4 | **20%** |
| Format (F) | F-01, F-02, F-03, F-04*, F-05 | 6 + 6 + 5 + 0* + 3 | **20%** |
| Cross-refs (X) | X-01, X-02, X-03, X-04 | 7 + 5 + 4 + 4 | **20%** |
| Instructions quality (Q) | Q-01, Q-02, Q-03, Q-04 | 5 + 4 + 3 + 3 | **15%** |
| Communication (C) | C-01, C-02, C-03, C-04 | 5 + 4 + 3 + 3 | **15%** |
| Efficiency (E) | E-01, E-02, E-03, E-04 | 3 + 3 + 2 + 2 | **10%** |
| **TOTAL** | | | **100%** |

> *F-04 weight is 0% in health_score computation. The face-value partial weight (3%) is excluded; Format group contributes via F-01+F-02+F-03+F-05 = 6+6+5+3 = 20%.

---

## Scoring Rules

1. **Binary sub-dimensions** (present/absent): score is exactly `1.0` or `0.0`.
2. **Graduated sub-dimensions**: score is in `{0.0, 0.5, 1.0}` per criteria above.
3. **F-04 special case**: score is computed and reported (for visibility), but its contribution to `health_score` is always `0.0` regardless of score value, until M-71 is implemented.
4. **health_score contribution** per sub-dim: `score × weight_pct` (F-04 excluded).

---

## Autofix Classes

| Class | Behavior |
|-------|----------|
| `auto` | Executed silently when `--auto-fix` is passed. See AUTOFIX.md. |
| `guided` | Step-by-step instructions shown. User executes manually. |
| `manual` | Issue reported only. Requires human judgment. |
