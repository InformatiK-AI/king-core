// Plantilla k6 — SPIKE test (M05 / perf-test)
// Pico repentino al 10× del baseline: ¿se rompe o degrada gracefully?
//
//   BASE_URL=http://localhost:3000 k6 run spike.js
import http from 'k6/http';
import { check } from 'k6';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const TOKEN = __ENV.AUTH_TOKEN || '';

export const options = {
  stages: [
    { duration: '30s', target: {{BASELINE_VUS}} }, // baseline
    { duration: '10s', target: {{SPIKE_VUS}} },    // pico repentino (10×)
    { duration: '30s', target: {{SPIKE_VUS}} },    // sostener el pico
    { duration: '10s', target: {{BASELINE_VUS}} }, // recuperación
  ],
  thresholds: {
    // En spike toleramos más latencia, pero el error rate sigue acotado:
    // el sistema debe DEGRADAR, no caerse.
    http_req_failed: ['rate<0.05'], // < 5% bajo pico
  },
};

const params = TOKEN ? { headers: { Authorization: `Bearer ${TOKEN}` } } : {};

export default function () {
  // {{ENDPOINTS}} — un bloque por endpoint descubierto.
  const res = http.get(`${BASE_URL}{{ENDPOINT_PATH}}`, params);
  check(res, {
    'no server error': (r) => r.status < 500, // degradar (4xx) es aceptable; 5xx no
  });
}
