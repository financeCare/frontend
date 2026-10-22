import { expect, test } from '@playwright/test';
import { API_URL, mintAccessToken } from './helpers';

/**
 * ทดสอบผู้ใช้ที่ "ไม่มีรหัสผ่าน" (ล็อกอินด้วย Google/LINE) เรียก API ที่ต้องมี token
 * ซึ่งเป็นจุดที่เคยพังเป็น 401 ทุก request หลังล็อกอิน (Spring User รับ password เป็น null ไม่ได้)
 *
 * ต้องตั้ง env ก่อน ไม่งั้นจะ skip:
 *   E2E_JWT_SECRET  = ค่า JWT_SECRET (base64) ที่ตั้งไว้ใน Render
 *   E2E_USER_EMAIL  = อีเมลของผู้ใช้ที่ล็อกอินด้วย Google ไว้แล้ว (มีใน DB)
 */
const secret = process.env.E2E_JWT_SECRET;
const email = process.env.E2E_USER_EMAIL;

test.describe('API ที่ต้องมี token (ผู้ใช้ Google)', () => {
  test.skip(!secret || !email, 'ตั้ง E2E_JWT_SECRET และ E2E_USER_EMAIL เพื่อรันกลุ่มนี้');

  const endpoints = [
    '/api/debts',
    '/api/debt-types',
    '/api/repayment-types',
    '/api/categories',
    '/api/receiver-mappings',
  ];

  for (const path of endpoints) {
    test(`[TC-AUTH-01] GET ${path} ได้ 200`, async ({ request }) => {
      const token = mintAccessToken(email!, secret!);
      const res = await request.get(`${API_URL}${path}`, {
        headers: { Authorization: `Bearer ${token}` },
        timeout: 90_000,
      });
      expect(res.status(), await res.text()).toBe(200);
    });
  }

  test('[TC-AUTH-02] token ที่ลงนามด้วย secret ผิด ได้ 401', async ({ request }) => {
    const wrongSecret = Buffer.from('wrong-secret-wrong-secret-wrong-secret').toString('base64');
    const res = await request.get(`${API_URL}/api/debts`, {
      headers: { Authorization: `Bearer ${mintAccessToken(email!, wrongSecret)}` },
    });
    expect(res.status()).toBe(401);
  });
});
