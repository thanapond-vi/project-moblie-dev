import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/radius.dart';
import '../core/spacing.dart';
import '../l10n/l10n.dart';
import '../models/review_schedule.dart';
import '../models/study_log.dart';
import '../services/settings_service.dart';
import '../services/study_log_repository.dart';
import '../widgets/keep_app_bar.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/stat_tile.dart';
import '../widgets/ui_helpers.dart';
import 'review_session_screen.dart';

/// แท็บทบทวน: บทความที่ถึงรอบทบทวนวันนี้ + กล่องความจำ 5 ใบ + รอบถัดไป
class ReviewScreen extends StatefulWidget {
  const ReviewScreen({
    super.key,
    required this.user,
    required this.onOpenProfile,
  });

  final User user;
  final VoidCallback onOpenProfile;

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  // StudyLog มาจาก lib/models/study_log.dart
  // StudyLogRepository มาจาก lib/services/study_log_repository.dart
  late Stream<List<StudyLog>> _logs = StudyLogRepository().watchLogs(
    widget.user.uid,
  );

  void _start(List<StudyLog> queue) => Navigator.push(
    context,
    // ReviewSessionScreen มาจาก lib/screens/review_session_screen.dart
    MaterialPageRoute(builder: (_) => ReviewSessionScreen(queue: queue)),
  );

  @override
  Widget build(BuildContext context) {
    // context.l10n มาจาก lib/l10n/l10n.dart
    final l10n = context.l10n;
    return Scaffold(
      // KeepAppBar มาจาก lib/widgets/keep_app_bar.dart
      appBar: KeepAppBar(onOpenProfile: widget.onOpenProfile),
      body: StreamBuilder<List<StudyLog>>(
        stream: _logs,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            // ErrorView มาจาก lib/widgets/ui_helpers.dart
            return ErrorView(
              message: l10n.historyLoadError('${snapshot.error}'),
              onRetry: () => setState(() {
                _logs = StudyLogRepository().watchLogs(widget.user.uid);
              }),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          return ReviewBody(logs: snapshot.data!, onStart: _start);
        },
      ),
    );
  }
}

/// เนื้อหาแท็บทบทวน (แยกจาก Firestore เพื่อทดสอบด้วยข้อมูลจำลองได้)
class ReviewBody extends StatelessWidget {
  const ReviewBody({
    super.key,
    required this.logs,
    required this.onStart,
    this.now,
  });

  final List<StudyLog> logs;

  /// เริ่มทบทวนตามลำดับในรายการที่ส่งมา
  final ValueChanged<List<StudyLog>> onStart;

  /// เวลาปัจจุบัน (ใส่ได้ในเทสต์)
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final today = now ?? DateTime.now();
    // ReviewSchedule มาจาก lib/models/review_schedule.dart
    final due = ReviewSchedule.dueList(logs, today);
    final upcoming = ReviewSchedule.upcoming(logs, today);
    final dateFormat = DateFormat.MMMEd(
      // SettingsService มาจาก lib/services/settings_service.dart
      SettingsService.instance.appLanguage.value.code,
    );

    return ListView(
      padding: EdgeInsets.only(
        // AppSpacing มาจาก lib/core/spacing.dart
        left: AppSpacing.md,
        top: AppSpacing.xs,
        right: AppSpacing.md,
        // เว้นที่ให้แถบเมนูแคปซูลที่ลอยทับด้านล่าง
        bottom: AppSpacing.xl + MediaQuery.paddingOf(context).bottom,
      ),
      // staggered มาจาก lib/widgets/motion_widgets.dart
      children: staggered([
        _DueHero(
          dueCount: due.length,
          hasLogs: logs.isNotEmpty,
          nextDate: upcoming.isEmpty
              ? null
              : dateFormat.format(ReviewSchedule.dueDay(upcoming.first)),
          onStart: due.isEmpty ? null : () => onStart(due),
        ),
        if (logs.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.lg),
          _Boxes(counts: ReviewSchedule.boxCounts(logs)),
        ],
        if (due.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(icon: Icons.today_outlined, text: l10n.dueToday),
          const SizedBox(height: AppSpacing.sm),
          for (final (i, log) in due.indexed)
            _ReviewCard(
              log: log,
              status: ReviewSchedule.overdueDays(log, today) > 0
                  ? l10n.overdueDays(ReviewSchedule.overdueDays(log, today))
                  : l10n.dueToday,
              overdue: ReviewSchedule.overdueDays(log, today) > 0,
              // เริ่มที่เรื่องนี้ แล้วทบทวนเรื่องที่เหลือต่อ
              onTap: () => onStart([...due.skip(i), ...due.take(i)]),
            ),
        ],
        if (upcoming.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xl),
          _SectionTitle(icon: Icons.event_outlined, text: l10n.comingUp),
          const SizedBox(height: AppSpacing.sm),
          for (final log in upcoming.take(5))
            _ReviewCard(
              log: log,
              status: l10n.dueOn(dateFormat.format(ReviewSchedule.dueDay(log))),
              overdue: false,
            ),
        ],
      ]),
    );
  }
}

