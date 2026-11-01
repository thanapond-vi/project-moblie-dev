import 'package:flutter/material.dart';

import '../core/app_exception.dart';
import '../core/motion.dart';
import '../core/radius.dart';
import '../core/spacing.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../models/key_point.dart';
import '../models/review_schedule.dart';
import '../models/study_log.dart';
import '../services/study_log_repository.dart';
import '../widgets/ui_helpers.dart';

/// ทบทวนทีละเรื่องตามคิว: 1) นึกจากชื่อเรื่อง + คำถาม  2) เฉลยประเด็นสำคัญ  3) ให้คะแนนตัวเอง
/// ให้คะแนนแล้วระบบเลื่อนกล่อง (Leitner) และไปเรื่องถัดไปเอง ครบคิวแล้วกลับแท็บทบทวน
class ReviewSessionScreen extends StatefulWidget {
  const ReviewSessionScreen({super.key, required this.queue, this.repository});

  // StudyLog มาจาก lib/models/study_log.dart
  final List<StudyLog> queue;

  // StudyLogRepository มาจาก lib/services/study_log_repository.dart
  /// ใส่ได้ในเทสต์ (ค่าเริ่มต้น = Firestore จริง)
  final StudyLogRepository? repository;

  @override
  State<ReviewSessionScreen> createState() => _ReviewSessionScreenState();
}

class _ReviewSessionScreenState extends State<ReviewSessionScreen> {
  late final _repo = widget.repository ?? StudyLogRepository();
  final _notes = TextEditingController();
  int _index = 0;
  bool _revealed = false;
  bool _saving = false;

