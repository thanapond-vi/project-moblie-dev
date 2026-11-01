# KEEP — สคริปต์ถาม-ตอบสำหรับการนำเสนอ

> ใช้คู่กับสไลด์นำเสนอ และ [architecture.md](architecture.md) · [workflow.md](workflow.md)
> ตัวเลขบรรทัดอ้างอิงตามโค้ดปัจจุบัน ถ้ามีการแก้ไฟล์ให้เช็กอีกครั้งก่อนนำเสนอ

## 1. Tech stack และเหตุผล

**ถาม: ใช้เทคโนโลยีอะไรบ้าง ทำไมเลือกแบบนี้**

| ส่วน | เทคโนโลยี | เหตุผล |
|---|---|---|
| แอป | Flutter + Dart (`environment sdk ^3.12.2`) | เขียนครั้งเดียวได้ทั้ง iOS และ Android |
| บัญชี | Firebase Authentication (Email/Password) | ไม่ต้องเขียน backend ระบบล็อกอินเอง และจำสถานะล็อกอินให้ |
| ฐานข้อมูล | Cloud Firestore | NoSQL มี realtime stream และคุมสิทธิ์ด้วย Security Rules |
| บทความ | Wikipedia API (MediaWiki) | ฟรี ไม่ต้องใช้ key มีระบบหัวข้อ `articletopic:` และ search ในตัว |
| AI | Groq API + `qwen/qwen3.8-27b` | ตอบเร็ว ฟรีในโควตาที่เพียงพอ ใช้ให้คะแนนและแท็ก |
| ข้อมูลในเครื่อง | SharedPreferences | ตั้งค่า เซสชันที่อ่านค้าง โปรไฟล์ที่ cache ไว้ |
| เสียง | flutter_tts | ใช้เสียงที่มากับเครื่อง ทำงานออฟไลน์ได้ ไม่เสียค่าบริการ |
| รูปโปรไฟล์ | image_picker | ใช้ Device Feature (กล้อง/คลังรูป) แทน Firebase Storage |
| ลิงก์ | url_launcher | เปิด Wikipedia ต้นฉบับหรือค้นต่อในเบราว์เซอร์ |
| ซ่อน key | flutter_dotenv (`.env`) | key ไม่ติด Git |
| หลายภาษา | flutter_localizations + ARB (`flutter gen-l10n`) | ระบบทางการของ Flutter |

**ถาม: ทำไมไม่ใช้ Firebase Storage เก็บรูป**
ตอบ: โปรเจกต์ใหม่ของ Firebase Storage ต้องใช้แพลน Blaze ที่ต้องผูกบัตร รูปถูกย่อเป็น 300×300 คุณภาพ 65 แล้วเก็บเป็น base64 ใน field `avatarBase64` ของ `users/{uid}` ซึ่งอยู่ได้ไม่เกิน 1 MB ต่อเอกสาร ตรวจขนาดไว้ที่ Rules ไม่เกิน 700 KB

**ถาม: ทำไมไม่ใช้ State Management library**
ตอบ: ใช้ `setState` + `StreamBuilder` (Firestore, Auth) + `ValueNotifier` สำหรับค่าที่หลายหน้าใช้ร่วม (ธีม ภาษา เซสชัน โปรไฟล์) แอปยังเล็กพอ จึงไม่ต้องเพิ่ม dependency และเห็นการไหลของข้อมูลชัดเจน

## 2. ตรงตามข้อกำหนดของวิชาหรือไม่

