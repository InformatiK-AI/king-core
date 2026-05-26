# Promote — Deploy & Post-Deploy (v2.0)

> Fases 4-10: ejecución del deploy y verificación post-deploy. Entry point: [SKILL.md](SKILL.md)

---

## Fase 4: Environment Config

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar .env del worktree destino:
   - DATABASE_URL apunta a la DB correcta
   - PORT es el correcto para el ambiente
   - CORS_ORIGIN es apropiado
   - ANTHROPIC_API_KEY está configurada
2. [ ] Verificar que no hay conflictos de configuración

### CHECKPOINT
- [ ] Destination environment .env verified — all required variables present and correct

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Environment configuration invalid — required variable missing or incorrect
Cause: `.env` file in destination worktree is missing, has wrong DB URL, wrong port, or missing API key.
Recovery:
  [ ] Option A: Identify the specific missing or wrong variable — correct it in the destination worktree's `.env` file and re-verify
  [ ] Option B: If `.env` file does not exist in the destination worktree, copy from a template or the origin environment and adjust environment-specific values
  [ ] Option C: If `ANTHROPIC_API_KEY` is missing and cannot be set, STOP — promote cannot proceed without a valid API key; ask user to configure it

---

## Fase 5: Deploy (Sincronizar Worktree)

### MUST DO
> ⚠️ All actions are MANDATORY

**develop → qa:**
```bash
cd .worktrees/environments/qa/
git fetch origin
git checkout origin/develop --detach
```

**main → prod:**
```bash
cd .worktrees/environments/prod/
git fetch origin
git checkout origin/main --detach
```

### CHECKPOINT
- [ ] Worktree destination synchronized — HEAD pointing to correct origin branch

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Worktree sync failed — git fetch or checkout did not complete
Cause: Network unreachable, remote not configured, or worktree is in a detached HEAD conflict state.
Recovery:
  [ ] Option A: Verify network connectivity and run `git fetch origin` manually inside the worktree — if fetch succeeds, retry the checkout
  [ ] Option B: If worktree is in a conflict state, run `git worktree repair` from the main repository, then retry the sync
  [ ] Option C: If remote is unreachable, do not proceed with promote — document the failure and ask user to retry when the network is available

---

## Fase 6: Post-Deploy Setup

### MUST DO
> ⚠️ All actions are MANDATORY

```bash
cd [worktree-destino]/[project-root]
npm install
npm run build
```

### CHECKPOINT
- [ ] npm install and build completed successfully in destination worktree

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Post-deploy setup failed — npm install or build error in destination worktree
Cause: Missing dependency, build script error, or environment-specific configuration missing in the destination.
Recovery:
  [ ] Option A: Show the last 20 lines of the npm install or build stderr — identify whether it's a missing package, version conflict, or config error
  [ ] Option B: If a new dependency was added in the promoted code, verify `package.json` was updated and re-run `npm install`
  [ ] Option C: If build fails due to environment config (missing env var in build step), add it to the destination `.env` and retry

---

## Fase 7: Smoke Tests

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar health endpoint:
   ```bash
   curl -s http://localhost:[PORT]/api/health
   ```
2. [ ] Verificar que el frontend carga
3. [ ] Verificar que el proxy /api funciona

### CHECKPOINT
- [ ] Smoke tests passed — health endpoint responds and frontend loads

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Smoke tests failed — destination environment not responding correctly
Cause: Server not started, wrong port configured, proxy misconfigured, or application crashed on startup.
Recovery:
  [ ] Option A: Check if the server process is running on the correct port — start it manually if needed and re-run the smoke test
  [ ] Option B: If the health endpoint returns an error, check the server logs in the destination worktree for startup errors
  [ ] Option C: If smoke tests cannot pass after fixing startup issues, rollback by reverting the worktree sync (`git checkout origin/[previous-tag] --detach`) and notify user

---

## Fase 8: Health Verification

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Verificar que `/api/health` responde con status "ok"
2. [ ] Verificar que `apiKeyConfigured` es true
3. [ ] Verificar uptime

### CHECKPOINT
- [ ] Health check OK — status "ok" and apiKeyConfigured: true confirmed

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Health verification failed — API health endpoint not returning expected status
Cause: API key not configured in destination environment, health route misconfigured, or server not fully started yet.
Recovery:
  [ ] Option A: If `apiKeyConfigured` is false — verify `ANTHROPIC_API_KEY` is set in the destination worktree `.env` and restart the server
  [ ] Option B: If health endpoint returns 404 or connection refused — verify the server is running on the correct port and the health route is registered
  [ ] Option C: If health cannot be verified after 3 attempts, document as FAIL in the promote report and escalate to user before proceeding to GitHub Integration

---

## Fase 9: GitHub Integration

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Crear PR de promote con CASTLE Score como body:
   ```bash
   gh pr create --title "promote: [ambiente] - [fecha]" --body "[CASTLE Report]"
   ```

### CHECKPOINT
- [ ] Promote PR created in GitHub with CASTLE score in body

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: GitHub PR creation failed for promote
Cause: `gh` CLI not authenticated, no remote configured, or repository not accessible.
Recovery:
  [ ] Option A: Run `gh auth status` and `gh auth login` if not authenticated — retry PR creation
  [ ] Option B: If the repository has no remote, document the CASTLE score in the promote report and skip the PR — note it as a manual step for the user
  [ ] Option C: If PR already exists for this promote (duplicate), use `gh pr view` to find it and update its body with the current CASTLE score instead of creating a new one

---

## Fase 10: Report

### MUST DO
> ⚠️ All actions are MANDATORY

```
## Promote Report

### Origen: [develop|qa]
### Destino: [qa|prod]
### Fecha: [fecha]

### Pre-Deploy
- Coverage Gate: [PASS|WARN|SKIP|FAIL] ({actual}% actual, threshold: {t}%)
- DR Gate: [PASS|WARN|SKIP|FAIL] (config: .king/dr-setup.yaml | RTO: Nh | RPO: Nh)
- Health-Check Setup Gate: [PASS|WARN|SKIP|FAIL] (config: .king/health-check-setup.yaml)
- Readiness: [PASS|FAIL]
- Security Gate: [SECURE|VULNERABLE]
- Accessibility Gate: [BLOCKED|PASS|SKIP]
- DB Migration: [OK|PENDING|N/A]
- Environment Config: [OK|ISSUES]

### Deploy
- Worktree sync: [OK|FAIL]
- npm install: [OK|FAIL]
- npm build: [OK|FAIL]

### Post-Deploy
- Health: [OK|FAIL]
- Smoke tests: [PASS|FAIL]

### CASTLE Score: [resultado S + E]
### Resultado: [EXITOSO|FALLIDO]
```

### CHECKPOINT
- [ ] Promote report generated — pre-deploy, deploy, post-deploy and CASTLE score documented

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Promote report not completed — required sections missing
Cause: One or more report sections (Readiness, Security Gate, Deploy status, Health, Smoke tests) could not be assembled.
Recovery:
  [ ] Option A: Reconstruct missing sections from outputs captured during each phase — use git log, build output, curl responses, and security gate results
  [ ] Option B: If some phases were skipped (e.g., no DB, no GitHub), document them explicitly as "N/A" with justification — do not leave sections blank
  [ ] Option C: Output a partial report with Status: PARTIAL — the promote result (EXITOSO/FALLIDO) is mandatory even in a partial report
