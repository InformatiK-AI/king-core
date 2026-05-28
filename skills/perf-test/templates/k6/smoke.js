// Plantilla k6 — SMOKE test (M05 / perf-test)
// ¿El servicio arranca y responde sin errores con carga mínima?
// Parametriza con env vars; el skill /perf-test reemplaza {{PLACEHOLDERS}}.
//
//   BASE_URL=http://localhost:3000 k6 run smoke.js
import http from 'k6/http';
import { check, sleep } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const TOKEN = __ENV.AUTH_TOKEN || ''; // nunca hardcodear: viene de env

export const options = {
  vus: 1,
  duration: '30s',
  thresholds: {
    // Smoke: el run FALLA si el error rate o la latencia se disparan.
    http_req_failed: ['rate<0.01'],          // < 1% errores
    http_req_duration: ['p(95)<{{P95_MS}}'], // p95 budget (default 500)
  },
};

const params = TOKEN ? { headers: { Authorization: `Bearer ${TOKEN}` } } : {};

export default function () {
  // {{ENDPOINTS}} — el skill expande un bloque por endpoint descubierto.
  const res = http.get(`${BASE_URL}{{ENDPOINT_PATH}}`, params);
  check(res, {
    'status is 2xx': (r) => r.status >= 200 && r.status < 300,
    'p95 within budget': (r) => r.timings.duration < {{P95_MS}},
  });
  sleep(1);
}
