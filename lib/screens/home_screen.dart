import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/app_exception.dart';
import '../core/navigation.dart';
import '../l10n/l10n.dart';
import '../models/article_tag.dart';
import '../models/reading_session.dart';
import '../models/study_log.dart';
import '../models/user_profile.dart';
import '../services/greeting_service.dart';
import '../services/profile_service.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/study_log_repository.dart';
import '../widgets/animated_counter.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/score_badge.dart';
import '../widgets/start_session_sheet.dart';
import '../widgets/ui_helpers.dart';
import 'onboarding_screen.dart';
import 'profile_screen.dart';
import 'reading_screen.dart';
import 'summary_screen.dart';
import '../core/spacing.dart';
import '../core/theme.dart';

/// หน้าจอ 2: Home / ประวัติการอ่าน (CRUD: Read + Delete)
///
/// - คำทักทายด้วยชื่อเล่น + ประโยคประจำวันที่ AI คิดให้
/// - การ์ดสถิติที่เล่น effect นับคะแนนใหม่ทุกครั้งที่กลับมาหน้านี้ (RouteAware)
/// - การ์ด "กำลังอ่านค้างอยู่" + ล็อกปุ่มสุ่มระหว่างมีเซสชันค้าง
/// - รายการบันทึกพร้อมแท็ก (ไม่เกิน 3)
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.user});

  final User user;

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

  void _openProfile() => Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => ProfileScreen(user: widget.user)),
  );

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
      appBar: AppBar(
        title: Text('KEEP', style: AppTheme.wordmark(context)),
        actions: [
          IconButton(
            tooltip: l10n.profileSettingsTooltip,
            icon: const Icon(Icons.settings_outlined),
            onPressed: _openProfile,
          ),
        ],
      ),
      // ฟังเซสชัน: มีเซสชันค้าง → ปุ่มกลายเป็นสีเทาพร้อมไอคอนแม่กุญแจ
      floatingActionButton: ValueListenableBuilder<ReadingSession?>(
        valueListenable: _sessions.current,
        builder: (context, session, _) {
          final locked = session != null;
          final scheme = Theme.of(context).colorScheme;
          return FloatingActionButton.extended(
            onPressed: _startNew,
            backgroundColor: locked ? scheme.surfaceContainerHighest : null,
            foregroundColor: locked ? scheme.outline : null,
            icon: Icon(locked ? Icons.lock_outline : Icons.shuffle),
            label: Text(locked ? l10n.finishCurrentFirst : l10n.randomArticle),
          );
        },
      ),
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

          return ListView(
            padding: const EdgeInsets.only(
              left: AppSpacing.md,
              top: AppSpacing.xs,
              right: AppSpacing.md,
              bottom: AppSpacing.fabClearance,
            ),
            children: [
              const EntranceFade(child: _Greeting()),
              const SizedBox(height: 16),
              ValueListenableBuilder<ReadingSession?>(
                valueListenable: _sessions.current,
                builder: (context, session, _) => session == null
                    ? const SizedBox.shrink()
                    : EntranceFade(
                        index: 1,
                        child: Pressable(
                          child: _SessionCard(
                            session: session,
                            onTap: () => _resume(session),
                            onDiscard: () => _discardSession(session),
                          ),
                        ),
                      ),
              ),
              _StatsRow(logs: logs, replay: _replay),
              const SizedBox(height: 16),
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
                    padding: const EdgeInsetsDirectional.only(end: 24),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.errorContainer,
                      borderRadius: BorderRadius.circular(16),
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
            ],
          );
        },
      ),
    );
  }
}

