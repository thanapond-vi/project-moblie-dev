import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'core/app_restarter.dart';
import 'core/motion.dart';
import 'core/navigation.dart';
import 'core/theme.dart';
import 'firebase_options.dart';
import 'l10n/l10n.dart';
import 'models/content_language.dart';
import 'screens/auth_screen.dart';
import 'screens/launch_screen.dart';
import 'screens/app_shell.dart';
import 'services/auth_service.dart';
import 'services/settings_service.dart';

/// จุดเริ่มต้นของแอป: เตรียมทุกอย่างที่ต้อง await ให้เสร็จก่อน runApp
Future<void> main() async {
  // ต้องเรียกก่อนใช้ plugin ใดๆ ที่คุยกับ native (Firebase, SharedPreferences)
  WidgetsFlutterBinding.ensureInitialized();

  // 1) โหลด API key จาก .env (ถ้าไม่มีไฟล์ แอปยังเปิดได้ แค่ AI จะใช้ไม่ได้)
  try {
    await dotenv.load(fileName: '.env');
  } catch (_) {}

  // 2) ค่าตั้งค่าในเครื่อง + รูปแบบวันที่ของทั้ง 3 ภาษา
  // SettingsService มาจาก lib/services/settings_service.dart
  await SettingsService.instance.load();
  // ContentLanguage มาจาก lib/models/content_language.dart
  for (final language in ContentLanguage.values) {
    await initializeDateFormatting(language.code);
  }

  // 3) เชื่อม Firebase (ถ้าพลาด แสดงหน้าข้อผิดพลาดแทนการแครช)
  try {
    await Firebase.initializeApp(
      // DefaultFirebaseOptions มาจาก lib/firebase_options.dart
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    runApp(_StartupErrorApp(message: '$e'));
    return;
  }

  // AppRestarter มาจาก lib/core/app_restarter.dart
  runApp(const AppRestarter(child: KeepApp()));
}

class KeepApp extends StatefulWidget {
  const KeepApp({super.key});

  @override
  State<KeepApp> createState() => _KeepAppState();
}

class _KeepAppState extends State<KeepApp> {
  // สร้าง stream ครั้งเดียว (ถ้าสร้างใน build จะ subscribe ใหม่ทุกครั้งที่ rebuild)
  // AuthService มาจาก lib/services/auth_service.dart
  final Stream<User?> _authStream = AuthService().authStateChanges();

  @override
  Widget build(BuildContext context) {
    final settings = SettingsService.instance;
    // ธีม: ยังไม่ล็อกอิน = ตามโหมดสว่าง/มืดของเครื่อง (หน้าเปิดแอป + หน้า login เหมือนกัน)
    //       ล็อกอินแล้ว = ตามค่าที่ผู้ใช้ตั้งใน Settings
    return StreamBuilder<User?>(
      stream: _authStream,
      initialData: FirebaseAuth.instance.currentUser,
      builder: (context, auth) => ListenableBuilder(
        // ฟังค่า Dark Mode และภาษาของแอป: เปลี่ยนใน Settings แล้วทั้งแอปเปลี่ยนตามทันที
        listenable: Listenable.merge([
          settings.isDarkMode,
          settings.appLanguage,
        ]),
        builder: (context, _) => _app(settings, signedIn: auth.data != null),
      ),
    );
  }

  Widget _app(SettingsService settings, {required bool signedIn}) {
    return MaterialApp(
      title: 'KEEP',
      debugShowCheckedModeBanner: false,
      // AppTheme มาจาก lib/core/theme.dart
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: !signedIn
          ? ThemeMode.system
          : (settings.isDarkMode.value ? ThemeMode.dark : ThemeMode.light),
      // ภาษาของแอป: ข้อความทั้งหมดมาจากไฟล์ ARB (lib/l10n/arb) ตาม locale นี้
      locale: settings.appLanguage.value.locale,
      // AppLocalizations มาจาก lib/l10n/gen/app_localizations.dart
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        // ข้อความของ widget สำเร็จรูป (ปุ่ม, date picker, tooltip ของระบบ)
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      navigatorObservers: [routeObserver],
      home: const LaunchGate(),
    );
  }
}

/// เล่นหน้าเปิดแอป (โลโก้ + ไฟกะพริบ) ก่อน แล้วค่อยค่อยๆ เปลี่ยนไปหน้าแรกจริง (AuthGate)
class LaunchGate extends StatefulWidget {
  const LaunchGate({super.key});

  @override
  State<LaunchGate> createState() => _LaunchGateState();
}

class _LaunchGateState extends State<LaunchGate> {
  bool _launched = false;

  // ธีมมาจาก KeepApp แล้ว (ยังไม่ล็อกอิน = ตามเครื่อง) หน้าเปิดแอปจึงใช้ธีมเดียวกับหน้าถัดไปเสมอ
  // LaunchScreen มาจาก lib/screens/launch_screen.dart
  Widget _launchScreen(BuildContext context) => LaunchScreen(
    onDone: () => setState(() => _launched = true),
    sound: SettingsService.instance.launchSound.value,
  );

  @override
  Widget build(BuildContext context) => AnimatedSwitcher(
    // AppMotion มาจาก lib/core/motion.dart
    duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.page,
    switchInCurve: AppMotion.pageEnter,
    child: _launched ? const AuthGate() : _launchScreen(context),
  );
}

/// เลือกหน้าแรกตามสถานะล็อกอิน
///
/// StreamBuilder ฟัง authStateChanges() ตลอดเวลา:
/// - ล็อกอินสำเร็จ → stream ส่ง User มา → แสดง AppShell (แท็บคลัง/ทบทวน/สถิติ)
/// - Logout → stream ส่ง null → แสดง AuthScreen อัตโนมัติ
/// - เปิดแอปใหม่ Firebase จำการล็อกอินไว้ จึงเข้า Home ได้เลย
class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  // สร้าง stream ครั้งเดียวใน State ถ้าสร้างใน build() ทุกครั้งที่ rebuild (เช่น สลับธีม)
  // StreamBuilder จะ subscribe ใหม่และกระพริบเป็นหน้า loading
  final Stream<User?> _authStream = AuthService().authStateChanges();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: _authStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final user = snapshot.data;
        // AuthScreen มาจาก lib/screens/auth_screen.dart
        // AppShell มาจาก lib/screens/app_shell.dart
        return user == null ? const AuthScreen() : AppShell(user: user);
      },
    );
  }
}

class _StartupErrorApp extends StatelessWidget {
  const _StartupErrorApp({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              // context.l10n มาจาก lib/l10n/l10n.dart
              tr.errFirebaseInit(message),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
