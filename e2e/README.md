# E2E tests (Playwright)

ทดสอบเว็บที่ deploy จริง (`https://c3b22.github.io/financecare-web/`) และ backend บน Render
ใช้ Chrome ที่ติดตั้งในเครื่อง ไม่ต้องดาวน์โหลด browser เพิ่ม

```bash
cd frontend/e2e
npm install
npm test                # รันทั้งหมด
npm run test:headed     # เห็นหน้าต่าง browser
npm run report          # เปิดรายงาน HTML
```

## กลุ่มเทสต์

| ไฟล์ | ทดสอบอะไร | ต้องตั้งค่าเพิ่ม |
|---|---|---|
| `tests/ui.spec.ts` | หน้า login บน web, ปุ่ม Google, ล็อกอินผิด, Demo Bypass, มือถือ | ไม่ต้อง |
| `tests/api.spec.ts` | backend: CORS, 401, ค่าที่ไม่ถูกต้องต้องไม่ได้ 500 | ไม่ต้อง |
| `tests/auth-api.spec.ts` | ผู้ใช้ Google (ไม่มีรหัสผ่าน) เรียก API ที่ต้องมี token ได้ | `E2E_JWT_SECRET`, `E2E_USER_EMAIL` |

กลุ่มที่สามจะ skip ถ้าไม่ตั้ง env (ห้าม commit ค่า secret):

```bash
E2E_JWT_SECRET='<JWT_SECRET จาก Render>' E2E_USER_EMAIL='you@gmail.com' npm test
```

## ไฟล์ Excel สำหรับทดสอบเอง

[FinanceCare_TestCases.xlsx](FinanceCare_TestCases.xlsx) รวม test case ทั้งหมด (อัตโนมัติ + ทดสอบเอง + unit test backend)
ชื่อเทสต์ใน Playwright มีรหัส `TC-…` ตรงกับคอลัมน์ รหัส ในไฟล์ ชีต สรุป นับความคืบหน้าให้อัตโนมัติ

## ทดสอบบัญชีอีเมล (production)

`tests/account.spec.ts` ใช้บัญชีที่ยืนยันอีเมลแล้ว ตั้งค่าโดยคัดลอก `.env.example` เป็น `.env` แล้วกรอก
`E2E_EMAIL` และ `E2E_PASSWORD` (`.env` ถูก .gitignore ไว้ ห้าม commit) จากนั้น `npm test`
ถ้าไม่ตั้ง รหัสผ่าน เทสต์กลุ่มนี้จะ skip (ยกเว้น TC-EM-05 ที่ใช้แค่อีเมล)

## ทดสอบบน localhost (ไม่แตะ production)

ต้องรันทั้งหน้าเว็บและ backend ในเครื่อง ไม่งั้นรหัสผ่านยังถูกส่งไป production

```bash
# 1) Postgres + Redis แยกพอร์ต ไม่ชนโปรเจกต์อื่น
docker run -d --name fc-e2e-postgres -e POSTGRES_USER=root -e POSTGRES_PASSWORD=password123 -e POSTGRES_DB=financeCare_DB -p 127.0.0.1:5436:5432 postgres:16-alpine
docker run -d --name fc-e2e-redis -p 127.0.0.1:6391:6379 redis:7-alpine

# 2) backend (ใน repo financecare-backend-deploy) ตั้ง env ก่อน bootRun
#    JWT_SECRET=<base64 สุ่ม> SPRING_DATASOURCE_URL=jdbc:postgresql://localhost:5436/financeCare_DB DB_PASSWORD=password123
#    SPRING_DATA_REDIS_HOST=localhost SPRING_DATA_REDIS_PORT=6391 APP_MAIL_ENABLED=false MINIO_ACCESS_KEY=admin MINIO_SECRET_KEY=password123
./gradlew bootRun

# 3) หน้าเว็บที่ชี้ backend ในเครื่อง แล้วเสิร์ฟที่พอร์ต 5055
cd frontend && flutter build web --release --base-href / --dart-define=API_BASE_URL=http://localhost:8080 --output build/web-local
python -m http.server 5055 --directory build/web-local

# 4) สร้างบัญชีทดสอบ: POST /api/auth/register → POST /api/auth/send-otp/{email}
#    อ่านรหัสจาก redis (docker exec fc-e2e-redis redis-cli GET otp:{email}) → POST /api/auth/verify-otp
#    ใส่ E2E_BASE_URL, E2E_API_URL, E2E_EMAIL, E2E_PASSWORD ใน .env.local-dev แล้วรัน
E2E_ENV_FILE=.env.local-dev npx playwright test --grep-invert "TC-GG"
```

