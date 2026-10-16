import { expect, test } from '@playwright/test';
import { API_URL } from './helpers';

const WEB_ORIGIN = new URL(process.env.E2E_BASE_URL ?? 'https://c3b22.github.io/financecare-web/')
  .origin;

test.describe('Backend API (ไม่ต้องล็อกอิน)', () => {
  test('[TC-API-01] service ตอบ (swagger 200)', async ({ request }) => {
    const res = await request.get(`${API_URL}/api/swagger-ui/index.html`, { timeout: 90_000 });
    expect(res.status()).toBe(200);
  });

  test('[TC-API-02] CORS: เว็บเรียก API ข้าม origin ได้ (preflight)', async ({ request }) => {
    const res = await request.fetch(`${API_URL}/api/auth/login/google`, {
      method: 'OPTIONS',
      headers: {
        Origin: WEB_ORIGIN,
        'Access-Control-Request-Method': 'POST',
        'Access-Control-Request-Headers': 'content-type,authorization',
      },
    });
    expect(res.status()).toBe(200);
    expect(res.headers()['access-control-allow-origin']).toBe(WEB_ORIGIN);
    expect(res.headers()['access-control-allow-headers'] ?? '').toMatch(/authorization/i);
  });

  for (const path of ['/api/debts', '/api/categories', '/api/debt-types', '/api/repayment-types']) {
    test(`[TC-API-03] ไม่มี token เรียก ${path} ได้ 401`, async ({ request }) => {
      const res = await request.get(`${API_URL}${path}`);
      expect(res.status()).toBe(401);
    });
  }

  test('[TC-API-04] token มั่ว ๆ ได้ 401 (ไม่ใช่ 500)', async ({ request }) => {
    const res = await request.get(`${API_URL}/api/debts`, {
      headers: { Authorization: 'Bearer not-a-real-token' },
    });
    expect(res.status()).toBe(401);
  });

  test('[TC-API-05] login/google ด้วย idToken ที่เป็น JWT แต่ไม่ถูกต้อง ได้ 401', async ({ request }) => {
    const res = await request.post(`${API_URL}/api/auth/login/google`, {
      data: { idToken: 'eyJhbGciOiJSUzI1NiJ9.eyJzdWIiOiIxIn0.c2ln' },
    });
    expect(res.status()).toBe(401);
  });

  test('[TC-API-06] login/google ด้วย idToken ที่ไม่ใช่ JWT ได้ 401 (เคยเป็น 500)', async ({
    request,
  }) => {
    const res = await request.post(`${API_URL}/api/auth/login/google`, {
      data: { idToken: 'x' },
    });
    expect(res.status(), await res.text()).toBe(401);
  });

  test('[TC-API-07] login/google ที่ไม่มี idToken ได้ 401 (เคยเป็น 500)', async ({ request }) => {
    const res = await request.post(`${API_URL}/api/auth/login/google`, { data: {} });
    expect(res.status(), await res.text()).toBe(401);
  });

  test('[TC-API-09] login/google ที่ idToken เป็นสตริงว่าง ได้ 401', async ({ request }) => {
    const res = await request.post(`${API_URL}/api/auth/login/google`, {
      data: { idToken: '' },
    });
    expect(res.status(), await res.text()).toBe(401);
  });

  test('[TC-API-08] login ด้วยอีเมลที่ไม่มีอยู่ ได้ 401', async ({ request }) => {
    const res = await request.post(`${API_URL}/api/auth/login`, {
      data: { email: 'e2e-nobody@example.com', password: 'WrongPass123!' },
    });
    expect(res.status()).toBe(401);
  });
});
