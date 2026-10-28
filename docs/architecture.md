# KEEP (ReadRecall) — สถาปัตยกรรมและคำอธิบายโค้ด

> เอกสารนี้ไว้อ่านเตรียมนำเสนอ อธิบายว่าโค้ดแต่ละส่วนทำอะไร ทำไมเลือกแบบนี้ และ async ทำงานตรงไหน
> สเปกการทำงานของแต่ละหน้าดูได้ที่ [workflow.md](workflow.md)

## 1. ภาพรวม

| หัวข้อ | รายละเอียด |
|---|---|
| ปัญหา | อ่านแล้วจำไม่ได้ / จับใจความไม่เป็น เพราะอ่านแบบผ่านๆ ไม่ได้ทบทวน |
| วิธีแก้ | Active Recall: อ่านแบบจับเวลา → ปิดบทความ → เขียนสรุปจากความจำ → AI ตรวจว่าขาดประเด็นอะไร |
| ผู้ใช้ | นิสิต นักศึกษา และคนที่อยากฝึกอ่านจับใจความ (English / Chinese / Thai) |
| Main Workflow | สมัคร → ตั้งค่าเริ่มต้น → Home → เลือกหมวด/ค้นหัวข้อ → สุ่มบทความ → อ่าน + Timer (+ ฟังเสียง / พักไว้อ่านต่อ) → เขียนสรุป → AI ให้คะแนน + แนะนำแท็ก → บันทึก → กลับ Home → แก้ไข/ลบ |

## 2. Technology ที่ใช้และเหตุผล

| ส่วน | Technology | เหตุผลที่เลือก |
|---|---|---|
| แอป | Flutter + Dart (iOS ขั้นต่ำ 15.0 ตามที่ Firebase SDK กำหนด) | เขียนครั้งเดียวได้ทั้ง iOS/Android |
| หลายภาษา | `flutter_localizations` + ไฟล์ ARB (`flutter gen-l10n`) | ระบบทางการของ Flutter, ข้อความทุกภาษาอยู่ในไฟล์เดียวต่อภาษา |
| Login | Firebase Authentication (Email/Password) | ไม่ต้องเขียน backend เอง, จำสถานะล็อกอินให้อัตโนมัติ |
| ฐานข้อมูล | Cloud Firestore | NoSQL บน Cloud, มี realtime stream, คุมสิทธิ์ด้วย Security Rules |
| ข้อมูลในเครื่อง | SharedPreferences | ภาษา 3 ค่า, เวลาอ่าน, ธีม, ความเร็วเสียง, แหล่งข้อมูล, **เซสชันที่อ่านค้าง**, cache โปรไฟล์, คำทักทายของวัน |
| บทความ | Wikipedia API (`en` / `zh` / `th.wikipedia.org`) ผ่าน interface `ArticleSource` | ฟรี ไม่ต้องใช้ key, มีระบบหัวข้อ `articletopic:` และ search engine ในตัว |
| AI | Groq Cloud API + โมเดล `qwen/qwen3.8-27b` (ของ Alibaba) | ฟรี ตอบเร็ว (~0.5 วินาที) ใช้ตรวจสรุป + แนะนำแท็ก + คิดคำทักทายรายวัน |
| เสียงอ่าน | flutter_tts (เสียงที่ติดมากับเครื่อง) | ฟรี ทำงานในเครื่อง ไม่ใช้เน็ต |
| รูปโปรไฟล์ | ตัวละครสัตว์ 5 แบบ (asset) หรือ image_picker (คลังรูป/กล้อง) | ไม่ต้องใช้ Storage, เป็น Device Feature (Camera) |
| ลิงก์ค้นต่อ | url_launcher | เปิด Google/Wikipedia ต้นฉบับในเบราว์เซอร์ |
| ซ่อน API key | flutter_dotenv (`.env`) | key ไม่ติดไปกับโค้ดใน Git |

**External / Mobile features ที่ใช้จริง (ขั้นต่ำ 2):** REST API (Wikipedia), REST API (Groq), SharedPreferences, Camera/Gallery (image_picker), Device TTS (flutter_tts), External Package (url_launcher)

## 3. โครงสร้างโฟลเดอร์