`TC-GG-02` (กดปุ่ม Google) ต้องข้ามบน localhost เพราะ origin นี้ยังไม่ได้ลงทะเบียนกับ Google
กลุ่ม `TC-AUTH` ทำบน localhost ได้โดยใส่ผู้ใช้ที่ `password_hash` เป็น NULL ใน DB
แล้วตั้ง `E2E_JWT_SECRET` เป็น JWT_SECRET ของ backend ในเครื่อง

## ทดสอบ feature หลังล็อกอิน

| ไฟล์ | ทดสอบอะไร | หมายเหตุ |
|---|---|---|
| `tests/features.spec.ts` | หมวดหมู่ งบ ธุรกรรม หนี้ จ่ายหนี้ แผนชำระ การจับคู่ผู้รับเงิน การแจ้งเตือน การแยกข้อมูลข้ามผู้ใช้ | **สร้าง/แก้/ลบข้อมูลจริง** ต้องตั้ง `E2E_ALLOW_WRITES=1` รันกับ stack ในเครื่องเท่านั้น |
| `tests/ui-features.spec.ts` | เปิดเมนูลัดบนหน้า Home (สร้างหนี้ / กลยุทธ์ชำระ / ดูแผน / ชำระหนี้) | ไม่แก้ข้อมูล |
| `tests/ui-flows.spec.ts` | ใช้งานผ่านหน้าจอจริง (เคส M-F01…M-F12): เพิ่ม/แก้รายการ ตั้งงบ สร้าง/แก้/ลบ/จ่ายหนี้ กลยุทธ์ ตั้งค่า ออกจากระบบ | **แก้ข้อมูลจริง** ต้องตั้ง `E2E_ALLOW_WRITES=1` รันกับ stack ในเครื่องเท่านั้น |

เทสต์ทั้งหมดรันทีละเทสต์ (`workers: 1`) เพราะใช้บัญชีและข้อมูลชุดเดียวกัน ถ้าฐานข้อมูลทดสอบมีหนี้ค้าง (ลบไม่ได้เพราะมีประวัติการจ่าย)
ล้างได้ด้วย SQL กับฐานข้อมูล **ทดสอบในเครื่อง** เท่านั้น ห้ามรันกับ production

ข้อควรรู้เรื่อง Flutter web: ข้อความธรรมดาและรายการใน popup/dialog บางส่วนไม่ปรากฏใน accessibility tree
จึงต้องเลื่อนหน้าด้วยล้อเมาส์และคลิกตามพิกัด (ดู `scrollToLocator`, `fillBelowLabel`, `tapText` ใน `tests/helpers.ts`)

ฐานข้อมูลใหม่ยังไม่มีประเภทหนี้/ประเภทการชำระ/กลยุทธ์ เทสต์จะสร้างให้เมื่อยังไม่มี
กลุ่มที่ตรวจการแยกข้อมูลข้ามผู้ใช้ (`TC-FT-16`, `TC-FT-22`) ต้องตั้ง `E2E_JWT_SECRET` และ `E2E_USER_EMAIL` (ผู้ใช้อีกคน)

ยังไม่มีเทสต์อัตโนมัติสำหรับ: อัปโหลดสลิป (ต้องใช้ OCR/MinIO), หางาน (ต้องใช้ Jooble API key),
การกรอกฟอร์มผ่านหน้าจอ และการตั้งค่าผู้ใช้ ดูเป็นเคส "ทดสอบเอง" ใน Excel

## env อื่น ๆ

- `E2E_BASE_URL` เว็บที่จะทดสอบ (default: GitHub Pages)
- `E2E_API_URL` backend ที่จะทดสอบ (default: Render)

## ข้อจำกัด

- ล็อกอิน Google จริงทดสอบอัตโนมัติไม่ได้ (Google บล็อกบอตและต้องใช้บัญชีจริง)
  เทสต์ตรวจแค่ว่ากดปุ่มแล้ว Google เปิดหน้าเลือกบัญชีโดยไม่ขึ้น `origin_mismatch`
- ถ้าทดสอบกับ `localhost` ต้องเพิ่ม origin นั้นใน Google Cloud Console ก่อน
  ไม่งั้นเทสต์ปุ่ม Google จะตก (ซึ่งถูกต้อง)
- Render แพลนฟรี sleep ได้ request แรกอาจช้า 50 วินาที จึงตั้ง timeout ไว้สูง
- Flutter web ต้องเปิด semantics ก่อนถึงจะเลือก element ได้ (ดู `openApp` ใน `tests/helpers.ts`)
  และช่องกรอกต้องพิมพ์ผ่านคีย์บอร์ดจริง ใช้ `fill()` ไม่ได้
