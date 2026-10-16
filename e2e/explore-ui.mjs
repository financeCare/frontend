import { chromium } from '@playwright/test';
import { readFileSync } from 'node:fs';
const env = Object.fromEntries(readFileSync('.env.local-dev','utf-8').split(/\r?\n/).filter(l=>l.includes('=')&&!l.startsWith('#')).map(l=>[l.slice(0,l.indexOf('=')),l.slice(l.indexOf('=')+1)]));
const OUT = process.argv[2];
const steps = JSON.parse(process.argv[3] || '[]');
const b = await chromium.launch({ channel: 'chrome' });
const p = await b.newPage({ viewport: { width: 480, height: 900 }, locale: 'th-TH' });
p.on('pageerror', e => console.log('[pageerror]', e.message.slice(0,150)));
p.on('response', r => { if (r.url().startsWith('http://localhost:8080') && r.status() >= 400) console.log('[api]', r.status(), r.request().method(), r.url().replace('http://localhost:8080','')); });
await p.goto('http://localhost:5055/');
await p.waitForSelector('flt-glass-pane', { state: 'attached', timeout: 90000 });
await p.evaluate(() => document.querySelector('flt-semantics-placeholder')?.click());
await p.getByLabel('you@example.com').click();
await p.keyboard.type(env.E2E_EMAIL, { delay: 10 });
await p.keyboard.press('Tab');
await p.keyboard.type(env.E2E_PASSWORD, { delay: 10 });
await p.getByRole('button', { name: 'เข้าสู่ระบบ' }).last().click();
await p.waitForFunction(() => document.querySelector('flt-semantics-host')?.innerText.includes('ภาพรวมหนี้สิน'), null, { timeout: 60000 });
async function dump(tag) {
  await p.waitForTimeout(2500);
  const t = await p.evaluate(() => document.querySelector('flt-semantics-host')?.innerText ?? '');
  const els = await p.locator('flt-semantics[role=button], flt-semantics[role=textbox], input, textarea, flt-semantics[role=tab], flt-semantics[role=checkbox], flt-semantics[role=switch]').evaluateAll(es => es.map(e => `${e.tagName.toLowerCase()}[${e.getAttribute('role')||e.type}] "${(e.getAttribute('aria-label')||e.textContent||'').trim().replace(/\s+/g,' ').slice(0,50)}"`));
  console.log(`\n===== ${tag}\n${t}\n--- controls:\n${els.join('\n')}`);
  await p.screenshot({ path: `${OUT}/${tag.replace(/\W+/g,'_')}.png` });
}
await dump('home');
for (const s of steps) {
  if (s.type) { await p.locator(`input[aria-label*="${s.type}"], textarea[aria-label*="${s.type}"]`).first().click(); await p.keyboard.type(s.text, { delay: 10 }); }
  if (s.tabs) { for (const item of s.tabs) { if (item !== null) await p.keyboard.type(item, { delay: 10 }); await p.keyboard.press('Tab'); await p.waitForTimeout(150); } }
  if (s.focus) { await p.locator("input").first().click(); }
  if (s.nth !== undefined) { await p.locator('input, textarea').nth(s.nth).click(); await p.keyboard.type(s.text, { delay: 10 }); }
  if (s.click) await p.getByRole('button', { name: new RegExp(s.click) }).first().click();
  if (s.wait) await p.waitForTimeout(s.wait);
  if (s.back) await p.goBack();
  if (s.key) await p.keyboard.press(s.key);
  await dump(s.tag);
}
await b.close();