```
lib/
├── main.dart                     เริ่มแอป: .env → Settings → Firebase → AppRestarter → MaterialApp(locale) → AuthGate
├── firebase_options.dart         สร้างโดย flutterfire configure
├── core/
│   ├── app_exception.dart        Exception กลาง มีข้อความพร้อมแสดง (แปลตามภาษาแอปแล้ว)
│   ├── app_restarter.dart        "รีสตาร์ตแอป" จากภายใน (ใช้ตอนเปลี่ยนภาษา)
│   ├── navigation.dart           routeObserver (ให้ Home รู้ว่าถูกกลับมาแสดง)
│   ├── motion.dart               ค่าการเคลื่อนไหว + การเปลี่ยนหน้าแบบเร็วต้น ช้าปลาย
│   ├── config.dart, theme.dart, validators.dart
├── l10n/
│   ├── arb/app_en.arb, app_zh.arb, app_th.arb   ข้อความทุกภาษา (app_en = แม่แบบ)
│   ├── gen/                      โค้ดที่ flutter gen-l10n สร้างให้ (AppLocalizations)
│   └── l10n.dart                 context.l10n (หน้าจอ) / tr (service, validator) / ชื่อแท็ก
├── models/
│   ├── article.dart              บทความ (+ readKey กันสุ่มซ้ำ, toJson/fromJson)
│   ├── article_tag.dart          หมวดยอดฮิต 5 หมวด = แท็ก (ไม่เกิน 3 ต่อบทความ)
│   ├── reading_topic.dart        หมวดที่เลือกก่อนสุ่ม: ทุกหมวด / ยอดฮิต / ค้นเอง
│   ├── content_language.dart     English / Chinese / Thai
│   ├── reading_session.dart      การอ่านที่ค้างอยู่
│   ├── user_profile.dart         โปรไฟล์ + ตัวละครสัตว์ 5 แบบ
│   ├── ai_evaluation.dart, study_log.dart
├── services/                     ชั้นที่คุยกับโลกภายนอก (หน้าจอไม่เรียก Firebase/HTTP ตรงๆ)
│   ├── sources/article_source.dart     interface แหล่งข้อมูล + รายชื่อที่ติดตั้ง
│   ├── sources/wikipedia_source.dart   แหล่งข้อมูล Wikipedia
│   ├── auth_service.dart, study_log_repository.dart, profile_service.dart
│   ├── session_service.dart, settings_service.dart
│   ├── slm_service.dart          Groq: ให้คะแนน + แท็ก / คำทักทาย
│   ├── greeting_service.dart     คำทักทายวันละครั้ง (cache รายวัน)
│   └── tts_service.dart          abstract TtsService + DeviceTtsService
├── screens/
│   ├── auth_screen.dart          1. Login / Register
│   ├── onboarding_screen.dart    (ครั้งแรกหลังสมัคร) ชื่อเล่น, รูปโปรไฟล์, ภาษา, เวลาอ่าน
│   ├── home_screen.dart          2. Home: ทักทาย, สถิติ, อ่านค้าง, ประวัติ (Read, Delete)
│   ├── reading_screen.dart       3. อ่าน + Timer + TTS + Reading Lamp
│   ├── summary_screen.dart       4. เขียนสรุป + AI + แท็ก (Create, Update)
│   └── profile_screen.dart       5. โปรไฟล์ / Settings / Logout
└── widgets/
    ├── animated_counter.dart     StatRevealCard (effect นับคะแนน), AnimatedCounter, EarnedBadge
    ├── avatar_widgets.dart       UserAvatar, AvatarPicker, pickProfilePhoto
    ├── start_session_sheet.dart  แผ่นเลือกหมวด/ค้นหัวข้อก่อนสุ่ม
    ├── motion_widgets.dart       EntranceFade, Pressable, SelectedScale, staggered()
    ├── reading_lamp.dart, score_badge.dart, ui_helpers.dart
assets/avatars/                   ภาพตัวละคร 5 แบบ (ตัดเป็นสี่เหลี่ยม หน้าสัตว์อยู่กลาง)
```

**แนวคิดการแบ่งชั้น:** `screens` → `services` → (Firebase / HTTP / SharedPreferences / native)
service แปลง error ทุกชนิดเป็น `AppException` ที่มีข้อความตามภาษาแอปแล้ว หน้าจอจึง `catch` แค่ชนิดเดียวแล้วโชว์ SnackBar

