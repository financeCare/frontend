import { existsSync, readFileSync } from 'node:fs';
import { defineConfig } from '@playwright/test';

// โหลดไฟล์ env (ค่าเริ่มต้น .env ระบุไฟล์อื่นด้วย E2E_ENV_FILE) โดยไม่ต้องใช้ package เพิ่ม
// ค่าที่ตั้งไว้ใน environment จริงมีสิทธิ์เหนือกว่า
const envFile = process.env.E2E_ENV_FILE ?? '.env';
if (existsSync(envFile)) {
  for (const line of readFileSync(envFile, 'utf-8').split(/\r?\n/)) {
    if (line.trim().startsWith('#')) continue;
    const m = line.match(/^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*?)\s*$/);
    if (m && process.env[m[1]] === undefined && m[2] !== '') {
      // ตัดเครื่องหมายคำพูดครอบค่า ถ้ามี
      process.env[m[1]] = m[2].replace(/^(['"])(.*)\1$/, '$2');
    }
  }
}

export default defineConfig({
  testDir: './tests',
  // Render แพลนฟรี sleep ได้ request แรกอาจช้า 50 วินาที+ และ Flutter web โหลดนาน
  timeout: 120_000,
  expect: { timeout: 30_000 },
  retries: 1,
  // เทสต์หลายกลุ่มสร้าง/ลบข้อมูลของบัญชีเดียวกันและเทียบยอดรวมบนหน้าจอ จึงต้องรันทีละเทสต์
  workers: 1,
  reporter: [['list'], ['html', { open: 'never' }]],
  use: {
    // ต้องลงท้ายด้วย / ไม่งั้น path สุดท้ายจะถูกตัดทิ้งตอนต่อ URL แบบ relative
    baseURL: (process.env.E2E_BASE_URL ?? 'https://c3b22.github.io/financecare-web/').replace(
      /\/?$/,
      '/',
    ),
    // ใช้ Chrome ที่ติดตั้งในเครื่อง ไม่ต้องดาวน์โหลด browser ของ Playwright
    channel: 'chrome',
    locale: 'th-TH',
    trace: 'retain-on-failure',
    screenshot: 'only-on-failure',
  },
});
