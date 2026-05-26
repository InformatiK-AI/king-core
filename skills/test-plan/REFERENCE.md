# REFERENCE — /test-plan

> Templates pre-construidos para usar en Fase 4: Generate.
> Esta es la fuente canonica para el HTML generado por el skill.

---

## Fragment 1: CSS Design System King

> Pegar verbatim dentro de `<style>` del HTML generado.

```css
@import url('https://fonts.googleapis.com/css2?family=DM+Sans:wght@400;500;600;700&family=JetBrains+Mono:wght@400;500&display=swap');

:root {
  /* === KING IDENTITY === */
  --king-crimson:        #DC143C;
  --king-crimson-dark:   #8B0000;
  --king-crimson-light:  #FF2744;
  --king-gold:           #D4AF37;
  --king-gold-dark:      #B8960F;
  --king-gold-light:     #E8C84A;

  /* === BACKGROUNDS === */
  --bg:                  #0a0a0f;
  --bg-darker:           #060609;
  --bg-card:             #12111a;
  --bg-card-hover:       #1a1825;
  --bg-elevated:         #1e1c2a;
  --bg-sidebar:          #0d0c14;

  /* === BORDERS === */
  --border:              #2a2435;
  --border-light:        #3d3550;
  --border-gold:         rgba(212, 175, 55, .25);
  --border-crimson:      rgba(220, 20, 60, .25);

  /* === TEXT === */
  --text:                #e8e0d4;
  --text-muted:          #9a8f82;
  --text-dim:            #6b6058;

  /* === STATUS COLORS === */
  --green:               #34d399;
  --green-bg:            rgba(52, 211, 153, .08);
  --green-border:        rgba(52, 211, 153, .2);
  --red:                 #f87171;
  --red-bg:              rgba(248, 113, 113, .08);
  --red-border:          rgba(248, 113, 113, .2);
  --yellow:              #fbbf24;
  --yellow-bg:           rgba(251, 191, 36, .08);
  --yellow-border:       rgba(251, 191, 36, .2);
  --orange:              #fb923c;
  --orange-bg:           rgba(251, 146, 60, .08);
  --orange-border:       rgba(251, 146, 60, .2);
  --purple:              #a78bfa;
  --purple-bg:           rgba(167, 139, 250, .08);
  --purple-border:       rgba(167, 139, 250, .2);
  --cyan:                #22d3ee;
  --cyan-bg:             rgba(34, 211, 238, .08);
  --cyan-border:         rgba(34, 211, 238, .2);
  --blue:                #60a5fa;
  --blue-bg:             rgba(96, 165, 250, .08);
  --blue-border:         rgba(96, 165, 250, .2);

  /* === SEMANTIC KING === */
  --crimson-bg:          rgba(220, 20, 60, .08);
  --crimson-border:      rgba(220, 20, 60, .2);
  --gold-bg:             rgba(212, 175, 55, .06);
  --gold-border:         rgba(212, 175, 55, .15);

  /* === TYPOGRAPHY === */
  --font-ui:    'DM Sans', system-ui, -apple-system, sans-serif;
  --font-mono:  'JetBrains Mono', 'Fira Code', monospace;

  /* === SPACING === */
  --card-pad:    1.5rem;
  --gap-sm:      0.75rem;
  --gap-md:      1rem;
  --gap-lg:      1.5rem;
  --gap-xl:      2rem;

  /* === RADII === */
  --radius:      12px;
  --radius-sm:   8px;
  --radius-xs:   6px;
  --radius-pill: 20px;

  /* === SHADOWS === */
  --shadow-sm:   0 1px 3px rgba(0,0,0,.4);
  --shadow-md:   0 4px 16px rgba(0,0,0,.5);
  --shadow-crimson: 0 0 20px rgba(220,20,60,.15);
  --shadow-gold:    0 0 20px rgba(212,175,55,.1);

  /* === TRANSITIONS === */
  --transition-fast:   all .2s ease;
  --transition-normal: all .3s ease;
}

*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
body { font-family: var(--font-ui); background: var(--bg); color: var(--text); min-height: 100vh; line-height: 1.6; }

/* === PORTADA === */
.portada {
  background: linear-gradient(135deg, var(--bg-darker) 0%, var(--bg-card) 100%);
  border-bottom: 1px solid var(--border-crimson);
  padding: 3rem 2rem 2rem; text-align: center;
}
.portada h1 { font-size: 2rem; color: var(--king-crimson-light); margin-bottom: 0.5rem; }
.portada .subtitle { color: var(--text-muted); font-size: 0.95rem; }
.portada input, .portada select {
  background: var(--bg-elevated); border: 1px solid var(--border-light);
  color: var(--text); border-radius: var(--radius-sm); padding: 0.5rem 0.75rem; font-family: var(--font-ui);
}

/* === ACTION BAR === */
.action-bar {
  background: var(--bg-card); border-bottom: 1px solid var(--border);
  padding: 1rem 2rem; display: flex; gap: var(--gap-md); flex-wrap: wrap; align-items: center;
  position: sticky; top: 0; z-index: 100;
}
.btn {
  padding: 0.5rem 1rem; border-radius: var(--radius-sm); border: 1px solid var(--border-light);
  background: var(--bg-elevated); color: var(--text); cursor: pointer; transition: var(--transition-fast); font-size: 0.875rem;
}
.btn:hover { background: var(--bg-card-hover); border-color: var(--king-gold); }
.btn-primary { background: var(--king-crimson-dark); border-color: var(--king-crimson); color: #fff; }
.btn-primary:hover { background: var(--king-crimson); }

/* === STATS GRID === */
.stats-grid {
  display: grid; grid-template-columns: repeat(auto-fit, minmax(120px, 1fr));
  gap: var(--gap-md); padding: 1.5rem 2rem;
}
.stat-num { font-size: 2rem; font-weight: 700; color: var(--king-gold); }
.stat-label { font-size: 0.75rem; color: var(--text-muted); text-transform: uppercase; letter-spacing: 0.05em; }

/* === MODULE SECTION === */
.module-section {
  margin: 1.5rem 2rem; background: var(--bg-card);
  border: 1px solid var(--border); border-radius: var(--radius); overflow: hidden;
}
.module-header {
  display: flex; justify-content: space-between; align-items: center;
  padding: 1rem 1.5rem; cursor: pointer; border-left: 4px solid var(--king-crimson); transition: var(--transition-fast);
}
.module-header:hover { background: var(--bg-elevated); }
.module-section.collapsed .module-body { display: none; }

/* Module color classes m01-m12 */
.m01 .module-header { border-left-color: #DC143C; }
.m02 .module-header { border-left-color: #D4AF37; }
.m03 .module-header { border-left-color: #34d399; }
.m04 .module-header { border-left-color: #60a5fa; }
.m05 .module-header { border-left-color: #a78bfa; }
.m06 .module-header { border-left-color: #fb923c; }
.m07 .module-header { border-left-color: #22d3ee; }
.m08 .module-header { border-left-color: #f472b6; }
.m09 .module-header { border-left-color: #2dd4bf; }
.m10 .module-header { border-left-color: #818cf8; }
.m11 .module-header { border-left-color: #fbbf24; }
.m12 .module-header { border-left-color: #f87171; }
/* Fallback ciclico: colorClass = 'm' + String((index % 12) + 1).padStart(2,'0') */

/* === TC TABLE === */
.tc-table { width: 100%; border-collapse: collapse; font-size: 0.875rem; }
.tc-table th { background: var(--bg-elevated); padding: 0.75rem 1rem; text-align: left; color: var(--text-muted); border-bottom: 1px solid var(--border); }
.tc-table td { padding: 0.75rem 1rem; border-bottom: 1px solid var(--border); vertical-align: top; }
.tc-row.status-aprobado { background: var(--green-bg); }
.tc-row.status-fallado  { background: var(--red-bg); }

/* === STATUS RADIOS === */
.status-group { display: flex; gap: 0.5rem; flex-wrap: wrap; }
.status-radio { display: none; }
.status-label { padding: 0.25rem 0.6rem; border-radius: var(--radius-pill); border: 1px solid var(--border-light); cursor: pointer; font-size: 0.75rem; transition: var(--transition-fast); }
.status-radio:checked + .status-label.aprobado { background: var(--green-bg); border-color: var(--green); color: var(--green); }
.status-radio:checked + .status-label.fallado   { background: var(--red-bg);   border-color: var(--red);   color: var(--red); }
.status-radio:checked + .status-label.bloqueado { background: var(--orange-bg); border-color: var(--orange); color: var(--orange); }
.status-radio:checked + .status-label.n-a       { background: var(--yellow-bg); border-color: var(--yellow); color: var(--yellow); }

/* === ACTA DE CIERRE === */
.acta-grid { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: var(--gap-md); }
.acta-field label { display: block; font-size: 0.8rem; color: var(--text-muted); margin-bottom: 0.3rem; }
.acta-field input, .acta-field select, .acta-field textarea {
  width: 100%; background: var(--bg-elevated); border: 1px solid var(--border-light);
  color: var(--text); border-radius: var(--radius-sm); padding: 0.5rem 0.75rem; font-family: var(--font-ui); resize: vertical;
}

/* === FILTER BAR === */
.filter-bar { display: flex; gap: 0.5rem; padding: 0.75rem 2rem; flex-wrap: wrap; }
.filter-btn { padding: 0.3rem 0.8rem; border-radius: var(--radius-pill); border: 1px solid var(--border); background: transparent; color: var(--text-muted); cursor: pointer; font-size: 0.8rem; }
.filter-btn.active { border-color: var(--king-gold); color: var(--king-gold); background: var(--gold-bg); }

/* === TOAST === */
#toast {
  position: fixed; bottom: 2rem; right: 2rem;
  background: var(--bg-elevated); border: 1px solid var(--border-gold);
  color: var(--king-gold); padding: 0.75rem 1.25rem; border-radius: var(--radius);
  opacity: 0; pointer-events: none; transition: opacity .3s ease; z-index: 999; font-size: 0.875rem;
}
#toast.show { opacity: 1; }

/* === EVIDENCE === */
.evidence-thumbs { display: flex; gap: 0.5rem; flex-wrap: wrap; margin-top: 0.5rem; }
.evidence-thumb { width: 60px; height: 60px; object-fit: cover; border-radius: var(--radius-xs); cursor: pointer; border: 2px solid var(--border-light); }
.evidence-thumb:hover { border-color: var(--king-gold); }

/* === PRINT === */
@media print {
  body { background: #fff; color: #111; }
  .action-bar, .filter-bar, #toast { display: none !important; }
  .module-section { break-inside: avoid; border: 1px solid #ccc; print-color-adjust: exact; -webkit-print-color-adjust: exact; }
  .module-header { background: #f5f5f5; }
  .module-section.collapsed .module-body { display: block !important; }
}

/* === RESPONSIVE === */
@media (max-width: 768px) {
  .portada { padding: 2rem 1rem 1.5rem; }
  .portada h1 { font-size: 1.5rem; }
  .module-section { margin: 1rem; }
}
```