**State management:** `setState` + `StreamBuilder` (Firestore, Auth) + `ValueNotifier`/`ValueListenableBuilder` (ค่าที่หลายหน้าใช้ร่วม: ธีม ภาษา เซสชัน โปรไฟล์ คำทักทาย สถานะ TTS) ไม่ใช้ library เพิ่ม

## 4. Navigation

```
AppRestarter (เปลี่ยน Key = รีสตาร์ตแอป)
 └── MaterialApp(locale, navigatorObservers: [routeObserver])
      └── AuthGate (StreamBuilder ฟัง authStateChanges)
           ├── ไม่มี user → AuthScreen
           └── มี user    → HomeScreen
                ├── (ผู้ใช้ใหม่) push fullscreenDialog → OnboardingScreen (ปิดไม่ได้จนกว่าจะกดเริ่มใช้งาน)
                ├── push → ProfileScreen ── Logout: signOut + popUntil(isFirst)
                ├── (แผ่นเลือกหมวด) push → ReadingScreen.start ── pushReplacement → SummaryScreen.fromSession
                ├── แตะการ์ดอ่านค้าง → ReadingScreen.resume / SummaryScreen.fromSession
                └── push → SummaryScreen.edit
```

- **AuthGate:** พอ Firebase แจ้งว่ามี user ก็สลับเป็น Home เอง เปิดแอปใหม่ก็ยังล็อกอินอยู่
- **`pushReplacement` จากหน้าอ่านไปหน้าสรุป:** กดย้อนกลับไปดูบทความไม่ได้ ตรงกับหลัก Active Recall
- **RouteAware:** Home subscribe กับ `routeObserver` → `didPopNext()` ถูกเรียกเมื่อปิดหน้าที่ซ้อนอยู่แล้วกลับมา → เพิ่ม `_replay` → การ์ดสถิติได้ Key ใหม่ → effect นับคะแนนเล่นใหม่

## 5. ภาษา 3 ค่า + รีสตาร์ตแอป

| ค่า | มีผลกับ | ค่าเริ่มต้น |
|---|---|---|
| ภาษาของแอป | เมนู/ข้อความทั้งหมด (ARB), Feedback จาก AI, คำทักทาย, รูปแบบวันที่ | ENG |
| ภาษาที่สุ่มบทความ | subdomain ของ Wikipedia | ENG |
| ภาษาที่ TTS อ่าน | locale ของเสียง (`AUTO` = ตามภาษาของบทความ) | ENG |

- แสดงเป็นชื่อภาษาสากล English / Chinese / Thai (English ก่อน) ไม่มีธง
- Thai: ใช้คำไทย แต่คำที่คนไทยนิยมเขียนอังกฤษ (Login, AI, Timer, Feedback, Dark Mode) คงเป็นอังกฤษ / Chinese: จีนตัวย่อ คำทับศัพท์คงเป็นอังกฤษ — ทั้งในไฟล์ ARB และใน prompt ของ AI
- **เปลี่ยนภาษาใน Settings:** เลือกครบ 3 ค่า → กด "ยืนยันภาษา" → ถามรีสตาร์ต
  - "รีสตาร์ตเลย" → `saveLanguages(applyNow: true)` + `AppRestarter.restart()` (เปลี่ยน Key ชั้นบนสุด Flutter สร้างทุกหน้าใหม่ตั้งแต่ AuthGate) — iOS ไม่อนุญาตให้แอปปิดตัวเองแล้วเปิดใหม่ จึงรีสตาร์ตจากภายในแบบนี้
  - "ไว้ทีหลัง" → บันทึกลง SharedPreferences อย่างเดียว ค่าในหน่วยความจำไม่เปลี่ยน แอปใช้ภาษาเดิมจนเปิดใหม่ (ตอนนั้น `load()` อ่านค่าใหม่)
- **ข้อความในหน้าจอ** ใช้ `context.l10n.xxx` / **ใน service, validator** (ไม่มี context) ใช้ `tr.xxx` ซึ่ง `lookupAppLocalizations(ภาษาแอปปัจจุบัน)`
- หน้าตั้งค่าเริ่มต้นใช้ `Localizations.override` ให้ทั้งหน้าแสดงด้วยภาษาที่กำลังเลือกทันที

