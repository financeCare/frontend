import { expect, test } from '@playwright/test';
import { API_URL, loginViaUi, screenText } from './helpers';

/**
 * ทดสอบเมนูลัดบนหน้า Home ผ่านหน้าจอจริง (ต้องล็อกอินบัญชีที่ยืนยันแล้ว)
 * เปิดแต่ละหน้า ตรวจว่าไม่มี error และไม่มี request ไป backend ที่ตอบ 4xx/5xx
 * ไม่สร้างหรือแก้ข้อมูล จึงรันกับบัญชีใดก็ได้
 */
const email = process.env.E2E_EMAIL;
const password = process.env.E2E_PASSWORD;

const SHORTCUTS = ['สร้างหนี้', 'กลยุทธ์ชำระ', 'ดูแผนของคุณ', 'ชำระหนี้'];

test.describe('เมนูลัดหน้า Home (UI)', () => {
  test.skip(!email || !password, 'ตั้ง E2E_EMAIL และ E2E_PASSWORD เพื่อรันกลุ่มนี้');

  for (const name of SHORTCUTS) {
    test(`[TC-FT-30] เปิดเมนู "${name}" ได้ ไม่มี error และ API ไม่ตอบ 4xx/5xx`, async ({ page }) => {
      const pageErrors: string[] = [];
      const apiErrors: string[] = [];
      page.on('pageerror', (e) => pageErrors.push(e.message));
      page.on('response', (r) => {
        if (r.url().startsWith(API_URL) && r.status() >= 400) {
          apiErrors.push(`${r.status()} ${r.request().method()} ${r.url().replace(API_URL, '')}`);
        }
      });

      await loginViaUi(page, email!, password!);
      const before = await screenText(page);
      apiErrors.length = 0; // นับเฉพาะหลังกดเมนู

      await page.getByRole('button', { name: new RegExp(name) }).first().click();
      await page.waitForTimeout(4000);

      const after = await screenText(page);
      expect(after, 'หน้าจอต้องเปลี่ยนหลังกดเมนู').not.toBe(before);
      expect(pageErrors, pageErrors.join('\n')).toEqual([]);
      // บัญชีที่ยังไม่มีแผน: GET /api/repayment-plans ตอบ 404 แล้วหน้าจอแสดง "ยังไม่มีแผนการชำระหนี้"
      // เป็นกรณีปกติที่จัดการแล้ว (แต่การใช้ 404 แทนผลลัพธ์ว่างเป็นข้อสังเกต) จึงไม่นับเป็นข้อผิดพลาด
      const unexpected = apiErrors.filter((e) => e !== '404 GET /api/repayment-plans');
      expect(unexpected, unexpected.join('\n')).toEqual([]);
    });
  }
});
