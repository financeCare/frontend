import { expect, test, type APIRequestContext } from '@playwright/test';
import { API_URL, mintAccessToken } from './helpers';

/**
 * ทดสอบ feature หลังล็อกอิน (หมวดหมู่ งบประมาณ ธุรกรรม หนี้ การจ่ายหนี้ แผนชำระหนี้ ฯลฯ) ผ่าน API
 *
 * กลุ่มนี้ "สร้าง/แก้/ลบข้อมูลจริง" ของบัญชีทดสอบ จึงรันเฉพาะเมื่อตั้ง E2E_ALLOW_WRITES=1
 * ห้ามตั้งกับบัญชีจริงบน production รันกับ stack ในเครื่อง (ดู README) แต่ละเทสต์ลบข้อมูลที่ตัวเองสร้างตอนจบ
 *
 * env: E2E_EMAIL, E2E_PASSWORD, E2E_ALLOW_WRITES=1
 * เสริม (ทดสอบการแยกข้อมูลระหว่างผู้ใช้): E2E_JWT_SECRET + E2E_USER_EMAIL (ผู้ใช้อีกคน)
 */
const email = process.env.E2E_EMAIL;
const password = process.env.E2E_PASSWORD;
const allowWrites = process.env.E2E_ALLOW_WRITES === '1';

const today = () => new Date().toISOString().slice(0, 10);
const hoursAgo = (h: number) => new Date(Date.now() - h * 3600_000).toISOString().slice(0, 19);