## 6. หมวด / ค้นหัวข้อ / แท็ก / ไม่สุ่มซ้ำ

- **ก่อนสุ่ม:** เลือก "สุ่มทุกหมวด" หรือหมวดยอดฮิต 5 หมวด (Technology, วิทยาศาสตร์, ประวัติศาสตร์, ชีวประวัติ, วัฒนธรรม) หรือพิมพ์ค้นหัวข้อเอง
  - ทุกหมวด: `generator=random`
  - หมวดยอดฮิต: `list=search` + `articletopic:biology|chemistry|...` + `srsort=random` (articletopic = หัวข้อที่ Wikipedia จัดให้ทุกบทความด้วยโมเดล ML ใช้ได้ทุกภาษา)
  - ค้นเอง: `list=search` + คำที่พิมพ์ + `srsort=relevance` แล้วสุ่มใน 50 เรื่องที่ตรงที่สุด (สุ่มจากทุกหน้าที่มีคำนั้นจะได้เรื่องที่แค่เอ่ยถึงผ่านๆ) รอบถัดไปเลื่อนไปชุดถัดไปด้วย `sroffset`
- **ไม่สุ่มซ้ำ:** บันทึกทุกอันเก็บ `source` + `language` + `pageId` → Home รวมเป็น `readKey` ส่งให้หน้าอ่าน → ตัดเรื่องที่อ่านแล้วออกจากผู้สมัคร
- **อ่านครบแล้ว:** `list=search` ส่ง `totalhits` มาด้วย ถ้าไล่ดูผลค้นหาครบทุกเรื่องแล้วแต่อ่านหมดแล้ว → `TopicExhaustedException` → กลับ Home พร้อมข้อความ "หมวด X ใน Wikipedia (ภาษา) อ่านครบหมดแล้ว"
- **แท็ก (ไม่เกิน 3):** หมวดที่เลือกตอนสุ่มเป็นแท็กแรก → AI แนะนำเพิ่มจาก 5 หมวด (ตอบใน JSON `tags`, แอปกรองเฉพาะ id ที่รู้จัก) → ผู้ใช้แตะเพิ่ม/ลบได้ เกิน 3 แจ้งเตือน → เก็บ `tags` ใน Firestore → แสดงบนการ์ดในหน้า Home
- **แหล่งข้อมูล:** แอปคุยกับแหล่งข้อมูลผ่าน `abstract class ArticleSource` เท่านั้น เพิ่มแหล่งใหม่ (หรือ plugin ในอนาคต) = เขียน class ที่ implements แล้วใส่ใน `ArticleSources.all` — Settings แสดงรายการแหล่ง + ช่อง "แหล่งข้อมูลเพิ่มเติม (เร็วๆ นี้)"

## 7. พัก / อ่านต่อ (Session Persistence + Lock)

- `ReadingSession` = บทความทั้งเรื่อง + หมวด + ภาษา + เวลาที่ตั้ง + เวลาที่อ่านไปแล้ว + ขั้นตอน + ร่างคำสรุป เก็บเป็น JSON ใน SharedPreferences key `activeSession_<uid>`
- **บันทึกเมื่อ:** ได้บทความใหม่, ทุก 10 วินาที, กดพัก, ออกจากหน้า, สลับแอป, พิมพ์ร่าง (debounce 500ms) / **ล้างเมื่อ:** บันทึกสรุปสำเร็จ หรือกด "ทิ้งบทความนี้"
- **ล็อก:** ปุ่มสุ่มฟัง `SessionService.current` มีเซสชัน → ปุ่มเทา + แม่กุญแจ, และ `await _sessionLoaded` ก่อนตัดสิน
- **เวลา:** `_baseElapsed` + `Stopwatch` = เวลาอ่านรวม, `Timer.periodic` แค่สั่งวาดจอใหม่ทุกวินาที

## 8. หน้าแรก: คำทักทาย + effect นับคะแนน