---

## Fragment 2: HTML Structure

> Skeleton del HTML. Reemplazar todos los `{{PLACEHOLDER}}` con datos reales.

```html
<!DOCTYPE html>
<html lang="es">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Plan de Pruebas — {{FEATURE_NAME}}</title>
  <style>/* Fragment 1 CSS aqui */</style>
</head>
<body>

<section class="portada">
  <div style="font-size:2.5rem;margin-bottom:1rem">&#x1F451;</div>
  <h1 id="titulo-plan">Plan de Pruebas: {{FEATURE_NAME}}</h1>
  <div class="subtitle">
    Feature: <input id="portada-feature" type="text" value="{{FEATURE_NAME}}" style="width:200px">
    &nbsp;|&nbsp; Rol: <input id="portada-rol" type="text" value="{{ROLE_NAME}}" style="width:150px">
    &nbsp;|&nbsp; Fecha: <input id="portada-fecha" type="date" value="{{DATE_ISO}}" style="width:140px">
    &nbsp;|&nbsp; Ejecutor: <input id="portada-ejecutor" type="text" placeholder="Nombre QA" style="width:150px">
  </div>
</section>

<div class="action-bar">
  <button class="btn" onclick="expandAll()">&#x25BC; Expandir</button>
  <button class="btn" onclick="collapseAll()">&#x25B2; Colapsar</button>
  <button class="btn btn-primary" onclick="exportJSON()">&#x2B07; Export JSON</button>
  <button class="btn" onclick="window.print()">&#x1F5A8; Imprimir A4</button>
  <div class="filter-bar" style="padding:0;margin-left:auto;">
    <button class="filter-btn active" onclick="setFilter('all')">Todos</button>
    <button class="filter-btn" onclick="setFilter('aprobado')">Aprobados</button>
    <button class="filter-btn" onclick="setFilter('fallado')">Fallados</button>
    <button class="filter-btn" onclick="setFilter('pendiente')">Pendientes</button>
  </div>
</div>

<section style="padding:1.5rem 2rem;">
  <h2 style="font-size:1.1rem;color:var(--text-muted);margin-bottom:1rem;">Resumen Ejecutivo</h2>
  <div class="stats-grid" style="padding:0;border:none;background:transparent;">
    <div class="stat-item"><div class="stat-num" id="stat-total">0</div><div class="stat-label">Total Casos</div></div>
    <div class="stat-item"><div class="stat-num" style="color:var(--green)" id="stat-aprobados">0</div><div class="stat-label">Aprobados</div></div>
    <div class="stat-item"><div class="stat-num" style="color:var(--red)" id="stat-fallados">0</div><div class="stat-label">Fallados</div></div>
    <div class="stat-item"><div class="stat-num" style="color:var(--yellow)" id="stat-pendientes">0</div><div class="stat-label">Pendientes</div></div>
    <div class="stat-item"><div class="stat-num" style="color:var(--king-gold)" id="stat-pct">0%</div><div class="stat-label">Completado</div></div>
  </div>
</section>

<div id="modules-container"></div>

<section class="module-section" id="section-OT" style="margin:1.5rem 2rem;">
  <div class="module-header" onclick="toggleModule('OT')">
    <h3>&#x2795; Otras Pruebas (Ad-hoc)</h3>
    <span id="stats-OT" style="font-size:0.8rem;color:var(--text-muted)"></span>
  </div>
  <div class="module-body" id="body-OT">
    <div style="padding:1rem 1.5rem;">
      <button class="btn" onclick="addOtraPrueba()">+ Agregar caso ad-hoc</button>
    </div>
    <div id="otras-container"></div>
  </div>
</section>

<section style="margin:1.5rem 2rem;background:var(--bg-card);border:1px solid var(--border-gold);border-radius:var(--radius);padding:1.5rem;">
  <h2 style="font-size:1rem;color:var(--king-gold);margin-bottom:1rem;">&#x1F4DC; Acta de Cierre</h2>
  <div class="acta-grid">
    <div class="acta-field"><label>Evaluador</label><input id="acta-evaluador" type="text" placeholder="Nombre y cargo"></div>
    <div class="acta-field"><label>Fecha Cierre</label><input id="acta-fecha" type="date"></div>
    <div class="acta-field"><label>Resultado</label>
      <select id="acta-resultado">
        <option value="">Seleccionar</option>
        <option value="APROBADO">APROBADO</option>
        <option value="APROBADO_OBS">APROBADO CON OBSERVACIONES</option>
        <option value="RECHAZADO">RECHAZADO</option>
      </select>
    </div>
    <div class="acta-field" style="grid-column:1/-1;"><label>Observaciones</label>
      <textarea id="acta-obs" rows="3" placeholder="Observaciones del cierre..."></textarea>
    </div>
  </div>
</section>

<footer style="text-align:center;padding:2rem;color:var(--text-dim);font-size:0.8rem;border-top:1px solid var(--border);">
  Generado con King Framework /test-plan &nbsp;|&nbsp; {{DATE_DISPLAY}}
</footer>

<div id="toast"></div>

<script>
  window.__SEED__ = { modules: [/* MODULES[] generado en Fase 3 */] };
  /* Fragment 3 JS aqui */
</script>
</body>
</html>
```