| ข้อกำหนด | ของ KEEP | ไฟล์ที่ชี้ได้ |
|---|---|---|
| ≥ 4 หน้าจอ | Auth, Home (ผ่าน AppShell แท็บ), Reading, Summary, Profile + Onboarding, Review, Stats | `lib/screens/` |
| Navigation | AuthGate, push, pushReplacement, popUntil, bottom nav 3 แท็บ, RouteObserver | `main.dart`, `core/navigation.dart`, `screens/app_shell.dart` |
| Form + Validation | Login/Register, สรุป (≥ 50 ตัวอักษร), ชื่อเล่น (2–20) | `core/validators.dart` |
| Authentication | Register / Login / Logout | `services/auth_service.dart` |
| Database + CRUD | `study_logs` (C/R/U/D), `users` | `services/study_log_repository.dart`, `profile_service.dart` |
| Async | Firebase, Groq, Wikipedia, TTS, Timeout | ดูหัวข้อ 6 |
| External ≥ 2 | Wikipedia API, Groq API, SharedPreferences, Camera/Gallery, Device TTS, url_launcher | ดูหัวข้อ 3 |
| Main Workflow | สมัคร → ตั้งค่า → เลือกหมวด → สุ่ม → อ่าน → สรุป → AI → บันทึก → ทบทวน/แก้/ลบ | ดูหัวข้อ 5 |

**หมายเหตุ:** `docs/architecture.md` ยังบรรยายหน้าจอ 5 หน้าแบบเดิม ก่อนมีแท็บทบทวนและสถิติ ตอนนำเสนอให้อ้างโครงสร้างจากสไลด์และหัวข้อนี้

## 3. API อยู่ตรงไหน

| API | ไฟล์ | เรียกที่ไหน / อย่างไร |
|---|---|---|
| Wikipedia | `lib/services/sources/wikipedia_source.dart` | `_getJson()` ทำ GET `https://{en|zh|th}.wikipedia.org/w/api.php` พร้อม User-Agent และ timeout 15 วินาที |
| Groq | `lib/services/slm_service.dart` | `_chat()` ทำ POST `{GROQ_BASE_URL}/chat/completions` พร้อม header `Authorization: Bearer` |
| Groq config | `lib/core/config.dart` | อ่าน `GROQ_API_KEY`, `GROQ_BASE_URL`, `GROQ_MODEL` จาก `.env` |
| Firebase Auth | `lib/services/auth_service.dart` | `signIn`, `register`, `signOut`, `authStateChanges()` |
| Cloud Firestore | `lib/services/study_log_repository.dart`, `lib/services/profile_service.dart`, `lib/services/account_service.dart` | collection `study_logs` และ `users` |
| SharedPreferences | `settings_service.dart`, `session_service.dart`, `bookmark_service.dart` | key เช่น `activeSession_<uid>`, `bookmarks_<uid>` |
| Device TTS | `lib/services/tts_service.dart` | `DeviceTtsService` (flutter_tts) อยู่หลัง abstract `TtsService` |
| Image picker | `lib/widgets/avatar_widgets.dart` | `ImagePicker().pickImage(...)` |

**ถาม: ทำไม Wikipedia ไม่ต้องใช้ key**
ตอบ: Wikipedia API เป็นสาธารณะ แต่ขอให้ระบุ User-Agent ที่บอกชื่อแอป ซึ่งแอปส่ง `KEEP-ReadRecall/1.0` ไปแล้ว ถ้ากดสุ่มถี่เกินไปจะได้ 429 แอปแสดงข้อความ "ลองใหม่อีกครั้ง"

**ถาม: API key อยู่ที่ไหน ปลอดภัยไหม**
ตอบ: key อยู่ใน `.env` ที่อยู่ใน `.gitignore` แต่ flutter_dotenv ฝังไฟล์นี้เข้ากับแอป คนที่แกะแอปออกมาอ่านได้ จึงยอมรับว่าไม่ปลอดภัยเต็มที่ ทางแก้จริงคือให้ backend ถือ key แล้วแอปเรียกผ่าน backend แต่อยู่นอกขอบเขต MVP ของวิชา

**ถาม: Firebase config เป็นความลับไหม**
ตอบ: `firebase_options.dart` ไม่ใช่ความลับ ความปลอดภัยของข้อมูลมาจาก Security Rules

## 4. โค้ดแต่ละส่วนทำอะไร