- **คำทักทาย:** "Hello / สวัสดี / 你好, ชื่อเล่น" + ประโยคชวนเรียนรู้ที่ AI คิดให้ **วันละครั้งต่อภาษา** (`GreetingService` เก็บ `{วันที่|ภาษา, ข้อความ}` ใน SharedPreferences) ระหว่างรอ/AI ล่มใช้ข้อความสำรองจาก ARB, เปลี่ยนด้วย `AnimatedSwitcher` (fade)
- **StatRevealCard:** `AnimationController` ตัวเดียว 1.6 วินาที แบ่งช่วงด้วย `Interval`
  - 0–30% การ์ดขยาย 85→100% + fade (easeOutBack) / 15–45% ป้ายพิมพ์ทีละตัวอักษร (ใช้ `characters` ไม่ตัดกลางสระไทย) / 20–100% ตัวเลขนับจาก 0 ด้วย easeOutExpo (เร็วตอนแรก ช้าลงตอนใกล้ถึง) / 60–100% คำอธิบาย fade
  - การ์ด 3 ใบเริ่มไล่กัน 0/150/300ms, เล่นใหม่ทุกครั้งที่กลับมาหน้านี้ (RouteAware) และเมื่อค่าเปลี่ยน
- หน้าสรุป: คะแนนวิ่งนับขึ้น + ป้าย "+X นาที" เด้งขึ้นหลังบันทึก

## 9. รูปโปรไฟล์ + ตั้งค่าเริ่มต้น

- **ตัวละคร 5 แบบ** (Cozy Cat, Night Owl, Forest Fox, Zen Capybara, Starlight Bunny) เป็นภาพในแอป `assets/avatars/` ตัดเป็นสี่เหลี่ยมจัตุรัสให้หน้าสัตว์อยู่กลาง แสดงเป็นวงกลม → Firestore เก็บแค่ `avatarPresetId`
- **หรือรูปของตัวเอง:** image_picker ย่อ 300×300 คุณภาพ 65 → base64 ใน `avatarBase64` (เลือกตัวละครทีหลัง = ลบ field นี้ทิ้ง ใช้ได้ทีละแบบ)
- **ตั้งค่าเริ่มต้น (ครั้งแรกหลังสมัคร):** `ProfileService.load()` อ่าน `users/{uid}` สำเร็จแต่ไม่มีเอกสาร → `needsSetup = true` → Home เปิด `OnboardingScreen` (ปิดไม่ได้) ให้เลือก ชื่อเล่น, รูปโปรไฟล์, ภาษาแอป, ภาษาบทความ, เวลาอ่าน → `completeSetup()` เขียนเอกสาร + บันทึกค่าในเครื่อง

## 10. เสียงอ่าน (TTS) และ Reading Lamp

- `TtsService` (abstract) → `DeviceTtsService` (flutter_tts) อ่านทีละย่อหน้าด้วย `awaitSpeakCompletion(true)`, หยุดกลางทางด้วยตัวนับ `_runId`, ไฮไลต์ + เลื่อนจอตาม, หยุดเองเมื่อพัก/ออกจากหน้า/สลับแอป, ความเร็ว 0.75x–1.5x
- ภาษาเสียง = Settings (ถ้า AUTO ใช้ภาษาของบทความ) ถ้าเครื่องไม่มีเสียงภาษานั้นแจ้ง error
- Reading Lamp: พื้น `#121413` + radial gradient (ทึบ 0.08–0.12) ตามนิ้วด้วย lerp `1 - e^(-k·dt)` ผ่าน `Ticker`, ไม่แตะ 3 วินาทีระหว่างจับเวลา → หายใจหลังการ์ด, วาดผ่าน `CustomPainter(repaint: ValueNotifier)`, หยุด Ticker เมื่อแสงนิ่ง, บทความอยู่บนการ์ด frosted

## 10.1 การเคลื่อนไหว (Motion)

