import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/theme.dart';
import '../core/validators.dart';
import '../l10n/l10n.dart';
import '../models/article_tag.dart';
import '../models/reading_session.dart';
import '../models/study_log.dart';
import '../services/session_service.dart';
import '../services/settings_service.dart';
import '../services/slm_service.dart';
import '../services/study_log_repository.dart';
import '../widgets/animated_counter.dart';
import '../widgets/score_badge.dart';
import '../widgets/ui_helpers.dart';
import '../widgets/motion_widgets.dart';
import '../core/spacing.dart';

/// หน้าจอ 4: เขียนสรุป + ให้ AI ประเมิน + เลือกแท็ก + บันทึก (CRUD: Create และ Update)
///
/// ใช้หน้าเดียวกัน 2 โหมด:
/// - SummaryScreen.fromSession: มาจากหน้าอ่าน/การ์ดอ่านต่อ → บันทึกครั้งแรกเป็น Create
///   (ร่างที่พิมพ์ถูกเก็บในเซสชันตลอด ออกจากหน้าไปแล้วกลับมาก็ยังอยู่)
/// - SummaryScreen.edit: มาจาก Home (แตะรายการเก่า) → บันทึกเป็น Update
class SummaryScreen extends StatefulWidget {
  const SummaryScreen.fromSession({
    super.key,
    required ReadingSession this.session,
  }) : log = null;

  const SummaryScreen.edit({super.key, required StudyLog this.log})
    : session = null;

  final ReadingSession? session;
  final StudyLog? log;

  @override
  State<SummaryScreen> createState() => _SummaryScreenState();
}