---

## Fragment 3: JavaScript Engine

> Motor JS completo. Usar JSON.parse() para parsing. Toda interpolacion de datos dinamicos
> DEBE pasar por escapeHtml(). Cada localStorage.setItem() DEBE estar en try/catch.

```javascript
// ============================================================
// KING TEST PLAN ENGINE v1.0
// SEGURIDAD: escapeHtml() obligatorio en toda interpolacion HTML
// ============================================================

const MODULES = window.__SEED__.modules;
const STORAGE_KEY       = 'king_tp_{{SLUG}}_{{ROLE}}_v1';
const STORAGE_KEY_OT    = 'king_tp_{{SLUG}}_ot_v1';
const STORAGE_KEY_PORTA = 'king_tp_{{SLUG}}_portada_v1';
const STORAGE_KEY_ACTA  = 'king_tp_{{SLUG}}_acta_v1';

// HTML Entity Encoding — USAR EN TODA INTERPOLACION DE DATOS DINAMICOS
function escapeHtml(str) {
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

// ============================================================
// STATE — localStorage con try/catch en CADA setItem
// ============================================================
let state = {};

function loadState() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    state = raw ? JSON.parse(raw) : {};
  } catch (e) { state = {}; }
}

function saveState() {
  try {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
  } catch (e) {
    showToast('Advertencia: no se pudo guardar (localStorage lleno)');
  }
}

function getStatus(modId, caseId) {
  return (state[modId] && state[modId][caseId]) ? state[modId][caseId].status : 'pendiente';
}

function getObs(modId, caseId) {
  return (state[modId] && state[modId][caseId]) ? (state[modId][caseId].obs || '') : '';
}

function setStateValue(modId, caseId, key, value) {
  if (!state[modId]) state[modId] = {};
  if (!state[modId][caseId]) state[modId][caseId] = { status: 'pendiente', obs: '' };
  state[modId][caseId][key] = value;
  saveState();
}

// ============================================================
// MODULE BUILDER — usa escapeHtml() en toda interpolacion
// ============================================================
function buildModules() {
  const container = document.getElementById('modules-container');
  if (!container) return;
  container.replaceChildren(); // limpia sin asignar markup directo
  MODULES.forEach((mod, idx) => {
    const colorClass = 'm' + String((idx % 12) + 1).padStart(2, '0');
    const section = buildModuleElement(mod, colorClass);
    container.appendChild(section);
  });
}

// Construye el elemento DOM de un modulo usando createElement para seguridad
function buildModuleElement(mod, colorClass) {
  const section = document.createElement('section');
  section.className = 'module-section ' + escapeHtml(colorClass);
  section.id = 'mod-' + escapeHtml(mod.id);

  const header = document.createElement('div');
  header.className = 'module-header';
  header.addEventListener('click', () => toggleModule(mod.id));

  const title = document.createElement('h3');
  title.textContent = mod.name; // textContent escapa automaticamente

  const statsSpan = document.createElement('span');
  statsSpan.id = 'stats-' + escapeHtml(mod.id);
  statsSpan.style.cssText = 'font-size:0.8rem;color:var(--text-muted)';

  header.appendChild(title);
  header.appendChild(statsSpan);
  section.appendChild(header);

  const body = document.createElement('div');
  body.className = 'module-body';
  body.id = 'body-' + escapeHtml(mod.id);

  const table = buildCaseTable(mod);
  body.appendChild(table);
  section.appendChild(body);

  return section;
}

function buildCaseTable(mod) {
  const table = document.createElement('table');
  table.className = 'tc-table';

  const thead = table.createTHead();
  const hrow = thead.insertRow();
  ['#', 'Caso de Prueba', 'Severidad', 'Estado', 'Observaciones'].forEach(h => {
    const th = document.createElement('th');
    th.textContent = h;
    hrow.appendChild(th);
  });

  const tbody = table.createTBody();
  mod.cases.forEach(c => {
    const row = buildCaseRow(mod.id, c);
    tbody.appendChild(row);
  });

  return table;
}

function buildCaseRow(modId, c) {
  const st = getStatus(modId, c.id);
  const obs = getObs(modId, c.id);

  const row = document.createElement('tr');
  row.className = 'tc-row status-' + st;
  row.id = 'row-' + escapeHtml(modId) + '-' + escapeHtml(c.id);

  // Columna ID
  const tdId = document.createElement('td');
  tdId.textContent = c.id;
  tdId.style.cssText = 'color:var(--text-dim);font-size:0.8rem';
  row.appendChild(tdId);

  // Columna Descripcion
  const tdDesc = document.createElement('td');
  const descDiv = document.createElement('div');
  descDiv.style.cssText = 'font-weight:500;margin-bottom:0.3rem';
  descDiv.textContent = c.desc;
  tdDesc.appendChild(descDiv);
  if (c.steps && c.steps.length) {
    const details = document.createElement('details');
    const summary = document.createElement('summary');
    summary.textContent = 'Ver pasos';
    summary.style.cssText = 'cursor:pointer;color:var(--text-muted);font-size:0.8rem';
    details.appendChild(summary);
    const ol = document.createElement('ol');
    ol.style.cssText = 'margin:0.5rem 0 0 1rem;font-size:0.8rem';
    c.steps.forEach(s => {
      const li = document.createElement('li');
      li.textContent = s;
      ol.appendChild(li);
    });
    details.appendChild(ol);
    tdDesc.appendChild(details);
  }
  row.appendChild(tdDesc);

  // Columna Severidad
  const tdSev = document.createElement('td');
  tdSev.textContent = c.severity || 'MED';
  tdSev.style.cssText = 'font-size:0.75rem;color:var(--text-muted)';
  row.appendChild(tdSev);

  // Columna Estado (radios)
  const tdSt = document.createElement('td');
  const group = document.createElement('div');
  group.className = 'status-group';
  ['aprobado', 'fallado', 'bloqueado', 'n-a', 'pendiente'].forEach(s => {
    const radioId = 'r-' + escapeHtml(modId) + '-' + escapeHtml(c.id) + '-' + s;
    const input = document.createElement('input');
    input.type = 'radio';
    input.className = 'status-radio';
    input.name = 'st-' + escapeHtml(modId) + '-' + escapeHtml(c.id);
    input.id = radioId;
    input.value = s;
    if (st === s) input.checked = true;
    input.addEventListener('change', () => onStatusChange(modId, c.id, s));
    const label = document.createElement('label');
    label.className = 'status-label ' + s;
    label.htmlFor = radioId;
    label.textContent = s;
    group.appendChild(input);
    group.appendChild(label);
  });
  tdSt.appendChild(group);
  row.appendChild(tdSt);

  // Columna Observaciones
  const tdObs = document.createElement('td');
  const textarea = document.createElement('textarea');
  textarea.rows = 2;
  textarea.value = obs;
  textarea.placeholder = 'Observaciones...';
  textarea.style.cssText = 'width:100%;background:var(--bg-elevated);border:1px solid var(--border);color:var(--text);border-radius:var(--radius-xs);padding:0.4rem;font-size:0.8rem;resize:vertical;';
  textarea.addEventListener('change', (e) => setStateValue(modId, c.id, 'obs', e.target.value));
  tdObs.appendChild(textarea);
  row.appendChild(tdObs);

  return row;
}

// ============================================================
// STATUS + STATS
// ============================================================
function onStatusChange(modId, caseId, value) {
  setStateValue(modId, caseId, 'status', value);
  const row = document.getElementById('row-' + modId + '-' + caseId);
  if (row) {
    row.className = 'tc-row status-' + value;
    applyFilter();
  }
  updateModuleStats(modId);
  updateGlobalStats();
  showToast('Estado: ' + value);
}

function getModuleStats(modId) {
  const mod = MODULES.find(m => m.id === modId);
  if (!mod) return { total:0, aprobado:0, fallado:0, pendiente:0 };
  const s = { total: mod.cases.length, aprobado:0, fallado:0, pendiente:0, bloqueado:0 };
  mod.cases.forEach(c => {
    const st = getStatus(modId, c.id);
    if (s[st] !== undefined) s[st]++;
    else s.pendiente++;
  });
  return s;
}

function updateModuleStats(modId) {
  const el = document.getElementById('stats-' + modId);
  if (!el) return;
  const s = getModuleStats(modId);
  el.textContent = s.aprobado + '/' + s.total + ' aprobados';
}

function updateGlobalStats() {
  let total=0, aprobado=0, fallado=0, pendiente=0;
  MODULES.forEach(mod => {
    const s = getModuleStats(mod.id);
    total += s.total; aprobado += s.aprobado; fallado += s.fallado; pendiente += s.pendiente;
  });
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('stat-total', total);
  set('stat-aprobados', aprobado);
  set('stat-fallados', fallado);
  set('stat-pendientes', pendiente);
  set('stat-pct', total > 0 ? Math.round((aprobado/total)*100) + '%' : '0%');
}

// ============================================================
// COLLAPSE / EXPAND / FILTER
// ============================================================
function toggleModule(modId) {
  const sec = document.getElementById('mod-' + modId) || document.getElementById('section-' + modId);
  if (sec) sec.classList.toggle('collapsed');
}
function expandAll()  { document.querySelectorAll('.module-section').forEach(s => s.classList.remove('collapsed')); }
function collapseAll(){ document.querySelectorAll('.module-section').forEach(s => s.classList.add('collapsed')); }

let currentFilter = 'all';
function setFilter(f) {
  currentFilter = f;
  document.querySelectorAll('.filter-btn').forEach(b => b.classList.remove('active'));
  document.querySelectorAll(`.filter-btn`).forEach(b => { if (b.textContent.toLowerCase().includes(f === 'all' ? 'todos' : f)) b.classList.add('active'); });
  applyFilter();
}
function applyFilter() {
  let total = 0, aprobado = 0, fallado = 0, pendiente = 0;
  document.querySelectorAll('.tc-row').forEach(row => {
    const visible = currentFilter === 'all' || row.classList.contains('status-' + currentFilter);
    row.style.display = visible ? '' : 'none';
    if (visible) {
      total++;
      if (row.classList.contains('status-aprobado')) aprobado++;
      else if (row.classList.contains('status-fallado')) fallado++;
      else pendiente++;
    }
  });
  const set = (id, val) => { const el = document.getElementById(id); if (el) el.textContent = val; };
  set('stat-total', total);
  set('stat-aprobados', aprobado);
  set('stat-fallados', fallado);
  set('stat-pendientes', pendiente);
  set('stat-pct', total > 0 ? Math.round((aprobado / total) * 100) + '%' : '0%');
}

// ============================================================
// EXPORT JSON
// ============================================================
function exportJSON() {
  const report = {
    feature: document.getElementById('portada-feature').value,
    rol:     document.getElementById('portada-rol').value,
    fecha:   document.getElementById('portada-fecha').value,
    generado: new Date().toISOString(),
    modulos: MODULES.map(mod => ({
      id: mod.id, name: mod.name,
      stats: getModuleStats(mod.id),
      casos: mod.cases.map(c => ({
        id: c.id, desc: c.desc,
        status: getStatus(mod.id, c.id),
        obs: getObs(mod.id, c.id)
      }))
    }))
  };
  const blob = new Blob([JSON.stringify(report, null, 2)], { type: 'application/json' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = 'test-plan-{{SLUG}}-' + new Date().toISOString().slice(0,10) + '.json';
  a.click();
  URL.revokeObjectURL(url);
  showToast('JSON exportado');
}

// ============================================================
// OTRAS PRUEBAS
// ============================================================
let otrasState = { casos: [] };

function loadOtras() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY_OT);
    otrasState = raw ? JSON.parse(raw) : { casos: [] };
  } catch(e) { otrasState = { casos: [] }; }
  renderOtras();
}

function saveOtras() {
  try {
    localStorage.setItem(STORAGE_KEY_OT, JSON.stringify(otrasState));
  } catch(e) { showToast('Error al guardar otras pruebas'); }
}

function addOtraPrueba() {
  otrasState.casos.push({ id: 'OT-' + Date.now(), desc: '', status: 'pendiente' });
  saveOtras(); renderOtras();
}

function renderOtras() {
  const container = document.getElementById('otras-container');
  if (!container) return;
  container.replaceChildren();
  otrasState.casos.forEach((c, i) => {
    const row = document.createElement('div');
    row.style.cssText = 'padding:0.75rem 1.5rem;border-top:1px solid var(--border);display:flex;gap:1rem;align-items:center;';

    const inp = document.createElement('input');
    inp.type = 'text'; inp.value = c.desc; inp.placeholder = 'Descripcion del caso...';
    inp.style.cssText = 'flex:1;background:var(--bg-elevated);border:1px solid var(--border);color:var(--text);border-radius:var(--radius-xs);padding:0.4rem 0.6rem;';
    inp.addEventListener('change', () => { otrasState.casos[i].desc = inp.value; saveOtras(); });

    const sel = document.createElement('select');
    sel.style.cssText = 'background:var(--bg-elevated);border:1px solid var(--border);color:var(--text);border-radius:var(--radius-xs);padding:0.4rem;';
    ['pendiente','aprobado','fallado','bloqueado'].forEach(s => {
      const opt = document.createElement('option');
      opt.value = s; opt.textContent = s;
      if (c.status === s) opt.selected = true;
      sel.appendChild(opt);
    });
    sel.addEventListener('change', () => { otrasState.casos[i].status = sel.value; saveOtras(); });

    const btn = document.createElement('button');
    btn.className = 'btn'; btn.textContent = 'x';
    btn.style.cssText = 'padding:0.3rem 0.6rem;color:var(--red);border-color:var(--red-border);';
    btn.addEventListener('click', () => { otrasState.casos.splice(i, 1); saveOtras(); renderOtras(); });

    row.appendChild(inp); row.appendChild(sel); row.appendChild(btn);
    container.appendChild(row);
  });
}

// ============================================================
// PORTADA + ACTA PERSISTENCE
// ============================================================
function savePortada() {
  try {
    localStorage.setItem(STORAGE_KEY_PORTA, JSON.stringify({
      feature: document.getElementById('portada-feature').value,
      rol:     document.getElementById('portada-rol').value,
      fecha:   document.getElementById('portada-fecha').value,
      ejecutor:document.getElementById('portada-ejecutor').value
    }));
  } catch(e) { showToast('Advertencia: no se pudo guardar portada'); }
}

function loadPortada() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY_PORTA);
    if (!raw) return;
    const d = JSON.parse(raw);
    if (d.feature) document.getElementById('portada-feature').value = d.feature;
    if (d.rol)     document.getElementById('portada-rol').value = d.rol;
    if (d.fecha)   document.getElementById('portada-fecha').value = d.fecha;
    if (d.ejecutor)document.getElementById('portada-ejecutor').value = d.ejecutor;
  } catch(e) {}
}

function saveActa() {
  try {
    localStorage.setItem(STORAGE_KEY_ACTA, JSON.stringify({
      evaluador: document.getElementById('acta-evaluador').value,
      fecha:     document.getElementById('acta-fecha').value,
      resultado: document.getElementById('acta-resultado').value,
      obs:       document.getElementById('acta-obs').value
    }));
  } catch(e) { showToast('Advertencia: no se pudo guardar acta'); }
}

function loadActa() {
  try {
    const raw = localStorage.getItem(STORAGE_KEY_ACTA);
    if (!raw) return;
    const d = JSON.parse(raw);
    if (d.evaluador) document.getElementById('acta-evaluador').value = d.evaluador;
    if (d.fecha)     document.getElementById('acta-fecha').value = d.fecha;
    if (d.resultado) document.getElementById('acta-resultado').value = d.resultado;
    if (d.obs)       document.getElementById('acta-obs').value = d.obs;
  } catch(e) {}
}

// ============================================================
// EVIDENCIA — Image Compression (max 500KB, JPEG 0.7)
// ============================================================
function addEvidence(modId, caseId) {
  const input = document.createElement('input');
  input.type = 'file'; input.accept = 'image/*'; input.multiple = true;
  input.addEventListener('change', async (e) => {
    for (const file of e.target.files) {
      const compressed = await compressImage(file);
      if (!state[modId]) state[modId] = {};
      if (!state[modId][caseId]) state[modId][caseId] = { status: 'pendiente', obs: '', evidence: [] };
      if (!state[modId][caseId].evidence) state[modId][caseId].evidence = [];
      state[modId][caseId].evidence.push(compressed);
      saveState();
    }
    showToast('Evidencia agregada');
  });
  input.click();
}

async function compressImage(file) {
  return new Promise(resolve => {
    const reader = new FileReader();
    reader.addEventListener('load', (e) => {
      const img = new Image();
      img.addEventListener('load', () => {
        const maxW = 900;
        let w = img.width, h = img.height;
        if (w > maxW) { h = Math.round(h * maxW / w); w = maxW; }
        const canvas = document.createElement('canvas');
        canvas.width = w; canvas.height = h;
        canvas.getContext('2d').drawImage(img, 0, 0, w, h);
        let quality = 0.7;
        let dataUrl = canvas.toDataURL('image/jpeg', quality);
        while (dataUrl.length > 512000 && quality > 0.3) {
          quality -= 0.1;
          dataUrl = canvas.toDataURL('image/jpeg', quality);
        }
        resolve(dataUrl);
      });
      img.src = e.target.result;
    });
    reader.readAsDataURL(file);
  });
}

// ============================================================
// PRINT HOOKS
// ============================================================
window.addEventListener('beforeprint', expandAll);

// ============================================================
// TOAST
// ============================================================
let _toastTimer = null;
function showToast(msg) {
  const toast = document.getElementById('toast');
  if (!toast) return;
  toast.textContent = msg;
  toast.classList.add('show');
  clearTimeout(_toastTimer);
  _toastTimer = setTimeout(() => toast.classList.remove('show'), 2500);
}

// ============================================================
// INIT
// ============================================================
document.addEventListener('DOMContentLoaded', () => {
  loadState();
  buildModules();
  loadOtras();
  loadPortada();
  loadActa();
  MODULES.forEach(mod => updateModuleStats(mod.id));
  updateGlobalStats();

  // Auto-save portada
  ['portada-feature','portada-rol','portada-fecha','portada-ejecutor'].forEach(id => {
    document.getElementById(id)?.addEventListener('change', savePortada);
  });
  // Auto-save acta
  ['acta-evaluador','acta-fecha','acta-resultado','acta-obs'].forEach(id => {
    document.getElementById(id)?.addEventListener('change', saveActa);
  });
  // Set fecha default
  const fechaEl = document.getElementById('portada-fecha');
  if (fechaEl && !fechaEl.value) fechaEl.value = new Date().toISOString().slice(0,10);
});
```