- ค่าทั้งหมดอยู่ใน `core/motion.dart` (`AppMotion`) ใช้ token ของ Material 3 (`Durations`, `Easing`) ไม่ใส่ตัวเลขลอยๆ
- **เปลี่ยนหน้า:** `GentlePageTransitionsBuilder` ตั้งใน `ThemeData.pageTransitionsTheme` ทุก `MaterialPageRoute` ใช้เองอัตโนมัติ
  - fade + เลื่อนเข้ามาแค่ 6% ของจอ, หน้าเดิมถอยไป 3%
  - curve `Easing.emphasizedDecelerate` = **เร็วตอนต้น ช้าตอนปลาย** (ของมาถึงเร็วแล้วค่อยชะลอเข้าที่ สายตาไม่ต้องไล่นาน)
  - ตอนย้อนกลับ animation วิ่ง 1 → 0 จึงใช้ `reverseCurve: Easing.emphasizedAccelerate` ให้ยังเป็นเร็วต้น ช้าปลาย
  - ข้อแลกเปลี่ยน: ใช้แบบเดียวกันทุกระบบ บน iOS จึงไม่มีการปัดขอบจอซ้ายเพื่อย้อนกลับ (ใช้ปุ่มย้อนกลับแทน)
- **กล่อง/การ์ด (`widgets/motion_widgets.dart`)** ทั้งหมดเป็น implicit animation ไม่ต้องมี AnimationController/dispose
  - `EntranceFade`: fade + เลื่อนขึ้น 12 px ไล่กันใบละ 50 ms (`TweenAnimationBuilder` + `Interval` ทำหน้าที่หน่วงเวลา) ใช้กับการ์ดใน Home, ชิปหมวด, การ์ดผล AI, ส่วนต่างๆ ใน Settings / หน้าตั้งค่าครั้งแรก (`staggered([...])`)
  - `Pressable`: การ์ดยุบเหลือ 97% ตอนนิ้วแตะ (`Listener` ไม่แย่ง gesture จึงใช้ร่วมกับ InkWell/Dismissible ได้)
  - `SelectedScale`: ชิป/รูปโปรไฟล์ที่ถูกเลือกขยาย 5%
  - การ์ดในรายการมี Key คงที่ (`ValueKey(log.id)`) จึงเล่นแค่ตอนปรากฏครั้งแรก ไม่เล่นซ้ำทุกครั้งที่ Firestore อัปเดต
  - ขยับแค่ `Opacity` / `Transform` (ไม่เปลี่ยน layout) จึงลื่นและไม่หนักเครื่อง
- **Reduce Motion:** ถ้าผู้ใช้เปิด "ลดการเคลื่อนไหว" ในเครื่อง (`MediaQuery.disableAnimations`) effect ตกแต่งทั้งหมดปิด และเปลี่ยนหน้าเหลือแค่ fade

## 11. Cloud Firestore

### `study_logs` (1 เอกสาร = อ่านและสรุป 1 ครั้ง)

| Field | ชนิด | ความหมาย |
|---|---|---|
| (document ID) | String | สร้างในแอปด้วย `doc().id` (กันเอกสารซ้ำตอนกดซ้ำ) |
| `userId` | String | uid ของเจ้าของ (ใช้ใน Security Rules) |
| `articleTitle`, `articleUrl` | String | ชื่อ/ลิงก์บทความ |
| `originalContent` | String | เนื้อหาต้นฉบับ 3,000 ตัวอักษรแรกที่ AI ใช้เทียบ |
| `userSummary` | String | คำสรุป (≥ 50 ตัวอักษร) |
| `readingTimeMinutes` | Number | เวลาที่อ่านจริง (นาที, ปัดขึ้น) |
| `tags` | Array<String> | ไม่เกิน 3: id หมวดยอดฮิต หรือหัวข้อที่ค้นเอง (บันทึกเก่ามี `category` แทน แอปแปลงให้) |
| `language` | String | `en` / `zh` / `th` ของบทความ (บันทึกเก่าไม่มี = `th`) |
| `source`, `pageId` | String, Number | แหล่งข้อมูล + id บทความ ใช้กันสุ่มซ้ำ |
| `aiScore`, `aiFeedback` | Number/null, String/null | ผลประเมิน (null = ยังไม่ได้ประเมิน) |
| `createdAt` / `updatedAt` | Timestamp | เวลาเซิร์ฟเวอร์ |

### `users/{uid}`

| Field | ความหมาย |
|---|---|
| `nickname` | ชื่อเล่น 2–20 ตัวอักษร (sync ไป `updateDisplayName` ด้วย) |
| `avatarPresetId` | `cover_cat` / `cover_owl` / `cover_fox` / `cover_capybara` / `cover_bunny` |
| `avatarBase64` | รูปของผู้ใช้เอง (ถ้ามี) ~20–40 KB |
| `email`, `updatedAt` | แนบทุกครั้งที่บันทึก |

