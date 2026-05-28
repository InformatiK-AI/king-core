// Plantilla k6 — LOAD test (M05 / perf-test)
// Comportamiento bajo carga normal: VUs crecientes hasta el target, sostenido 5min.
//
//   BASE_URL=http://localhost:3000 k6 run load.js
import http from 'k6/http';
import { check } from 'k6';
import { Trend, Rate } from 'k6/metrics';

const BASE_URL = __ENV.BASE_URL || 'http://localhost:3000';
const TOKEN = __ENV.AUTH_TOKEN || '';

const latency = new Trend('endpoint_latency', true);
const errors = new Rate('endpoint_errors');

export const options = {
  stages: [
    { duration: '1m', target: {{TARGET_VUS}} }, // ramp-up
    { duration: '5m', target: {{TARGET_VUS}} }, // steady
    { duration: '30s', target: 0 },             // ramp-down
  ],
  thresholds: {
    http_req_failed: ['rate<0.01'],
    http_req_duration: ['p(95)<{{P95_MS}}', 'p(99)<{{P99_MS}}'],
  },
};

const params = TOKEN ? { headers: { Authorization: `Bearer ${TOKEN}` } } : {};

export default function () {
  // {{ENDPOINTS}} — un bloque por endpoint descubierto.
  const res = http.get(`${BASE_URL}{{ENDPOINT_PATH}}`, params);
  latency.add(res.timings.duration);
  errors.add(res.status >= 400);
  check(res, { 'status is 2xx': (r) => r.status >= 200 && r.status < 300 });
}
