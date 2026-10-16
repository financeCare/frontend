import { expect, test, type APIRequestContext } from '@playwright/test';
import { API_URL, openApp, screenText, typeInto } from './helpers';

/**
 * ทดสอบด้วยบัญชีอีเมลที่ "ยืนยันอีเมลแล้ว" (ผู้ใช้ปกติ ไม่ใช่ Google/LINE)
 *
 * ตั้งค่าผ่าน env (ห้ามเขียนรหัสผ่านลงไฟล์ที่ commit):
 *   E2E_EMAIL     อีเมลของบัญชีทดสอบ
 *   E2E_PASSWORD  รหัสผ่านของบัญชีทดสอบ
 * วิธีตั้ง: คัดลอก .env.example เป็น .env แล้วกรอก หรือส่ง env ตอนรัน
 */
const email = process.env.E2E_EMAIL;
const password = process.env.E2E_PASSWORD;

const JWT_SHAPE = /^[\w-]+\.[\w-]+\.[\w-]+$/;
const PROTECTED = ['/api/debts', '/api/categories', '/api/debt-types', '/api/repayment-types'];

type Tokens = { accessToken: string; refreshToken: string };

async function login(request: APIRequestContext): Promise<Tokens> {
  const res = await request.post(`${API_URL}/api/auth/login`, {
    data: { email, password },
    timeout: 90_000, // Render อาจ sleep อยู่
  });
  expect(res.status(), await res.text()).toBe(200);
  return res.json();
}

test.describe('บัญชีอีเมลที่ยืนยันแล้ว — API', () => {
  test.skip(!email || !password, 'ตั้ง E2E_EMAIL และ E2E_PASSWORD เพื่อรันกลุ่มนี้');

  test('[TC-EM-01] ล็อกอินด้วยอีเมล/รหัสผ่านที่ถูกต้อง ได้ access และ refresh token', async ({
    request,
  }) => {
    const t = await login(request);
    expect(t.accessToken).toMatch(JWT_SHAPE);
    expect(t.refreshToken).toMatch(JWT_SHAPE);
    expect(t.accessToken).not.toBe(t.refreshToken);
  });

  for (const path of PROTECTED) {
    test(`[TC-EM-02] ล็อกอินแล้วเรียก ${path} ได้ 200 (ไม่ใช่ 401/403)`, async ({ request }) => {
      const { accessToken } = await login(request);
      const res = await request.get(`${API_URL}${path}`, {
        headers: { Authorization: `Bearer ${accessToken}` },
        timeout: 60_000,
      });
      expect(res.status(), await res.text()).toBe(200);
    });
  }

  test('[TC-EM-03] refresh token ขอ access token ใหม่ได้ และใช้เรียก API ได้', async ({
    request,
  }) => {
    const { refreshToken } = await login(request);
    const res = await request.post(`${API_URL}/api/auth/refresh-token`, {
      headers: { Authorization: `Bearer ${refreshToken}` },
    });
    expect(res.status(), await res.text()).toBe(200);
    const body = await res.json();
    expect(body.accessToken).toMatch(JWT_SHAPE);

    const api = await request.get(`${API_URL}/api/debts`, {
      headers: { Authorization: `Bearer ${body.accessToken}` },
    });
    expect(api.status()).toBe(200);
  });

  test('[TC-EM-04] เอา refresh token ไปใช้เรียก API ตรง ๆ ต้องถูกปฏิเสธ (ไม่ใช่ 200)', async ({
    request,
  }) => {
    const { refreshToken } = await login(request);
    const res = await request.get(`${API_URL}/api/debts`, {
      headers: { Authorization: `Bearer ${refreshToken}` },
    });
    expect(res.status()).toBeGreaterThanOrEqual(400);
    expect(res.status()).toBeLessThan(500);
  });
});

test.describe('บัญชีอีเมล — รหัสผ่านผิด', () => {
  // ใช้แค่อีเมล (ไม่ใช้รหัสผ่านจริง) จึงรันได้โดยไม่ต้องมี E2E_PASSWORD
  test.skip(!email, 'ตั้ง E2E_EMAIL เพื่อรันข้อนี้');

  test('[TC-EM-05] อีเมลถูกแต่รหัสผ่านผิด ได้ 401', async ({ request }) => {
    const res = await request.post(`${API_URL}/api/auth/login`, {
      data: { email, password: 'definitely-not-the-password-123!' },
      timeout: 90_000,
    });
    expect(res.status(), await res.text()).toBe(401);
  });
});

test.describe('บัญชีอีเมลที่ยืนยันแล้ว — ผ่านหน้าเว็บ', () => {
  test.skip(!email || !password, 'ตั้ง E2E_EMAIL และ E2E_PASSWORD เพื่อรันกลุ่มนี้');

  /** ล็อกอินผ่านฟอร์มจริง แล้วรอจนเห็นหน้า Home */
  async function loginViaUi(page: import('@playwright/test').Page) {
    await openApp(page);
    await typeInto(page, 'you@example.com', email!);
    await page.keyboard.press('Tab');
    await page.keyboard.type(password!, { delay: 15 });
    await page.getByRole('button', { name: 'เข้าสู่ระบบ' }).last().click();
    await expect
      .poll(() => screenText(page), { timeout: 90_000 })
      .toContain('ภาพรวมหนี้สิน');
  }

  /** เก็บ response ของ backend ที่เป็น 4xx/5xx */
  function trackApiErrors(page: import('@playwright/test').Page) {
    const errors: string[] = [];
    page.on('response', (r) => {
      if (r.url().startsWith(API_URL) && r.status() >= 400) {
        errors.push(`${r.status()} ${r.request().method()} ${r.url().replace(API_URL, '')}`);
      }
    });
    return errors;
  }

  test('[TC-EM-06] ล็อกอินผ่านหน้าเว็บแล้วเข้า Home ได้ และ API ไม่ตอบ 4xx/5xx', async ({
    page,
  }) => {
    const errors = trackApiErrors(page);
    await loginViaUi(page);
    await page.waitForTimeout(5000); // ให้ Home โหลดข้อมูลครบ
    expect(errors, errors.join('\n')).toEqual([]);
  });

  test('[TC-EM-07] รีเฟรชหน้า (F5) แล้วยังอยู่ในระบบ', async ({ page }) => {
    await loginViaUi(page);
    await page.reload();
    await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 90_000 });
    await page.evaluate(() =>
      (document.querySelector('flt-semantics-placeholder') as HTMLElement | null)?.click(),
    );
    await expect
      .poll(() => screenText(page), { timeout: 60_000 })
      .toContain('ภาพรวมหนี้สิน');
  });

  test('[TC-EM-08] สลับแท็บล่าง (สแกน OCR / งบประมาณ / ตั้งค่า) แล้ว API ไม่ตอบ 4xx/5xx', async ({
    page,
  }) => {
    await loginViaUi(page);
    const errors = trackApiErrors(page);
    for (const tab of ['สแกน OCR', 'งบประมาณ', 'ตั้งค่า', 'หน้าหลัก']) {
      await page.getByRole('button', { name: new RegExp(tab) }).first().click();
      await page.waitForTimeout(3000);
    }
    expect(errors, errors.join('\n')).toEqual([]);
  });
});
