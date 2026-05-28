# Promote — Pre-Deploy Gates (v2.0)

> Fases 1-3: gates de calidad antes del deploy. Entry point: [SKILL.md](SKILL.md)

---

## Fase 1: Readiness Check

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Coverage Gate (pre-condition — ejecutar PRIMERO):
   → Ver `rules/coverage-gate.md` para el proceso completo
   → Scope: `promote_scope` del `.king/coverage.yaml` (default: `full` — cobertura total del proyecto)
   → Si modo `error` y cobertura < threshold: **BLOQUEAR promote** — mostrar los 5 archivos con menor cobertura del reporte del gate, no continuar a Fase 2
   → Si modo `warn`, gate skipped, o runner no detectado: registrar en Promote Report y continuar
2. [ ] Verificar que QA batch o CASTLE pasaron (según destino):
   - → QA: qa-batch debe haber pasado (FORTIFIED o CONDITIONAL)
   - → Prod: release debe estar certificada (FORTIFIED obligatorio)
3. [ ] Verificar que no hay cambios sin commitear en develop/main
4. [ ] Verificar que el worktree destino existe
5. [ ] **Performance Gate** (si el proyecto tiene frontend):
   - Ejecutar según `rules/performance-gate.md`
   - Si modo `error` y cualquier score < threshold → BLOQUEAR promote
   - Si gate skipped (no frontend detectado) → continuar con nota en sesión

### CHECKPOINT
- [ ] Coverage Gate ejecutado — resultado registrado (PASS / WARN / SKIP / FAIL)
- [ ] QA/CASTLE verdict verified — worktree destination accessible — no uncommitted changes
- [ ] Performance Gate: PASS o skipped (no frontend)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Coverage Gate failed — promote bloqueado
Cause: La cobertura total del proyecto está por debajo del threshold configurado en `.king/coverage.yaml`.
Recovery:
  [ ] Option A: Volver a develop, agregar tests hasta alcanzar el threshold — re-ejecutar `/qa` + `/promote`
  [ ] Option B: Cambiar temporalmente a `mode: warn` en `.king/coverage.yaml` — el promote pasa con advertencia registrada
  [ ] Option C: Si falló por YAML malformado — corregir `.king/coverage.yaml` y reintentar

ERROR: Readiness check failed — promote prerequisites not met
Cause: QA batch not run, CASTLE verdict is BREACHED, uncommitted changes exist, or worktree destination is missing.
Recovery:
  [ ] Option A: If QA not run — run `/qa --batch` for the origin environment first, then retry `/promote`
  [ ] Option B: If uncommitted changes exist — commit or stash them in the origin branch before promoting
  [ ] Option C: If worktree does not exist — run `/worktree init` to create the destination worktree, then retry

---

## Fase 1b: Disaster Recovery Gate

### GATE IN
- [ ] Fase 1 (Readiness) completada — CASTLE/QA verificado, worktree destino accesible

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar Disaster Recovery Gate:
   → Ver `rules/dr-gate.md` para el proceso completo
   → **Scope**: solo aplica cuando el ambiente destino está en `scope.environments` de `.king/dr-setup.yaml` (default: `[prod]`) — SKIP automático para qa y dev
   → Leer `.king/dr-setup.yaml` si existe; si no, usar detección heurística de stack con estado
   → Si `enabled: false` en `.king/dr-setup.yaml` → SKIP sin error
   → Si modo `error` y gate FAIL → **BLOQUEAR promote** con mensaje accionable (ver `rules/dr-gate.md`)
   → Si modo `warn` (default) y gate FAIL → registrar WARN y continuar

### CHECKPOINT
- [ ] DR Gate ejecutado — resultado registrado (PASS / WARN / SKIP / FAIL)
- [ ] Si FAIL en modo `error`: promote detenido con mensaje que incluye el comando `/dr-setup`
- [ ] Si SKIP: motivo documentado en el Promote Report

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: DR Gate failed — promote a producción bloqueado por Disaster Recovery gate
Cause: `.king/dr-setup.yaml` no existe o tiene campos mínimos faltantes (rto_hours, rpo_hours, storage.backends).
Recovery:
  [ ] Option A: Ejecutar `/dr-setup` — detecta el stack automáticamente y genera `.king/dr-setup.yaml` + scripts de backup + runbook de failover
  [ ] Option B: Copiar el template manualmente: `cp templates/dr-setup.yaml .king/dr-setup.yaml` — editar con los valores del proyecto y reintentar `/promote`
  [ ] Option C: Si DR no aplica al proyecto, agregar `enabled: false` en `.king/dr-setup.yaml` — el gate se omitirá en futuros promotes sin error

---

