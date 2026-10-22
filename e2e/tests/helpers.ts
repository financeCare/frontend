import { createHmac } from 'node:crypto';
import { expect, type Locator, type Page } from '@playwright/test';

export const API_URL =
  process.env.E2E_API_URL ?? 'https://financecare-backend-deploy.onrender.com';

/**
 * เปิดแอป Flutter web แล้วเปิด accessibility tree (semantics)
 * ถ้าไม่เปิด Flutter จะวาดทุกอย่างลง canvas และ Playwright จะมองไม่เห็นปุ่ม/ช่องกรอก
 */
export async function openApp(page: Page) {
  // ใช้ './' ไม่ใช่ '/' เพราะ '/' จะข้าม path ของ baseURL (/financecare-web/)
  await page.goto('./');
  await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 90_000 });
  await page.waitForSelector('flt-semantics-placeholder', { state: 'attached' });
  await page.evaluate(() =>
    (document.querySelector('flt-semantics-placeholder') as HTMLElement).click(),
  );
  await expect(page.getByRole('button', { name: 'ดำเนินการต่อด้วย LINE' })).toBeVisible();
}

/** ข้อความทั้งหมดที่ Flutter แสดงอยู่ ณ ตอนนี้ (อ่านจาก semantics tree) */
export function screenText(page: Page): Promise<string> {
  return page.evaluate(
    () => (document.querySelector('flt-semantics-host') as HTMLElement | null)?.innerText ?? '',
  );
}

/** ช่องกรอกของ Flutter ไม่รับ fill() ต้องคลิกแล้วพิมพ์ผ่านคีย์บอร์ดจริง */
export async function typeInto(page: Page, label: string, text: string) {
  await page.getByLabel(label).click();
  await page.keyboard.type(text, { delay: 15 });
}

/** สร้าง JWT (HS256) แบบเดียวกับ JwtUtil ของ backend ใช้กับเทสต์ที่ต้องมี token เท่านั้น */
export function mintAccessToken(email: string, base64Secret: string): string {
  const b64url = (v: object) => Buffer.from(JSON.stringify(v)).toString('base64url');
  const now = Math.floor(Date.now() / 1000);
  const head = b64url({ alg: 'HS256', typ: 'JWT' });
  const body = b64url({ sub: email, type: 'access', iat: now, exp: now + 600 });
  const sig = createHmac('sha256', Buffer.from(base64Secret, 'base64'))
    .update(`${head}.${body}`)
    .digest('base64url');
  return `${head}.${body}.${sig}`;
}

/** ล็อกอินผ่านฟอร์มจริง แล้วรอจนเห็นหน้า Home (ภาพรวมหนี้สิน) */
export async function loginViaUi(page: Page, email: string, password: string) {
  await openApp(page);
  await typeInto(page, 'you@example.com', email);
  await page.keyboard.press('Tab');
  await page.keyboard.type(password, { delay: 15 });
  await page.getByRole('button', { name: 'เข้าสู่ระบบ' }).last().click();
  await expect
    .poll(() => screenText(page), { timeout: 90_000 })
    .toContain('ภาพรวมหนี้สิน');
}

/**
 * เลื่อนหน้า Flutter (ด้วยล้อเมาส์) จนข้อความที่ระบุอยู่ในพื้นที่ที่มองเห็นได้ แล้วคืน bounding box
 * Flutter วาดลง canvas จึงใช้ scrollIntoView ของ DOM ไม่ได้
 */
export async function scrollToLocator(page: Page, node: Locator) {
  await expect(node).toBeAttached({ timeout: 20_000 });
  const vh = page.viewportSize()?.height ?? 900;
  for (let i = 0; i < 20; i++) {
    const box = await node.boundingBox();
    if (box && box.y > 170 && box.y < vh - 200) return box;
    await page.mouse.move(240, vh / 2);
    await page.mouse.wheel(0, box && box.y < 170 ? -250 : 250);
    await page.waitForTimeout(250);
  }
  const box = await node.boundingBox();
  if (!box) throw new Error('ไม่พบ element ที่ต้องการ');
  return box;
}

export async function scrollToText(page: Page, text: string | RegExp, exact = true) {
  return scrollToLocator(page, page.getByText(text, { exact }).first());
}

/** กรอกช่องที่อยู่ "ใต้" ป้ายกำกับ (ช่องกรอกของ Flutter ไม่มี label ในตัว) */
export async function fillBelowLabel(page: Page, label: string | RegExp, value: string, exact = true) {
  const box = await scrollToText(page, label, exact);
  await page.mouse.click(box.x + 120, box.y + box.height + 28);
  await page.keyboard.press('Control+A');
  await page.keyboard.type(value, { delay: 12 });
}

/** กดปุ่มตามชื่อ (semantics role=button) */
export async function tapButton(page: Page, name: string | RegExp) {
  await page.getByRole('button', { name }).first().click();
}

/**
 * กดข้อความที่ไม่ใช่ปุ่มใน semantics (เช่นรายการในเมนู popup, ข้อความที่กดได้)
 * locator.click() ค้างเพราะ flutter-view ทับอยู่ จึงคลิกด้วยพิกัดกึ่งกลางของข้อความแทน
 */
export async function tapText(page: Page, text: string | RegExp, exact = true) {
  const box = await scrollToText(page, text, exact);
  await page.mouse.click(box.x + box.width / 2, box.y + box.height / 2);
}

/**
 * เลื่อนลงจนข้อความปรากฏ (รายการใน Flutter สร้างเมื่อเลื่อนมาถึงเท่านั้น จึงยังไม่อยู่ใน semantics tree)
 * แล้วคืน bounding box ที่อยู่ในพื้นที่ที่มองเห็นได้
 */
export async function scrollUntilText(page: Page, text: string | RegExp, exact = false) {
  const node = page.getByText(text, { exact }).first();
  const vh = page.viewportSize()?.height ?? 900;
  for (let i = 0; i < 20 && (await node.count()) === 0; i++) {
    await page.mouse.move(240, vh / 2);
    await page.mouse.wheel(0, 350);
    await page.waitForTimeout(300);
  }
  return scrollToLocator(page, node);
}

/** เลื่อนลงสุดหน้า (ใช้ก่อนกดปุ่มท้ายหน้า) */
export async function scrollToBottom(page: Page) {
  const vh = page.viewportSize()?.height ?? 900;
  for (let i = 0; i < 8; i++) {
    await page.mouse.move(240, vh / 2);
    await page.mouse.wheel(0, 500);
    await page.waitForTimeout(200);
  }
}
