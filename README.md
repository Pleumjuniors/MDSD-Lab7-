# Campus Marketplace Week 7 — Web

โปรเจกต์รองรับเว็บแล้ว โดยอ่านภาพด้วย XFile.readAsBytes และแสดงด้วย Image.memory
ไม่มี dart:io/File ในโค้ดแอป

## รันใน Chrome

```powershell
flutter pub get
flutter run -d chrome --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

แทน YOUR_API_KEY ด้วยคีย์ของคุณ เฉพาะคำสั่งรัน
รันจากโฟลเดอร์ที่มี pubspec.yaml ไม่ต้องเปิด Android emulator หรือบิลด์ Gradle

ถ้า Flutter เปิด Chrome ไม่ได้ ใช้:

```powershell
flutter run -d web-server --web-port=8080 --dart-define=GEMINI_API_KEY=YOUR_API_KEY
```

จากนั้นเปิด http://localhost:8080 ใน Chrome หรือ Edge

## ทดสอบ

```powershell
flutter analyze
flutter test
flutter build web
```

ผลตรวจ: analyze ผ่าน, เทส 8 กรณีผ่าน และ build web ผ่าน

## ฟีเจอร์

- รายการสินค้าและตะกร้า ใช้ Fake Store API ก่อน และ DummyJSON เป็น API สำรองพร้อมแสดงแหล่งข้อมูล
- ทดสอบ Gemini Text ผ่านปุ่มหน้าหลัก แสดง SnackBar และ GEMINI RESPONSE ใน Terminal
- เลือกรูปสินค้า JPEG/PNG/WebP ขนาดไม่เกิน 10 MB จากเครื่อง
- Gemini Vision ส่งภาพ Base64 พร้อม Prompt และบังคับ JSON schema
- ฟอร์ม title/category/description ให้แก้ไขก่อนยืนยัน
- หลังยืนยันแสดงร่างที่บันทึกใน State พร้อมล้างรูปและฟอร์ม
- IndexedStack เก็บสถานะแท็บเมื่อสลับหน้า
- จัดการ timeout 20 วินาที, โควตา, Safety block และคำตอบว่าง/ผิดรูปแบบ

ใช้ gemini-3.5-flash-lite เป็นค่าเริ่มต้น เปลี่ยนได้ด้วย --dart-define=GEMINI_MODEL=ชื่อโมเดล

Google AI Studio และภาพหน้าจอผู้ใช้ทำเอง
ผลจากบริการจริงขึ้นกับคีย์ โควตา เครือข่าย และความพร้อมของ Gemini API