## Fase 1c: Health-Check Setup Gate

### GATE IN
- [ ] Fase 1b (DR Gate) completada — resultado registrado

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar Health-Check Setup Gate:
   → Ver `rules/health-check-gate.md` para el proceso completo
   → **Scope**: solo aplica cuando el ambiente destino está en `scope.environments` de `.king/health-check-setup.yaml` (default: `[prod]`) — SKIP automático para qa y dev
   → Leer `.king/health-check-setup.yaml` si existe; si no, usar defaults (enabled:true, mode:warn, scope:[prod])
   → Si `enabled: false` en `.king/health-check-setup.yaml` → SKIP + WARN: documentar en exceptions.yml
   → Si modo `error` y gate FAIL → **BLOQUEAR promote** con mensaje: "Health check endpoints requeridos para producción. Ejecutá /health-check-setup"
   → Si modo `warn` (default) y gate FAIL → registrar WARN y continuar

### CHECKPOINT
- [ ] Health-Check Gate ejecutado — resultado registrado (PASS / WARN / SKIP / FAIL)
- [ ] Si FAIL en modo `error`: promote detenido con mensaje que incluye el comando `/health-check-setup`
- [ ] Si SKIP: motivo documentado en el Promote Report

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Health Check Gate failed — promote a producción bloqueado
Cause: Los endpoints `/health` y/o `/ready` no están implementados o no respetan el contrato esperado.
Recovery:
  [ ] Option A: Ejecutar `/health-check-setup` — detecta el stack automáticamente y genera los endpoints con el contrato correcto
  [ ] Option B: Verificar manualmente que `/health` retorna 200 `{status:"ok", version, timestamp}` y `/ready` retorna 200/503 con `{status, checks:{dep:"ok|fail"}}` — ajustar implementación si falta algún campo
  [ ] Option C: Si health checks no aplican al proyecto, agregar `enabled: false` en `.king/health-check-setup.yaml` y documentar la excepción en `exceptions.yml`

---

## Fase 2: Security Gate (via @security)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar Security Gate completo sobre el código a promover
2. [ ] Resultado VULNERABLE → BLOQUEAR promoción

### CHECKPOINT
- [ ] Security Gate completed — result is SECURE or REVIEW (not VULNERABLE)

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Security Gate returned VULNERABLE — promotion blocked
Cause: Code to be promoted contains secrets, OWASP vulnerabilities, or unsafe dependencies detected by the Security Gate.
Recovery:
  [ ] Option A: Document the specific finding (type, file, line) — return to @developer to fix the vulnerability on the feature branch, then re-run Security Gate before retrying promote
  [ ] Option B: If finding is a false positive, document the justification and get explicit user approval before reclassifying as REVIEW
  [ ] Option C: Never promote with a VULNERABLE result — if the fix requires significant time, keep the code in the origin environment and schedule the fix before the next promote attempt

---

## Fase 2b: Accessibility Gate

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Ejecutar Accessibility Gate completo sobre el código a promover
   > Seguir instrucciones de `rules/accessibility-gate.md`
2. [ ] Resultado `critical` o `serious` → BLOQUEAR promoción

### CHECKPOINT
- [ ] A11y Gate completado — resultado BLOCKED / WARNING / PASS / SKIP documentado en el reporte

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Accessibility Gate returned critical or serious violations — promotion blocked
Cause: UI changes introduce WCAG 2.2 AA violations that prevent user access or create barriers.
Recovery:
  [ ] Option A: Document each violation with `element`, `impact`, `wcag`, `wcag_url` — return to @developer to fix on the feature branch, then re-run the Accessibility Gate before retrying promote
  [ ] Option B: If finding is a false positive (axe misidentified the element), document justification in `.king/a11y.yaml` under `exceptions` with required `approved_by` field and `expires` date — get explicit user approval before adding the exception
  [ ] Option C: Never promote with `critical` or `serious` violations — if the fix requires significant time, keep code in origin environment and schedule fixes before the next promote attempt

---

#### Phase 2b Extension: /a11y-audit Gate (M-28)

> Extiende el Accessibility Gate cualitativo de arriba con el gate numérico `/a11y-audit`. Requiere que Phase 2b cualitativo haya pasado.

1. Si `.king/castle/a11y-report.json` existe Y fue generado hace < 24h → usar el report existente
2. Si no existe o es stale (>= 24h) → ejecutar `/a11y-audit`
3. Si `violations.critical > 0 OR violations.serious > 0` → **BLOCK** Phase 2c y promote
4. Si violations solo moderate/minor → WARN (no block), continuar a Phase 2c
5. Mensaje de block: "A11y gate FAILED: {N} critical + {M} serious violations. Run /a11y-fix and re-promote."