---

## Fragment 4: Data Model Schema

> Schema canonico de MODULES[] para usar en Fase 3 y 4.

```javascript
// MODULES[] — Schema completo con todos los campos
const MODULES_SCHEMA_EXAMPLE = [
  {
    id: "MOD-01",           // string, kebab-case unico
    name: "Nombre Modulo",  // string, visible al usuario
    colorClass: "m01",      // string: m01-m12 (asignado ciclicamente en Fase 3)
    issues: [],             // string[], referencias a tickets/issues
    prereqs: [],            // string[], precondiciones del modulo
    cases: [
      {
        id: "TC-01-001",          // string, ID unico
        desc: "Descripcion",      // string, descripcion del caso
        severity: "HIGH",         // HIGH | MED | LOW
        priority: "P1",           // P1 | P2 | P3
        category: "Functional",   // Functional | Security | Performance | UX | Regression
        coverageType: "Happy",    // Happy | Negative | Edge | Security | Regression
        steps: [                  // string[], pasos de ejecucion
          "Paso 1: ...",
          "Paso 2: ..."
        ],
        expected: "Resultado esperado",
        variants: [],             // string[], variantes del caso
        suggestions: [],          // string[], sugerencias de automatizacion
        gherkinSource: null       // string | null, scenario Gherkin origen
      }
    ]
  }
];

// localStorage State Schema
// key:   'king_tp_{feature}_{role}_v1'
// value: { "MOD-01": { "TC-01-001": { status, obs, evidence[] } } }
const STORAGE_SCHEMA = {
  "MOD-01": {
    "TC-01-001": {
      status: "pendiente", // pendiente | aprobado | fallado | bloqueado | n-a
      obs: "",
      evidence: []         // dataURL[], comprimidas a max ~500KB
    }
  }
};
```