| ไฟล์ | หน้าที่ |
|---|---|
| `main.dart` | โหลด `.env` → SettingsService → Firebase → `KeepApp` → `LaunchGate` → `AuthGate` |
| `screens/auth_screen.dart` | Login / Register พร้อม validator และ error ตามภาษาแอป |
| `screens/app_shell.dart` | ตัวแท็บหลัก: คลัง (Home), ทบทวน, สถิติ |
| `screens/home_screen.dart` | รายการบทความ, การ์ดอ่านค้าง, ลบบทความ, เริ่มอ่านใหม่ |
| `widgets/start_session_sheet.dart` | เลือกหมวดหรือค้นหัวข้อก่อนสุ่ม |
| `screens/reading_screen.dart` | ดึงบทความ (`_loadArticle`), Timer (`_startTimer`), TTS (`_playTts`), บันทึกเซสชัน (`_persist`) |
| `screens/summary_screen.dart` | ให้คะแนน (`_save` → `evaluate`), บันทึก (`create`/`update`), ล้างเซสชัน |
| `screens/review_session_screen.dart` | ทบทวนแบบ Leitner เรียก `recordReview()` |
| `screens/profile_screen.dart` | ตั้งค่า ภาษา ธีม รูปโปรไฟล์ Logout ลบบัญชี |
| `services/slm_service.dart` | prompt ให้คะแนน, `scoreOf()` คำนวณคะแนน, parse JSON |
| `services/sources/wikipedia_source.dart` | สุ่มบทความ, ทำความสะอาดข้อความ (`cleanExtractWithHeadings`) |
| `services/session_service.dart` | เซสชันที่อ่านค้าง เก็บลง SharedPreferences |
| `models/review_schedule.dart` | Leitner 5 กล่อง (1/3/7/14/30 วัน) |
| `core/motion.dart`, `widgets/motion_widgets.dart` | การเคลื่อนไหวและ Reduce Motion |
| `l10n/arb/*.arb` | ข้อความ 3 ภาษา, `flutter gen-l10n` สร้าง `AppLocalizations` |

**ถาม: คะแนนเป็นของ AI ใช่ไหม**
ตอบ: ไม่ทั้งหมด AI ทำ 3 อย่าง คือระบุประเด็นสำคัญ ตรวจว่าแต่ละประเด็นมีในสรุปไหม และคัดลอกข้อความจากสรุปมาเป็นหลักฐาน แอปเป็นคนคำนวณคะแนนเองใน `scoreOf()` ตามน้ำหนัก: ประเด็น core หนักเป็น 2 เท่า, มีหลักฐานจริงได้เต็ม, ไม่มีหลักฐานได้ครึ่ง, ข้อมูลผิดหักข้อละ 10 สูงสุด 30 จึงตรวจย้อนได้

## 5. Call path ตัวอย่าง (อ่านทีละขั้น)

### 5.1 เริ่มอ่าน: กด "สุ่มบทความ"

1. `widgets/start_session_sheet.dart` ผู้ใช้เลือกหมวดหรือพิมพ์คำค้น
2. `reading_screen.dart:167` เรียก `_source.fetchRandomArticle(...)` ซึ่ง `_source` มาจาก `ArticleSources.byId(...)`
3. `wikipedia_source.dart` `_randomBatch()`:
   - หมวดว่าง → `generator=random`
   - หมวดยอดฮิต → `list=search` + `srsort=random`
   - ค้นเอง → `list=search` + `srsort=relevance` + `sroffset` ตามรอบ
4. ตัดเรื่องที่อ่านแล้วออกด้วย `excludeKeys` (readKey = source + language + pageId)
5. `_fetchContent()` ขอ `prop=extracts|info|pageimages` แบบ `explaintext`
6. `cleanExtractWithHeadings()` ตัดเทมเพลต ตัดส่วนอ้างอิง ตัดหัวข้อที่สั้นเกินไป
7. คืน `Article` กลับไปที่ `_loadArticle` แสดงบนหน้าอ่าน และ `SessionService.save()` บันทึกไว้ทันที

