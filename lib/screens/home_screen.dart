import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/radius.dart';
import '../core/app_exception.dart';
import '../core/motion.dart';
import '../core/navigation.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/article_tag.dart';
import '../models/reading_session.dart';
import '../models/reading_stats.dart';
import '../models/study_log.dart';
import '../models/user_profile.dart';
import '../services/bookmark_service.dart';
import '../services/greeting_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/study_log_repository.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/keep_app_bar.dart';
import '../widgets/score_badge.dart';
import '../widgets/stat_tile.dart';
import '../widgets/start_session_sheet.dart';
import '../widgets/ui_helpers.dart';
import 'onboarding_screen.dart';
import 'reading_screen.dart';
import 'summary_screen.dart';
import '../core/spacing.dart';

/// หน้าจอ 2: Home / ประวัติการอ่าน (CRUD: Read + Delete)
///
/// - คำทักทายด้วยชื่อเล่น + ประโยคประจำวันที่ AI คิดให้
/// - การ์ดสถิติที่เล่น effect นับคะแนนใหม่ทุกครั้งที่กลับมาหน้านี้ (RouteAware)
/// - การ์ด "กำลังอ่านค้างอยู่" + ล็อกปุ่มสุ่มระหว่างมีเซสชันค้าง
/// - รายการบันทึกพร้อมแท็ก (ไม่เกิน 3)
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.user,
    required this.onOpenProfile,
  });

  final User user;

  /// เปิดหน้าโปรไฟล์ (มาจาก AppShell ซึ่งเป็นเจ้าของการนำทาง)
  final VoidCallback onOpenProfile;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

/// RouteAware: ให้ RouteObserver (ใน main.dart) แจ้งเมื่อหน้านี้ถูกกลับมาแสดงอีกครั้ง
class _HomeScreenState extends State<HomeScreen> with RouteAware {
  final _repo = StudyLogRepository();
  final _sessions = SessionService.instance;
  final _profiles = ProfileService.instance;
  late Stream<List<StudyLog>> _logsStream;

  /// งานโหลดเซสชันจากเครื่อง: เก็บ Future ไว้ เพื่อให้ปุ่มสุ่มรอจนโหลดเสร็จก่อนตัดสินใจล็อก
  late final Future<void> _sessionLoaded;

  /// บทความที่เคยอ่านแล้ว (Article.readKey) ส่งให้หน้าอ่านเพื่อไม่สุ่มซ้ำ
  /// null = ประวัติยังโหลดไม่เสร็จ (ยังไม่ให้สุ่ม ไม่งั้นอาจได้เรื่องที่อ่านแล้ว)
  Set<String>? _readKeys;

  /// เพิ่มทุกครั้งที่กลับมาหน้านี้ → ใช้เป็น Key ของการ์ดสถิติ ให้สร้างใหม่และเล่น effect อีกรอบ
  int _replay = 0;

  bool _setupShown = false;