---

### Phase 2c: Lighthouse Gate + Mobile-First (M-50+M-51)

> Gate BLOQUEANTE en CI. Requiere que Phase 2b (a11y) haya pasado.
> Si Phase 2b bloqueó → esta fase NO ejecuta (log: "Phase 2c skipped — Phase 2b blocked").

#### Prerequisitos

- `CI=true` (o `KING_LIGHTHOUSE=true`) — **solo ejecuta en CI**. En dev → exit 0 + WARN "Lighthouse gate skipped in non-CI environment"
- Si `.king/lighthouse-baseline.json` NO existe → **grace period**: exit 0 + WARN "No Lighthouse baseline found — first /promote will create it. Run in CI to establish baseline."

#### Mobile-First Check (ejecutar ANTES del audit de desktop)

1. Verificar que el proyecto tiene `<meta name="viewport" content="width=device-width, initial-scale=1">` en todos los HTML/template entry points
2. Verificar que los breakpoints CSS siguen mobile-first pattern (media queries `min-width`, no solo `max-width`)
3. Si FALLA → BLOCK con mensaje: "Mobile-first check FAILED: {issue}. Fix before running Lighthouse."

#### Lighthouse Audit

1. Ejecutar Lighthouse CLI: `lighthouse {url} --output=json --quiet --chrome-flags="--headless --no-sandbox"`
   - Si Lighthouse CLI no disponible → WARN "Lighthouse CLI not installed. Skip gate or run: npm i -g lighthouse" → exit 0
2. Parsear score de `categories.performance.score * 100`
3. Comparar vs threshold en `.king/lighthouse.yaml` (default: 95)
4. Si score < threshold Y baseline existe → BLOCK: "Lighthouse score {actual} < required {threshold} (delta: -{gap})"
5. Si score >= threshold Y NO hay baseline → crear `.king/lighthouse-baseline.json`:
   ```json
   { "score": X.X, "url": "...", "created_at": "ISO8601", "environment": "CI" }
   ```
6. Si score >= threshold Y hay baseline → actualizar baseline si mejora >= 2 puntos

#### Mensajes

- Block: `[King/Lighthouse] BLOCKED: Score {actual}/100 < required {threshold}/100 (delta: -{gap}). Run /optimize or check bundle size.`
- Grace period: `[King/Lighthouse] WARN: No baseline found — establishing baseline on first successful run.`
- Pass: `[King/Lighthouse] ✅ Lighthouse {actual}/100 (threshold: {threshold}) — PASS`

---

## Fase 3: Database Migration Check (via /db-migrate)

### MUST DO
> ⚠️ All actions are MANDATORY

1. [ ] Invocar `/db-migrate --check --env {{DEST_ENV}}`:
   - Resultado posible: `CLEAN` | `PENDING` | `CHECKSUM_MISMATCH` | `N/A`
2. [ ] Si resultado == `PENDING` → **BLOCKING**: no continuar a Fase 4
   - Informar al usuario que debe ejecutar `/db-migrate apply --env {{DEST_ENV}}` primero
3. [ ] Si resultado == `CHECKSUM_MISMATCH` → **BLOCKING** + escalar a @architect:
   - Alguien modificó la BD directamente fuera del sistema de migraciones
   - Requiere decisión arquitectónica antes de continuar
4. [ ] Si resultado == `N/A` (proyecto sin BD o sin directorio de migraciones):
   - Documentar "No DB migration required" y continuar a Fase 4
5. [ ] Si resultado == `CLEAN` → continuar a Fase 4

### CHECKPOINT
- [ ] `/db-migrate --check` retorna `CLEAN` o `N/A` para el ambiente destino

### IF FAILS
> ❌ What to do when CHECKPOINT fails

ERROR: Database migration check failed — pending migrations or checksum mismatch detected
Cause: `/db-migrate --check` returned PENDING or CHECKSUM_MISMATCH for the destination environment.
Recovery:
  [ ] Option A (PENDING): Ejecutar `/db-migrate apply --env {{DEST_ENV}}` en el worktree
      destino para aplicar las migraciones pendientes. Verificar con `/db-migrate status`
      que el resultado es CLEAN, luego reintentar `/promote`.
  [ ] Option B (CHECKSUM_MISMATCH): Escalar a @architect — la BD del ambiente destino fue
      modificada directamente sin pasar por el sistema de migraciones. La decisión de qué
      hacer (recrear la BD, marcar divergencia como aceptada) es arquitectónica y no puede
      tomarse automáticamente.
  [ ] Option C (N/A): Documentar "No DB migration required" en el reporte de promote y
      continuar — este proyecto no usa BD o no tiene sistema de migraciones configurado.