/// "สวัสดี, ชื่อเล่น" + ประโยคชวนเรียนรู้ประจำวันที่ AI คิดให้ (มีข้อความสำรองถ้า AI ล่ม)
class _Greeting extends StatelessWidget {
  const _Greeting();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ValueListenableBuilder<UserProfile?>(
          valueListenable: ProfileService.instance.current,
          builder: (context, profile, _) => Text(
            l10n.helloName(profile?.nickname ?? ''),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 4),
        ValueListenableBuilder<String?>(
          valueListenable: GreetingService.instance.text,
          // AnimatedSwitcher: ข้อความสำรอง → ข้อความจาก AI ค่อยๆ fade เปลี่ยน ไม่กระพริบ
          builder: (context, text, _) => AnimatedSwitcher(
            duration: const Duration(milliseconds: 500),
            child: Text(
              GreetingService.display(text, l10n),
              key: ValueKey(text),
              style: theme.textTheme.bodyLarge?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// การ์ดสถิติ 3 ใบ เปิดตัวไล่กัน (0 / 150 / 300 ms) และเล่นใหม่ทุกครั้งที่ replay เปลี่ยน
class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.logs, required this.replay});

  final List<StudyLog> logs;
  final int replay;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final scored = logs.where((l) => l.isEvaluated).toList();
    final avg = scored.isEmpty
        ? null
        : (scored.map((l) => l.aiScore!).reduce((a, b) => a + b) /
                  scored.length)
              .round();
    final minutes = logs.fold<int>(0, (sum, l) => sum + l.readingTimeMinutes);

    // จุดเด่นของหน้า = เวลาอ่านสะสม (สิ่งที่แอปนี้ช่วยสร้าง) การ์ดใหญ่เต็มความกว้าง
    // จำนวนบทความและคะแนนเฉลี่ยเป็นข้อมูลรอง อยู่แถวล่างเล็กลง
    final secondary = [
      (Icons.menu_book_outlined, l10n.statRead, logs.length, l10n.unitArticles),
      (Icons.verified_outlined, l10n.statAvgScore, avg, '/100'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        StatRevealCard(
          // Key เปลี่ยน = Flutter สร้างการ์ดใหม่ = effect เริ่มเล่นใหม่
          key: ValueKey('stat-total-$replay'),
          icon: Icons.timer_outlined,
          label: l10n.statTotalTime,
          value: minutes,
          unit: l10n.unitMinutes,
          caption: l10n.statAllTime,
          highlight: true,
          prominent: true,
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < secondary.length; i++) ...[
              if (i > 0) const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: StatRevealCard(
                  key: ValueKey('stat-$i-$replay'),
                  icon: secondary[i].$1,
                  label: secondary[i].$2,
                  value: secondary[i].$3,
                  unit: secondary[i].$4,
                  caption: l10n.statAllTime,
                  delay: Duration(milliseconds: 150 * (i + 1)),
                ),
              ),
            ],
          ],
        ),
      ],
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
      margin: const EdgeInsets.only(bottom: 16),
      color: scheme.primaryContainer.withValues(alpha: 0.45),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: scheme.primary, width: 1.5),
      ),
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
              CircleAvatar(
                radius: 24,
                backgroundColor: scheme.primary,
                foregroundColor: scheme.onPrimary,
                child: Icon(reading ? Icons.pause : Icons.edit_note),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StatusBadge(
                      label: reading
                          ? l10n.sessionReading
                          : l10n.sessionSummarizing,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      article.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      [
                        article.language.label,
                        if (article.topic != null)
                          tagLabel(article.topic!, l10n),
                        reading
                            ? l10n.timeLeft('$mm:$ss')
                            : l10n.readForMinutes(session.readingMinutes),
                      ].join(' · '),
                      style: theme.textTheme.labelMedium,
                    ),
                    const SizedBox(height: 6),
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: scheme.primary,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: Theme.of(
          context,
        ).textTheme.labelMedium?.copyWith(color: scheme.onPrimary),
      ),
    );
  }
}

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
    final l10n = context.l10n;
    // วันที่แสดงตามภาษาของแอป
    final date = DateFormat(
      'd MMM yyyy · HH:mm',
      SettingsService.instance.appLanguage.value.code,
    ).format(log.createdAt);
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
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
              ScoreBadge(score: log.aiScore, size: 48),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      log.articleTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      log.userSummary,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (log.tags.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final tag in log.tags) _TagPill(tag: tag),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Text(
                      [
                        log.language.label,
                        date,
                        l10n.readForMinutes(log.readingTimeMinutes),
                        if (!log.isEvaluated) l10n.notEvaluated,
                      ].join(' · '),
                      style: theme.textTheme.labelSmall,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: l10n.delete,
                icon: const Icon(Icons.delete_outline),
                onPressed: onDelete,
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            ArticleTag.fromId(tag)?.icon ?? Icons.tag,
            size: 12,
            color: scheme.onSecondaryContainer,
          ),
          const SizedBox(width: 4),
          Text(
            tagLabel(tag, context.l10n),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: scheme.onSecondaryContainer,
            ),
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
          const SizedBox(height: 16),
          Text(l10n.emptyTitle, style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
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