class _SummaryScreenState extends State<SummaryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _controller = TextEditingController();
  final _slm = SlmService();
  final _repo = StudyLogRepository();

  late final String _title;
  late final String _url;
  late final String _originalContent;

  /// document ID ของบันทึกนี้: โหมด edit ใช้ ID เดิม, โหมด create จอง ID ใหม่ไว้ตั้งแต่เปิดหน้า
  late final String _logId;

  /// false = ยังไม่มีเอกสารใน Firestore (ต้อง Create), true = มีแล้ว (ต้อง Update)
  /// กดประเมินซ้ำหลังบันทึกแล้วจึงเป็น Update ไม่สร้างเอกสารซ้ำ
  bool _persisted = false;

  /// ข้อความที่คะแนนปัจจุบันใช้ประเมิน ถ้าผู้ใช้แก้ข้อความหลังจากนั้น คะแนนจะ "ล้าสมัย"
  String _scoredText = '';

  /// นาทีที่ได้เพิ่มจากรอบนี้ (มีค่าหลังบันทึกครั้งแรกสำเร็จ ใช้แสดงป้าย "+X นาที")
  int? _earnedMinutes;

  /// แท็กของบทความ (ไม่เกิน 3) และค่าที่บันทึกไว้ล่าสุด (ใช้เช็กว่ามีการแก้ที่ยังไม่บันทึก)
  List<String> _tags = [];
  List<String> _savedTags = [];

  /// ผู้ใช้แตะแก้แท็กเองแล้ว → AI จะไม่เขียนทับแท็กที่ผู้ใช้เลือก
  bool _tagsTouched = false;

  int? _score;
  String? _feedback;
  String? _model;
  String? _aiError;
  String _savedText = '';

  Timer? _draftTimer;

  bool _evaluating = false;
  bool _saving = false;

  bool get _busy => _evaluating || _saving;
  bool get _isEdit => widget.log != null;
  bool get _textChanged => _controller.text.trim() != _savedText;
  bool get _tagsChanged => !listEquals(_tags, _savedTags);
  bool get _hasUnsavedChanges => _textChanged || _tagsChanged;
  bool get _scoreIsStale =>
      _score != null && _controller.text.trim() != _scoredText;

  @override
  void initState() {
    super.initState();
    final log = widget.log;
    if (log != null) {
      _title = log.articleTitle;
      _url = log.articleUrl;
      _originalContent = log.originalContent;
      _logId = log.id;
      _persisted = true;
      _score = log.aiScore;
      _feedback = log.aiFeedback;
      _savedText = log.userSummary;
      _scoredText = log.userSummary;
      _controller.text = log.userSummary;
      _tags = [...log.tags];
      _savedTags = [...log.tags];
    } else {
      final article = widget.session!.article;
      _title = article.title;
      _url = article.url;
      _originalContent = article.reference;
      _controller.text = widget.session!.draftSummary;
      _logId = _repo.newLogId();
      // หมวดที่เลือกตอนสุ่มเป็นแท็กแรกให้ก่อน (AI จะเติมให้ครบหลังประเมิน)
      _tags = ArticleTag.normalize([article.topic]);
    }
  }

  @override
  void dispose() {
    // ออกจากหน้าระหว่างที่ยังไม่ครบ 500ms: บันทึกร่างล่าสุดทันที ไม่ให้หาย
    if (_draftTimer?.isActive ?? false) {
      _draftTimer!.cancel();
      _writeDraft(_controller.text);
    }
    _controller.dispose();
    super.dispose();
  }

  /// ขั้นตอนหลัก: validate → เรียก AI (async) → บันทึก Firestore (async)
  Future<void> _evaluateAndSave() async {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() {
      _evaluating = true;
      _aiError = null;
    });
    try {
      final result = await _slm.evaluate(
        // Feedback เป็นภาษาของแอปที่ผู้ใช้เลือก (ไม่จำเป็นต้องตรงกับภาษาบทความ)
        language: SettingsService.instance.appLanguage.value,
        articleTitle: _title,
        originalContent: _originalContent,
        userSummary: _controller.text.trim(),
      );
      if (!mounted) return;
      setState(() {
        _scoredText = _controller.text.trim();
        _score = result.score;
        _feedback = result.feedback;
        _model = result.model;
        // ผู้ใช้ยังไม่ได้แตะแท็ก และไม่ใช่บันทึกเก่าที่มีแท็กอยู่แล้ว
        // → ใช้แท็กที่ AI แนะนำต่อท้ายแท็กเดิม (รวมไม่เกิน 3)
        if (!_tagsTouched && (!_isEdit || _savedTags.isEmpty)) {
          _tags = ArticleTag.normalize([..._tags, ...result.tags]);
        }
        _evaluating = false;
      });
      await _save();
    } on AppException catch (e) {
      // AI ล่ม/timeout: ข้อความที่พิมพ์ยังอยู่ครบ ผู้ใช้เลือกได้ว่าจะลองใหม่หรือบันทึกไว้ก่อน
      if (!mounted) return;
      setState(() {
        _aiError = e.message;
        _evaluating = false;
      });
    }
  }

  /// บันทึกโดยยังไม่มีคะแนน (ใช้เมื่อ AI ใช้งานไม่ได้)
  Future<void> _saveWithoutScore() async {
    if (!_formKey.currentState!.validate()) return;
    // ถ้ามีคะแนนเดิมอยู่ ต้องถามก่อน เพราะการบันทึกแบบนี้จะลบคะแนนเดิมทิ้ง
    if (_score != null) {
      final ok = await confirmDialog(
        context,
        title: context.l10n.removeScoreTitle,
        message: context.l10n.removeScoreMessage,
        confirmLabel: context.l10n.save,
      );
      if (!ok || !mounted) return;
    }
    setState(() {
      _score = null;
      _feedback = null;
      _model = null;
    });
    await _save();
    if (mounted && !_hasUnsavedChanges) setState(() => _aiError = null);
  }

  Future<void> _save() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final summary = _controller.text.trim();
    final tags = [..._tags];

    setState(() => _saving = true);
    try {
      if (!_persisted) {
        final session = widget.session!;
        // Create: เขียนเอกสารใหม่ด้วย ID ที่จองไว้
        await _repo.create(
          logId: _logId,
          userId: user.uid,
          articleTitle: _title,
          articleUrl: _url,
          originalContent: _originalContent,
          userSummary: summary,
          readingTimeMinutes: session.readingMinutes,
          tags: tags,
          language: session.article.language.code,
          source: session.article.sourceId,
          pageId: session.article.pageId,
          aiScore: _score,
          aiFeedback: _feedback,
        );
        _persisted = true;
        _earnedMinutes = session.readingMinutes;
        // บันทึกลง Firestore แล้ว = จบเซสชันนี้ ปลดล็อกให้สุ่มบทความใหม่ได้
        await SessionService.instance.clear();
      } else {
        // Update: แก้เฉพาะคำสรุป แท็ก และผลประเมิน
        await _repo.update(
          logId: _logId,
          userSummary: summary,
          tags: tags,
          aiScore: _score,
          aiFeedback: _feedback,
        );
      }
      _savedText = summary;
      _savedTags = tags;
      if (mounted) showMessage(context, context.l10n.savedMessage);
    } on AppException catch (e) {
      if (mounted) showMessage(context, e.message, isError: true);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _toggleTag(String tag) {
    setState(() {
      _tagsTouched = true;
      if (_tags.contains(tag)) {
        _tags = [..._tags]..remove(tag);
      } else if (_tags.length >= ArticleTag.maxPerArticle) {
        showMessage(context, context.l10n.tagsLimit);
      } else {
        _tags = [..._tags, tag];
      }
    });
  }

  void _done() => Navigator.popUntil(context, (route) => route.isFirst);

  /// โหมดจากเซสชัน: เก็บร่างลงเครื่องทุกครั้งที่พิมพ์ (ยังไม่ได้ลง Firestore)
  ///
  /// debounce 500ms: รอให้หยุดพิมพ์ก่อนค่อยเขียน ไม่เขียนทุกตัวอักษร
  /// (เซสชันมีเนื้อหาบทความทั้งเรื่อง การแปลง JSON ทุกครั้งที่กดแป้นจะหนักเกินไป)
  void _saveDraft(String text) {
    _draftTimer?.cancel();
    _draftTimer = Timer(
      const Duration(milliseconds: 500),
      () => _writeDraft(text),
    );
  }

  void _writeDraft(String text) {
    final session = SessionService.instance.current.value;
    if (_isEdit || _persisted || session == null) return;
    SessionService.instance.save(session.copyWith(draftSummary: text));
  }

  Future<void> _confirmDiscard() async {
    final discard = await confirmDialog(
      context,
      title: context.l10n.discardDraftTitle,
      message: context.l10n.discardDraftMessage,
      confirmLabel: context.l10n.discard,
      destructive: true,
    );
    if (discard && mounted) _done();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    // ออกได้ทันทีถ้า: ยังไม่เคยบันทึกจากเซสชัน (ร่างอยู่ในเครื่องแล้ว อ่านต่อทีหลังได้)
    // หรือไม่มีอะไรที่ยังไม่ได้บันทึก
    final draftIsSafe = !_isEdit && !_persisted;
    return PopScope(
      canPop: !_busy && (draftIsSafe || !_hasUnsavedChanges),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop && !_busy) _confirmDiscard();
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEdit ? l10n.editSummaryTitle : l10n.writeSummaryTitle),
        ),
        body: SafeArea(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.only(
                left: AppSpacing.lg,
                top: AppSpacing.xs,
                right: AppSpacing.lg,
                bottom: AppSpacing.xxl,
              ),
              children: [
                Text(_title, style: theme.textTheme.titleLarge),
                const SizedBox(height: 4),
                Text(
                  _isEdit ? l10n.editHint : l10n.recallHint,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _controller,
                  enabled: !_busy,
                  minLines: 8,
                  maxLines: 16,
                  keyboardType: TextInputType.multiline,
                  textCapitalization: TextCapitalization.sentences,
                  style: AppTheme.readingInput(context),
                  decoration: InputDecoration(
                    hintText: l10n.summaryHint,
                    alignLabelWithHint: true,
                    helperText: l10n.summaryCounter(
                      _controller.text.trim().length,
                      Validators.minSummaryLength,
                    ),
                  ),
                  onChanged: (text) {
                    setState(() {}); // อัปเดตตัวนับตัวอักษร
                    _saveDraft(text);
                  },
                  validator: Validators.summary,
                ),
                const SizedBox(height: 16),
                _TagEditor(tags: _tags, enabled: !_busy, onToggle: _toggleTag),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _busy ? null : _evaluateAndSave,
                  icon: _busy
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : const Icon(Icons.auto_awesome),
                  label: Text(
                    _evaluating
                        ? l10n.aiEvaluating
                        : _saving
                        ? l10n.saving
                        : (_score == null
                              ? l10n.evaluateAndSave
                              : l10n.reevaluateAndSave),
                  ),
                ),
                // แก้แค่แท็ก (ข้อความเดิม) → บันทึกได้เลยไม่ต้องให้ AI ประเมินใหม่
                if (_persisted && _tagsChanged && !_textChanged) ...[
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _save,
                    icon: const Icon(Icons.sell_outlined),
                    label: Text(l10n.save),
                  ),
                ],
                if (_aiError != null) ...[
                  const SizedBox(height: 16),
                  EntranceFade(
                    child: _AiErrorCard(
                      message: _aiError!,
                      busy: _busy,
                      onRetry: _evaluateAndSave,
                      onSaveWithoutScore: _saveWithoutScore,
                    ),
                  ),
                ],
                if (_earnedMinutes != null) ...[
                  const SizedBox(height: 16),
                  Center(
                    child: EarnedBadge(
                      label: l10n.earnedMinutes(_earnedMinutes!),
                    ),
                  ),
                ],
                if (_score != null || _feedback != null) ...[
                  const SizedBox(height: 16),
                  EntranceFade(
                    child: _ResultCard(
                      score: _score,
                      feedback: _feedback,
                      model: _model,
                      stale: _scoreIsStale,
                    ),
                  ),
                ],
                if (_isEdit && _originalContent.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    clipBehavior: Clip.antiAlias,
                    child: ExpansionTile(
                      title: Text(l10n.viewOriginal),
                      subtitle: Text(l10n.viewOriginalSub),
                      childrenPadding: const EdgeInsets.only(
                        left: AppSpacing.md,
                        right: AppSpacing.md,
                        bottom: AppSpacing.md,
                      ),
                      children: [
                        Text(
                          _originalContent,
                          style: AppTheme.reading(context),
                        ),
                      ],
                    ),
                  ),
                ],
                if (_persisted && !_hasUnsavedChanges) ...[
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    onPressed: _busy ? null : _done,
                    child: Text(l10n.doneBackHome),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// ตัวเลือกแท็ก: หมวดยอดฮิต 5 หมวด + แท็กที่ค้นเอง (ถ้ามี) เลือกได้ไม่เกิน 3
class _TagEditor extends StatelessWidget {
  const _TagEditor({
    required this.tags,
    required this.enabled,
    required this.onToggle,
  });

  final List<String> tags;
  final bool enabled;
  final ValueChanged<String> onToggle;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // แท็กที่ไม่ใช่หมวดยอดฮิต (หัวข้อที่ผู้ใช้ค้นเอง) แสดงต่อท้าย
    final custom = tags.where((t) => ArticleTag.fromId(t) == null);
    final options = [...ArticleTag.values.map((t) => t.id), ...custom];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${l10n.tagsTitle} · ${tags.length}/${ArticleTag.maxPerArticle}',
          style: theme.textTheme.titleSmall,
        ),
        const SizedBox(height: 2),
        Text(
          l10n.tagsHint,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final tag in options)
              SelectedScale(
                selected: tags.contains(tag),
                child: FilterChip(
                  avatar: Icon(
                    ArticleTag.fromId(tag)?.icon ?? Icons.tag,
                    size: 16,
                  ),
                  label: Text(tagLabel(tag, l10n)),
                  selected: tags.contains(tag),
                  onSelected: enabled ? (_) => onToggle(tag) : null,
                ),
              ),
          ],
        ),
      ],
    );
  }
}