ถ้าหมวดอ่านครบแล้ว `batch.isComplete` จะเป็น true และโยน `TopicExhaustedException` ให้กลับไปหน้า Home พร้อมข้อความ

### 5.2 ระหว่างอ่าน: Timer และการพัก

1. `_startTimer()` เริ่ม `Stopwatch` และ `Timer.periodic` ที่แค่สั่งวาดจอใหม่ทุกวินาที เวลารวมคำนวณจาก `_baseElapsed + Stopwatch`
2. `_updateProgress()` และ `_persist()` บันทึกเซสชันลง SharedPreferences ทุก 10 วินาทีและเมื่อออกจากหน้า
3. ถ้าผู้ใช้กดออก `_pauseAndExit()` หยุด TTS และบันทึกแล้วกลับ Home การ์ดอ่านค้างจะพากลับมา
4. ระหว่างมีเซสชันค้าง ปุ่มสุ่มในหน้า Home จะถูกล็อกผ่าน `SessionService.current`

### 5.3 เขียนสรุปและให้คะแนน: กด "บันทึก"

1. `summary_screen.dart:154` เรียก `_slm.evaluate(language, title, originalContent, userSummary)`
2. `slm_service.dart:99` `evaluate()` สร้าง prompt แล้วเรียก `_chat(json: true, temperature: 0)`
3. `_chat()` ทำ POST ไป `{GROQ_BASE_URL}/chat/completions` พร้อม `model` จาก `.env`
   - timeout 30 วินาที
   - 429 และ `retry-after` ไม่เกิน 10 วินาที → รอแล้วลองใหม่ 1 ครั้ง
   - 401 / 404 / 429 แยกเป็นข้อความเฉพาะ
4. `_parseEvaluation()` ตัด `<think>...</think>` ออก หา `{` ถึง `}` แล้ว `jsonDecode`
5. `scoreOf(keyPoints, accuracyIssues, summary)` คำนวณคะแนน ถ้าไม่มี keyPoints จึงใช้ `aiScore` ที่โมเดลตอบ
6. `ArticleTag.normalize` กรองแท็กที่ไม่รู้จักทิ้ง
7. `summary_screen.dart:222` เรียก `_repo.create(...)` หรือ `_repo.update(...)` ถ้าแก้ไข
8. `study_log_repository.dart` `create()` เรียก `_logs.doc(logId).set({...})` โดยใช้ `logId` ที่จองไว้ก่อน (`newLogId()`) และ `createdAt: serverTimestamp`
9. หลังบันทึกสำเร็จ `summary_screen.dart:245` เรียก `SessionService.instance.clear()` ล้างเซสชัน
10. Home ฟัง `watchLogs()` ซึ่งเป็น Firestore snapshot stream จึงเห็นการ์ดใหม่โดยไม่ต้องรีเฟรช

ทุกขั้นที่ `await` อยู่ใน `try` และ `on AppException` ที่โยนข้อความตามภาษาแอปแล้ว หน้าจอจึงแสดง SnackBar ได้โดยไม่ต้องรู้ว่าเกิดจาก Groq หรือ Firebase

### 5.4 ทบทวน: Leitner

1. `models/review_schedule.dart` คำนวณ `dueList()` จาก `nextReviewAt` หรือ `createdAt + 1 วัน` ถ้ายังไม่เคยทบทวน
2. `review_session_screen.dart:49` เมื่อผู้ใช้ให้คะแนน (ลืม / ยาก / ดี / ง่าย) เรียก `recordReview()`
3. `recordReview()` อัปเดต `reviewBox`, `nextReviewAt`, `lastReviewedAt` และใช้ `FieldValue.increment` สำหรับ `reviewsTotal` และ `reviewsPassed` ให้บวกที่เซิร์ฟเวอร์ ไม่ทับกันเมื่อมีสองเครื่อง

### 5.5 สมัคร / ล็อกอิน