  StudyLog get _log => widget.queue[_index];

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  // ReviewRating มาจาก lib/models/review_schedule.dart
  Future<void> _rate(ReviewRating rating) async {
    if (_saving) return;
    // ReviewSchedule มาจาก lib/models/review_schedule.dart
    final box = ReviewSchedule.nextBox(_log.reviewBox, rating);
    setState(() => _saving = true);
    try {
      await _repo.recordReview(
        logId: _log.id,
        box: box,
        nextReviewAt: ReviewSchedule.nextDue(box, DateTime.now()),
        passed: rating.passed,
      );
      if (!mounted) return;
      // context.l10n มาจาก lib/l10n/l10n.dart
      final l10n = context.l10n;
      // showMessage มาจาก lib/widgets/ui_helpers.dart
      showMessage(context, l10n.reviewSaved(ReviewSchedule.intervalOf(box)));
      if (_index + 1 >= widget.queue.length) {
        Navigator.pop(context);
        return;
      }
      setState(() {
        _index++;
        _revealed = false;
        _saving = false;
        _notes.clear();
      });
      // AppException มาจาก lib/core/app_exception.dart
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showMessage(context, e.message, isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final log = _log;
    final total = widget.queue.length;
    return Scaffold(
      appBar: AppBar(
        title: Text('${l10n.navReview} · ${_index + 1}/$total'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: Padding(
            // AppSpacing มาจาก lib/core/spacing.dart
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
            child: LinearProgressIndicator(
              value: (_index + (_revealed ? 0.5 : 0)) / total,
              minHeight: 4,
              // AppRadius มาจาก lib/core/radius.dart
              borderRadius: AppRadius.pillAll,
              color: scheme.primary,
              backgroundColor: scheme.surfaceContainerHigh,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          // AppMotion มาจาก lib/core/motion.dart
          duration: AppMotion.reduced(context) ? Duration.zero : AppMotion.page,
          switchInCurve: AppMotion.pageEnter,
          child: ListView(
            key: ValueKey(log.id),
            padding: const EdgeInsets.only(
              left: AppSpacing.lg,
              top: AppSpacing.lg,
              right: AppSpacing.lg,
              bottom: AppSpacing.xxl,
            ),
            children: [
              Text(log.articleTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: AppSpacing.md),
              _Prompt(question: log.recallQuestion ?? l10n.recallPromptGeneric),
              const SizedBox(height: AppSpacing.md),
              TextField(
                controller: _notes,
                minLines: 3,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
                // AppTheme มาจาก lib/core/theme.dart
                style: AppTheme.readingInput(context),
                decoration: InputDecoration(hintText: l10n.recallJotHint),
              ),
              const SizedBox(height: AppSpacing.lg),
              if (!_revealed)
                FilledButton.icon(
                  onPressed: () {
                    FocusScope.of(context).unfocus();
                    setState(() => _revealed = true);
                  },
                  icon: const Icon(Icons.visibility_outlined),
                  label: Text(l10n.reveal),
                )
              else
                // liveRegion: เฉลยปรากฏ → โปรแกรมอ่านหน้าจอประกาศให้รู้
                Semantics(liveRegion: true, child: _Answer(log: log)),
              if (_revealed) ...[
                const SizedBox(height: AppSpacing.xl),
                Text(l10n.rateTitle, style: theme.textTheme.titleMedium),
                const SizedBox(height: AppSpacing.sm),
                _RatingButtons(
                  box: log.reviewBox,
                  enabled: !_saving,
                  onRate: _rate,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// คำถามให้นึก: แถบสีอำพันด้านหน้า แบบเดียวกับโน้ตชวนนึกในหน้าอ่าน
class _Prompt extends StatelessWidget {
  const _Prompt({required this.question});

  final String question;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
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
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.psychology_outlined, color: scheme.tertiary),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        question,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppTheme.reading(context).color,
                        ),
                      ),
                    ),
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

/// เฉลย: ประเด็นสำคัญที่ AI ตรวจไว้ (บันทึกเก่าที่ไม่มี = แสดงคำสรุปเดิมแทน)
class _Answer extends StatelessWidget {
  const _Answer({required this.log});

  final StudyLog log;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final points = [...log.keyPoints]
      ..sort((a, b) => (b.core ? 1 : 0).compareTo(a.core ? 1 : 0));
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              points.isEmpty ? l10n.reviewYourSummary : l10n.keyPointsTitle,
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (points.isEmpty)
              Text(log.userSummary, style: AppTheme.readingInput(context))
            else
              // KeyPoint มาจาก lib/models/key_point.dart
              for (final KeyPoint p in points)
                Padding(
                  padding: const EdgeInsets.only(top: AppSpacing.xs),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Icon(
                          p.core ? Icons.star_rounded : Icons.circle,
                          size: p.core ? 18 : 8,
                          color: p.core ? scheme.tertiary : scheme.outline,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(text: p.point),
                              if (p.core)
                                TextSpan(
                                  text: '  · ${l10n.keyPointCore}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                            ],
                          ),
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }
}

/// 4 ปุ่มให้คะแนนตัวเอง แต่ละปุ่มบอกว่าจะได้ทบทวนอีกกี่วัน (2 × 2)
class _RatingButtons extends StatelessWidget {
  const _RatingButtons({
    required this.box,
    required this.enabled,
    required this.onRate,
  });

  final int box;
  final bool enabled;
  final ValueChanged<ReviewRating> onRate;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final options = [
      (ReviewRating.again, l10n.rateAgain, Icons.replay),
      (ReviewRating.hard, l10n.rateHard, Icons.sentiment_neutral),
      (ReviewRating.good, l10n.rateGood, Icons.check),
      (ReviewRating.easy, l10n.rateEasy, Icons.done_all),
    ];
    Widget button((ReviewRating, String, IconData) o) {
      final (rating, label, icon) = o;
      final days = ReviewSchedule.intervalOf(
        ReviewSchedule.nextBox(box, rating),
      );
      return _RateButton(
        icon: icon,
        label: label,
        sub: l10n.nextInDays(days),
        primary: rating == ReviewRating.good,
        onPressed: enabled ? () => onRate(rating) : null,
      );
    }

    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: button(options[0])),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: button(options[1])),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: button(options[2])),
              const SizedBox(width: AppSpacing.xs),
              Expanded(child: button(options[3])),
            ],
          ),
        ),
      ],
    );
  }
}

class _RateButton extends StatelessWidget {
  const _RateButton({
    required this.icon,
    required this.label,
    required this.sub,
    required this.primary,
    required this.onPressed,
  });

  final IconData icon;
  final String label;

  /// "อีก 3 วัน"
  final String sub;

  /// ปุ่มที่ใช้บ่อยที่สุด ("ดี") เด่นกว่าปุ่มอื่น
  final bool primary;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final content = Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18),
              const SizedBox(width: AppSpacing.xxs),
              Flexible(child: Text(label)),
            ],
          ),
          // ใช้สีตัวอักษรของปุ่ม (ปุ่มทึบ/ปุ่มอ่อนสีต่างกัน) ไม่ใช่สีตัวอักษรของธีม
          Builder(
            builder: (context) => Text(
              sub,
              style: theme.textTheme.labelSmall?.copyWith(
                color: DefaultTextStyle.of(context).style.color,
              ),
            ),
          ),
        ],
      ),
    );
    final shape = const RoundedRectangleBorder(
      borderRadius: AppRadius.controlAll,
    );
    return Semantics(
      button: true,
      label: '$label, $sub',
      excludeSemantics: true,
      onTap: onPressed,
      child: primary
          ? FilledButton(
              style: FilledButton.styleFrom(shape: shape),
              onPressed: onPressed,
              child: content,
            )
          : FilledButton.tonal(
              style: FilledButton.styleFrom(shape: shape),
              onPressed: onPressed,
              child: content,
            ),
    );
  }
}