class _ResultCard extends StatelessWidget {
  const _ResultCard({
    required this.score,
    required this.feedback,
    required this.model,
    required this.stale,
  });

  final int? score;
  final String? feedback;
  final String? model;

  /// true = ผู้ใช้แก้ข้อความหลังได้คะแนนนี้แล้ว คะแนนจึงยังไม่ใช่ของข้อความปัจจุบัน
  final bool stale;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final headline = theme.textTheme.headlineSmall;
    return Opacity(
      opacity: stale ? 0.55 : 1,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (stale) ...[
                Text(
                  l10n.staleScore,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 8),
              ],
              Row(
                children: [
                  ScoreBadge(score: score, size: 64),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.scoreLabel,
                          style: theme.textTheme.labelLarge,
                        ),
                        score == null
                            ? Text(l10n.notEvaluatedYet, style: headline)
                            // คะแนนวิ่งนับขึ้นจาก 0 ทุกครั้งที่ได้ผลใหม่
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.baseline,
                                textBaseline: TextBaseline.alphabetic,
                                children: [
                                  AnimatedCounter(
                                    key: ValueKey(score),
                                    value: score!,
                                    style: headline,
                                  ),
                                  Text(' / 100', style: headline),
                                ],
                              ),
                        if (model != null)
                          Text(
                            l10n.evaluatedBy(model!),
                            style: theme.textTheme.labelSmall,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
              if (feedback != null) ...[
                const Divider(height: 24),
                Text(l10n.aiFeedbackTitle, style: theme.textTheme.labelLarge),
                const SizedBox(height: 6),
                Text(
                  feedback!,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.6),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _AiErrorCard extends StatelessWidget {
  const _AiErrorCard({
    required this.message,
    required this.busy,
    required this.onRetry,
    required this.onSaveWithoutScore,
  });

  final String message;
  final bool busy;
  final VoidCallback onRetry;
  final VoidCallback onSaveWithoutScore;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final l10n = context.l10n;
    return Card(
      color: scheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              l10n.aiFailed,
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 4),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: scheme.onErrorContainer),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: busy ? null : onRetry,
                  icon: const Icon(Icons.refresh),
                  label: Text(l10n.retry),
                ),
                TextButton(
                  onPressed: busy ? null : onSaveWithoutScore,
                  child: Text(l10n.saveWithoutScore),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
