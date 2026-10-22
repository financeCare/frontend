import { expect, test, type APIRequestContext, type Page } from '@playwright/test';
import {
  API_URL,
  fillBelowLabel,
  loginViaUi,
  screenText,
  scrollToBottom,
  scrollToLocator,
  tapButton,
  tapText,
} from './helpers';

/**
 * ทดสอบการใช้งานผ่านหน้าจอจริงของเคส M-F01…M-F12 (ทำ action บนหน้าจอ แล้วยืนยันผลกับ API)
 * สร้าง/แก้/ลบข้อมูลจริง จึงต้องตั้ง E2E_ALLOW_WRITES=1 และรันกับ stack ในเครื่องเท่านั้น
 *
 * หมายเหตุเรื่อง Flutter web: ข้อความธรรมดาไม่ใช่ปุ่ม (คลิกด้วยพิกัด), รายการใน popup menu และ
 * dialog บางส่วนไม่ปรากฏใน semantics tree จึงต้องคลิกตามตำแหน่ง
 */
const email = process.env.E2E_EMAIL;
const password = process.env.E2E_PASSWORD;
const allowWrites = process.env.E2E_ALLOW_WRITES === '1';

const money = (n: number) => n.toLocaleString('en-US', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
const hoursAgo = (h: number) => new Date(Date.now() - h * 3600_000).toISOString().slice(0, 19);
const uid = () => Math.random().toString(36).slice(2, 7);

test.describe('การใช้งานผ่านหน้าจอ (M-F)', () => {
  test.skip(!email || !password || !allowWrites, 'ตั้ง E2E_EMAIL, E2E_PASSWORD และ E2E_ALLOW_WRITES=1 (stack ในเครื่องเท่านั้น)');
  test.use({ viewport: { width: 480, height: 900 } });

  let ctx: APIRequestContext;
  let h: Record<string, string> = {};
  let debtTypeId = 0;
  let repaymentTypeId = 0;
  let strategyId = '';
  let food: any;
  const debtIds: string[] = [];
  const txIds: string[] = [];

  const api = async (method: string, path: string, data?: unknown) =>
    ctx.fetch(`${API_URL}/api${path}`, { method, data: data as never, headers: h, timeout: 60_000 });
  const apiJson = async <T = any>(method: string, path: string, data?: unknown): Promise<T> => {
    const res = await api(method, path, data);
    expect(res.status(), `${method} ${path}: ${await res.text()}`).toBeLessThan(300);
    return res.json();
  };

  const debtBody = (over: Record<string, unknown> = {}) => ({
    principalAmount: 10000,
    principalOutstanding: 10000,
    interestRate: 12,
    repaymentTypeId,
    startDate: '2026-01-01',
    endDate: '2027-10-01',
    isActive: true,
    priority: 1,
    debtTypeId,
    debtName: 'UF debt',
    minPayment: 500,
    dueDay: 15,
    penaltyAnnualRate: 0,
    gracePeriodDays: 0,
    penaltyTriggerDays: 0,
    isDefaulted: false,
    isInformal: false,
    interestCalculationType: 'THIRTY_360',
    interestInterval: 'YEARLY',
    paymentInterval: 'MONTHLY',
    initialInterestRemaining: 0,
    initialLateFeeRemaining: 0,
    initialPenaltyRemaining: 0,
    ...over,
  });
  const createDebt = async (name: string, over: Record<string, unknown> = {}) => {
    const d = await apiJson<any>('POST', '/debts', debtBody({ debtName: name, ...over }));
    debtIds.push(d.debtId);
    return d;
  };
  const createTx = async (amount: number, description: string) => {
    const t = await apiJson<any>('POST', '/transactions', {
      categoryId: food.categoryId,
      amount,
      transactionDate: hoursAgo(1),
      description,
      budgetId: food.budgetId,
    });
    txIds.push(t.transactionId);
    return t;
  };
  const foodBudget = async () =>
    (await apiJson<any[]>('GET', '/budget')).find((b) => b.budgetId === food.budgetId);

  /** ล็อกอินผ่านหน้าจอ แล้วเก็บ response ของ backend ที่เป็น 4xx/5xx ไว้ตรวจ */
  async function open(page: Page) {
    const errors: string[] = [];
    page.on('response', (r) => {
      if (r.url().startsWith(API_URL) && r.status() >= 400) {
        errors.push(`${r.status()} ${r.request().method()} ${r.url().replace(API_URL, '')}`);
      }
    });
    await loginViaUi(page, email!, password!);
    return errors;
  }
  async function openBudgetFab(page: Page, action: RegExp) {
    await tapButton(page, /งบประมาณ แท็บ/);
    await page.waitForTimeout(2500);
    await page.mouse.click(436, 800); // ปุ่ม FAB มุมขวาล่าง
    await page.waitForTimeout(800);
    await tapButton(page, action);
    await page.waitForTimeout(1500);
  }

  test.beforeAll(async ({ playwright }) => {
    ctx = await playwright.request.newContext();
    const res = await ctx.post(`${API_URL}/api/auth/login`, { data: { email, password }, timeout: 90_000 });
    expect(res.status(), await res.text()).toBe(200);
    h = { Authorization: `Bearer ${(await res.json()).accessToken}` };

    const types = await apiJson<any[]>('GET', '/debt-types');
    const reps = await apiJson<any[]>('GET', '/repayment-types');
    const strategies = (await apiJson<any>('GET', '/repayment-plans/strategies')).repaymentStrategyList;
    expect(types.length && reps.length && strategies.length, 'ต้องมีประเภทหนี้/ประเภทการชำระ/กลยุทธ์ในฐานข้อมูล').toBeTruthy();
    debtTypeId = types[0].debtTypeId;
    repaymentTypeId = reps[0].repaymentTypeId;
    strategyId = strategies[0].strategyId;
    food = (await apiJson<any[]>('GET', '/categories')).find((c) => c.categoryName === 'Food');
  });

  test.afterEach(async () => {
    for (const id of txIds.splice(0)) await api('DELETE', `/transactions/${id}`);
    for (const id of debtIds.splice(0)) {
      const del = await api('DELETE', `/debts/${id}`);
      if (del.status() >= 400) await api('PUT', `/debts/${id}`, debtBody({ isActive: false, debtName: 'UF leftover' }));
    }
  });
  test.afterAll(async () => {
    await ctx?.dispose();
  });

  // ------------------------------------------------------------------ M-F01
  test('[TC-UF-01] (M-F01) หน้า Home แสดงสรุปหนี้ตรงกับข้อมูลจริง และ API ไม่ตอบ 4xx/5xx', async ({ page }) => {
    await createDebt(`UF home ${uid()}`, { principalAmount: 12000, principalOutstanding: 12000, minPayment: 600 });
    const list = await apiJson<any[]>('GET', '/debts');
    const active = list.filter((d) => d.debt.active);
    const outstanding = active.reduce((s, d) => s + Number(d.debt.principalOutstanding), 0);
    const minSum = active.reduce((s, d) => s + Number(d.debt.minPayment), 0);

    const errors = await open(page);
    await page.waitForTimeout(3000);
    const text = await screenText(page);
    expect(text).toContain('ภาพรวมหนี้สิน');
    expect(text).toContain(`${money(outstanding)} ฿`);
    expect(text).toContain(`${active.length} รายการ`);
    expect(text).toContain(`ยอดจ่ายขั้นต่ำรวม: ${money(minSum)} ฿`);
    expect(errors, errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F02
  test('[TC-UF-02] (M-F02) เพิ่มรายการรายจ่ายผ่านหน้าจอ แล้วงบและรายการอัปเดต', async ({ page }) => {
    const before = (await foodBudget()).amount as number;
    const note = `uf-expense-${uid()}`;
    const errors = await open(page);
    await openBudgetFab(page, /เพิ่มรายการใหม่/);

    await fillBelowLabel(page, /จำนวนเงิน \(฿\)/, '120', false);
    await fillBelowLabel(page, /คำอธิบาย \(ไม่บังคับ\)/, note, false);
    await tapButton(page, /^บันทึก$/);
    await page.waitForTimeout(3000);

    const txs = await apiJson<any[]>('GET', '/transactions');
    const created = txs.find((t) => t.description === note);
    expect(created, 'ต้องมีรายการที่เพิ่ม').toBeTruthy();
    txIds.push(created.transactionId ?? created.id);
    expect(created.amount).toBe(120);
    expect((await foodBudget()).amount).toBe(before + 120);
    expect(errors, errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F03
  test('[TC-UF-03] (M-F03) เปิดรายการธุรกรรม ดูรายละเอียด และแก้ไขจำนวนเงิน', async ({ page }) => {
    const note = `uf-edit-${uid()}`;
    await createTx(80, note);
    const before = (await foodBudget()).amount as number;

    const errors = await open(page);
    await openBudgetFab(page, /ดูรายการทั้งหมด/);
    expect(await screenText(page)).toContain(note);

    await tapText(page, note, false);
    await page.waitForTimeout(1500);
    expect(await screenText(page)).toContain('Edit Transaction');
    await tapButton(page, /Edit Transaction/);
    await page.waitForTimeout(1500);
    // หน้าแก้ไขต้องเปิดมาพร้อมหมวดเดิม (Food/รายจ่าย) ไม่ใช่หมวดแรกของรายการ (เคยเป็นบั๊ก)
    await fillBelowLabel(page, /^จำนวนเงิน$/, '95');
    await scrollToBottom(page);
    await tapButton(page, /บันทึก|แก้ไข/);
    await page.waitForTimeout(3000);

    const txs = await apiJson<any[]>('GET', '/transactions');
    const edited = txs.find((t) => t.description === note);
    expect(edited.amount).toBe(95);
    expect(edited.categoryDTO.type, 'ประเภทหมวดต้องไม่ถูกเปลี่ยน').toBe('Expense');
    expect(edited.categoryDTO.categoryName).toBe('Food');
    expect((await foodBudget()).amount, 'งบต้องเปลี่ยนตามส่วนต่าง').toBe(before + 15);
    expect(errors, errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F04
  test('[TC-UF-04] (M-F04) ตั้งวงเงินงบรายหมวดผ่านหน้าจอ', async ({ page }) => {
    const budgets = await apiJson<any[]>('GET', '/budget');
    const target = (await apiJson<any[]>('GET', '/categories')).find((c) => c.categoryName === 'Bills');
    const bills = budgets.find((b) => b.budgetId === target.budgetId);
    try {
      const errors = await open(page);
      await tapButton(page, /งบประมาณ แท็บ/);
      await page.waitForTimeout(2500);
      await page.getByRole('button', { name: 'แก้ไข' }).first().click(); // Bills เป็นหมวดแรกของรายการ
      await page.waitForTimeout(1500);
      await fillBelowLabel(page, /งบประมาณ \(฿\)/, '2500', false);
      await tapButton(page, /^บันทึก$/);
      await page.waitForTimeout(3000);

      const after = (await apiJson<any[]>('GET', '/budget')).find((b) => b.budgetId === bills.budgetId);
      expect(after.limitBudget).toBe(2500);
      expect(errors, errors.join('\n')).toEqual([]);
    } finally {
      await api('PUT', `/budget/${bills.budgetId}/amount/${bills.limitBudget}`);
    }
  });

  // ------------------------------------------------------------------ M-F05
  test('[TC-UF-05] (M-F05) เพิ่มหนี้ผ่านฟอร์ม 3 ขั้น แล้วขึ้นในรายการและ API', async ({ page }) => {
    const name = `UF wizard ${uid()}`;
    const errors = await open(page);
    await tapButton(page, /สร้างหนี้/);
    await page.waitForTimeout(2000);
    await fillBelowLabel(page, 'ชื่อหนี้', name);
    await tapButton(page, /ถัดไป/);
    await page.waitForTimeout(1500);
    await fillBelowLabel(page, 'จำนวนเงินต้น', '20000');
    await fillBelowLabel(page, /ยอดหนี้คงเหลือปัจจุบัน/, '20000', false);
    await fillBelowLabel(page, 'อัตราดอกเบี้ย', '12');
    await fillBelowLabel(page, /ชำระขั้นต่ำ/, '800', false);
    await tapButton(page, /ถัดไป/);
    await page.waitForTimeout(2000);
    await fillBelowLabel(page, /วันที่ต้องชำระของทุกเดือน/, '15', false);
    await tapButton(page, /สร้างรายการหนี้/);
    await page.waitForTimeout(4000);

    const list = await apiJson<any[]>('GET', '/debts');
    const created = list.find((d) => d.debt.debtName === name);
    expect(created, 'หนี้ต้องถูกสร้าง').toBeTruthy();
    debtIds.push(created.debt.debtId);
    expect(Number(created.debt.principalAmount)).toBe(20000);
    expect(Number(created.debt.interestRate)).toBe(12);
    expect(Number(created.debt.minPayment)).toBe(800);
    expect(created.debt.dueDay).toBe(15);
    // การ์ดหนี้บน Home ไม่มีข้อความในแผนผังการเข้าถึง (accessibility) จึงตรวจจากจำนวนรายการที่ Home สรุปให้
    const activeCount = (await apiJson<any[]>('GET', '/debts')).filter((d) => d.debt.active).length;
    await page.waitForTimeout(1500);
    expect(await screenText(page)).toContain(`${activeCount} รายการ`);
    expect(errors, errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F06
  test('[TC-UF-06] (M-F06) แก้ไขชื่อหนี้ผ่านเมนูการ์ด และลบหนี้ที่ยังไม่เคยจ่าย', async ({ page }) => {
    const name = `UF edit ${uid()}`;
    const newName = `${name} X`;
    const debt = await createDebt(name);
    // ให้เหลือหนี้ที่ใช้งานอยู่แค่รายการนี้ ปุ่มเมนูแรกของ Home จะได้เป็นของรายการนี้แน่นอน
    // (การ์ดหนี้ไม่มีข้อความใน accessibility tree จึงระบุการ์ดด้วยชื่อไม่ได้)
    for (const d of await apiJson<any[]>('GET', '/debts')) {
      if (d.debt.debtId === debt.debtId || !d.debt.active) continue;
      const del = await api('DELETE', `/debts/${d.debt.debtId}`);
      if (del.status() >= 400) await api('PUT', `/debts/${d.debt.debtId}`, debtBody({ isActive: false, debtName: 'UF leftover' }));
    }
    const errors = await open(page);

    const openMenu = async () => {
      const btn = page.getByRole('button', { name: 'แสดงเมนู' }).first();
      const bb = await scrollToLocator(page, btn);
      await btn.click();
      await page.waitForTimeout(800);
      return bb;
    };

    let bb = await openMenu();
    await page.mouse.click(bb.x + bb.width / 2 - 60, bb.y + bb.height / 2 + 8); // แก้ไข
    await page.waitForTimeout(2000);
    expect(await screenText(page)).toContain('แก้ไขหนี้');
    await fillBelowLabel(page, 'ชื่อหนี้', newName);
    await tapButton(page, /ถัดไป/);
    await page.waitForTimeout(1200);
    await tapButton(page, /ถัดไป/);
    await page.waitForTimeout(1200);
    await tapButton(page, /บันทึก|อัปเดต|แก้ไข/);
    await page.waitForTimeout(3500);

    const edited = await apiJson<any>('GET', `/debts/debtId/${debt.debtId}`);
    expect(edited.debtName).toBe(newName);

    bb = await openMenu();
    await page.mouse.click(bb.x + bb.width / 2 - 60, bb.y + bb.height / 2 + 58); // ลบ
    await page.waitForTimeout(1200);
    await tapButton(page, /ลบ|ยืนยัน|ตกลง/);
    await page.waitForTimeout(3000);
    const after = await apiJson<any[]>('GET', '/debts');
    expect(after.find((d) => d.debt.debtId === debt.debtId), 'หนี้ต้องถูกลบ').toBeUndefined();
    expect(errors, errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F07
  test('[TC-UF-07] (M-F07) จ่ายหนี้ผ่านหน้าจอ แล้วยอดคงเหลือลดลง', async ({ page }) => {
    const name = `UF pay ${uid()}`;
    const debt = await createDebt(name);
    const errors = await open(page);
    await tapButton(page, /ชำระหนี้/);
    await page.waitForTimeout(2500);
    expect(await screenText(page)).toContain('เลือกรายการหนี้');
    // หนี้ที่ลบไม่ได้ (เคยจ่ายแล้ว ดู TC-FT-21) อาจค้างอยู่ จึงเลือกหนี้ตามชื่อให้แน่ใจว่าจ่ายถูกตัว
    if (!(await screenText(page)).includes(name)) {
      await tapButton(page, /Personal Loan/); // ตัวเลือกหนี้ที่เลือกอยู่
      await page.waitForTimeout(1000);
      await tapButton(page, new RegExp(name));
      await page.waitForTimeout(1000);
    }
    expect(await screenText(page)).toContain(name);
    await fillBelowLabel(page, 'จำนวนเงินที่ต้องการชำระ', '1000');
    await tapButton(page, /ชำระเงิน/);
    await page.waitForTimeout(3500);

    const after = await apiJson<any>('GET', `/debts/debtId/${debt.debtId}`);
    expect(Number(after.principalOutstanding)).toBeLessThan(10000);
    const history = await apiJson<any[]>('GET', `/debts/${debt.debtId}/history`);
    expect(history.some((x) => x.txnType === 'PAYMENT' && x.amount === 1000)).toBe(true);
    expect(errors, errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F08
  test('[TC-UF-08] (M-F08) ตั้งงบรายเดือนและเลือกกลยุทธ์ชำระหนี้ จนได้แผน', async ({ page }) => {
    await createDebt(`UF plan A ${uid()}`, { interestRate: 24, minPayment: 300 });
    await createDebt(`UF plan B ${uid()}`, { interestRate: 6, minPayment: 300 });
    const errors = await open(page);
    await tapButton(page, /กลยุทธ์ชำระ/);
    await page.waitForTimeout(2500);
    expect(await screenText(page)).toContain('เลือกยุทธวิธีการชำระหนี้ของคุณ');
    await fillBelowLabel(page, 'งบประมาณรายเดือน', '3000');
    await tapButton(page, /ถัดไป/);
    await page.waitForTimeout(3500);
    const step2 = await screenText(page);
    expect(step2).toContain('ขั้นตอนที่ 2 จาก 3');
    await scrollToBottom(page);
    await tapButton(page, /ดูแผนการชำระหนี้/);
    await page.waitForTimeout(4000);

    const plan = await apiJson<any>('GET', '/repayment-plans');
    expect(JSON.stringify(plan).length).toBeGreaterThan(50);
    expect(await screenText(page)).toContain('ขั้นตอนที่ 3 จาก 3');
    expect(errors.filter((e) => !e.includes('/api/repayment-plans')), errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F09
  test('[TC-UF-09] (M-F09) หน้าการแจ้งเตือนเปิดได้ สลับแท็บทั้งหมด/งบประมาณ/หนี้สิน', async ({ page }) => {
    const errors = await open(page);
    await page.locator('flt-semantics[role=button]').first().click(); // ไอคอนกระดิ่งมุมขวาบน
    await page.waitForTimeout(2500);
    expect(await screenText(page)).toContain('การแจ้งเตือน');
    for (const tab of ['งบประมาณ', 'หนี้สิน', 'ทั้งหมด']) {
      await tapButton(page, new RegExp(`^${tab}$`));
      await page.waitForTimeout(1500);
    }
    expect(errors, errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F10
  /** รูปที่ไม่ใช่สลิป (ข้อความธรรมดาบนพื้นขาว) สร้างจากการแคปหน้าเว็บเปล่า ๆ */
  async function notASlipPng(page: Page): Promise<Buffer> {
    const p = await page.context().newPage();
    await p.setContent('<body style="margin:0;background:#fff;font:32px sans-serif;padding:40px">This is not a bank slip</body>');
    const buf = await p.screenshot({ clip: { x: 0, y: 0, width: 480, height: 240 } });
    await p.close();
    return buf;
  }

  test('[TC-UF-10] (M-F10) อัปโหลดรูปที่ไม่ใช่สลิปทาง API ต้องไม่ได้ 500', async ({ page }) => {
    const png = await notASlipPng(page);
    const res = await ctx.post(`${API_URL}/api/slips/upload`, {
      headers: h,
      multipart: { files: { name: 'not-a-slip.png', mimeType: 'image/png', buffer: png } },
      timeout: 120_000,
    });
    // รูปที่อ่านเป็นสลิปไม่ได้ควรได้ 4xx หรือผลลัพธ์ที่บอกว่าไม่ผ่าน ไม่ใช่ 500
    expect(res.status(), await res.text()).toBeLessThan(500);
  });

  // fixme: เลือกไฟล์ผ่าน file chooser แล้วแอปไม่ส่งรูปไป backend (ไม่มี request) และมี pageerror ทั่วไป 1 รายการ
  // ยังไม่ทราบว่าเป็นบั๊กของแอปหรือข้อจำกัดของการทดสอบอัตโนมัติ ให้ทดสอบด้วยมือ (เคส M-F10) ก่อน
  test.fixme('[TC-UF-10b] (M-F10) อัปโหลดรูปที่ไม่ใช่สลิปผ่านหน้าสแกน แอปต้องแจ้งผลและไม่ค้าง', async ({ page }) => {
    const png = await notASlipPng(page);
    const errors = await open(page);
    const calls: string[] = [];
    page.on('response', (r) => {
      if (r.url().startsWith(API_URL) && r.request().method() !== 'GET') {
        calls.push(`${r.status()} ${r.request().method()} ${r.url().replace(API_URL, '')}`);
      }
    });
    page.on('console', (m) => {
      if (['error', 'warning', 'log'].includes(m.type()) && !/Token|HomePage|!!!/.test(m.text())) console.log(`[console.${m.type()}] ${m.text().slice(0, 200)}`);
    });
    page.on('pageerror', (e) => console.log(`[pageerror] ${e.message.slice(0, 200)}`));
    await tapButton(page, /สแกน OCR แท็บ/);
    await page.waitForTimeout(2500);
    expect(await screenText(page)).toContain('เลือกรูปภาพสลิป');

    // ตัวเลือกไฟล์ของเบราว์เซอร์เปิดได้เฉพาะเมื่อมีการกดจริง (user activation) จึงใช้เมาส์คลิกตามพิกัด
    const area = (await page.getByRole('button', { name: /แตะเพื่ออัปโหลดรูปภาพ/ }).boundingBox())!;
    await page.mouse.click(area.x + area.width / 2, area.y + area.height / 2);
    await page.waitForTimeout(1200);
    // แอปเปิดเมนูล่าง "เลือกจากแกลเลอรี่ / ถ่ายรูป" ต้องเลือกแกลเลอรี่ก่อนจึงเปิดตัวเลือกไฟล์
    const chooser = page.waitForEvent('filechooser', { timeout: 15_000 });
    const gallery = (await page.getByText('เลือกจากแกลเลอรี่').first().boundingBox())!;
    await page.mouse.click(gallery.x + gallery.width / 2, gallery.y + gallery.height / 2);
    await (await chooser).setFiles({ name: 'not-a-slip.png', mimeType: 'image/png', buffer: png });

    // รอผลประมวลผล (OCR ครั้งแรกอาจช้า) แล้วหน้าจอต้องยังตอบสนองและไม่ค้างที่ตัวโหลด
    await page.waitForTimeout(15_000);
    const after = await screenText(page);
    console.log('OCR API CALLS: ' + calls.join(' | '));
    console.log('OCR RESULT SCREEN:\n' + after.slice(0, 600));
    expect(calls.some((c) => c.includes('/slips/upload')), 'ต้องมีการส่งรูปไปที่ backend').toBe(true);
    expect(errors.filter((e) => e.startsWith('5')), errors.join('\n')).toEqual([]);
  });

  // ------------------------------------------------------------------ M-F11 / M-F12
  test('[TC-UF-11] (M-F11) ตั้งเงินเดือนในหน้าตั้งค่าแล้วบันทึก', async ({ page }) => {
    const before = await apiJson<number>('GET', '/budget/salary');
    try {
      const errors = await open(page);
      await tapButton(page, /ตั้งค่า แท็บ/);
      await page.waitForTimeout(2500);
      await fillBelowLabel(page, /เงินเดือนปัจจุบัน/, '33000', false);
      await tapButton(page, /บันทึกการตั้งค่า/);
      await page.waitForTimeout(1200);
      await tapButton(page, /^บันทึก$/); // ยืนยันใน dialog
      await page.waitForTimeout(3000);
      expect(await apiJson<number>('GET', '/budget/salary')).toBe(33000);
      expect(errors, errors.join('\n')).toEqual([]);
    } finally {
      await api('POST', `/budget/salary/${before}`);
    }
  });

  test('[TC-UF-12] (M-F12) ออกจากระบบแล้วกลับหน้า login และรีเฟรชแล้วยังไม่เข้าระบบ', async ({ page }) => {
    await open(page);
    await tapButton(page, /ตั้งค่า แท็บ/);
    await page.waitForTimeout(2500);
    await tapButton(page, /ออกจากระบบ/);
    await page.waitForTimeout(2500);
    // อาจมี dialog ยืนยัน
    const confirm = page.getByRole('button', { name: /^(ออกจากระบบ|ยืนยัน|ตกลง)$/ });
    if (await confirm.first().isVisible().catch(() => false)) await confirm.first().click();
    await expect(page.getByRole('button', { name: 'ดำเนินการต่อด้วย LINE' })).toBeVisible({ timeout: 20_000 });

    await page.reload();
    await page.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 60_000 });
    await page.evaluate(() => (document.querySelector('flt-semantics-placeholder') as HTMLElement | null)?.click());
    await expect(page.getByRole('button', { name: 'ดำเนินการต่อด้วย LINE' })).toBeVisible({ timeout: 30_000 });
    expect(await screenText(page)).not.toContain('ภาพรวมหนี้สิน');
  });
});
