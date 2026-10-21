import http from 'k6/http';
import { check, sleep } from 'k6';

// -------------------------------------------------------------
// SRE: Definición formal de SLOs y fases de estrés
// -------------------------------------------------------------
export const options = {
  stages: [
    { duration: '30s', target: 15 }, // Rampa de subida a 15 usuarios virtuales
    { duration: '1m', target: 40 },  // Pico de carga sostenida a 40 usuarios concurrentes
    { duration: '30s', target: 0 },  // Rampa de enfriamiento
  ],
  thresholds: {
    // SLO 1 (Latencia): El 95% de las peticiones debe responder en menos de 500 ms (p95 < 500ms)
    http_req_duration: ['p(95)<500'],
    // SLO 2 (Confiabilidad): Tasa de fallos menor al 1% (99% de éxito)
    http_req_failed: ['rate<0.01'],
  },
};

const BASE_URL = 'http://aab60d2eca9894286a2a2ff428b04663-1936829239.us-east-1.elb.amazonaws.com';

export default function () {
  // 1. Validar endpoint de Health Check (Liveness / Readiness)
  const healthRes = http.get(`${BASE_URL}/healthz`);
  check(healthRes, {
    'healthz status is 200': (r) => r.status === 200,
  });

  // 2. Simular lectura masiva de notas desde la base de datos
  const notesRes = http.get(`${BASE_URL}/api/notes`);
  check(notesRes, {
    'get notes status is 200': (r) => r.status === 200,
  });

  // 3. Simular escritura concurrente en PostgreSQL
  const payload = JSON.stringify({
    content: `Stress test note generated at ${Date.now()}`,
  });

  const params = {
    headers: {
      'Content-Type': 'application/json',
    },
  };

  const createRes = http.post(`${BASE_URL}/api/notes`, payload, params);
  check(createRes, {
    'create note status is 201': (r) => r.status === 201,
  });

  sleep(0.3); // Pausa breve entre iteraciones para no saturar la red local
}