test.describe('feature หลังล็อกอิน (API)', () => {
  test.skip(
    !email || !password || !allowWrites,
    'ตั้ง E2E_EMAIL, E2E_PASSWORD และ E2E_ALLOW_WRITES=1 (ใช้กับ stack ในเครื่องเท่านั้น)',
  );

  let ctx: APIRequestContext;
  let token = '';
  let debtTypeId = 0;
  let repaymentTypeId = 0;
  let strategyId = '';

  const call = async (method: string, path: string, data?: unknown, auth = true) =>
    ctx.fetch(`${API_URL}/api${path}`, {
      method,
      data: data as never,
      headers: auth ? { Authorization: `Bearer ${token}` } : {},
      timeout: 60_000,
    });
  const json = async <T = any>(res: Awaited<ReturnType<typeof call>>): Promise<T> => {
    expect(res.status(), await res.text()).toBeLessThan(300);
    return res.json();
  };

  /** ล้างหนี้ของเทสต์: ถ้าลบไม่ได้ (เช่น มีประวัติการจ่าย ดู TC-FT-21) ให้ปิดการใช้งานแทน */
  const cleanupDebt = async (id: string) => {
    const del = await call('DELETE', `/debts/${id}`);
    if (del.status() >= 400) await call('PUT', `/debts/${id}`, debtBody({ isActive: false, debtName: 'E2E leftover' }));
  };

  const debtBody = (over: Record<string, unknown> = {}) => ({
    principalAmount: 10000,
    principalOutstanding: 10000,
    interestRate: 12,
    repaymentTypeId,
    startDate: '2026-01-01',
    endDate: '2027-01-01',
    isActive: true,
    priority: 1,
    debtTypeId,
    debtName: 'E2E debt',
    minPayment: 500,
    dueDay: 15,
    penaltyAnnualRate: 0,
    gracePeriodDays: 0,
    penaltyTriggerDays: 0,
    isDefaulted: false,
    isInformal: false,
    interestCalculationType: 'THIRTY_360',
    interestInterval: 'YEARLY', // อัตราดอกเบี้ยเป็นต่อปี (MONTHLY จะตีความเป็นต่อเดือน)
    paymentInterval: 'MONTHLY',
    initialInterestRemaining: 0,
    initialLateFeeRemaining: 0,
    initialPenaltyRemaining: 0,
    ...over,
  });

  test.beforeAll(async ({ playwright }) => {
    ctx = await playwright.request.newContext();
    const res = await ctx.post(`${API_URL}/api/auth/login`, { data: { email, password }, timeout: 90_000 });
    expect(res.status(), await res.text()).toBe(200);
    token = (await res.json()).accessToken;

    // ข้อมูลอ้างอิงที่ฐานข้อมูลใหม่ยังไม่มี (production ต้องมีอยู่แล้ว) สร้างเมื่อยังไม่มีเท่านั้น
    let types = await json<any[]>(await call('GET', '/debt-types'));
    if (types.length === 0) {
      await call('POST', '/debt-types', { debtTypeName: 'Personal Loan', debtTypeDescription: 'e2e seed' });
      types = await json<any[]>(await call('GET', '/debt-types'));
    }
    debtTypeId = types[0].debtTypeId ?? types[0].id;

    let reps = await json<any[]>(await call('GET', '/repayment-types'));
    if (reps.length === 0) {
      await call('POST', '/repayment-types', {
        repaymentTypeName: 'Installment / EMI',
        repaymentTypeDescription: 'e2e seed',
      });
      reps = await json<any[]>(await call('GET', '/repayment-types'));
    }
    repaymentTypeId = reps[0].repaymentTypeId ?? reps[0].id;

    let strategies = (await json<any>(await call('GET', '/repayment-plans/strategies'))).repaymentStrategyList;
    if (!strategies?.length) {
      await call('POST', '/repayment-plans/strategies', {
        strategyName: 'Avalanche',
        description: 'e2e seed',
        isActive: true,
      });
      // รายการกลยุทธ์ถูก cache ต่อผู้ใช้ และการเพิ่มกลยุทธ์ไม่ล้าง cache
      // การสร้าง/ลบหนี้จะล้าง cache จึงใช้หนี้ชั่วคราวช่วยล้าง
      const tmp = await json<any>(await call('POST', '/debts', debtBody({ debtName: 'E2E cache bust' })));
      await call('DELETE', `/debts/${tmp.debtId ?? tmp.id}`);
      strategies = (await json<any>(await call('GET', '/repayment-plans/strategies'))).repaymentStrategyList;
    }
    strategyId = strategies[0].strategyId ?? strategies[0].id;
    expect(debtTypeId, 'debt type id').toBeTruthy();
    expect(repaymentTypeId, 'repayment type id').toBeTruthy();
    expect(strategyId, 'strategy id').toBeTruthy();
  });

  test.afterAll(async () => {
    await ctx?.dispose();
  });

  // ---------------------------------------------------------------- หมวดหมู่
  test('[TC-FT-01] ผู้ใช้ใหม่มีหมวดหมู่เริ่มต้น รายรับ 2 และรายจ่าย 8', async () => {
    const cats = await json<any[]>(await call('GET', '/categories'));
    expect(cats.filter((c) => c.type === 'Income')).toHaveLength(2);
    expect(cats.filter((c) => c.type === 'Expense')).toHaveLength(8);
    for (const c of cats) expect(c.budgetId, `budget ของ ${c.categoryName}`).toBeTruthy();
  });

  test('[TC-FT-02] เพิ่ม แก้ไข และลบหมวดหมู่ของตัวเอง', async () => {
    const created = await json<any>(await call('POST', '/categories', { categoryName: 'E2E Cat', type: 'Expense' }));
    expect(created.categoryId).toBeTruthy();
    const edited = await json<any>(
      await call('PUT', `/categories/${created.categoryId}`, { categoryName: 'E2E Cat 2', type: 'Expense' }),
    );
    expect(edited.categoryName).toBe('E2E Cat 2');
    const one = await json<any>(await call('GET', `/categories/${created.categoryId}`));
    expect(one.categoryName).toBe('E2E Cat 2');

    expect((await call('DELETE', `/categories/${created.categoryId}`)).status()).toBeLessThan(300);
    const after = await json<any[]>(await call('GET', '/categories'));
    expect(after.find((c) => c.categoryId === created.categoryId)).toBeUndefined();
  });

  test('[TC-FT-03] สร้างหมวดหมู่โดยไม่ใส่ชื่อหรือประเภท ได้ 400', async () => {
    expect((await call('POST', '/categories', { categoryName: '', type: 'Expense' })).status()).toBe(400);
    expect((await call('POST', '/categories', { categoryName: 'x' })).status()).toBe(400);
  });

  // ---------------------------------------------------------------- งบประมาณ
  test('[TC-FT-04] งบประมาณของเดือนปัจจุบันมีครบทุกหมวด วงเงินเริ่มต้น 1000', async () => {
    const budgets = await json<any[]>(await call('GET', '/budget'));
    const now = new Date();
    expect(budgets.length).toBeGreaterThanOrEqual(10);
    for (const b of budgets) {
      expect(b.month).toBe(now.getMonth() + 1);
      expect(b.year).toBe(now.getFullYear());
    }
    const overview = await json<any[]>(await call('GET', '/budget/overview'));
    expect(overview.length).toBeGreaterThan(0);
    for (const o of overview) expect(o.limit).toBeGreaterThan(0);
  });

  test('[TC-FT-05] ตั้งวงเงินของงบหนึ่งรายการ แล้วอ่านกลับได้ค่าที่ตั้ง (ไม่แตะยอดที่ใช้ไป)', async () => {
    const budgets = await json<any[]>(await call('GET', '/budget'));
    const target = budgets[0];
    // endpoint /budget/{id}/amount/{n} ตั้ง "วงเงิน" (limitBudget) ไม่ใช่ยอดที่ใช้ไป (amount)
    const updated = await json<any>(await call('PUT', `/budget/${target.budgetId}/amount/321`));
    expect(updated.limitBudget).toBe(321);
    expect(updated.amount).toBe(target.amount);
    const again = (await json<any[]>(await call('GET', '/budget'))).find((b) => b.budgetId === target.budgetId);
    expect(again.limitBudget).toBe(321);
    await call('PUT', `/budget/${target.budgetId}/amount/${target.limitBudget}`); // คืนค่าเดิม
  });

  test('[TC-FT-06] ตั้งและอ่านเงินเดือน', async () => {
    const before = await json<number>(await call('GET', '/budget/salary'));
    expect((await call('POST', '/budget/salary/45000')).status()).toBeLessThan(300);
    expect(await json<number>(await call('GET', '/budget/salary'))).toBe(45000);
    await call('POST', `/budget/salary/${before}`);
  });

  test('[TC-FT-07] เรียก rollover รายเดือนซ้ำ ต้องไม่สร้างงบซ้ำ', async () => {
    const count = async () => (await json<any[]>(await call('GET', '/budget'))).length;
    const before = await count();
    expect((await call('GET', '/budget/reset-budget')).status()).toBeLessThan(300);
    expect((await call('GET', '/budget/reset-budget')).status()).toBeLessThan(300);
    expect(await count()).toBe(before);
  });

  // ---------------------------------------------------------------- ธุรกรรม
  test('[TC-FT-08] เพิ่ม ดู แก้ไข และลบรายการรายจ่าย', async () => {
    const food = (await json<any[]>(await call('GET', '/categories'))).find((c) => c.categoryName === 'Food');
    const before = await json<number>(await call('GET', '/transactions/monthly-expenses'));

    const tx = await json<any>(
      await call('POST', '/transactions', {
        categoryId: food.categoryId,
        amount: 120,
        transactionDate: hoursAgo(1),
        description: 'e2e lunch',
        budgetId: food.budgetId,
      }),
    );
    const id = tx.transactionId ?? tx.id;
    expect(id).toBeTruthy();

    const list = await json<any[]>(await call('GET', '/transactions'));
    expect(list.some((t) => (t.transactionId ?? t.id) === id)).toBe(true);
    expect(await json<number>(await call('GET', '/transactions/monthly-expenses'))).toBe(before + 120);

    const edited = await json<any>(
      await call('PUT', `/transactions/${id}`, {
        categoryId: food.categoryId,
        amount: 150,
        transactionDate: hoursAgo(1),
        description: 'e2e lunch 2',
        budgetId: food.budgetId,
      }),
    );
    expect(edited.amount).toBe(150);
    expect(await json<number>(await call('GET', '/transactions/monthly-expenses'))).toBe(before + 150);

    expect((await call('DELETE', `/transactions/${id}`)).status()).toBeLessThan(300);
    expect(await json<number>(await call('GET', '/transactions/monthly-expenses'))).toBe(before);
  });

  test('[TC-FT-23] ยอด "ใช้ไป" ของงบตรงกับธุรกรรมหลังเพิ่ม แก้ไข และลบ', async () => {
    const food = (await json<any[]>(await call('GET', '/categories'))).find((c) => c.categoryName === 'Food');
    const used = async () =>
      (await json<any[]>(await call('GET', '/budget'))).find((b) => b.budgetId === food.budgetId).amount as number;
    const body = (amount: number) => ({
      categoryId: food.categoryId,
      amount,
      transactionDate: hoursAgo(1),
      budgetId: food.budgetId,
    });

    const baseline = await used();
    const tx = await json<any>(await call('POST', '/transactions', body(100)));
    const id = tx.transactionId ?? tx.id;
    try {
      expect(await used(), 'หลังเพิ่ม').toBe(baseline + 100);
      await json(await call('PUT', `/transactions/${id}`, body(150)));
      // เคยเป็น baseline + 250: บวกยอดใหม่ซ้ำโดยไม่หักยอดเดิม
      expect(await used(), 'หลังแก้เป็น 150').toBe(baseline + 150);
    } finally {
      await call('DELETE', `/transactions/${id}`);
    }
    expect(await used(), 'หลังลบ').toBe(baseline);
  });

  test('[TC-FT-09] รายการธุรกรรมแบ่งหน้าตามหมวดหมู่ได้', async () => {
    const food = (await json<any[]>(await call('GET', '/categories'))).find((c) => c.categoryName === 'Food');
    const res = await json<any>(await call('GET', `/transactions/category/${food.categoryId}?page=0&size=5`));
    expect(Array.isArray(res.content)).toBe(true);
    expect(res.page.size).toBe(5);
  });

  test('[TC-FT-10] ข้อมูลธุรกรรมที่ไม่ถูกต้องถูกปฏิเสธ (จำนวน ≤ 0, วันที่อนาคต, ไม่มีหมวด)', async () => {
    const food = (await json<any[]>(await call('GET', '/categories'))).find((c) => c.categoryName === 'Food');
    const ok = { categoryId: food.categoryId, amount: 10, transactionDate: hoursAgo(1) };
    expect((await call('POST', '/transactions', { ...ok, amount: 0 })).status()).toBe(400);
    expect((await call('POST', '/transactions', { ...ok, amount: -5 })).status()).toBe(400);
    expect(
      (await call('POST', '/transactions', { ...ok, transactionDate: hoursAgo(-48) })).status(),
    ).toBe(400);
    expect((await call('POST', '/transactions', { amount: 10, transactionDate: hoursAgo(1) })).status()).toBe(400);
  });

  // ---------------------------------------------------------------- หนี้
  test('[TC-FT-11] เพิ่มหนี้แล้วเห็นในรายการ รายละเอียด และสรุป', async () => {
    const debt = await json<any>(await call('POST', '/debts', debtBody()));
    const id = debt.debtId ?? debt.id;
    expect(id).toBeTruthy();
    try {
      const list = await json<any[]>(await call('GET', '/debts'));
      // แต่ละรายการเป็น { debt, summary }
      expect(list.some((d) => d.debt.debtId === id)).toBe(true);
      const detail = await json<any>(await call('GET', `/debts/debtId/${id}`));
      expect(detail.debtName).toBe('E2E debt');
      const summary = await json<any>(await call('GET', `/debts/${id}/summary`));
      expect(summary).toBeTruthy();
      expect(await json<any[]>(await call('GET', `/debts/${id}/history`))).toEqual([]);
      const status = await json<any>(await call('GET', '/debts/monthly-status'));
      expect(status.requiredMinPayment).toBeGreaterThanOrEqual(0);
    } finally {
      await cleanupDebt(id);
    }
  });

  test('[TC-FT-12] ข้อมูลหนี้ที่ไม่ถูกต้องถูกปฏิเสธ (ไม่มีชื่อ, ดอกเบี้ยติดลบ, วันครบกำหนด 40)', async () => {
    expect((await call('POST', '/debts', debtBody({ debtName: '' }))).status()).toBe(400);
    expect((await call('POST', '/debts', debtBody({ interestRate: -1 }))).status()).toBe(400);
    expect((await call('POST', '/debts', debtBody({ dueDay: 40 }))).status()).toBe(400);
    expect((await call('POST', '/debts', debtBody({ principalAmount: -5 }))).status()).toBe(400);
  });

  test('[TC-FT-13] แก้ไขหนี้ได้ และลบแล้วหายจากรายการ', async () => {
    const debt = await json<any>(await call('POST', '/debts', debtBody({ debtName: 'E2E edit me' })));
    const id = debt.debtId ?? debt.id;
    const edited = await json<any>(await call('PUT', `/debts/${id}`, debtBody({ debtName: 'E2E edited', minPayment: 700 })));
    expect(edited.debtName).toBe('E2E edited');
    expect(Number(edited.minPayment)).toBe(700);

    expect((await call('DELETE', `/debts/${id}`)).status()).toBeLessThan(300);
    const list = await json<any[]>(await call('GET', '/debts'));
    expect(list.find((d) => (d.debtId ?? d.id) === id)).toBeUndefined();
  });

  test('[TC-FT-14] จ่ายหนี้แล้วยอดคงเหลือลดลงและมีประวัติการจ่าย', async () => {
    const debt = await json<any>(await call('POST', '/debts', debtBody({ debtName: 'E2E pay me' })));
    const id = debt.debtId ?? debt.id;
    try {
      const before = Number((await json<any>(await call('GET', `/debts/debtId/${id}`))).principalOutstanding);
      const pay = await call('POST', '/debts/pays', { debtId: id, paymentAmount: 500, paymentDate: today() });
      expect(pay.status(), await pay.text()).toBeLessThan(300);

      const after = Number((await json<any>(await call('GET', `/debts/debtId/${id}`))).principalOutstanding);
      expect(after).toBeLessThan(before);
      // การจ่าย 1 ครั้งบันทึกเป็นแถวยอดรวม (PAYMENT) และแถวแยกส่วน (เช่น PRINCIPAL_PAYMENT)
      const history = await json<any[]>(await call('GET', `/debts/${id}/history`));
      const total = history.filter((h) => h.txnType === 'PAYMENT');
      expect(total).toHaveLength(1);
      expect(total[0].amount).toBe(500);
    } finally {
      await cleanupDebt(id);
    }
  });

  test('[TC-FT-15] จ่ายหนี้ด้วยจำนวน ≤ 0 หรือหนี้ที่ไม่มีอยู่ ถูกปฏิเสธ', async () => {
    const debt = await json<any>(await call('POST', '/debts', debtBody({ debtName: 'E2E bad pay' })));
    const id = debt.debtId ?? debt.id;
    try {
      expect((await call('POST', '/debts/pays', { debtId: id, paymentAmount: 0, paymentDate: today() })).status()).toBe(400);
      expect((await call('POST', '/debts/pays', { debtId: id, paymentAmount: -10, paymentDate: today() })).status()).toBe(400);
      const ghost = await call('POST', '/debts/pays', {
        debtId: '00000000-0000-0000-0000-000000000000',
        paymentAmount: 10,
        paymentDate: today(),
      });
      expect(ghost.status()).toBeGreaterThanOrEqual(400);
      expect(ghost.status()).toBeLessThan(500);
    } finally {
      await cleanupDebt(id);
    }
  });

  test('[TC-FT-16] ผู้ใช้อื่นอ่าน/แก้/ลบหนี้ของเราไม่ได้', async () => {
    const secret = process.env.E2E_JWT_SECRET;
    const other = process.env.E2E_USER_EMAIL;
    test.skip(!secret || !other, 'ตั้ง E2E_JWT_SECRET และ E2E_USER_EMAIL (ผู้ใช้อีกคน)');
    const debt = await json<any>(await call('POST', '/debts', debtBody({ debtName: 'E2E private' })));
    const id = debt.debtId ?? debt.id;
    try {
      const h = { Authorization: `Bearer ${mintAccessToken(other!, secret!)}` };
      const read = await ctx.get(`${API_URL}/api/debts/debtId/${id}`, { headers: h });
      expect(read.status(), 'อ่านหนี้ของคนอื่น').toBeGreaterThanOrEqual(400);
      const edit = await ctx.put(`${API_URL}/api/debts/${id}`, { headers: h, data: debtBody({ debtName: 'hacked' }) });
      expect(edit.status(), 'แก้หนี้ของคนอื่น').toBeGreaterThanOrEqual(400);
      const del = await ctx.delete(`${API_URL}/api/debts/${id}`, { headers: h });
      expect(del.status(), 'ลบหนี้ของคนอื่น').toBeGreaterThanOrEqual(400);
      const still = await json<any>(await call('GET', `/debts/debtId/${id}`));
      expect(still.debtName).toBe('E2E private');
    } finally {
      await cleanupDebt(id);
    }
  });

  test('[TC-FT-21] ลบหนี้ที่เคยจ่ายแล้ว ลบสำเร็จพร้อมประวัติ และการจับคู่ผู้รับเงินไม่ชี้หนี้ที่หาย', async () => {
    const food = (await json<any[]>(await call('GET', '/categories'))).find((c) => c.categoryName === 'Food');
    const debt = await json<any>(await call('POST', '/debts', debtBody({ debtName: 'E2E delete after pay' })));
    const id = debt.debtId ?? debt.id;
    let mappingId: number | undefined;
    try {
      const pay = await call('POST', '/debts/pays', { debtId: id, paymentAmount: 100, paymentDate: today() });
      expect(pay.status(), await pay.text()).toBeLessThan(300);
      expect((await json<any[]>(await call('GET', `/debts/${id}/history`))).length).toBeGreaterThan(0);

      // การจับคู่ผู้รับเงินที่ผูกทั้งหมวดหมู่และหนี้นี้
      const mapping = await json<any>(
        await call('POST', '/receiver-mappings', { receiverName: 'E2E payee', categoryId: food.categoryId, debtId: id }),
      );
      mappingId = mapping.id ?? mapping.mappingId;

      // เดิมได้ 500 (ผิด foreign key กับ debt_transactions) ตอนนี้ต้องลบสำเร็จ
      const del = await call('DELETE', `/debts/${id}`);
      expect(del.status(), await del.text()).toBeLessThan(300);

      const list = await json<any[]>(await call('GET', '/debts'));
      expect(list.find((d) => d.debt.debtId === id), 'หนี้ต้องหายจากรายการ').toBeUndefined();
      expect((await call('GET', `/debts/debtId/${id}`)).status(), 'หนี้ต้องไม่เหลือให้เปิดดู').toBeGreaterThanOrEqual(400);

      const mappings = await json<any[]>(await call('GET', '/receiver-mappings'));
      const kept = mappings.find((m) => m.receiverName === 'E2E payee');
      expect(kept, 'การจับคู่ที่มีหมวดหมู่ต้องยังอยู่').toBeTruthy();
      expect(kept.debtId ?? null, 'ต้องไม่ชี้ไปหาหนี้ที่ถูกลบ').toBeNull();
    } finally {
      if (mappingId !== undefined) await call('DELETE', `/receiver-mappings/${mappingId}`);
      await cleanupDebt(id);
    }
  });

  test('[TC-FT-22] ผู้ใช้อื่นอ่านธุรกรรมของหมวดหมู่เรา แก้/ลบธุรกรรมและหมวดหมู่เราไม่ได้', async () => {
    const secret = process.env.E2E_JWT_SECRET;
    const other = process.env.E2E_USER_EMAIL;
    test.skip(!secret || !other, 'ตั้ง E2E_JWT_SECRET และ E2E_USER_EMAIL (ผู้ใช้อีกคน)');
    const h = { Authorization: `Bearer ${mintAccessToken(other!, secret!)}` };

    const food = (await json<any[]>(await call('GET', '/categories'))).find((c) => c.categoryName === 'Food');
    const tx = await json<any>(
      await call('POST', '/transactions', {
        categoryId: food.categoryId,
        amount: 77,
        transactionDate: hoursAgo(1),
        description: 'e2e private tx',
        budgetId: food.budgetId,
      }),
    );
    const id = tx.transactionId ?? tx.id;
    try {
      const read = await ctx.get(`${API_URL}/api/transactions/category/${food.categoryId}?page=0&size=5`, { headers: h });
      const body = read.status() < 300 ? await read.json() : { content: [] };
      expect(body.content, 'ต้องไม่เห็นธุรกรรมของเรา').toEqual([]);
      expect((await ctx.delete(`${API_URL}/api/transactions/${id}`, { headers: h })).status()).toBeGreaterThanOrEqual(400);
      const edit = await ctx.put(`${API_URL}/api/categories/${food.categoryId}`, {
        headers: h,
        data: { categoryName: 'hacked', type: 'Expense' },
      });
      expect(edit.status()).toBeGreaterThanOrEqual(400);
      const cats = await json<any[]>(await call('GET', '/categories'));
      expect(cats.find((c) => c.categoryId === food.categoryId).categoryName).toBe('Food');
    } finally {
      await call('DELETE', `/transactions/${id}`);
    }
  });

  // ---------------------------------------------------------------- แผนชำระหนี้
  test('[TC-FT-17] จำลองแผนชำระหนี้จากหนี้ 2 รายการ ได้ผลลัพธ์ที่สมเหตุสมผล', async () => {
    const a = await json<any>(await call('POST', '/debts', debtBody({ debtName: 'E2E A', interestRate: 24, minPayment: 300, priority: 1 })));
    const b = await json<any>(await call('POST', '/debts', debtBody({ debtName: 'E2E B', interestRate: 6, minPayment: 300, priority: 2 })));
    const ids = [a.debtId ?? a.id, b.debtId ?? b.id];
    try {
      const min = await json<Record<string, number>>(await call('GET', '/repayment-plans/total-min-payment'));
      expect(Object.values(min).every((v) => Number(v) >= 0)).toBe(true);

      const plan = await call('POST', '/repayment-plans', { monthlyBudget: 3000, strategyId });
      expect(plan.status(), await plan.text()).toBeLessThan(300);

      const sim = await json<any>(await call('GET', '/repayment-plans'));
      expect(sim).toBeTruthy();
      const text = JSON.stringify(sim);
      expect(text.length).toBeGreaterThan(50);

      const prio = await call('GET', `/repayment-plans/priority-suggestion?strategyId=${strategyId}`);
      expect(prio.status(), await prio.text()).toBeLessThan(300);
    } finally {
      for (const id of ids) await cleanupDebt(id);
    }
  });

  // ---------------------------------------------------------------- อื่น ๆ
  test('[TC-FT-18] บันทึกและลบการจับคู่ผู้รับเงินกับหมวดหมู่', async () => {
    const food = (await json<any[]>(await call('GET', '/categories'))).find((c) => c.categoryName === 'Food');
    const saved = await json<any>(await call('POST', '/receiver-mappings', { receiverName: 'E2E Shop', categoryId: food.categoryId }));
    const id = saved.id ?? saved.mappingId;
    expect(id).toBeTruthy();
    const list = await json<any[]>(await call('GET', '/receiver-mappings'));
    expect(list.some((m) => m.receiverName === 'E2E Shop')).toBe(true);
    expect((await call('DELETE', `/receiver-mappings/${id}`)).status()).toBeLessThan(300);
    const after = await json<any[]>(await call('GET', '/receiver-mappings'));
    expect(after.some((m) => m.receiverName === 'E2E Shop')).toBe(false);
  });

  test('[TC-FT-19] การแจ้งเตือน: รายการ, จำนวนที่ยังไม่อ่าน และอุปกรณ์ที่ลงทะเบียน', async () => {
    expect((await call('GET', '/notifications/logs')).status()).toBe(200);
    const unread = await json<number>(await call('GET', '/notifications/logs/unread-count'));
    expect(unread).toBeGreaterThanOrEqual(0);
    expect((await call('GET', '/notifications/devices/my-devices')).status()).toBe(200);
  });

  test('[TC-FT-20] API ที่แก้ข้อมูลทั้งหมดปฏิเสธเมื่อไม่มี token', async () => {
    for (const [m, p] of [
      ['POST', '/categories'],
      ['POST', '/transactions'],
      ['POST', '/debts'],
      ['POST', '/debts/pays'],
      ['POST', '/budget/salary/1'],
      ['POST', '/repayment-plans'],
      ['POST', '/receiver-mappings'],
      ['POST', '/debt-types'],
    ]) {
      const res = await call(m, p, {}, false);
      expect(res.status(), `${m} ${p}`).toBe(401);
    }
  });
});
