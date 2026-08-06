# 📱 FinanceCare Frontend (Mobile Application)

แอปพลิเคชันมือถือ **FinanceCare** พัฒนาด้วย **Flutter & Dart** สำหรับการจัดการการเงินส่วนบุคคล วางแผนปลดหนี้อัจฉริยะ และบันทึกธุรกรรมรายวัน ด้วยการออกแบบ UI ที่เป็นมิตร ใช้งานง่าย และเน้นความปลอดภัยสูงสุด

---

## 🛠️ Stack เทคโนโลยีที่ใช้งาน (Technology Stack)

* **Language & SDK:** Dart 3.x & Flutter 3.x
* **UI/UX Design:** Material 3, Google Fonts (Kanit), Smooth Animations, `fl_chart` (การแสดงผลกราฟการเงิน)
* **Authentication:** Firebase Auth (Email/Password, Google Sign-In) & LINE SDK (LINE Login)
* **State & Local Storage:** `shared_preferences`, `flutter_secure_storage` (เก็บข้อมูลความลับ/Token ปลอดภัย)
* **Push Notifications:** Firebase Cloud Messaging (FCM) & `flutter_local_notifications`
* **Device Services:** `image_picker` (สำหรับสแกนใบเสร็จ), `geolocator` & `geocoding` (สำหรับตำแหน่งพิกัด)

---

## 🚀 ฟีเจอร์เด่นบนแอปมือถือ (Key Features)

* **📊 Dashboard & Financial Visualization**
  * สรุปภาพรวมสถานะการเงิน รายรับ รายจ่าย และยอดหนี้คงเหลือ
  * แสดงข้อมูลสถิติในรูปแบบแผนภูมิวงกลมและกราฟเส้นสุดพรีเมียมด้วย `fl_chart`
* **🔑 Multi-Platform Authentication**
  * เข้าสู่ระบบได้อย่างรวดเร็วและปลอดภัยผ่าน:
    * LINE Login (`flutter_line_sdk`)
    * Google Sign-In
    * อีเมลและรหัสผ่านแบบปกติ
* **💰 Budget & Expense Tracker**
  * บันทึกรายการรายรับ-รายจ่ายประจำวัน พร้อมแยกตามหมวดหมู่
  * กำหนดและติดตามงบประมาณ (Budget) เพื่อป้องกันการใช้จ่ายเกินตัว
* **🛡️ Debt Management & Repayment Simulator**
  * ระบบบันทึกรายชื่อหนี้สิน ดอกเบี้ย และกำหนดชำระ
  * เครื่องจำลองการคำนวณแผนการชำระหนี้ (Simulator) ด้วย 2 กลยุทธ์หลัก:
    * **Debt Snowball**: จ่ายหนี้ก้อนเล็กสุดก่อนเพื่อสร้างแรงบันดาลใจ
    * **Debt Avalanche**: จ่ายหนี้ที่มีดอกเบี้ยสูงสุดก่อนเพื่อประหยัดดอกเบี้ยสะสม
* **📑 Slip OCR Scan (Receipt Processing)**
  * อัปโหลดหรือถ่ายรูปใบเสร็จเพื่อส่งให้ OCR Python Service ประมวลผลและดึงข้อมูลรายจ่ายลงแอปโดยอัตโนมัติ
* **🔔 Notification & Slip Auto-Detection**
  * ระบบแจ้งเตือนแจ้งเตือนกำหนดชำระเงิน หรือข่าวสารการเงิน
  * พิเศษสำหรับ Android: ระบบตรวจจับรูปภาพสลิปที่เพิ่งบันทึกอัตโนมัติ (`SlipDetectionService`) เพื่อนำไปประมวลผลต่อได้ทันที

---

## 📂 โครงสร้างโฟลเดอร์โครงการ (Project Directory Structure)

การจัดวางโฟลเดอร์เน้นระบบ Modularization และการแบ่งความรับผิดชอบของโค้ดอย่างชัดเจน:

```text
lib/
├── core/                  # แกนหลักของแอปพลิเคชันที่ใช้ร่วมกันทุกหน้า
│   ├── config/            # ไฟล์การตั้งค่า เช่น API URL, Environment variables
│   ├── services/          # บริการกลางระดับแอป
│   └── utils/             # เครื่องมือช่วยเหลือทั่วไป เช่น NavigatorKey
├── features/              # ฟีเจอร์หลักแบ่งแยกตาม Business Logic
│   ├── auth/              # ระบบยืนยันตัวตน (Login, Register, Welcome)
│   ├── budget/            # บันทึกรายรับ-รายจ่าย และงบประมาณ
│   ├── dashboard/         # หน้าหลักสรุปผลและรายงานกราฟ
│   ├── debt/              # ระบบจัดการหนี้และประวัติการชำระ
│   ├── job/               # หน้าแนะนำอาชีพเสริม/คำแนะนำเพื่อสร้างรายได้เพิ่ม
│   ├── notification/      # ระบบ Push Notification & ตรวจจับสลิป
│   ├── ocr/               # หน้าสแกนใบเสร็จรับเงิน
│   ├── settings/          # ตั้งค่าข้อมูลส่วนตัวและการทำงานของแอป
│   └── simulator/         # เครื่องมือคำนวณเปรียบเทียบกลยุทธ์การปลดหนี้
└── shared/                # วิดเจ็ต ดีไซน์ และ UI Components ที่แชร์ใช้ข้าม Feature
```

---

## ⚙️ การเตรียมตัวและตั้งค่าระบบก่อนรัน (Prerequisites & Configuration)

### 1. ไฟล์การตั้งค่า API Base URL (`lib/core/config/config.dart`)
แอปพลิเคชันมีระบบตรวจหา Base URL อัตโนมัติ เพื่อรองรับการทำงานในแต่ละ Emulator/Device:
* **Android Emulator:** จะเชื่อมต่อผ่าน `http://10.0.2.2:8080` (หรือผ่าน Nginx `http://10.0.2.2`)
* **iOS Simulator / Web:** จะเชื่อมต่อผ่าน `http://localhost:8080`
* **Physical Device (เครื่องจริง):** ให้แก้ baseUrl ไปที่ IP เครื่องคอมพิวเตอร์ของคุณบนวง Wi-Fi เดียวกัน เช่น `http://192.168.1.51:8080`
* **Production/Staging:** เปิดใช้งาน URL ของ SIT Server:
  ```dart
  final String baseUrl = 'https://bscit.sit.kmutt.ac.th/capstone25/cp25ms2';
  ```

### 2. ตั้งค่าบริการ Firebase
เนื่องจากโปรเจกต์นี้ใช้งาน Firebase Auth และ FCM คุณจำเป็นต้องนำไฟล์ config จาก Firebase Console มาใส่ในโฟลเดอร์ดังนี้:
* **Android:** นำไฟล์ `google-services.json` ไปวางไว้ที่ `android/app/`
* **iOS:** นำไฟล์ `GoogleService-Info.plist` ไปวางไว้ที่ `ios/Runner/`
* **Dart/Web Config:** ตรวจสอบและอัปเดตไฟล์ `lib/firebase_options.dart` หากต้องการเปลี่ยน Project

### 3. ตั้งค่า LINE SDK
* LINE Login จะทำงานผ่าน ID ช่องทางที่ระบุไว้ใน `lib/main.dart`:
  ```dart
  await LineSDK.instance.setup('1111111111'); // Channel ID ของ LINE Developers
  ```
* ตรวจสอบว่าแอปของคุณได้ตั้งค่า Redirect URI และ Schema ในฝั่ง Native แล้ว (`android/app/build.gradle` และ `ios/Runner/Info.plist`)

---

## 📦 ขั้นตอนการติดตั้งและเริ่มต้นใช้งาน (Installation & Setup)

1. **ดาวน์โหลด Dependencies ของ Flutter:**
   ```bash
   flutter pub get
   ```

2. **เชื่อมต่ออุปกรณ์ทดสอบ (Emulator/Device):**
   * ตรวจสอบความพร้อมของอุปกรณ์:
     ```bash
     flutter devices
     ```

3. **สั่งรันแอปพลิเคชัน:**
   * รันในโหมด Debug ทั่วไป:
     ```bash
     flutter run
     ```
   * หากต้องการรันบนแพลตฟอร์มเฉพาะ เช่น Web หรือระบุอุปกรณ์:
     ```bash
     flutter run -d chrome
     flutter run -d <device_id>
     ```

---