  @override
  void initState() {
    super.initState();
    // สร้าง stream ครั้งเดียว: Firestore จะส่งข้อมูลชุดใหม่มาเองทุกครั้งที่มีการเพิ่ม/แก้/ลบ
    _logsStream = _repo.watchLogs(widget.user.uid);
    // โหลดเซสชันที่ค้างไว้ของผู้ใช้คนนี้จากเครื่อง (ไม่ await ใน initState การ์ดจะโผล่เองเมื่อโหลดเสร็จ)
    _sessionLoaded = _sessions.load(widget.user.uid);
    BookmarkService.instance.load(widget.user.uid);
    // ผู้ใช้ใหม่ (ยังไม่มีโปรไฟล์) → เปิดหน้าตั้งค่าเริ่มต้น
    _profiles.needsSetup.addListener(_openSetupIfNeeded);
    _profiles.load(widget.user);
    GreetingService.instance.load();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route is PageRoute<void>) routeObserver.subscribe(this, route);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    _profiles.needsSetup.removeListener(_openSetupIfNeeded);
    super.dispose();
  }

  /// เรียกเมื่อหน้าที่ซ้อนอยู่ถูกปิด แล้วหน้านี้กลับมาแสดง → เล่น effect นับคะแนนใหม่
  @override
  void didPopNext() => setState(() => _replay++);

  void _openSetupIfNeeded() {
    if (!_profiles.needsSetup.value || _setupShown || !mounted) return;
    _setupShown = true;
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => OnboardingScreen(user: widget.user),
      ),
    );
  }

  /// กดปุ่มสุ่ม: ถ้ามีเซสชันค้างอยู่จะไม่ให้สุ่มใหม่ ต้องอ่าน/สรุปเรื่องเดิมให้จบก่อน
  Future<void> _startNew() async {
    // ถ้ากดเร็วมากตอนเพิ่งเปิดแอป เซสชันอาจยังโหลดไม่เสร็จ ต้องรอก่อน ไม่งั้นจะสุ่มทับเรื่องเดิม
    await _sessionLoaded;
    if (!mounted || _readKeys == null) return;
    if (_sessions.current.value != null) {
      showMessage(context, context.l10n.sessionLockedMessage);
      return;
    }
    final topic = await showStartSessionSheet(context);
    if (topic == null || !mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ReadingScreen.start(
          language: SettingsService.instance.articleLanguage.value,
          topic: topic,
          excludeKeys: _readKeys!,
        ),
      ),
    );
  }

  /// แตะการ์ดเซสชัน: อ่านต่อ (ถ้ายังอ่านไม่จบ) หรือไปเขียนสรุปต่อ (ถ้าอ่านจบแล้ว)
  void _resume(ReadingSession session) => Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => session.stage == SessionStage.reading
          ? ReadingScreen.resume(session: session)
          : SummaryScreen.fromSession(session: session),
    ),
  );

  Future<void> _discardSession(ReadingSession session) async {
    final ok = await confirmDialog(
      context,
      title: context.l10n.discardSessionTitle,
      message: context.l10n.discardSessionMessage(session.article.title),
      confirmLabel: context.l10n.discard,
      destructive: true,
    );
    if (ok) await _sessions.clear();
  }

  void _openLog(StudyLog log) => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => SummaryScreen.edit(log: log)),
  );

  /// คืนค่า true เมื่อลบสำเร็จ (Dismissible ใช้ค่านี้ตัดสินว่าจะเอาการ์ดออกหรือเด้งกลับ)
  Future<bool> _delete(StudyLog log) async {
    try {
      await _repo.delete(log.id);
      if (mounted) {
        showMessage(context, context.l10n.deletedMessage(log.articleTitle));
      }
      return true;
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
      return false;
    }
  }

  /// ถามยืนยัน → ลบจริง → ถ้าลบไม่สำเร็จ การ์ดจะเด้งกลับที่เดิม ไม่หายไปเฉยๆ
  Future<bool> _confirmAndDelete(StudyLog log) async {
    final ok = await confirmDialog(
      context,
      title: context.l10n.deleteLogTitle,
      message: context.l10n.deleteLogMessage(log.articleTitle),
      confirmLabel: context.l10n.delete,
      destructive: true,
    );
    if (!ok) return false;
    return _delete(log);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Scaffold(
      appBar: KeepAppBar(onOpenProfile: widget.onOpenProfile),
      // StreamBuilder: rebuild รายการเองทุกครั้งที่ข้อมูลใน Firestore เปลี่ยน (realtime)
      body: StreamBuilder<List<StudyLog>>(
        stream: _logsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return ErrorView(
              message: l10n.historyLoadError('${snapshot.error}'),
              onRetry: () => setState(() {
                _logsStream = _repo.watchLogs(widget.user.uid);
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final logs = snapshot.data!;
          _readKeys = {
            for (final log in logs)
              if (log.readKey != null) log.readKey!,
          };
          final stats = ReadingStats.from(logs);

          return ListView(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              top: AppSpacing.xs,
              right: AppSpacing.md,
              // เว้นที่ให้แถบเมนูแคปซูลที่ลอยทับด้านล่าง
              bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
            ),
            children: [
              EntranceFade(
                child: _HeroCard(stats: stats, replay: _replay),
              ),
              const SizedBox(height: AppSpacing.xl),
              // จุดเด่นของหน้า: มีเรื่องค้าง → การ์ดอ่านต่อ, ไม่มี → การ์ดสุ่มบทความ
              // (สุ่มใหม่ไม่ได้จนกว่าจะอ่าน/สรุปเรื่องเดิมจบ จึงไม่ต้องแสดงปุ่มที่ถูกล็อก)
              ValueListenableBuilder<ReadingSession?>(
                valueListenable: _sessions.current,
                builder: (context, session, _) => EntranceFade(
                  index: 1,
                  child: Pressable(
                    child: session == null
                        ? _RandomArticleCard(onTap: _startNew)
                        : _SessionCard(
                            session: session,
                            onTap: () => _resume(session),
                            onDiscard: () => _discardSession(session),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              _SectionHeader(icon: Icons.history, title: l10n.historyTitle),
              const SizedBox(height: AppSpacing.sm),
              if (logs.isEmpty)
                const EntranceFade(index: 2, child: _EmptyState()),
              // indexed = ได้ลำดับ (i) มาด้วย ใช้ไล่ให้การ์ดเข้ามาทีละใบ
              for (final (i, log) in logs.indexed)
                // Dismissible = ปัดซ้ายเพื่อลบ, confirmDismiss ถามยืนยันและลบให้เสร็จก่อน
                Dismissible(
                  key: ValueKey(log.id),
                  direction: DismissDirection.endToStart,
                  confirmDismiss: (_) => _confirmAndDelete(log),
                  background: Container(
                    alignment: AlignmentDirectional.centerEnd,
                    padding: const EdgeInsetsDirectional.only(
                      end: AppSpacing.xl,
                    ),
                    margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: AppRadius.cardAll,
                    ),
                    child: Icon(
                      Icons.delete_outline,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                  // Dismissible มี Key = log.id → การ์ดเดิมไม่ถูกสร้างใหม่ตอนข้อมูลอัปเดต
                  // effect ปรากฏจึงเล่นแค่ครั้งแรก (และกับการ์ดใหม่ที่เพิ่งบันทึก)
                  child: EntranceFade(
                    index: i + 2,
                    child: Pressable(
                      child: _LogCard(
                        log: log,
                        onTap: () => _openLog(log),
                        onDelete: () => _confirmAndDelete(log),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.md),
              const _TipCard(),
            ],
          );
        },
      ),
    );
  }
}

/// การ์ดบนสุด: ชื่อ + วันติดกัน, ประโยคประจำวันจาก AI, สถิติ 3 ช่อง และเป้าหมายวันนี้
/// มุมขวาบนมีแสงอำพันจางๆ แบบเดียวกับโคมไฟในหน้าอ่าน
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.stats, required this.replay});

  final ReadingStats stats;
  final int replay;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final lamp = ReadingLampColors.of(context);
    final l10n = context.l10n;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: AppRadius.cardAll,
        gradient: RadialGradient(
          center: const Alignment(1, -1),
          radius: 0.8,
          colors: [
            lamp.glowHalo.withValues(alpha: 0.08 * lamp.glowStrength),
            // จางเป็นอำพันโปร่งใส (ไม่ใช่สีพื้น) ไม่งั้นช่วงกลางจะไล่สีผ่านโทนน้ำตาลขุ่น
            lamp.glowHalo.withValues(alpha: 0),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: ValueListenableBuilder<UserProfile?>(
                    valueListenable: ProfileService.instance.current,
                    builder: (context, profile, _) => Text(
                      l10n.helloName(profile?.nickname ?? ''),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                _StreakPill(days: stats.streakDays),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            ValueListenableBuilder<String?>(
              valueListenable: GreetingService.instance.text,
              // AnimatedSwitcher: ข้อความสำรอง → ข้อความจาก AI ค่อยๆ fade เปลี่ยน ไม่กระพริบ
              builder: (context, text, _) => AnimatedSwitcher(
                duration: AppMotion.reduced(context)
                    ? Duration.zero
                    : Durations.long2,
                child: Text(
                  GreetingService.display(text, l10n),
                  key: ValueKey(text),
                  style: theme.textTheme.headlineSmall,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            // สูงเท่ากันทุกช่อง แม้ป้ายบางช่องยาวจนขึ้นบรรทัดใหม่
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: StatTile(
                      key: ValueKey('total-$replay'),
                      value: stats.totalMinutes,
                      unit: l10n.unitMinutes,
                      label: l10n.statTotalTime,
                      color: scheme.primary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: StatTile(
                      key: ValueKey('read-$replay'),
                      value: stats.articles,
                      label: l10n.statRead,
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Expanded(
                    child: StatTile(
                      key: ValueKey('avg-$replay'),
                      value: stats.averageScore,
                      unit: '/100',
                      label: l10n.statAvgScore,
                      color: scheme.secondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            ValueListenableBuilder<int>(
              valueListenable: SettingsService.instance.timerMinutes,
              builder: (context, goal, _) =>
                  _DailyGoal(done: stats.todayMinutes, goal: goal),
            ),
          ],
        ),
      ),
    );
  }
}

/// ป้ายวันติดกัน: เปลวไฟสีอำพัน (สีเดียวกับแสงโคมไฟ)
class _StreakPill extends StatelessWidget {
  const _StreakPill({required this.days});

  final int days;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final active = days > 0;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs + 2,
      ),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active
                ? Icons.local_fire_department
                : Icons.local_fire_department_outlined,
            size: 18,
            color: active ? scheme.tertiary : scheme.outline,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            active ? l10n.streakDays(days) : l10n.streakStart,
            style: theme.textTheme.labelMedium?.copyWith(
              color: active ? scheme.tertiary : scheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

/// เป้าหมายวันนี้ = อ่านครบ 1 รอบตามเวลาที่ตั้งไว้ใน Settings
class _DailyGoal extends StatelessWidget {
  const _DailyGoal({required this.done, required this.goal});

  final int done;
  final int goal;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final met = done >= goal;
    final progress = goal <= 0 ? 1.0 : (done / goal).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.todayGoal(done, goal),
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ),
            if (met) ...[
              Icon(Icons.check_circle, size: 16, color: scheme.primary),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(
                child: Text(
                  l10n.todayGoalMet,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.primary,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: progress),
          duration: AppMotion.reduced(context)
              ? Duration.zero
              : Durations.long4,
          curve: AppMotion.entranceCurve,
          builder: (context, value, _) => LinearProgressIndicator(
            value: value,
            minHeight: 6,
            borderRadius: AppRadius.pillAll,
            color: scheme.primary,
            backgroundColor: scheme.surfaceContainerHigh,
            semanticsLabel: l10n.todayGoal(done, goal),
          ),
        ),
      ],
    );
  }
}

/// การ์ดสุ่มบทความใหม่ (แทนปุ่มลอยเดิม): แตะแล้วไอคอนสุ่มหมุนครึ่งรอบ
class _RandomArticleCard extends StatefulWidget {
  const _RandomArticleCard({required this.onTap});

  final VoidCallback onTap;

  @override
  State<_RandomArticleCard> createState() => _RandomArticleCardState();
}

class _RandomArticleCardState extends State<_RandomArticleCard> {
  double _turns = 0;

  void _tap() {
    if (!AppMotion.reduced(context)) setState(() => _turns += 0.5);
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final language = SettingsService.instance.articleLanguage.value.label;
    return Material(
      color: scheme.secondaryContainer,
      borderRadius: AppRadius.cardAll,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: _tap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.3),
                  borderRadius: AppRadius.controlAll,
                ),
                child: AnimatedRotation(
                  turns: _turns,
                  duration: Durations.long2,
                  curve: AppMotion.entranceCurve,
                  child: Icon(Icons.shuffle, color: scheme.primary),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.randomArticle,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.randomArticleSubtitle(language),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Icon(Icons.arrow_forward, color: scheme.onSurface),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(title, style: theme.textTheme.titleLarge)),
        ],
      ),
    );
  }
}

/// เคล็ดลับการจำ: เปลี่ยนวันละข้อ (เลือกตามวันของปี)
class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final tips = [
      l10n.recallTip1,
      l10n.recallTip2,
      l10n.recallTip3,
      l10n.recallTip4,
    ];
    final now = DateTime.now();
    final dayOfYear = now.difference(DateTime(now.year)).inDays;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppRadius.cardAll,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: scheme.surfaceContainerHigh,
              borderRadius: AppRadius.controlAll,
            ),
            child: Icon(Icons.lightbulb_outline, color: scheme.tertiary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.tipTitle, style: theme.textTheme.labelLarge),
                const SizedBox(height: AppSpacing.xxs),
                Text(
                  tips[dayOfYear % tips.length],
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// การ์ด "กำลังอ่านค้างอยู่" หน้าตาเหมือนการ์ดประวัติ แต่มีป้ายสถานะและเวลาที่เหลือ
class _SessionCard extends StatelessWidget {
  const _SessionCard({
    required this.session,
    required this.onTap,
    required this.onDiscard,
  });

  final ReadingSession session;
  final VoidCallback onTap;
  final VoidCallback onDiscard;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final reading = session.stage == SessionStage.reading;
    final left = Duration(seconds: session.remainingSeconds);
    final mm = left.inMinutes.toString().padLeft(2, '0');
    final ss = (left.inSeconds % 60).toString().padLeft(2, '0');
    final article = session.article;

    return Card(
      margin: EdgeInsets.zero,
      color: scheme.secondaryContainer,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            top: AppSpacing.md,
            end: AppSpacing.xxs,
            bottom: AppSpacing.md,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: scheme.surface.withValues(alpha: 0.3),
                  borderRadius: AppRadius.controlAll,
                ),
                child: Icon(
                  reading ? Icons.pause : Icons.edit_note,
                  color: scheme.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(
                      label: reading
                          ? l10n.sessionReading
                          : l10n.sessionSummarizing,
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      [
                        article.language.label,
                        if (article.topic != null)
                          tagLabel(article.topic!, l10n),
                        reading
                            ? l10n.timeLeft('$mm:$ss')
                            : l10n.readForMinutes(session.readingMinutes),
                      ].join(' · '),
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSecondaryContainer,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      reading ? l10n.tapToResume : l10n.tapToSummarize,
                      style: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: l10n.options,
                onSelected: (_) => onDiscard(),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'discard',
                    child: Text(l10n.discardArticle),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: 2,
      ),
      decoration: ShapeDecoration(
        color: scheme.primary,
        shape: const StadiumBorder(),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: scheme.onPrimary),
      ),
    );
  }
}

/// การ์ดประวัติ 1 รายการ (แบบ Stitch): แท็ก + เวลาอ่าน | ป้ายคะแนน, ชื่อเรื่อง, คำสรุปย่อ,
/// แถบความจำตามระดับคะแนน และวันที่ + ปุ่มลบ
class _LogCard extends StatelessWidget {
  const _LogCard({
    required this.log,
    required this.onTap,
    required this.onDelete,
  });

  final StudyLog log;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final level = ScoreLevel.of(log.aiScore);
    // วันที่แสดงตามภาษาของแอป
    final date = DateFormat(
      'd MMM yyyy · HH:mm',
      SettingsService.instance.appLanguage.value.code,
    ).format(log.createdAt);
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsetsDirectional.only(
            start: AppSpacing.md,
            top: AppSpacing.md,
            end: AppSpacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        for (final tag in log.tags) _TagPill(tag: tag),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.schedule,
                              size: 14,
                              color: scheme.outline,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              l10n.readForMinutes(log.readingTimeMinutes),
                              style: muted,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  ScorePill(score: log.aiScore),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                log.articleTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: AppSpacing.xxs),
              Text(
                log.userSummary,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              // แถบความจำ: ยาวตามคะแนน สีตามระดับ (ยังไม่ประเมิน = ไม่มีแถบ)
              Row(
                children: [
                  if (log.aiScore != null) ...[
                    Expanded(
                      child: ExcludeSemantics(
                        child: LinearProgressIndicator(
                          value: log.aiScore! / 100,
                          minHeight: 6,
                          borderRadius: AppRadius.pillAll,
                          color: level.color(scheme),
                          backgroundColor: scheme.surfaceContainer,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                  ],
                  Text(
                    level.label(l10n),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: level.color(scheme),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      [log.language.label, date].join(' · '),
                      style: muted,
                    ),
                  ),
                  IconButton(
                    tooltip: l10n.delete,
                    icon: const Icon(Icons.delete_outline),
                    color: scheme.onSurfaceVariant,
                    onPressed: onDelete,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// ป้ายแท็กเล็กๆ บนการ์ดบันทึก
class _TagPill extends StatelessWidget {
  const _TagPill({required this.tag});

  final String tag;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ArticleTag.fromId(tag)?.icon ?? Icons.tag,
            size: 12,
            color: scheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppSpacing.xxs),
          Text(
            tagLabel(tag, context.l10n),
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            size: 64,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(l10n.emptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            l10n.emptyBody,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
