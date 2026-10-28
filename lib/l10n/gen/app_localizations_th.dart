// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get tagline => 'อ่าน · จำ · สรุป ฝึกจับใจความด้วย Active Recall';

  @override
  String get cancel => 'ยกเลิก';

  @override
  String get retry => 'ลองใหม่';

  @override
  String get save => 'บันทึก';

  @override
  String get discard => 'ทิ้ง';

  @override
  String get delete => 'ลบ';

  @override
  String get continueLabel => 'ต่อไป';

  @override
  String minutesValue(int count) {
    return '$count นาที';
  }

  @override
  String get login => 'Login';

  @override
  String get register => 'สมัครสมาชิก';

  @override
  String get email => 'Email';

  @override
  String get password => 'รหัสผ่าน';

  @override
  String get confirmPassword => 'ยืนยันรหัสผ่าน';

  @override
  String get showPassword => 'แสดงรหัสผ่าน';

  @override
  String get hidePassword => 'ซ่อนรหัสผ่าน';

  @override
  String get haveAccount => 'มีบัญชีแล้ว? Login';

  @override
  String get noAccount => 'ยังไม่มีบัญชี? สมัครสมาชิก';

  @override
  String get vEmailRequired => 'กรุณากรอก Email';

  @override
  String get vEmailInvalid => 'รูปแบบ Email ไม่ถูกต้อง';

  @override
  String get vPasswordRequired => 'กรุณากรอกรหัสผ่าน';

  @override
  String vPasswordMin(int min) {
    return 'รหัสผ่านต้องมีอย่างน้อย $min ตัวอักษร';
  }

  @override
  String get vConfirmRequired => 'กรุณายืนยันรหัสผ่าน';

  @override
  String get vPasswordMismatch => 'รหัสผ่านไม่ตรงกัน';

  @override
  String get vSummaryRequired => 'กรุณาเขียนสรุปใจความสำคัญ';

  @override
  String vSummaryMin(int min, int count) {
    return 'สรุปสั้นเกินไป ต้องมีอย่างน้อย $min ตัวอักษร (ตอนนี้ $count)';
  }

  @override
  String get vNicknameRequired => 'กรุณากรอกชื่อเล่น';

  @override
  String vNicknameLength(int min, int max) {
    return 'ชื่อเล่นต้องยาว $min–$max ตัวอักษร';
  }

  @override
  String get errNoInternet => 'ไม่มีการเชื่อมต่ออินเทอร์เน็ต';

  @override
  String get errTimeout => 'เชื่อมต่อนานเกินไป กรุณาลองใหม่';

  @override
  String get errGeneric => 'เกิดข้อผิดพลาด กรุณาลองใหม่อีกครั้ง';

  @override
  String errGenericCode(String code) {
    return 'เกิดข้อผิดพลาด ($code)';
  }

  @override
  String get errUserDisabled => 'บัญชีนี้ถูกระงับการใช้งาน';

  @override
  String get errWrongCredentials => 'Email หรือรหัสผ่านไม่ถูกต้อง';

  @override
  String get errEmailInUse => 'Email นี้ถูกใช้สมัครแล้ว';

  @override
  String get errWeakPassword => 'รหัสผ่านง่ายเกินไป';

  @override
  String get errTooManyRequests => 'ลองหลายครั้งเกินไป กรุณารอสักครู่';

  @override
  String get errAuthNotEnabled =>
      'ยังไม่ได้เปิดใช้ Email/Password ใน Firebase Console';

  @override
  String get errPermissionDenied => 'ไม่มีสิทธิ์เข้าถึงข้อมูลนี้';

  @override
  String get errDbUnavailable =>
      'เชื่อมต่อฐานข้อมูลไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';

  @override
  String errSaveFailed(String code) {
    return 'บันทึกข้อมูลไม่สำเร็จ ($code)';
  }

  @override
  String get errDbTimeout => 'ฐานข้อมูลตอบช้าเกินไป กรุณาลองใหม่';

  @override
  String get errArticleEmpty => 'บทความนี้ไม่มีเนื้อหา กรุณาสุ่มใหม่';

  @override
  String get errNoArticle => 'ไม่พบบทความ กรุณาลองใหม่';

  @override
  String get errWikiTimeout => 'Wikipedia ตอบช้าเกินไป กรุณาลองใหม่';

  @override
  String get errWikiLoad => 'โหลดบทความไม่สำเร็จ กรุณาลองใหม่';

  @override
  String get errWikiRateLimit =>
      'สุ่มบทความถี่เกินไป กรุณารอสักครู่แล้วลองใหม่';

  @override
  String errWikiStatus(String code) {
    return 'Wikipedia ตอบกลับผิดปกติ ($code)';
  }

  @override
  String get errAiNotConfigured =>
      'ยังไม่ได้ตั้งค่า AI (ใส่ GROQ_API_KEY ในไฟล์ .env)';

  @override
  String get errAiBadKey => 'API key ของ Groq ไม่ถูกต้อง';

  @override
  String errAiModelNotFound(String model) {
    return 'ไม่พบโมเดล $model บน Groq (แก้ GROQ_MODEL ใน .env)';
  }

  @override
  String get errAiRateLimit => 'ใช้งาน AI ถี่เกินไป กรุณารอสักครู่แล้วลองใหม่';

  @override
  String errAiStatus(String code) {
    return 'AI ตอบกลับผิดปกติ ($code)';
  }

  @override
  String get errAiTimeout => 'AI ใช้เวลานานเกินไป กรุณาลองใหม่';

  @override
  String get errAiConnect => 'เชื่อมต่อ AI ไม่ได้ กรุณาตรวจสอบอินเทอร์เน็ต';

  @override
  String get errAiRead => 'อ่านผลจาก AI ไม่สำเร็จ กรุณาลองใหม่';

  @override
  String get errAiBadFormat => 'AI ตอบกลับในรูปแบบที่อ่านไม่ได้';

  @override
  String get errAiNoScore => 'AI ไม่ได้ส่งคะแนนกลับมา';

  @override
  String get aiNoFeedback => 'ไม่มี Feedback';

  @override
  String errTtsNoVoice(String language) {
    return 'เครื่องนี้ไม่มีเสียงอ่านภาษา $language';
  }

  @override
  String get errImageTooLarge => 'รูปใหญ่เกินไป กรุณาเลือกรูปอื่น';

  @override
  String get errLoginAgain => 'กรุณา Login ใหม่';

  @override
  String get errProfilePermission => 'ไม่มีสิทธิ์บันทึกโปรไฟล์';

  @override
  String errProfileSave(String code) {
    return 'บันทึกโปรไฟล์ไม่สำเร็จ ($code)';
  }

  @override
  String errFirebaseInit(String message) {
    return 'เชื่อมต่อ Firebase ไม่สำเร็จ\n\n$message';
  }

  @override
  String helloName(String name) {
    return 'สวัสดี, $name';
  }

  @override
  String get greetingFallback => 'วันนี้จะได้เรียนรู้อะไรดีนะ';

  @override
  String get profileSettingsTooltip => 'โปรไฟล์และ Settings';

  @override
  String get randomArticle => 'สุ่มบทความใหม่';

  @override
  String get finishCurrentFirst => 'สรุปเรื่องเดิมก่อน';

  @override
  String get sessionLockedMessage =>
      'มีบทความที่อ่านค้างอยู่ ต้องสรุปให้เสร็จก่อนจึงจะสุ่มเรื่องใหม่ได้';

  @override
  String get sessionReading => 'กำลังอ่าน · พักไว้';

  @override
  String get sessionSummarizing => 'อ่านจบแล้ว · รอสรุป';

  @override
  String timeLeft(String time) {
    return 'เหลือเวลา $time';
  }

  @override
  String readForMinutes(int count) {
    return 'อ่าน $count นาที';
  }

  @override
  String get tapToResume => 'แตะเพื่ออ่านต่อ';

  @override
  String get tapToSummarize => 'แตะเพื่อเขียนสรุปต่อ';

  @override
  String get options => 'ตัวเลือก';

  @override
  String get discardArticle => 'ทิ้งบทความนี้';

  @override
  String get discardSessionTitle => 'ทิ้งบทความที่อ่านค้าง?';

  @override
  String discardSessionMessage(String title) {
    return '\"$title\" และร่างคำสรุปจะหายไป แล้วจึงสุ่มเรื่องใหม่ได้';
  }

  @override
  String get statRead => 'อ่านแล้ว';

  @override
  String get statAvgScore => 'คะแนนเฉลี่ย';

  @override
  String get statTotalTime => 'เวลาอ่านรวม';

  @override
  String get unitArticles => 'เรื่อง';

  @override
  String get unitMinutes => 'นาที';

  @override
  String get statAllTime => 'ทั้งหมด';

  @override
  String get emptyTitle => 'ยังไม่มีประวัติการอ่าน';

  @override
  String get emptyBody =>
      'กด \"สุ่มบทความใหม่\" เพื่อเริ่มอ่าน แล้วลองสรุปจากความจำ';

  @override
  String get deleteLogTitle => 'ลบบันทึกนี้?';

  @override
  String deleteLogMessage(String title) {
    return '\"$title\" จะถูกลบถาวร ไม่สามารถกู้คืนได้';
  }

  @override
  String deletedMessage(String title) {
    return 'ลบ \"$title\" แล้ว';
  }

  @override
  String get notEvaluated => 'ยังไม่ได้ประเมิน';

  @override
  String historyLoadError(String error) {
    return 'โหลดประวัติไม่สำเร็จ\n$error';
  }

  @override
  String get readingTitle => 'อ่านบทความ';

  @override
  String get searchMore => 'ค้นหาข้อมูลเพิ่ม';

  @override
  String get pauseForLater => 'พักไว้อ่านทีหลัง';

  @override
  String get pausedMessage => 'พักการอ่านไว้แล้ว กดการ์ดในหน้าแรกเพื่ออ่านต่อ';

  @override
  String get timeUpTitle => 'หมดเวลาอ่านแล้ว';

  @override
  String get timeUpBody =>
      'ลองสรุปใจความสำคัญจากความจำ โดยไม่ต้องกลับไปดูบทความ';

  @override
  String get goSummarize => 'ไปเขียนสรุป';

  @override
  String get finishedReading => 'อ่านจบแล้ว ไปเขียนสรุป';

  @override
  String get loadingArticle => 'กำลังสุ่มบทความจาก Wikipedia...';

  @override
  String charCount(int count) {
    return '$count ตัวอักษร';
  }

  @override
  String get timerRunning => 'Timer กำลังเดิน';

  @override
  String get timerPaused => 'หยุดชั่วคราว';

  @override
  String get pauseTimer => 'หยุดชั่วคราว';

  @override
  String get resumeTimer => 'จับเวลาต่อ';

  @override
  String get ttsPlay => 'ฟังเสียงอ่าน';

  @override
  String get ttsPause => 'พักเสียง';

  @override
  String get ttsStop => 'หยุดเสียง';

  @override
  String ttsReading(int current, int total) {
    return 'กำลังอ่านย่อหน้า $current/$total';
  }

  @override
  String ttsPausedAt(int current, int total) {
    return 'พักเสียงที่ย่อหน้า $current/$total';
  }

  @override
  String get ttsIdle => 'ฟังเสียงอ่านบทความ';

  @override
  String get ttsError => 'เปิดเสียงอ่านไม่ได้';

  @override
  String get linkError => 'เปิดลิงก์ไม่ได้';

  @override
  String get searchGoogle => 'ค้นหาเพิ่มใน Google';

  @override
  String get openWikipedia => 'เปิดหน้า Wikipedia ต้นฉบับ';

  @override
  String get openWikipediaSub => 'ดูรูปภาพ ตาราง และแหล่งอ้างอิง';

  @override
  String get writeSummaryTitle => 'เขียนสรุป';

  @override
  String get editSummaryTitle => 'แก้ไขบทสรุป';

  @override
  String get recallHint => 'สรุปใจความสำคัญจากความจำ ไม่ต้องกลับไปดูบทความ';

  @override
  String get editHint => 'แก้ไขคำสรุปแล้วให้ AI ประเมินใหม่ได้';

  @override
  String get summaryHint =>
      'บทความนี้พูดถึงเรื่องอะไร ประเด็นหลักมีอะไรบ้าง...';

  @override
  String summaryCounter(int count, int min) {
    return '$count ตัวอักษร (อย่างน้อย $min)';
  }

  @override
  String get aiEvaluating => 'AI กำลังประเมิน...';

  @override
  String get saving => 'กำลังบันทึก...';

  @override
  String get evaluateAndSave => 'ให้ AI ประเมินและบันทึก';

  @override
  String get reevaluateAndSave => 'ประเมินใหม่และบันทึก';

  @override
  String earnedMinutes(int count) {
    return '+$count นาที เข้าเวลาอ่านรวมแล้ว';
  }

  @override
  String get viewOriginal => 'ดูบทความต้นฉบับ';

  @override
  String get viewOriginalSub => 'ส่วนที่ AI ใช้เทียบตอนให้คะแนน';

  @override
  String get doneBackHome => 'เสร็จสิ้น กลับหน้าแรก';

  @override
  String get staleScore =>
      'คะแนนนี้เป็นของข้อความก่อนแก้ไข กดประเมินใหม่เพื่ออัปเดต';

  @override
  String get scoreLabel => 'คะแนนความเข้าใจ';

  @override
  String get notEvaluatedYet => 'ยังไม่ได้ประเมิน';

  @override
  String scoreOutOf(int score) {
    return '$score / 100';
  }

  @override
  String evaluatedBy(String model) {
    return 'ประเมินโดย Groq · $model';
  }

  @override
  String get aiFeedbackTitle => 'Feedback จาก AI';

  @override
  String get aiFailed => 'AI ประเมินไม่สำเร็จ';

  @override
  String get saveWithoutScore => 'บันทึกไว้ก่อน (ยังไม่มีคะแนน)';

  @override
  String get savedMessage => 'บันทึกเรียบร้อย';

  @override
  String get removeScoreTitle => 'ลบคะแนนเดิม?';

  @override
  String get removeScoreMessage =>
      'คะแนนเดิมเป็นของข้อความก่อนแก้ไข การบันทึกนี้จะเปลี่ยนเป็น \"ยังไม่ได้ประเมิน\"';

  @override
  String get discardDraftTitle => 'ทิ้งข้อความที่เขียน?';

  @override
  String get discardDraftMessage => 'คำสรุปที่ยังไม่ได้บันทึกจะหายไป';

  @override
  String get tagsTitle => 'แท็ก (ไม่เกิน 3)';

  @override
  String get tagsHint => 'AI จะแนะนำแท็กให้หลังประเมิน แตะเพื่อเปลี่ยนได้';

  @override
  String get tagsLimit => 'เลือกได้ไม่เกิน 3 แท็ก';

  @override
  String get tagTechnology => 'Technology';

  @override
  String get tagScience => 'วิทยาศาสตร์';

  @override
  String get tagHistory => 'ประวัติศาสตร์';

  @override
  String get tagBiographies => 'ชีวประวัติ';

  @override
  String get tagCulture => 'วัฒนธรรม';

  @override
  String get chooseTopicTitle => 'อยากอ่านเรื่องอะไร?';

  @override
  String get popularTopics => 'หมวดยอดฮิต';

  @override
  String get anyTopic => 'สุ่มทุกหมวด';

  @override
  String get searchTopic => 'หรือค้นหาหมวดที่ต้องการ';

  @override
  String get searchTopicHint => 'เช่น อวกาศ, กาแฟ, จักรวรรดิโรมัน';

  @override
  String readingFrom(String source, String language) {
    return 'จาก $source · $language';
  }

  @override
  String get startReading => 'เริ่มอ่าน';

  @override
  String topicExhausted(String topic, String source, String language) {
    return 'หมวด \"$topic\" ใน $source ($language) อ่านครบหมดแล้ว';
  }

  @override
  String get noNewArticles => 'รอบนี้ไม่พบบทความที่ยังไม่เคยอ่าน กรุณาลองใหม่';

  @override
  String get settingsTitle => 'โปรไฟล์และ Settings';

  @override
  String get editNickname => 'แก้ไขชื่อเล่น';

  @override
  String get nickname => 'ชื่อเล่น';

  @override
  String get changePhoto => 'เปลี่ยนรูปโปรไฟล์';

  @override
  String get chooseAnimal => 'เลือกตัวละครสัตว์';

  @override
  String get useMyPhoto => 'หรือใช้รูปของคุณเอง';

  @override
  String get fromGallery => 'เลือกจากคลังรูป';

  @override
  String get takePhoto => 'ถ่ายรูป';

  @override
  String get cameraHint => 'ใช้ได้บนเครื่องจริง (Simulator ไม่มีกล้อง)';

  @override
  String get removePhoto => 'ลบรูปของฉัน';

  @override
  String photoUpdated(int size) {
    return 'อัปเดตรูปโปรไฟล์แล้ว ($size KB)';
  }

  @override
  String get photoRemoved => 'ลบรูปของคุณแล้ว';

  @override
  String get photoError => 'เปิดรูปไม่ได้ กรุณาอนุญาตการเข้าถึงใน Settings';

  @override
  String get languageSection => 'ภาษา';

  @override
  String get appLanguage => 'ภาษาของแอป';

  @override
  String get appLanguageHint => 'เมนู ข้อความ และ Feedback จาก AI';

  @override
  String get articleLanguage => 'ภาษาที่สุ่มบทความ';

  @override
  String get articleLanguageHint => 'สุ่มบทความใหม่จาก Wikipedia ภาษานี้';

  @override
  String get ttsLanguage => 'ภาษาที่ BOT TTS อ่าน';

  @override
  String get ttsLanguageHint => 'AUTO = อ่านตามภาษาของบทความ';

  @override
  String get sourcesSection => 'แหล่งข้อมูล';

  @override
  String get sourceWikipediaDesc =>
      'สารานุกรมเสรี มีทั้ง English, Chinese และ Thai';

  @override
  String get sourcesMore => 'แหล่งข้อมูลเพิ่มเติม';

  @override
  String get sourcesMoreHint => 'จะเพิ่มในอัปเดตถัดไป หรือติดตั้งเป็น plugin';

  @override
  String get comingSoon => 'เร็วๆ นี้';

  @override
  String get applyLanguage => 'ยืนยันภาษา';

  @override
  String get restartTitle => 'รีสตาร์ตแอป?';

  @override
  String get restartMessage =>
      'ต้องรีสตาร์ตแอปเพื่อใช้ภาษาใหม่ จะรีสตาร์ตเลยไหม?';

  @override
  String get restartNow => 'รีสตาร์ตเลย';

  @override
  String get restartLater => 'ไว้ทีหลัง';

  @override
  String get languageSavedForLater =>
      'บันทึกแล้ว จะใช้ภาษาใหม่เมื่อเปิดแอปครั้งถัดไป';

  @override
  String get languagePending => 'บันทึกแล้ว รอรีสตาร์ตแอป';

  @override
  String get readingSection => 'การอ่าน';

  @override
  String get readingTimePerRound => 'เวลาอ่านต่อรอบ';

  @override
  String get displaySection => 'การแสดงผล';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get logout => 'Logout';

  @override
  String get logoutTitle => 'Logout?';

  @override
  String get logoutMessage => 'ต้อง Login ใหม่เพื่อดูประวัติการอ่าน';

  @override
  String get setupTitle => 'ตั้งค่าเริ่มต้น';

  @override
  String get setupSubtitle =>
      'เลือกสิ่งพื้นฐานก่อนเริ่มอ่าน เปลี่ยนทีหลังได้ใน Settings';

  @override
  String get setupProfilePicture => 'รูปโปรไฟล์';

  @override
  String get setupStart => 'เริ่มใช้งาน';
}