1. `auth_screen.dart` เรียก `AuthService.register` หรือ `signIn` ซึ่งห่อ `FirebaseAuth` ไว้
2. `main.dart` `AuthGate` ฟัง `authStateChanges()` เมื่อมี user จะแสดง `AppShell` เอง
3. ผู้ใช้ใหม่ `ProfileService.load()` ไม่พบ `users/{uid}` จึงเปิด `OnboardingScreen` ให้ตั้งชื่อเล่น รูป ภาษา และเวลาอ่าน แล้วเรียก `completeSetup()`

### 5.6 แก้ไขหรือลบ

- แก้ไข: `summary_screen.dart:248` เรียก `_repo.update()` แก้เฉพาะคำสรุป แท็ก ผลประเมิน
- ลบ: `home_screen.dart:170` เรียก `_repo.delete(log.id)` หลังผู้ใช้ยืนยันแบบ Dismissible

## 6. Database และความปลอดภัย

**ถาม: โครงสร้างข้อมูลเป็นอย่างไร**
ตอบ: มี 2 collection
- `study_logs/{id}`: userId, articleTitle, articleUrl, originalContent (3,000 ตัวอักษรแรก), userSummary, readingTimeMinutes, tags (≤ 3), language, source, pageId, aiScore, aiFeedback, keyPoints, recallQuestion, reviewBox, nextReviewAt, reviewsTotal, reviewsPassed, createdAt, updatedAt
- `users/{uid}`: nickname, avatarPresetId, avatarBase64, email, updatedAt

**ถาม: ทำไมเรียงข้อมูลในแอปไม่ใช้ `orderBy`**
ตอบ: `where(userId) + orderBy(createdAt)` คนละ field ต้องสร้าง Composite Index ก่อน ข้อมูลต่อคนมีไม่มาก เรียงในแอปเร็วพอและไม่ต้องตั้งค่าเพิ่ม

**ถาม: ทำไมกดบันทึกซ้ำไม่เกิดเอกสารซ้ำ**
ตอบ: จองเลข id ด้วย `doc().id` ก่อน แล้ว `set()` ซ้ำจะทับเอกสารเดิม

**ถาม: `set(merge: true)` ต่างจาก `update()` อย่างไร**
ตอบ: `update()` ต้องมีเอกสารอยู่แล้ว ส่วน `set(merge: true)` สร้างให้ได้ถ้ายังไม่มี และแก้เฉพาะ field ที่ส่ง ใช้กับ `users`

**ถาม: Security Rules ป้องกันอะไรบ้าง**
ตอบ:
- `study_logs` อ่านและลบได้เฉพาะเจ้าของ สร้างได้เฉพาะ `userId` ของตัวเอง และแก้ไขห้ามเปลี่ยน `userId`
- `users` อ่านและเขียนได้เฉพาะ uid ของตัวเอง และตรวจรูปแบบ field กับขนาดรูปที่เซิร์ฟเวอร์ด้วย
- ไม่ได้ล็อกอินไม่มีสิทธิ์อ่านหรือเขียนทั้งหมด

## 7. Asynchronous Operations

| จุด | สิ่งที่รอ | จัดการระหว่างรอ / ผิดพลาด |
|---|---|---|
| `main()` | `.env`, SharedPreferences, Firebase init | ทำก่อน `runApp` ถ้า Firebase พัง แสดง `_StartupErrorApp` |
| Login / Register | FirebaseAuth | ปุ่ม disable + spinner, error code → ข้อความตามภาษา |
| Home | Firestore stream, โหลดเซสชัน, โหลดโปรไฟล์, คำทักทาย AI | StreamBuilder, ใช้ข้อความสำรองระหว่างรอ |
| Reading | Wikipedia 2+ request, บันทึกเซสชัน, TTS | "กำลังสุ่มบทความ...", timeout, ลองใหม่ได้ |
| Summary | Groq → Firestore → ล้างเซสชัน | ปุ่มแสดงสถานะ, AI ล่มบันทึกไว้ก่อนได้ |
| Review | `recordReview` | SnackBar เมื่อล้มเหลว |

