import 'dart:async';
import 'dart:ui' show ImageFilter;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/radius.dart';
import '../core/app_exception.dart';
import '../core/motion.dart';
import '../core/theme.dart';
import '../models/article.dart';
import '../models/article_tag.dart';
import '../l10n/l10n.dart';
import '../models/content_language.dart';
import '../models/reading_session.dart';
import '../models/reading_topic.dart';
import '../services/bookmark_service.dart';
import '../services/session_service.dart';
import '../services/slm_service.dart';
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
    // ContentLanguage มาจาก lib/models/content_language.dart
    required ContentLanguage this.language,
    // ReadingTopic มาจาก lib/models/reading_topic.dart
    required ReadingTopic this.topic,
    required Set<String> this.excludeKeys,
  }) : session = null;

  // ReadingSession มาจาก lib/models/reading_session.dart
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
  // ArticleSources มาจาก lib/services/sources/article_source.dart
  // SettingsService มาจาก lib/services/settings_service.dart
  /// แหล่งข้อมูลที่เลือกใน Settings (ตอนนี้คือ Wikipedia)
  final _source = ArticleSources.byId(SettingsService.instance.sourceId.value);
  // SessionService มาจาก lib/services/session_service.dart
  final _sessions = SessionService.instance;
  // TtsService มาจาก lib/services/tts_service.dart
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

  /// อ่านไปแล้วกี่ % ของบทความ (ตามตำแหน่งที่เลื่อน) ใช้กับแถบความคืบหน้าใต้เวลา
  final _scroll = ScrollController();
  final _readProgress = ValueNotifier<double>(0);

  /// AI ตั้งคำถามไม่สำเร็จ → แสดงคำถามทั่วไปแทน (ไม่ขึ้น error ให้รบกวนการอ่าน)
  bool _questionFailed = false;

  // Article มาจาก lib/models/article.dart
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
    _scroll.addListener(_updateProgress);

    final resumed = widget.session;
    if (resumed != null) {
      _setSession(resumed);
      _startTimer();
      _loadRecallQuestion();
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
    _scroll.dispose();
    _readProgress.dispose();
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
        // SessionStage มาจาก lib/models/reading_session.dart
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
      _loadRecallQuestion();
      // TopicExhaustedException มาจาก lib/services/sources/article_source.dart
    } on TopicExhaustedException {
      // หมวดนี้อ่านครบหมดแล้ว → กลับหน้าแรกพร้อมบอกว่าหมดของแหล่งข้อมูลไหน
      if (!mounted) return;
      final topic = widget.topic!;
      // showMessage มาจาก lib/widgets/ui_helpers.dart
      showMessage(
        context,
        // context.l10n มาจาก lib/l10n/l10n.dart
        context.l10n.topicExhausted(
          topic.preset?.label(context.l10n) ?? topic.query ?? '',
          _source.name,
          widget.language!.label,
        ),
      );
      Navigator.pop(context);
      // AppException มาจาก lib/core/app_exception.dart
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    }
  }

  /// ให้ AI ตั้งคำถามชวนนึกจากบทความ (ครั้งเดียวต่อเซสชัน เก็บไว้ในเซสชัน)
  Future<void> _loadRecallQuestion() async {
    final session = _session;
    if (session == null || session.recallQuestion != null) return;
    try {
      // SlmService มาจาก lib/services/slm_service.dart
      final question = await SlmService().recallQuestion(
        title: session.article.title,
        reference: session.article.reference,
        language: session.article.language,
      );
      final current = _session;
      // ไปหน้าสรุปแล้ว (เซสชันเป็นขั้น "กำลังสรุป") → ห้ามบันทึกทับ ไม่งั้นร่างคำสรุปที่หน้าสรุปเขียนไว้จะหาย
      if (!mounted ||
          current == null ||
          _navigating ||
          current.stage != SessionStage.reading) {
        return;
      }
      // ใช้เซสชันล่าสุด (เวลาอ่านอาจถูกบันทึกเพิ่มระหว่างรอ AI)
      final updated = current.copyWith(recallQuestion: question);
      setState(() => _session = updated);
      await _sessions.save(updated);
    } on AppException {
      if (mounted) setState(() => _questionFailed = true);
    }
  }

  void _updateProgress() {
    final position = _scroll.position;
    final max = position.maxScrollExtent;
    _readProgress.value = max <= 0
        ? 1
        : (position.pixels / max).clamp(0.0, 1.0);
  }

  Future<void> _toggleBookmark() async {
    final article = _article;
    if (article == null) return;
    // BookmarkService มาจาก lib/services/bookmark_service.dart
    final saved = await BookmarkService.instance.toggle(article);
    if (!mounted) return;
    showMessage(
      context,
      saved ? context.l10n.bookmarkSaved : context.l10n.bookmarkRemoved,
    );
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
    // TtsStatus มาจาก lib/services/tts_service.dart
    if (_tts.status.value == TtsStatus.playing) _tts.pause();
    _persist();
    if (mounted) setState(() {});
  }

  /// "พักไว้อ่านทีหลัง": บันทึกแล้วกลับหน้าแรก (การ์ดอ่านต่อจะไปโผล่ที่หน้า Home)
  void _pauseAndExit() {
    // กำลังไปหน้าสรุปอยู่: ห้าม pop ซ้อน ไม่งั้น pushReplacement จะไปแทนหน้าแรกแทน
    if (_navigating) return;
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
    // ต้องยังเป็นหน้าบนสุดอยู่ (ระหว่างรอ ผู้ใช้อาจออกจากหน้านี้ไปแล้ว)
    if (!mounted || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        // SummaryScreen มาจาก lib/screens/summary_screen.dart
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
      // AppMotion มาจาก lib/core/motion.dart
      duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.scrollTo,
      curve: AppMotion.entranceCurve,
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

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final article = _article;
    // ปุ่มย้อนกลับ = พักไว้อ่านทีหลัง (ไม่ทิ้งบทความ)
    return PopScope(
      canPop: article == null,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _pauseAndExit();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.readingTitle),
          actions: [
            if (article != null)
              ValueListenableBuilder<Set<String>>(
                valueListenable: BookmarkService.instance.saved,
                builder: (context, saved, _) {
                  final isSaved = saved.contains(article.readKey);
                  return IconButton(
                    tooltip: isSaved ? l10n.bookmarkRemove : l10n.bookmarkAdd,
                    isSelected: isSaved,
                    icon: const Icon(Icons.bookmark_border),
                    selectedIcon: Icon(
                      Icons.bookmark,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    onPressed: _toggleBookmark,
                  );
                },
              ),
            // เมนูเพิ่มเติม: ค้นต่อ / เปิด Wikipedia / พักไว้อ่านทีหลัง
            PopupMenuButton<_ReadingMenu>(
              tooltip: l10n.options,
              enabled: article != null,
              onSelected: (choice) => switch (choice) {
                _ReadingMenu.wikipedia => _open(Uri.parse(article!.url)),
                _ReadingMenu.google => _open(
                  Uri.https('www.google.com', '/search', {'q': article!.title}),
                ),
                _ReadingMenu.pause => _pauseAndExit(),
              },
              itemBuilder: (context) => [
                if (article?.url.isNotEmpty ?? false)
                  PopupMenuItem(
                    value: _ReadingMenu.wikipedia,
                    child: ListTile(
                      leading: const Icon(Icons.public),
                      title: Text(l10n.openWikipedia),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                PopupMenuItem(
                  value: _ReadingMenu.google,
                  child: ListTile(
                    leading: const Icon(Icons.travel_explore),
                    title: Text(l10n.searchGoogle),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: _ReadingMenu.pause,
                  child: ListTile(
                    leading: const Icon(Icons.pause_circle_outline),
                    title: Text(l10n.pauseForLater),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        body: _buildBody(),
        bottomNavigationBar: article == null
            ? null
            : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    // AppSpacing มาจาก lib/core/spacing.dart
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.xs,
                  ),
                  child: FilledButton.icon(
                    onPressed: _goToSummary,
                    icon: const Icon(Icons.edit_note),
                    label: Text(l10n.finishedReading),
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
            const SizedBox(height: AppSpacing.md),
            Text(context.l10n.loadingArticle),
          ],
        ),
      );
    }
    if (_error != null) {
      // ErrorView มาจาก lib/widgets/ui_helpers.dart
      return ErrorView(message: _error!, onRetry: _loadArticle);
    }
    final article = _article;
    if (article == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final l10n = context.l10n;
    final paragraphs = article.paragraphs;
    return Column(
      children: [
        _ReadingHeader(
          remaining: _remaining,
          running: _stopwatch.isRunning,
          onToggle: _stopwatch.isRunning ? _pauseTimer : _startTimer,
          progress: _readProgress,
          tts: _tts,
          paragraphCount: paragraphs.length,
          onPlay: _playTts,
          onCycleRate: _cycleRate,
        ),
        Expanded(
          // พื้นหลังโคมไฟ: แสงตามนิ้ว / หายใจตอนไม่ได้แตะระหว่างจับเวลา
          // ReadingLampBackground มาจาก lib/widgets/reading_lamp.dart
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
                        controller: _scroll,
                        padding: const EdgeInsets.only(
                          left: AppSpacing.lg,
                          top: AppSpacing.lg,
                          right: AppSpacing.lg,
                          bottom: AppSpacing.xxl,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            if (article.imageUrl != null)
                              _LeadImage(url: article.imageUrl!),
                            Text(
                              article.title,
                              style: theme.textTheme.headlineSmall?.copyWith(
                                // AppTheme มาจาก lib/core/theme.dart
                                color: AppTheme.reading(context).color,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.sm),
                            Wrap(
                              spacing: AppSpacing.xs,
                              runSpacing: AppSpacing.xs,
                              children: [
                                _MetaPill(
                                  icon: Icons.public,
                                  label: ArticleSources.byId(
                                    article.sourceId,
                                  ).name,
                                ),
                                _MetaPill(
                                  icon: Icons.translate,
                                  label: article.language.label,
                                ),
                                if (article.topic != null)
                                  _MetaPill(
                                    icon:
                                        // ArticleTag มาจาก lib/models/article_tag.dart
                                        ArticleTag.fromId(
                                          article.topic!,
                                        )?.icon ??
                                        Icons.tag,
                                    // tagLabel มาจาก lib/l10n/l10n.dart
                                    label: tagLabel(article.topic!, l10n),
                                  ),
                                _MetaPill(
                                  icon: Icons.notes,
                                  label: l10n.charCount(article.content.length),
                                ),
                                _MetaPill(
                                  icon: Icons.schedule,
                                  label: l10n.readMinutesEstimate(
                                    article.estimatedMinutes,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: AppSpacing.lg),
                            _RecallNote(
                              question: _session?.recallQuestion,
                              failed: _questionFailed,
                            ),
                            const SizedBox(height: AppSpacing.lg),
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

enum _ReadingMenu { wikipedia, google, pause }

/// การ์ดบทความแบบกระจกฝ้า (frosted glass): เบลอแสงด้านหลัง + พื้นเกือบทึบ
/// แสงโคมไฟจึงเห็นเป็นแค่ประกายนุ่มๆ ที่ขอบ ไม่รบกวนตัวหนังสือ
class _FrostedCard extends StatelessWidget {
  const _FrostedCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ClipRRect(
      // AppRadius มาจาก lib/core/radius.dart
      borderRadius: AppRadius.sheetTop,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: DecoratedBox(
          decoration: BoxDecoration(
            // ทึบ 88% = ตัวหนังสือ contrast สูง แต่ยังเห็นแสงด้านหลังจางๆ
            color: theme.colorScheme.surfaceContainerLow.withValues(
              alpha: 0.88,
            ),
            border: Border.all(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.4),
            ),
            borderRadius: AppRadius.sheetTop,
          ),
          child: child,
        ),
      ),
    );
  }
}

/// รูปนำของบทความจาก Wikipedia (ภาพตกแต่ง: ชื่อเรื่องด้านล่างบอกเนื้อหาอยู่แล้ว)
/// โหลดไม่ได้ = ซ่อนไปเฉยๆ ไม่ให้เป็นกรอบว่าง
class _LeadImage extends StatelessWidget {
  const _LeadImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.lg),
        child: ClipRRect(
          borderRadius: AppRadius.controlAll,
          child: AspectRatio(
            aspectRatio: 16 / 9,
            child: Image.network(
              url,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, progress) => progress == null
                  ? child
                  : ColoredBox(color: scheme.surfaceContainer),
              errorBuilder: (context, error, stack) => ColoredBox(
                color: scheme.surfaceContainer,
                child: Icon(Icons.image_outlined, color: scheme.outline),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaPill extends StatelessWidget {
  const _MetaPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs + 2,
        vertical: AppSpacing.xxs,
      ),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainerHigh,
        shape: const StadiumBorder(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: scheme.secondary),
          const SizedBox(width: AppSpacing.xxs),
          Flexible(
            child: Text(
              label,
              style: theme.textTheme.labelSmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// โน้ตชวนนึก: คำถาม 1 ข้อจาก AI ให้ถือไว้ในใจระหว่างอ่าน แล้วตอบตอนเขียนสรุป
/// แถบซ้ายสีอำพัน = สีเดียวกับแสงโคมไฟ (สิ่งที่ "ส่องทาง" การอ่าน)
class _RecallNote extends StatelessWidget {
  const _RecallNote({required this.question, required this.failed});

  /// null + ไม่ failed = กำลังรอ AI
  final String? question;
  final bool failed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final waiting = question == null && !failed;
    final text = question ?? l10n.recallNoteFallback;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: AppRadius.controlAll,
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: scheme.tertiary,
              child: const SizedBox(width: AppSpacing.xxs),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.psychology_outlined,
                          size: 18,
                          color: scheme.tertiary,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Expanded(
                          child: Text(
                            l10n.recallNoteTitle,
                            style: theme.textTheme.labelMedium?.copyWith(
                              color: scheme.tertiary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    // liveRegion: คำถามจาก AI มาถึงทีหลัง → โปรแกรมอ่านหน้าจอประกาศให้รู้
                    Semantics(
                      liveRegion: true,
                      child: AnimatedSwitcher(
                        duration: AppMotion.reduced(context)
                            ? Duration.zero
                            : Durations.long2,
                        child: waiting
                            ? Text(
                                l10n.recallNoteLoading,
                                key: const ValueKey('waiting'),
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              )
                            : Text(
                                text,
                                key: ValueKey(text),
                                style: theme.textTheme.titleMedium?.copyWith(
                                  color: AppTheme.reading(context).color,
                                ),
                              ),
                      ),
                    ),
                    if (!waiting) ...[
                      const SizedBox(height: AppSpacing.xxs),
                      Text(
                        l10n.recallNoteHint,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ย่อหน้า 1 ย่อหน้า
/// - หัวข้อ: แถบสีหลักด้านหน้า + ตัวหนา เว้นด้านบนมากกว่า ให้เห็นว่าเริ่มส่วนใหม่
/// - ย่อหน้าที่ TTS กำลังอ่าน: พื้นเขียวเข้มจางๆ + แถบด้านหน้า (ไม่ใช้สีอย่างเดียว)
class _Paragraph extends StatelessWidget {
  const _Paragraph({
    super.key,
    required this.text,
    required this.highlighted,
    this.heading = false,
  });

  final String text;
  final bool highlighted;
  final bool heading;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final reading = AppTheme.reading(context);
    final bar = heading || highlighted;
    return AnimatedContainer(
      duration: AppMotion.reduced(context)
          ? Duration.zero
          : AppMotion.highlight,
      margin: EdgeInsets.only(
        top: heading ? AppSpacing.lg : 0,
        bottom: heading ? AppSpacing.xs : AppSpacing.sm,
      ),
      padding: const EdgeInsetsDirectional.only(
        start: AppSpacing.sm,
        top: AppSpacing.xxs,
        end: AppSpacing.xs,
        bottom: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: highlighted
            ? scheme.secondaryContainer.withValues(alpha: 0.5)
            : scheme.secondaryContainer.withValues(alpha: 0),
        border: BorderDirectional(
          start: BorderSide(
            color: bar
                ? (highlighted ? scheme.secondary : scheme.primary)
                : scheme.primary.withValues(alpha: 0),
            width: 3,
          ),
        ),
      ),
      child: Semantics(
        header: heading,
        child: Text(
          text,
          style: heading
              ? theme.textTheme.titleLarge?.copyWith(color: reading.color)
              : reading,
        ),
      ),
    );
  }
}

/// ส่วนหัวของหน้าอ่าน: เวลาที่เหลือ + ปุ่มพัก, แถบอ่านไปแล้วกี่ %, และแถวควบคุมเสียงอ่าน
class _ReadingHeader extends StatelessWidget {
  const _ReadingHeader({
    required this.remaining,
    required this.running,
    required this.onToggle,
    required this.progress,
    required this.tts,
    required this.paragraphCount,
    required this.onPlay,
    required this.onCycleRate,
  });

  final Duration remaining;
  final bool running;
  final VoidCallback onToggle;
  final ValueListenable<double> progress;
  final TtsService tts;
  final int paragraphCount;
  final VoidCallback onPlay;
  final VoidCallback onCycleRate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final mm = remaining.inMinutes.toString().padLeft(2, '0');
    final ss = (remaining.inSeconds % 60).toString().padLeft(2, '0');
    // เหลือไม่ถึง 2 นาที → สีอำพัน (เตือนเบาๆ ไม่ใช่สีแดง)
    final almostUp = remaining.inMinutes < 2;
    final timeColor = almostUp ? scheme.tertiary : scheme.primary;

    return Padding(
      padding: const EdgeInsets.only(
        left: AppSpacing.md,
        right: AppSpacing.md,
        bottom: AppSpacing.xs,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              // ใกล้หมดเวลา: เปลี่ยนทั้งสี ไอคอน และข้อความ (ไม่บอกด้วยสีอย่างเดียว)
              Icon(
                almostUp ? Icons.hourglass_bottom : Icons.timer_outlined,
                color: timeColor,
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '$mm:$ss',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: timeColor,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Flexible(
                child: Text(
                  almostUp && running
                      ? l10n.timeAlmostUp
                      : (running ? l10n.timerRunning : l10n.timerPaused),
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                tooltip: running ? l10n.pauseTimer : l10n.resumeTimer,
                icon: Icon(
                  running
                      ? Icons.pause_circle_outline
                      : Icons.play_circle_outline,
                ),
                onPressed: onToggle,
              ),
            ],
          ),
          ValueListenableBuilder<double>(
            valueListenable: progress,
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              minHeight: 4,
              borderRadius: AppRadius.pillAll,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHigh,
              semanticsLabel: l10n.readingProgress((value * 100).round()),
            ),
          ),
          const SizedBox(height: AppSpacing.xxs),
          ValueListenableBuilder<TtsStatus>(
            valueListenable: tts.status,
            builder: (context, status, _) => Row(
              children: [
                IconButton(
                  tooltip: status == TtsStatus.playing
                      ? l10n.ttsPause
                      : l10n.ttsPlay,
                  icon: Icon(
                    status == TtsStatus.playing
                        ? Icons.pause_rounded
                        : Icons.volume_up_outlined,
                  ),
                  onPressed: status == TtsStatus.playing ? tts.pause : onPlay,
                ),
                IconButton(
                  tooltip: l10n.ttsStop,
                  icon: const Icon(Icons.stop_rounded),
                  onPressed: status == TtsStatus.stopped ? null : tts.stop,
                ),
                Expanded(
                  child: ValueListenableBuilder<int>(
                    valueListenable: tts.currentParagraph,
                    builder: (context, current, _) => Text(
                      switch (status) {
                        TtsStatus.playing => l10n.ttsReading(
                          current + 1,
                          paragraphCount,
                        ),
                        TtsStatus.paused => l10n.ttsPausedAt(
                          current + 1,
                          paragraphCount,
                        ),
                        TtsStatus.stopped => l10n.ttsIdle,
                      },
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
                // ความเร็วเสียง: แตะวนค่า 0.75 → 1.0 → 1.25 → 1.5
                ValueListenableBuilder<double>(
                  valueListenable: SettingsService.instance.ttsRate,
                  builder: (context, rate, _) => ActionChip(
                    tooltip: l10n.ttsSpeed('$rate'),
                    avatar: const Icon(Icons.speed, size: 16),
                    label: Text('$rate×'),
                    onPressed: onCycleRate,
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