> **ทำไมไม่ใช้ Firebase Storage:** โปรเจกต์ใหม่ต้องใช้แผน Blaze (ผูกบัตร) ไม่ตรงงบ 0 บาท รูปที่ย่อแล้วเล็กพอเก็บใน Firestore (เอกสารละ ≤ 1 MB) และเก็บเป็น field เดียวจึงเขียนทับของเดิม ไม่มีไฟล์ค้าง

### CRUD

| | Method | เรียกจากหน้า |
|---|---|---|
| Create | `StudyLogRepository.newLogId()` + `create()` → `doc(id).set()` / `ProfileService.completeSetup()` | Summary / Onboarding |
| Read | `watchLogs()` → `where('userId', ==).snapshots()` / `users/{uid}.get()` | Home |
| Update | `update()` (คำสรุป แท็ก ผลประเมิน) / `set(merge: true)` | Summary / Profile |
| Delete | `delete()` / ลบรูปด้วย `FieldValue.delete()` | Home / Profile |

### Security Rules (`firestore.rules`)

```
match /users/{uid} {
  allow read: if request.auth != null && request.auth.uid == uid;
  allow write: if request.auth != null && request.auth.uid == uid
               && validProfile(request.resource.data);   // field ที่อนุญาต + ความยาว + ขนาดรูป < 700 KB
}
match /study_logs/{logId} {
  allow read, delete: if request.auth != null && resource.data.userId == request.auth.uid;
  allow create: if request.auth != null && request.resource.data.userId == request.auth.uid;
  allow update: if request.auth != null && resource.data.userId == request.auth.uid
                && request.resource.data.userId == resource.data.userId;
}
```

### คำถามที่อาจโดนถาม
- **ทำไมเรียงในแอป ไม่ใช้ `orderBy`?** `where` + `orderBy` คนละ field ต้องสร้าง Composite Index ข้อมูลต่อคนไม่เยอะ เรียงในแอปเร็วพอ
- **`serverTimestamp()`** ใช้เวลาเซิร์ฟเวอร์ ตรงกันทุกเครื่อง ระหว่างรอยืนยันเป็น null ชั่วคราว จึงใช้ `DateTime.now()` แทน
- **ทำไมกดซ้ำไม่ได้เอกสารซ้ำ?** จอง ID ด้วย `doc().id` ไว้ก่อน แล้ว `set()` ซ้ำก็ทับ ID เดิม
- **`set(merge: true)` ต่างจาก `update()`?** `update()` ต้องมีเอกสารอยู่แล้ว ส่วน `set(merge:)` สร้างให้ถ้ายังไม่มี และแก้เฉพาะ field ที่ส่ง
- **`validProfile()`** ตรวจซ้ำที่เซิร์ฟเวอร์ เพราะไม่ควรเชื่อการตรวจฝั่งแอปอย่างเดียว

## 12. Asynchronous Operations

| จุด | สิ่งที่รอ | จัดการระหว่างรอ / เมื่อผิดพลาด |
|---|---|---|
| `main()` | `.env`, `SharedPreferences`, date format 3 ภาษา, `Firebase.initializeApp` | ทำก่อน `runApp`, Firebase พัง → หน้า error |
| Login/Register | Firebase Auth | ปุ่ม disable + spinner, error code → ข้อความตามภาษาแอป |
| Home | Firestore stream, โหลดเซสชัน, โหลดโปรไฟล์, คำทักทายจาก AI | StreamBuilder / ValueListenableBuilder, คำทักทายใช้ข้อความสำรองก่อน |
| Onboarding | `pickImage` → `completeSetup` (Firestore + displayName) → SharedPreferences | spinner, ปิดหน้าไม่ได้จนบันทึกสำเร็จ |
| Reading | Wikipedia 2+ request, `SessionService.save`, TTS `speak` | "กำลังสุ่มบทความ...", error → ลองใหม่, อ่านครบ → กลับ Home |
| Summary | Groq → Firestore → ล้างเซสชัน | ปุ่มบอกสถานะ, AI พลาด → ลองใหม่ / บันทึกไว้ก่อน |
| Profile | `usePreset` / `usePhoto` / `updateNickname`, `saveLanguages`, `signOut` | SnackBar / error ใต้ช่องกรอก |

