import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/app_exception.dart';
import '../core/theme.dart';
import '../models/article.dart';
import '../l10n/l10n.dart';
import '../models/content_language.dart';
import '../models/reading_session.dart';
import '../models/reading_topic.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/sources/article_source.dart';
import '../services/tts_service.dart';
import '../widgets/reading_lamp.dart';
import '../widgets/ui_helpers.dart';
import 'summary_screen.dart';
import '../core/spacing.dart';

/// หน้าจอ 3: อ่านบทความพร้อมจับเวลาถอยหลัง + เสียงอ่าน (TTS)
///
/// เปิดได้ 2 แบบ:
/// - ReadingScreen.start:  สุ่มบทความใหม่ตามหมวดที่เลือก แล้วสร้างเซสชัน
/// - ReadingScreen.resume: อ่านต่อจากเซสชันที่พักไว้ (เวลานับต่อจากเดิม)
class ReadingScreen extends StatefulWidget {
  const ReadingScreen.start({
    super.key,
    required ContentLanguage this.language,
    required ReadingTopic this.topic,
    required Set<String> this.excludeKeys,
  }) : session = null;

  const ReadingScreen.resume({super.key, required ReadingSession this.session})
    : language = null,
      topic = null,
      excludeKeys = null;

  final ContentLanguage? language;
  final ReadingTopic? topic;

  /// บทความที่เคยอ่านแล้ว (Article.readKey) ห้ามสุ่มซ้ำ
  final Set<String>? excludeKeys;
  final ReadingSession? session;

  @override
  State<ReadingScreen> createState() => _ReadingScreenState();
}