/// การ์ดบน: วันนี้ต้องทบทวนกี่เรื่อง + ปุ่มเริ่ม (จุดเด่นของแท็บ)
class _DueHero extends StatelessWidget {
  const _DueHero({
    required this.dueCount,
    required this.hasLogs,
    required this.nextDate,
    required this.onStart,
  });

  final int dueCount;
  final bool hasLogs;
  final String? nextDate;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final String sub;
    if (!hasLogs) {
      sub = l10n.reviewEmptyAll;
    } else if (dueCount > 0) {
      sub = l10n.reviewDueSub;
    } else {
      sub = nextDate == null ? '' : l10n.reviewAllDone(nextDate!);
    }
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(Icons.psychology_outlined, color: scheme.tertiary),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.reviewDueTitle(dueCount),
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
              ],
            ),
            if (sub.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(
                sub,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
            if (onStart != null) ...[
              const SizedBox(height: AppSpacing.lg),
              FilledButton.icon(
                onPressed: onStart,
                icon: const Icon(Icons.play_arrow_rounded),
                label: Text(l10n.startReview),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// กล่องความจำ 5 ใบ: จำนวนบทความในแต่ละกล่อง + ระยะห่างของกล่องนั้น
class _Boxes extends StatelessWidget {
  const _Boxes({required this.counts});

  final List<int> counts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Semantics(
              header: true,
              child: Text(
                l10n.reviewBoxesTitle,
                style: theme.textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: AppSpacing.xxs),
            Text(
              l10n.reviewBoxesHint,
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            // สูงเท่ากันทุกช่อง แม้ป้ายบางช่องยาวจนขึ้นบรรทัดใหม่
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var i = 0; i < counts.length; i++) ...[
                    if (i > 0) const SizedBox(width: AppSpacing.xxs),
                    Expanded(
                      // StatTile มาจาก lib/widgets/stat_tile.dart
                      child: StatTile(
                        value: counts[i],
                        label: l10n.boxLabel(i + 1),
                        caption: l10n.everyDays(ReviewSchedule.intervals[i]),
                        color: scheme.primary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Row(
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.primary),
          const SizedBox(width: AppSpacing.xs),
          Expanded(child: Text(text, style: theme.textTheme.titleLarge)),
        ],
      ),
    );
  }
}

/// บทความ 1 เรื่องในรายการทบทวน: ชื่อ, กล่องปัจจุบัน, สถานะวันครบกำหนด
/// [onTap] = null → แสดงอย่างเดียว (รอบถัดไป ยังทบทวนไม่ได้)
class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.log,
    required this.status,
    required this.overdue,
    this.onTap,
  });

  final StudyLog log;
  final String status;
  final bool overdue;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final box = log.reviewBox < 1 ? 1 : log.reviewBox;
    final muted = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Card(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Row(
            children: [
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
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xxs,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xs,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainer,
                            // AppRadius มาจาก lib/core/radius.dart
                            borderRadius: AppRadius.pillAll,
                          ),
                          child: Text(
                            '${l10n.boxLabel(box)} · '
                            '${l10n.everyDays(ReviewSchedule.intervalOf(box))}',
                            style: muted,
                          ),
                        ),
                        // เลยกำหนด = ไอคอน + สีอำพัน (ไม่ใช้สีอย่างเดียว)
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              overdue ? Icons.schedule : Icons.event_available,
                              size: 14,
                              color: overdue ? scheme.tertiary : scheme.outline,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              status,
                              style: muted?.copyWith(
                                color: overdue
                                    ? scheme.tertiary
                                    : scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (onTap != null) ...[
                const SizedBox(width: AppSpacing.xs),
                Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