**กฎที่ใช้ทุกที่:** `try / on AppException catch` ครอบทุก `await` ภายนอก, `.timeout(...)` ทุก request, เช็ก `mounted` หลัง `await`, `dispose()` ยกเลิก Timer / Ticker / Controller / TTS
**Future vs Stream:** Future = ผลครั้งเดียว (Login, ดึงบทความ, บันทึก) / Stream = ผลต่อเนื่อง (สถานะล็อกอิน, รายการใน Firestore)

## 13. AI (Groq)

- **Groq** = ผู้ให้บริการรันโมเดลบน Cloud ด้วยชิป LPU (สะกดด้วย q ไม่ใช่ Grok ของ xAI) ไม่ได้สร้างโมเดลเอง
- แอปเลือกโมเดลเองด้วย `"model": "qwen/qwen3.8-27b"` (`GROQ_MODEL`), response มี `model` ยืนยัน แอปแสดงใต้คะแนน
- **ให้คะแนน:** `response_format: json_object` → `{"aiScore", "aiFeedback", "tags"}`, temperature 0.2, feedback เป็นภาษาแอป (กฎคำทับศัพท์ใน prompt)
- **คำทักทาย:** ข้อความธรรมดา 1 บรรทัด, temperature 0.9 (หลากหลาย), ใส่วันที่ใน prompt ให้แต่ละวันไม่ซ้ำ
- แยก error 401/404/429, parse แบบระวังพลาด (ตัด `<think>`, เอาเฉพาะ `{...}`), Free Tier 1,000 request/วัน, 8,000 tokens/นาที

## 14. ความปลอดภัย

- Groq key อยู่ใน `.env` (ใน `.gitignore`) แต่ `flutter_dotenv` ฝังไปกับแอป แกะแอปแล้วอ่านได้ ทางที่ปลอดภัยจริงคือเรียกผ่าน backend ที่ถือ key (เกินขอบเขต MVP)
- `firebase_options.dart` ไม่ใช่ความลับ ความปลอดภัยของข้อมูลมาจาก Security Rules
- iOS ต้องประกาศ `NSPhotoLibraryUsageDescription`, `NSCameraUsageDescription` ใน `Info.plist`

## 15. วิธีรันและทดสอบ

```bash
flutter pub get
open -a Simulator
flutter run
```

- แก้ข้อความ/เพิ่มภาษา: แก้ไฟล์ใน `lib/l10n/arb/` แล้ว `flutter gen-l10n`
- deploy Security Rules: `firebase deploy --only firestore:rules`
- unit/widget test (ไม่ต้องใช้เน็ต): `flutter test test/widget_test.dart test/features_test.dart`
- API จริง: `flutter test test/live` — ตัวเลือก `LANG_CODE=en|zh|th`, `TOPIC=science` หรือ `TOPIC=coffee`, `MODEL=...` (กดถี่ๆ Wikipedia จะตอบ 429)

## 16. Checklist ของวิชา

| ข้อกำหนด | อยู่ที่ |
|---|---|
| ≥ 4 Screens | 5 หน้าหลัก + หน้าตั้งค่าเริ่มต้น |
| Navigation | AuthGate, push, pushReplacement, popUntil, PopScope, fullscreenDialog, bottom sheet, RouteObserver |
| Form + Validation | Auth, Summary (≥ 50), ชื่อเล่น (2–20) — `core/validators.dart` (ข้อความตามภาษาแอป) |
| Authentication | Register / Login / Logout + updateDisplayName |
| Firebase Database | Firestore `study_logs`, `users` |
| CRUD | ตารางในข้อ 11 |
| Async | ตารางในข้อ 12 |
| External ≥ 2 | Wikipedia API, Groq API, SharedPreferences, Camera/Gallery, Device TTS, url_launcher |
| Main Workflow | สมัคร → ตั้งค่า → เลือกหมวด → สุ่ม → อ่าน → สรุป → AI → บันทึก → ดู/แก้/ลบ |