class _ReadingScreenState extends State<ReadingScreen>
    with WidgetsBindingObserver {
  /// แหล่งข้อมูลที่เลือกใน Settings (ตอนนี้คือ Wikipedia)
  final _source = ArticleSources.byId(SettingsService.instance.sourceId.value);
  final _sessions = SessionService.instance;
  final _tts = TtsService.create();

  ReadingSession? _session;
  String? _error;
  bool _loading = false;
  bool _ttsLanguageReady = false;

  // ---- Timer ----
  // _baseElapsed = เวลาที่อ่านไปแล้วจากรอบก่อนๆ (ตอนอ่านต่อจากที่พักไว้)
  // Stopwatch นับเวลาของรอบนี้, Timer.periodic แค่สั่งให้หน้าจอวาดใหม่ทุก 1 วินาที
  Duration _baseElapsed = Duration.zero;
  final _stopwatch = Stopwatch();
  Timer? _ticker;
  bool _timeUpHandled = false;

  /// true = เวลาถูกพักเพราะออกจากแอป/เปิด Control Center (ไม่ใช่ผู้ใช้กดพัก)
  bool _pausedBySystem = false;

  /// กันกด "ไปเขียนสรุป" ซ้ำระหว่างรอบันทึก (ไม่งั้นจะเปิดหน้าสรุป 2 รอบ)
  bool _navigating = false;

  /// วินาทีล่าสุดที่บันทึกไปแล้ว (กันบันทึกซ้ำ/ข้าม เวลา tick ไม่ตรงวินาทีพอดี)
  int _lastPersistedSecond = 0;

  /// GlobalKey ของแต่ละย่อหน้า ใช้เลื่อนจอไปย่อหน้าที่ TTS กำลังอ่าน
  List<GlobalKey> _paragraphKeys = [];

  Article? get _article => _session?.article;
  Duration get _elapsed => _baseElapsed + _stopwatch.elapsed;
  Duration get _limit => Duration(seconds: _session?.limitSeconds ?? 0);
  Duration get _remaining {
    final left = _limit - _elapsed;
    return left.isNegative ? Duration.zero : left;
  }

  @override
  void initState() {
    super.initState();
    // ฟังสถานะแอป: ถ้าผู้ใช้สลับไปแอปอื่น จะพักเวลาและบันทึกเซสชันให้อัตโนมัติ
    WidgetsBinding.instance.addObserver(this);
    _tts.currentParagraph.addListener(_scrollToCurrentParagraph);

    final resumed = widget.session;
    if (resumed != null) {
      _setSession(resumed);
      _startTimer();
    } else {
      _loadArticle();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    // ออกจากหน้า (ทุกกรณี): หยุดเสียง, หยุดเวลา, บันทึกเวลาที่อ่านไปล่าสุด
    _ticker?.cancel();
    _stopwatch.stop();
    _persist();
    _tts.currentParagraph.removeListener(_scrollToCurrentParagraph);
    _tts.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // จำไว้ว่าระบบเป็นคนพัก (ไม่ใช่ผู้ใช้กดพักเอง) กลับเข้าแอปจะได้จับเวลาต่อให้
      if (_stopwatch.isRunning) _pausedBySystem = true;
      _pauseTimer();
    } else if (state == AppLifecycleState.resumed && _pausedBySystem) {
      _pausedBySystem = false;
      if (_remaining > Duration.zero) _startTimer();
    }
  }

  void _setSession(ReadingSession session) {
    _session = session;
    _baseElapsed = Duration(seconds: session.elapsedSeconds);
    _stopwatch.reset();
    _paragraphKeys = List.generate(
      session.article.paragraphs.length,
      (_) => GlobalKey(),
    );
  }

  /// สุ่มบทความใหม่ (async): ได้บทความแล้วสร้างเซสชันและบันทึกลงเครื่องทันที
  Future<void> _loadArticle() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final article = await _source.fetchRandomArticle(
        language: widget.language!,
        topic: widget.topic!,
        excludeKeys: widget.excludeKeys!,
      );
      if (!mounted) return;
      final session = ReadingSession(
        article: article,
        limitSeconds: SettingsService.instance.timerMinutes.value * 60,
        elapsedSeconds: 0,
        stage: SessionStage.reading,
        draftSummary: '',
        updatedAt: DateTime.now(),
      );
      await _sessions.save(session);
      if (!mounted) return;
      setState(() {
        _setSession(session);
        _loading = false;
      });
      _startTimer(); // ได้บทความแล้วเริ่มจับเวลาทันที
    } on TopicExhaustedException {
      // หมวดนี้อ่านครบหมดแล้ว → กลับหน้าแรกพร้อมบอกว่าหมดของแหล่งข้อมูลไหน
      if (!mounted) return;
      final topic = widget.topic!;
      showMessage(
        context,
        context.l10n.topicExhausted(
          topic.preset?.label(context.l10n) ?? topic.query ?? '',
          _source.name,
          widget.language!.label,
        ),
      );
      Navigator.pop(context);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// บันทึกเวลาที่อ่านไปแล้วลงเครื่อง (เรียกตอนพัก, ทุก 10 วินาที และตอนออกจากหน้า)
  Future<void> _persist() async {
    final session = _session;
    if (session == null || session.stage != SessionStage.reading) return;
    final updated = session.copyWith(elapsedSeconds: _elapsed.inSeconds);
    _session = updated;
    await _sessions.save(updated);
  }

  void _startTimer() {
    if (_session == null) return;
    _stopwatch.start();
    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
      if (_elapsed.inSeconds - _lastPersistedSecond >= 10) {
        _lastPersistedSecond = _elapsed.inSeconds;
        _persist();
      }
      if (_remaining == Duration.zero) _onTimeUp();
    });
    if (mounted) setState(() {});
  }

  /// พักเวลา = พักเสียงอ่านด้วย และบันทึกเวลาลงเครื่อง
  void _pauseTimer() {
    _stopwatch.stop();
    _ticker?.cancel();
    if (_tts.status.value == TtsStatus.playing) _tts.pause();
    _persist();
    if (mounted) setState(() {});
  }

  /// "พักไว้อ่านทีหลัง": บันทึกแล้วกลับหน้าแรก (การ์ดอ่านต่อจะไปโผล่ที่หน้า Home)
  void _pauseAndExit() {
    _pauseTimer();
    showMessage(context, context.l10n.pausedMessage);
    Navigator.pop(context);
  }

  Future<void> _onTimeUp() async {
    if (_timeUpHandled) return;
    _timeUpHandled = true;
    _pauseTimer();
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text(context.l10n.timeUpTitle),
        content: Text(context.l10n.timeUpBody),
        actions: [
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
            onPressed: () => Navigator.pop(context),
            child: Text(context.l10n.goSummarize),
          ),
        ],
      ),
    );
    if (mounted) _goToSummary();
  }

  /// ไปหน้าสรุป: เปลี่ยนเซสชันเป็นขั้น "กำลังสรุป" แล้วบันทึก
  /// ใช้ pushReplacement เพื่อไม่ให้กดย้อนกลับมาดูบทความได้ (Active Recall)
  Future<void> _goToSummary() async {
    final session = _session;
    if (session == null || _navigating) return;
    _navigating = true;
    _pauseTimer();
    await _tts.stop();
    final next = session.copyWith(
      elapsedSeconds: _elapsed.inSeconds,
      stage: SessionStage.summarizing,
    );
    _session = next;
    await _sessions.save(next);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => SummaryScreen.fromSession(session: next),
      ),
    );
  }

  // ---------- TTS ----------

  Future<void> _playTts() async {
    final article = _article;
    if (article == null) return;
    try {
      if (!_ttsLanguageReady) {
        // ภาษาเสียงจาก Settings (null = AUTO อ่านตามภาษาของบทความ)
        final voice =
            SettingsService.instance.ttsLanguage.value ?? article.language;
        await _tts.setLanguage(voice);
        _ttsLanguageReady = true;
      }
      await _tts.setRate(SettingsService.instance.ttsRate.value);
      // ฟังเสียง = กำลังอ่าน เวลาต้องเดินด้วย
      if (!_stopwatch.isRunning && _remaining > Duration.zero) _startTimer();
      await _tts.play(article.paragraphs);
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } catch (_) {
      if (mounted) {
        showMessage(context, context.l10n.ttsError, isError: true);
      }
    }
  }

  Future<void> _cycleRate() async {
    const options = SettingsService.ttsRateOptions;
    final settings = SettingsService.instance;
    final next =
        options[(options.indexOf(settings.ttsRate.value) + 1) % options.length];
    await settings.setTtsRate(next);
    // กำลังเล่นอยู่: เริ่มย่อหน้าปัจจุบันใหม่ด้วยความเร็วใหม่ทันที
    if (_tts.status.value == TtsStatus.playing) {
      await _tts.pause();
      await _playTts();
    }
  }

  void _scrollToCurrentParagraph() {
    final index = _tts.currentParagraph.value;
    if (_tts.status.value != TtsStatus.playing) return;
    if (index >= _paragraphKeys.length) return;
    final ctx = _paragraphKeys[index].currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      duration: const Duration(milliseconds: 400),
      alignment: 0.2,
    );
  }

  // ---------- ลิงก์ค้นต่อ ----------

  Future<void> _open(Uri uri) async {
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        showMessage(context, context.l10n.linkError, isError: true);
      }
    } catch (_) {
      if (mounted) {
        showMessage(context, context.l10n.linkError, isError: true);
      }
    }
  }

  void _showSearchSheet() {
    final article = _article;
    if (article == null) return;
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.search),
              title: Text(context.l10n.searchGoogle),
              subtitle: Text(article.title),
              onTap: () {
                Navigator.pop(context);
                _open(
                  Uri.https('www.google.com', '/search', {'q': article.title}),
                );
              },
            ),
            if (article.url.isNotEmpty)
              ListTile(
                leading: const Icon(Icons.public),
                title: Text(context.l10n.openWikipedia),
                subtitle: Text(context.l10n.openWikipediaSub),
                onTap: () {
                  Navigator.pop(context);
                  _open(Uri.parse(article.url));
                },
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // ปุ่มย้อนกลับ = พักไว้อ่านทีหลัง (ไม่ทิ้งบทความ)
    return PopScope(
      canPop: _article == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pauseAndExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.l10n.readingTitle),
          actions: [
            IconButton(
              tooltip: context.l10n.searchMore,
              icon: const Icon(Icons.travel_explore),
              onPressed: _article == null ? null : _showSearchSheet,
            ),
            IconButton(
              tooltip: context.l10n.pauseForLater,
              icon: const Icon(Icons.bookmark_add_outlined),
              onPressed: _article == null ? null : _pauseAndExit,
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: _article == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: FilledButton.icon(
                    onPressed: _goToSummary,
                    icon: const Icon(Icons.edit_note),
                    label: Text(context.l10n.finishedReading),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(context.l10n.loadingArticle),
          ],
        ),
      );
    }
    if (_error != null) {
      return ErrorView(message: _error!, onRetry: _loadArticle);
    }
    final article = _article;
    if (article == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final paragraphs = article.paragraphs;
    return Column(
      children: [
        _TimerBar(
          remaining: _remaining,
          limit: _limit,
          running: _stopwatch.isRunning,
          onToggle: _stopwatch.isRunning ? _pauseTimer : _startTimer,
        ),
        _TtsBar(
          tts: _tts,
          paragraphCount: paragraphs.length,
          onPlay: _playTts,
          onCycleRate: _cycleRate,
        ),
        Expanded(
          // พื้นหลังโคมไฟ: แสงตามนิ้ว / หายใจตอนไม่ได้แตะระหว่างจับเวลา
          child: ReadingLampBackground(
            active: _stopwatch.isRunning,
            child: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.sm,
                top: AppSpacing.sm,
                right: AppSpacing.sm,
              ),
              child: _FrostedCard(
                child: SelectionArea(
                  // ฟังย่อหน้าปัจจุบันของ TTS เพื่อไฮไลต์
                  child: ValueListenableBuilder<int>(
                    valueListenable: _tts.currentParagraph,
                    builder: (context, current, _) => ValueListenableBuilder<TtsStatus>(
                      valueListenable: _tts.status,
                      // SingleChildScrollView + Column สร้างทุกย่อหน้าไว้ตั้งแต่แรก (ไม่ lazy แบบ ListView)
                      // ย่อหน้าที่อยู่นอกจอจึงมี context ให้ ensureVisible เลื่อนไปหาได้เสมอ
                      builder: (context, status, _) => SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: AppSpacing.lg,
                          top: AppSpacing.md,
                          right: AppSpacing.lg,
                          bottom: AppSpacing.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              article.title,
                              style: theme.textTheme.headlineSmall,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              [
                                ArticleSources.byId(article.sourceId).name,
                                article.language.label,
                                if (article.topic != null)
                                  tagLabel(article.topic!, context.l10n),
                                context.l10n.charCount(article.content.length),
                              ].join(' · '),
                              style: theme.textTheme.labelMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            const Divider(height: 32),
                            for (var i = 0; i < paragraphs.length; i++)
                              _Paragraph(
                                key: _paragraphKeys[i],
                                text: paragraphs[i],
                                heading: article.isHeading(paragraphs[i]),
                                highlighted:
                                    status != TtsStatus.stopped && i == current,
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// การ์ดบทความแบบกระจกฝ้า (frosted glass): เบลอแสงด้านหลัง + พื้นเกือบทึบ
/// แสงโคมไฟจึงเห็นเป็นแค่ประกายนุ่มๆ ที่ขอบ ไม่รบกวนตัวหนังสือ
class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // ทึบ 85–88% = ตัวหนังสือ contrast สูง แต่ยังเห็นแสงด้านหลังจางๆ
            color: theme.colorScheme.surfaceContainerHigh.withValues(
              alpha: 0.88,
            ),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// ย่อหน้า 1 ย่อหน้า (ไฮไลต์พื้นหลังเมื่อ TTS กำลังอ่านย่อหน้านี้)
class _Paragraph extends StatelessWidget {
  const _Paragraph({
    super.key,
    required this.text,
    required this.highlighted,
    this.heading = false,
  });

  final String text;
  final bool highlighted;

  /// หัวข้อของบทความ: ตัวหนาและเว้นด้านบนมากกว่า ให้เห็นว่าเริ่มส่วนใหม่
  final bool heading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: EdgeInsets.only(
        top: heading ? AppSpacing.md : 0,
        bottom: heading ? AppSpacing.xxs : AppSpacing.sm,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.primaryContainer.withValues(alpha: 0.6)
            : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Semantics(
        header: heading,
        child: Text(
          text,
          style: heading
              ? theme.textTheme.titleLarge?.copyWith(
                  color: AppTheme.reading(context).color,
                )
              : AppTheme.reading(context),
        ),
      ),
    );
  }
}

/// แถบแสดงเวลาที่เหลือ + ปุ่มเริ่ม/หยุดชั่วคราว
class _TimerBar extends StatelessWidget {
  const _TimerBar({
    required this.remaining,
    required this.limit,
    required this.running,
    required this.onToggle,
  });

  final Duration remaining;
  final Duration limit;
  final bool running;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    final progress = limit.inSeconds == 0
        ? 0.0
        : remaining.inSeconds / limit.inSeconds;
    final warning = remaining.inMinutes < 2;

    return Material(
      color: theme.colorScheme.surfaceContainer,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              top: AppSpacing.xs,
              right: AppSpacing.xs,
              bottom: AppSpacing.xs,
            ),
            child: Row(
              children: [
                Icon(
                  Icons.timer_outlined,
                  color: warning
                      ? theme.colorScheme.error
                      : theme.colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  '$mm:$ss',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: warning ? theme.colorScheme.error : null,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  running
                      ? context.l10n.timerRunning
                      : context.l10n.timerPaused,
                  style: theme.textTheme.labelMedium,
                ),
                const Spacer(),
                IconButton(
                  tooltip: running
                      ? context.l10n.pauseTimer
                      : context.l10n.resumeTimer,
                  icon: Icon(
                    running
                        ? Icons.pause_circle_outline
                        : Icons.play_circle_outline,
                  ),
                  onPressed: onToggle,
                ),
              ],
            ),
          ),
          LinearProgressIndicator(value: progress, minHeight: 3),
        ],
      ),
    );
  }
}

/// แถบควบคุมเสียงอ่าน: เล่น/พัก, หยุด, ความเร็ว และบอกว่าอ่านถึงย่อหน้าไหน
class _TtsBar extends StatelessWidget {
  const _TtsBar({
    required this.tts,
    required this.paragraphCount,
    required this.onPlay,
    required this.onCycleRate,
  });

  final TtsService tts;
  final int paragraphCount;
  final VoidCallback onPlay;
  final VoidCallback onCycleRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: ValueListenableBuilder<TtsStatus>(
          valueListenable: tts.status,
          builder: (context, status, _) => Row(
            children: [
              IconButton(
                tooltip: status == TtsStatus.playing
                    ? context.l10n.ttsPause
                    : context.l10n.ttsPlay,
                icon: Icon(
                  status == TtsStatus.playing
                      ? Icons.pause_rounded
                      : Icons.play_arrow_rounded,
                ),
                onPressed: status == TtsStatus.playing ? tts.pause : onPlay,
              ),
              IconButton(
                tooltip: context.l10n.ttsStop,
                icon: const Icon(Icons.stop_rounded),
                onPressed: status == TtsStatus.stopped ? null : tts.stop,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: ValueListenableBuilder<int>(
                  valueListenable: tts.currentParagraph,
                  builder: (context, current, _) => Text(switch (status) {
                    TtsStatus.playing => context.l10n.ttsReading(
                      current + 1,
                      paragraphCount,
                    ),
                    TtsStatus.paused => context.l10n.ttsPausedAt(
                      current + 1,
                      paragraphCount,
                    ),
                    TtsStatus.stopped => context.l10n.ttsIdle,
                  }, style: theme.textTheme.labelMedium),
                ),
              ),
              ValueListenableBuilder<double>(
                valueListenable: SettingsService.instance.ttsRate,
                builder: (context, rate, _) =>
                    TextButton(onPressed: onCycleRate, child: Text('${rate}x')),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
