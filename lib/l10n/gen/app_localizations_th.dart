// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Thai (`th`).
class AppLocalizationsTh extends AppLocalizations {
  AppLocalizationsTh([String locale = 'th']) : super(locale);

  @override
  String get tagline => 'อ่าน · นึก · ทบทวน';

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
  String get unitMinutes => 'นาที';

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
  String photoUpdated(int size) {
    return 'อัปเดตรูปโปรไฟล์แล้ว ($size KB)';
  }

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

  @override
  String get navLibrary => 'คลัง';

  @override
  String get navReview => 'ทบทวน';

  @override
  String get navStats => 'สถิติ';

  @override
  String streakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ติดต่อกัน $count วัน',
    );
    return '$_temp0';
  }

  @override
  String get streakStart => 'เริ่มนับวันติดกัน';

  @override
  String todayGoal(int done, int goal) {
    return 'วันนี้ $done / $goal นาที';
  }

  @override
  String get todayGoalMet => 'ครบเป้าวันนี้แล้ว';

  @override
  String randomArticleSubtitle(String language) {
    return 'Wikipedia · $language · เลือกหมวดได้';
  }

  @override
  String get historyTitle => 'ประวัติการอ่าน';

  @override
  String get scoreMastered => 'จำได้แม่น';

  @override
  String get scoreGood => 'จำได้ดี';

  @override
  String get scoreReview => 'ควรทบทวน';

  @override
  String scoreSemantics(int score, String level) {
    return 'คะแนน $score, $level';
  }

  @override
  String get tipTitle => 'เคล็ดลับการจำ';

  @override
  String get recallTip1 =>
      'ปิดบทความแล้วเขียนสิ่งที่จำได้ก่อนเปิดดู ความพยายามนึกนี่แหละที่ทำให้จำได้นาน';

  @override
  String get recallTip2 =>
      'เล่าเหมือนอธิบายให้เพื่อนฟัง คำง่ายๆ จะบอกว่าคุณเข้าใจจริงแค่ไหน';

  @override
  String get recallTip3 =>
      'อ่านสั้นๆ ทุกวันดีกว่าอ่านยาวครั้งเดียว การอ่านต่อเนื่องช่วยให้ความจำไม่จางหาย';

  @override
  String get recallTip4 =>
      'พลาดประเด็นสำคัญไป? พรุ่งนี้อ่านเฉพาะส่วนนั้นซ้ำ แล้วลองนึกอีกครั้ง';

  @override
  String get close => 'ปิด';

  @override
  String get topicSheetHint =>
      'หมดเวลาแล้วคุณจะเขียนสิ่งที่จำได้ โดยไม่ย้อนกลับไปดูบทความ';

  @override
  String get recallNoteTitle => 'โน้ตชวนนึก';

  @override
  String get recallNoteLoading => 'กำลังตั้งคำถามให้คุณถือไว้ระหว่างอ่าน…';

  @override
  String get recallNoteFallback =>
      'ถามตัวเองระหว่างอ่าน: ใจความหลักคืออะไร และสำคัญอย่างไร?';

  @override
  String get recallNoteHint => 'ตอบจากความจำตอนเขียนสรุป';

  @override
  String get bookmarkAdd => 'บันทึกบทความ';

  @override
  String get bookmarkRemove => 'เลิกบันทึก';

  @override
  String get bookmarkSaved => 'บันทึกบทความไว้แล้ว';

  @override
  String get bookmarkRemoved => 'เลิกบันทึกแล้ว';

  @override
  String readMinutesEstimate(int minutes) {
    return 'อ่านราว $minutes นาที';
  }

  @override
  String readingProgress(int percent) {
    return 'อ่านไปแล้ว $percent%';
  }

  @override
  String get keyPointsTitle => 'ประเด็นสำคัญ';

  @override
  String keyPointsCovered(int count) {
    return 'เขียนถึงแล้ว ($count)';
  }

  @override
  String keyPointsMissed(int count) {
    return 'ยังขาด ($count)';
  }

  @override
  String keyPointsSummary(int covered, int total) {
    return 'เขียนถึง $covered จาก $total ประเด็น';
  }

  @override
  String get keyPointCore => 'ใจความหลัก';

  @override
  String get accuracyTitle => 'ตรวจข้อมูลเหล่านี้อีกครั้ง';

  @override
  String get readAnother => 'อ่านบทความถัดไป';

  @override
  String get statusActive => 'นักอ่านต่อเนื่อง';

  @override
  String get statusReader => 'นักอ่าน';

  @override
  String memberSince(String month) {
    return 'เป็นสมาชิกตั้งแต่ $month';
  }

  @override
  String get statLogsSaved => 'บันทึกแล้ว';

  @override
  String get statReviewSuccess => 'ทบทวนสำเร็จ';

  @override
  String get statStreak => 'วันติดกัน';

  @override
  String get launchSound => 'เสียงตอนเปิดแอป';

  @override
  String get launchSoundHint =>
      'เสียงโคมไฟกะพริบเบาๆ ตอนเปิด KEEP และจะเงียบเมื่อเครื่องเปิดโหมดปิดเสียง';

  @override
  String versionLabel(String version) {
    return 'เวอร์ชัน $version';
  }

  @override
  String get authStatusPill => 'ฝึกอ่านแบบ Active Recall';

  @override
  String get authFooter =>
      'ประวัติการอ่านของคุณเห็นได้เฉพาะบัญชีของคุณเท่านั้น';

  @override
  String get forgotPassword => 'ลืมรหัสผ่าน?';

  @override
  String get resetTitle => 'ตั้งรหัสผ่านใหม่';

  @override
  String get resetBody => 'เราจะส่งลิงก์สำหรับตั้งรหัสผ่านใหม่ไปที่อีเมลของคุณ';

  @override
  String get resetSend => 'ส่งลิงก์';

  @override
  String resetSent(String email) {
    return 'ถ้ามีบัญชีของ $email ลิงก์ตั้งรหัสผ่านใหม่จะถูกส่งไปที่อีเมลนี้';
  }

  @override
  String stepOf(int current, int total) {
    return 'ขั้นที่ $current จาก $total';
  }

  @override
  String get next => 'ถัดไป';

  @override
  String get back => 'ย้อนกลับ';

  @override
  String get setupStep1Title => 'ใครกำลังอ่าน?';

  @override
  String get setupStep2Title => 'อยากอ่านแบบไหน?';

  @override
  String ttsSpeed(String rate) {
    return 'ความเร็วเสียงอ่าน $rate× แตะเพื่อเปลี่ยน';
  }

  @override
  String get timeAlmostUp => 'ใกล้หมดเวลา';

  @override
  String get skipIntro => 'ข้ามหน้าเปิด';

  @override
  String get noData => 'ยังไม่มีข้อมูล';

  @override
  String get range7 => '7 วัน';

  @override
  String get range30 => '30 วัน';

  @override
  String get rangeAll => 'ทั้งหมด';

  @override
  String get statsMinutesTitle => 'เวลาอ่าน';

  @override
  String get statsScoresTitle => 'คะแนนการจำ';

  @override
  String get statsCalendarTitle => 'ปฏิทินการอ่าน';

  @override
  String get statsTopicsTitle => 'หมวดที่อ่าน';

  @override
  String get statsEmpty => 'ช่วงนี้ยังไม่ได้อ่านเลย ลองสุ่มบทความจากแท็บคลังดู';

  @override
  String changeUp(String value) {
    return '↑ $value จากช่วงก่อน';
  }

  @override
  String changeDown(String value) {
    return '↓ $value จากช่วงก่อน';
  }

  @override
  String get changeSame => 'เท่ากับช่วงก่อน';

  @override
  String get showTable => 'ดูเป็นตาราง';

  @override
  String get showChart => 'ดูเป็นกราฟ';

  @override
  String get chartTapHint => 'แตะกราฟเพื่อดูค่า';

  @override
  String get legendLess => 'น้อย';

  @override
  String get legendMore => 'มาก';

  @override
  String weekOf(String date) {
    return 'สัปดาห์ของ $date';
  }

  @override
  String minutesSummary(int total, int max, String day) {
    return 'รวม $total นาที มากที่สุด $max นาที เมื่อ $day';
  }

  @override
  String scoresSummary(int count, int latest, int average) {
    return 'มีคะแนน $count บทความ ล่าสุด $latest เฉลี่ย $average';
  }

  @override
  String calendarSummary(int days, int longest) {
    return 'อ่าน $days วันใน 12 สัปดาห์ที่ผ่านมา ติดกันยาวที่สุด $longest วัน';
  }

  @override
  String topicsSummary(String topic, int count) {
    return 'อ่านมากที่สุด: $topic $count บทความ';
  }

  @override
  String longestStreak(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ติดกันยาวที่สุด $count วัน',
    );
    return '$_temp0';
  }

  @override
  String topicValue(int count, int score) {
    return '$count · เฉลี่ย $score';
  }

  @override
  String get otherTopics => 'อื่นๆ';

  @override
  String get noScoresYet => 'ช่วงนี้ยังไม่มีคะแนน';

  @override
  String reviewDueTitle(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทบทวนวันนี้ $count เรื่อง',
      zero: 'วันนี้ไม่มีเรื่องต้องทบทวน',
    );
    return '$_temp0';
  }

  @override
  String get reviewDueSub => 'นึกให้ออกก่อน แล้วค่อยดูประเด็นสำคัญ';

  @override
  String get reviewBoxesTitle => 'กล่องความจำ';

  @override
  String get reviewBoxesHint =>
      'จำได้ = บทความเลื่อนไปกล่องที่เว้นนานขึ้น ลืม = กลับไปกล่อง 1';

  @override
  String boxLabel(int box) {
    return 'กล่อง $box';
  }

  @override
  String everyDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทุก $count วัน',
    );
    return '$_temp0';
  }

  @override
  String get dueToday => 'ถึงกำหนดวันนี้';

  @override
  String overdueDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'เลยกำหนด $count วัน',
    );
    return '$_temp0';
  }

  @override
  String get comingUp => 'รอบถัดไป';

  @override
  String dueOn(String date) {
    return 'ครบกำหนด $date';
  }

  @override
  String get startReview => 'ทบทวน';

  @override
  String get reviewEmptyAll =>
      'อ่านบทความแล้วบันทึกคำสรุปก่อน บทความจะถึงรอบทบทวนในวันถัดไป';

  @override
  String reviewAllDone(String date) {
    return 'ทบทวนครบแล้ว กลับมาอีกครั้ง $date';
  }

  @override
  String get recallPromptGeneric =>
      'จำอะไรเกี่ยวกับบทความนี้ได้บ้าง? เริ่มจากใจความหลักก่อน';

  @override
  String get recallJotHint => 'จดสิ่งที่จำได้ (ไม่บังคับ ไม่บันทึก)';

  @override
  String get reveal => 'เฉลยประเด็นสำคัญ';

  @override
  String get reviewYourSummary => 'คำสรุปเดิมของคุณ';

  @override
  String get rateTitle => 'จำได้แค่ไหน?';

  @override
  String get rateAgain => 'ลืม';

  @override
  String get rateHard => 'ยาก';

  @override
  String get rateGood => 'ดี';

  @override
  String get rateEasy => 'ง่าย';

  @override
  String nextInDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'อีก $count วัน',
    );
    return '$_temp0';
  }

  @override
  String reviewSaved(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'ทบทวนอีกครั้งในอีก $count วัน',
      one: 'ทบทวนอีกครั้งพรุ่งนี้',
    );
    return '$_temp0';
  }

  @override
  String get deleteAccount => 'ลบบัญชี';

  @override
  String get deleteAccountTitle => 'ลบบัญชีของคุณ?';

  @override
  String get deleteAccountBody =>
      'จะลบประวัติการอ่าน คำสรุป ความคืบหน้าการทบทวน และโปรไฟล์ทั้งหมดอย่างถาวร และกู้คืนไม่ได้';

  @override
  String get deleteAccountPassword => 'ใส่รหัสผ่านเพื่อยืนยัน';

  @override
  String get deleteAccountConfirm => 'ลบถาวร';

  @override
  String get accountDeleted => 'ลบบัญชีเรียบร้อยแล้ว';

  @override
  String get continueWithGoogle => 'ดำเนินการต่อด้วย Google';

  @override
  String get orDivider => 'หรือ';

  @override
  String get errGoogleSetup =>
      'ยังไม่ได้ตั้งค่าการเข้าสู่ระบบด้วย Google สำหรับแอปนี้';

  @override
  String get errGoogleFailed => 'เข้าสู่ระบบด้วย Google ไม่สำเร็จ ลองอีกครั้ง';

  @override
  String get errAccountOtherProvider =>
      'อีเมลนี้สมัครด้วยวิธีอื่นไว้แล้ว ลองเข้าสู่ระบบด้วยรหัสผ่าน';

  @override
  String get deleteAccountGoogle =>
      'ระบบจะให้เข้าสู่ระบบ Google อีกครั้งเพื่อยืนยัน';

  @override
  String get continueWithApple => 'ดำเนินการต่อด้วย Apple';

  @override
  String get appleComingSoon => 'เข้าสู่ระบบด้วย Apple จะเปิดให้ใช้เร็วๆ นี้';
}
