import { expect, test } from '@playwright/test';
import { openApp, screenText, typeInto } from './helpers';

test.describe('หน้าเข้าสู่ระบบ (web)', () => {
  test('[TC-UI-01] โหลดได้โดยไม่มี error ใน console และไม่มี Google origin_mismatch', async ({ page }) => {
    const problems: string[] = [];
    page.on('console', (m) => {
      if (m.type() === 'error') problems.push(`console.error: ${m.text()}`);
      if (/GSI_LOGGER|origin is not allowed/i.test(m.text())) {
        problems.push(`google: ${m.text()}`);
      }
    });
    page.on('pageerror', (e) => problems.push(`pageerror: ${e.message}`));

    await openApp(page);
    await page.waitForTimeout(3000); // ให้ GIS และ Firebase โหลดเสร็จ

    expect(problems, problems.join('\n')).toEqual([]);
  });

  test('[TC-UI-02] แสดงส่วนประกอบหลักของหน้า', async ({ page }) => {
    await openApp(page);
    const text = await screenText(page);
    for (const s of [
      'FINANCE CARE',
      'เข้าสู่ระบบ',
      'สมัครสมาชิก',
      'ดำเนินการต่อด้วย LINE',
      'ดำเนินการต่อด้วย Google',
      'หรือเข้าสู่ระบบด้วยอีเมล',
    ]) {
      expect(text).toContain(s);
    }
    await expect(page.getByLabel('you@example.com')).toBeVisible();
    await expect(page.getByLabel('กรอกรหัสผ่านของคุณ')).toBeVisible();
  });

  test('[TC-UI-03] สลับไปแท็บสมัครสมาชิกแล้วมีช่องยืนยันรหัสผ่าน', async ({ page }) => {
    await openApp(page);
    await page.getByRole('button', { name: 'สมัครสมาชิก' }).click();
    await expect.poll(() => screenText(page)).toContain('ยืนยันรหัสผ่าน');
    expect(await screenText(page)).toContain('สร้างบัญชี');
  });

  test('[TC-UI-04] กดเข้าสู่ระบบโดยไม่กรอกอะไรเลย แสดงข้อความให้กรอกข้อมูล', async ({ page }) => {
    await openApp(page);
    await page.getByRole('button', { name: 'เข้าสู่ระบบ' }).last().click();
    await expect.poll(() => screenText(page)).toContain('กรุณากรอกข้อมูล');
  });

  test('[TC-UI-05] อีเมล/รหัสผ่านผิด แสดง dialog ข้อผิดพลาด และไม่เข้าหน้า home', async ({ page }) => {
    await openApp(page);
    await typeInto(page, 'you@example.com', 'e2e-nobody@example.com');
    await page.keyboard.press('Tab');
    await page.keyboard.type('WrongPass123!', { delay: 15 });
    await page.getByRole('button', { name: 'เข้าสู่ระบบ' }).last().click();

    // request แรกอาจช้ามากถ้า Render sleep อยู่
    await expect
      .poll(() => screenText(page), { timeout: 90_000 })
      .toContain('อีเมลหรือรหัสผ่านไม่ถูกต้อง');
    expect(page.url()).not.toContain('/home');
  });

  test('[TC-UI-06] ไม่มี token แล้วเข้า home (Demo Bypass) จะถูกเด้งกลับหน้า login', async ({ page }) => {
    const errors: string[] = [];
    page.on('pageerror', (e) => errors.push(e.message));

    await openApp(page);
    await page.getByRole('button', { name: /Demo Bypass/ }).click();

    await expect(page).toHaveURL(/#\/welcome/, { timeout: 60_000 });
    await expect(page.getByRole('button', { name: 'ดำเนินการต่อด้วย LINE' })).toBeVisible();
    expect(errors).toEqual([]);
  });

  test('[TC-UI-07] หน้าจอมือถือ (390x844) ยังใช้งานได้', async ({ page }) => {
    await page.setViewportSize({ width: 390, height: 844 });
    await openApp(page);
    await expect(page.getByRole('button', { name: 'ดำเนินการต่อด้วย LINE' })).toBeVisible();
    const noHScroll = await page.evaluate(
      () => document.documentElement.scrollWidth <= window.innerWidth,
    );
    expect(noHScroll).toBe(true);
  });
});

test.describe('ปุ่ม Google', () => {
  test('[TC-GG-01] ปุ่มของ Google (iframe) ถูกวางทับปุ่มที่เห็น และสูงเท่าปุ่ม LINE', async ({ page }) => {
    await page.setViewportSize({ width: 480, height: 900 });
    await openApp(page);

    const iframe = page.locator('iframe[src*="accounts.google.com/gsi/button"]');
    await expect(iframe).toBeAttached();
    await expect.poll(async () => (await iframe.boundingBox())?.height ?? 0).toBeGreaterThan(30);

    const box = (await iframe.boundingBox())!;
    const line = (await page.getByRole('button', { name: 'ดำเนินการต่อด้วย LINE' }).boundingBox())!;
    expect(box.width).toBeGreaterThan(200);
    expect(Math.abs(box.height - line.height)).toBeLessThanOrEqual(4);
  });

  test('[TC-GG-02] กดแล้วเปิดหน้าเลือกบัญชีของ Google โดยไม่ขึ้น origin_mismatch', async ({
    page,
    context,
  }) => {
    await page.setViewportSize({ width: 480, height: 900 });
    await openApp(page);

    const iframe = page.locator('iframe[src*="accounts.google.com/gsi/button"]');
    await expect.poll(async () => (await iframe.boundingBox())?.height ?? 0).toBeGreaterThan(30);
    const box = (await iframe.boundingBox())!;

    const popupPromise = context.waitForEvent('page', { timeout: 30_000 });
    await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
    const popup = await popupPromise;
    await popup.waitForLoadState('load');
    await popup.waitForTimeout(3000); // รอ redirect ไปหน้า error (ถ้า origin ไม่ถูกต้อง)

    expect(popup.url()).toContain('accounts.google.com');
    expect(popup.url()).not.toMatch(/oauth\/error|authError/);
    expect(await popup.locator('body').innerText()).not.toMatch(/origin_mismatch/);
  });
});