---

## Fragment 5: Gherkin Mapping Rules

> Reglas de mapeo para parsear archivos .feature en Fase 2.

### Tabla de Mapeo Principal

| Elemento Gherkin | Campo MODULES[] | Notas |
|-----------------|-----------------|-------|
| `Feature: X` | `module.name = X` | Un Feature = Un Modulo |
| `Scenario: Y` | `case.desc = Y` | Un Scenario = Un TestCase |
| `Given Z` | `case.steps[]` | Primera Given puede ser prereq del modulo |
| `When A` | `case.steps[]` | Agregar como paso |
| `And B` (after When) | `case.steps[]` | Agregar como paso adicional |
| `Then C` | `case.expected` | Primera Then = expected principal |
| `And D` (after Then) | `case.expected` (append) | Concatenar con "; " |
| `Background: Z` | `module.prereqs[]` | Precondicion de todos los casos del modulo |
| `Scenario Outline` | `case.desc + variants[]` | Cada Example Row = una variante |

### Tag Classification Map

| Tag | Campo | Valor |
|-----|-------|-------|
| `@critical` | `case.severity` | `HIGH` |
| `@high` | `case.severity` | `HIGH` |
| `@medium`, `@med` | `case.severity` | `MED` |
| `@low` | `case.severity` | `LOW` |
| `@security` | `case.category` | `Security` |
| `@performance`, `@perf` | `case.category` | `Performance` |
| `@regression` | `case.coverageType` | `Regression` |
| `@smoke` | `case.priority` | `P1` |
| `@ui`, `@ux` | `case.category` | `UX` |