**กฎที่ใช้ทุกที่:** ทุก `await` ภายนอกอยู่ใน `try / on AppException`, มี `.timeout(...)`, เช็ก `mounted` หลัง `await`, `dispose()` ปิด Timer / Ticker / Controller / TTS

**ถาม: Future กับ Stream ต่างกันอย่างไร และใช้ตรงไหน**
ตอบ: Future คืนผลครั้งเดียว เช่น Login, ดึงบทความ, บันทึก ส่วน Stream ส่งผลต่อเนื่อง เช่น สถานะล็อกอิน และรายการใน Firestore ซึ่งอัปเดตเองเมื่อข้อมูลเปลี่ยน

## 8. คำถามที่อาจโดนถามยาก ๆ และข้อจำกัด

**ถาม: ถ้า AI ให้คะแนนผิดจะทำอย่างไร**
ตอบ: AI ไม่ได้เดาคะแนนเอง คะแนนมาจากรายการประเด็นพร้อมหลักฐาน ผู้ใช้เห็น Feedback และสามารถแก้สรุปแล้วให้คะแนนใหม่ได้ อุณหภูมิตั้งเป็น 0 เพื่อให้ผลคงที่

**ถาม: ทำไมใช้ Groq ไม่ใช้ OpenAI**
ตอบ: Groq ให้โควตาฟรีและตอบเร็ว และ API เข้ากันได้กับ OpenAI จึงเปลี่ยนผู้ให้บริการได้โดยแก้ `GROQ_BASE_URL` และ `GROQ_MODEL` ใน `.env`

**ถาม: ถ้าอินเทอร์เน็ตหลุดระหว่างอ่านจะเป็นอย่างไร**
ตอบ: เซสชันบันทึกลงเครื่องแล้วทุก 10 วินาที อ่านต่อได้ สุ่มบทความใหม่หรือบันทึกสรุปจะแจ้งข้อผิดพลาดและลองใหม่ได้ ส่วนการอ่านด้วยเสียงทำงานในเครื่อง

**ถาม: ข้อจำกัดของแอปคืออะไร**
ตอบ:
- ไม่มี backend เอง key ของ Groq จึงฝังในแอป
- การลบบัญชีลบข้อมูลใน Firestore และ SharedPreferences ของผู้ใช้ แต่ไม่ได้ทำ Cloud Function
- คำแนะนำแท็กและคะแนนขึ้นกับคุณภาพของโมเดล
- Wikipedia จำกัดอัตราการเรียก ถ้ากดถี่จะได้ 429
- การอ่านออกเสียงขึ้นกับเสียงที่ติดตั้งในเครื่อง ถ้าไม่มีภาษานั้นจะแจ้ง error

**ถาม: ถ้าจะเพิ่มแหล่งบทความอื่นต้องแก้อะไร**
ตอบ: เขียน class ที่ implements `ArticleSource` แล้วเพิ่มใน `ArticleSources.all` หน้าจออื่นไม่ต้องแก้

**ถาม: ทำไมเลือก setState ไม่ใช้ Bloc หรือ Provider**
ตอบ: ขนาดแอปยังเล็ก ค่าที่ใช้ร่วมมีไม่กี่ตัว และ `ValueNotifier` กับ `StreamBuilder` พอแล้ว ถ้าขยายมากกว่านี้จะพิจารณา Riverpod หรือ Bloc

**ถาม: มีการทดสอบอะไรบ้าง**
ตอบ: `flutter test` ทำงานออฟไลน์ โดยจำลอง Wikipedia และ Groq ด้วย `MockClient` ครอบคลุม scoreOf, การทำความสะอาดบทความ, ธีม, Reduce Motion, ตัวอักษรขนาดใหญ่ และการทบทวน ส่วนโฟลเดอร์ `test/live` เรียก API จริงและเปิดด้วย `LIVE=1` เท่านั้น

## 9. คำสั่งที่อาจต้องใช้ตอนสาธิต

```bash
flutter analyze
flutter test
flutter run
firebase deploy --only firestore:rules
```