### Defaults (sin tags)

| Campo | Default |
|-------|---------|
| `severity` | `MED` |
| `priority` | `P2` |
| `category` | `Functional` |
| `coverageType` | `Happy` |

### Ejemplo de Mapeo

**Input Gherkin:**
```gherkin
@critical @security
Feature: Autenticacion de Usuarios
  Background:
    Given el sistema esta disponible

  @smoke
  Scenario: Login exitoso con credenciales validas
    Given el usuario esta en la pagina de login
    When ingresa credenciales validas
    And hace click en Ingresar
    Then es redirigido al dashboard
    And ve el menu de navegacion
```

**Output MODULES[]:**
```javascript
{
  id: "MOD-01",
  name: "Autenticacion de Usuarios",
  colorClass: "m01",
  prereqs: ["El sistema esta disponible"],
  cases: [{
    id: "TC-01-001",
    desc: "Login exitoso con credenciales validas",
    severity: "HIGH",      // de @critical
    priority: "P1",        // de @smoke
    category: "Security",  // de @security
    coverageType: "Happy",
    steps: [
      "El usuario esta en la pagina de login",
      "Ingresa credenciales validas",
      "Hace click en Ingresar"
    ],
    expected: "Es redirigido al dashboard; Ve el menu de navegacion",
    gherkinSource: "Scenario: Login exitoso con credenciales validas"
  }]
}
```
