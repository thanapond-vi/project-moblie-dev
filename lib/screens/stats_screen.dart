import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../core/spacing.dart';
import '../l10n/l10n.dart';
import '../models/article_tag.dart';
import '../models/period_stats.dart';
import '../models/study_log.dart';
import '../services/settings_service.dart';
import '../services/study_log_repository.dart';
import '../widgets/charts.dart';
import '../widgets/keep_app_bar.dart';
import '../widgets/motion_widgets.dart';
import '../widgets/stat_tile.dart';
import '../widgets/ui_helpers.dart';

/// แท็บสถิติ: ดูภาพรวมการอ่านตามช่วงเวลา (7 วัน / 30 วัน / ทั้งหมด)
/// คำนวณจากประวัติใน Firestore ทั้งหมดในเครื่อง ไม่ต้องเก็บสถิติแยก
class StatsScreen extends StatefulWidget {
  const StatsScreen({
    super.key,
    required this.user,
    required this.onOpenProfile,
  });

  final User user;
  final VoidCallback onOpenProfile;

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  // StudyLog มาจาก lib/models/study_log.dart
  // StudyLogRepository มาจาก lib/services/study_log_repository.dart
  late Stream<List<StudyLog>> _logs = StudyLogRepository().watchLogs(
    widget.user.uid,
  );
  // StatsRange มาจาก lib/models/period_stats.dart
  StatsRange _range = StatsRange.week;

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
          return StatsBody(
            logs: snapshot.data!,
            range: _range,
            onRange: (r) => setState(() => _range = r),
          );
        },
      ),
    );
  }
}

/// เนื้อหาแท็บสถิติ (แยกจาก Firestore เพื่อทดสอบด้วยข้อมูลจำลองได้)
class StatsBody extends StatelessWidget {
  const StatsBody({
    super.key,
    required this.logs,
    required this.range,
    required this.onRange,
    this.now,
  });

  final List<StudyLog> logs;
  final StatsRange range;
  final ValueChanged<StatsRange> onRange;

  /// เวลาปัจจุบัน (ใส่ได้ในเทสต์)
  final DateTime? now;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    // PeriodStats มาจาก lib/models/period_stats.dart
    final today = PeriodStats.day(now ?? DateTime.now());
    final stats = PeriodStats.from(logs, range, now: today);
    // SettingsService มาจาก lib/services/settings_service.dart
    final locale = SettingsService.instance.appLanguage.value.code;

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
        SizedBox(
          width: double.infinity,
          child: SegmentedButton<StatsRange>(
            showSelectedIcon: false,
            segments: [
              ButtonSegment(value: StatsRange.week, label: Text(l10n.range7)),
              ButtonSegment(value: StatsRange.month, label: Text(l10n.range30)),
              ButtonSegment(value: StatsRange.all, label: Text(l10n.rangeAll)),
            ],
            selected: {range},
            onSelectionChanged: (s) => onRange(s.first),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                // StatTile มาจาก lib/widgets/stat_tile.dart
                child: StatTile(
                  key: ValueKey('min-$range'),
                  value: stats.minutes,
                  unit: l10n.unitMinutes,
                  label: l10n.statTotalTime,
                  color: scheme.primary,
                  caption: _short(l10n, stats.minutes, stats.previousMinutes),
                  captionSemantics: _change(
                    l10n,
                    stats.minutes,
                    stats.previousMinutes,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: StatTile(
                  key: ValueKey('read-$range'),
                  value: stats.articles,
                  label: l10n.statRead,
                  color: scheme.onSurface,
                  caption: _short(l10n, stats.articles, stats.previousArticles),
                  captionSemantics: _change(
                    l10n,
                    stats.articles,
                    stats.previousArticles,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: StatTile(
                  key: ValueKey('avg-$range'),
                  value: stats.averageScore,
                  unit: '/100',
                  label: l10n.statAvgScore,
                  color: scheme.secondary,
                  caption: _short(
                    l10n,
                    stats.averageScore,
                    stats.previousAverageScore,
                  ),
                  captionSemantics: _change(
                    l10n,
                    stats.averageScore,
                    stats.previousAverageScore,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (stats.isEmpty) ...[
          _EmptyPeriod(text: l10n.statsEmpty),
          const SizedBox(height: AppSpacing.lg),
        ] else ...[
          _minutesCard(context, stats, locale),
          const SizedBox(height: AppSpacing.md),
          _scoresCard(context, stats, locale),
          const SizedBox(height: AppSpacing.md),
        ],
        _calendarCard(context, today, locale),
        if (stats.topics.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          _topicsCard(context, stats),
        ],
      ]),
    );
  }

  // AppLocalizations มาจาก lib/l10n/gen/app_localizations.dart
  /// "↑ 12" สั้นๆ บนช่องสถิติ (ข้อความเต็มอยู่ใน semantics)
  static String? _short(AppLocalizations l10n, int? now, int? before) {
    if (now == null || before == null) return null;
    final diff = now - before;
    if (diff == 0) return '=';
    return diff > 0 ? '↑ $diff' : '↓ ${-diff}';
  }

  /// "↑ 12 จากช่วงก่อน" (null = ไม่มีให้เทียบ เช่น ช่วงทั้งหมด หรือยังไม่มีคะแนน)
  static String? _change(AppLocalizations l10n, int? now, int? before) {
    if (now == null || before == null) return null;
    final diff = now - before;
    if (diff == 0) return l10n.changeSame;
    return diff > 0 ? l10n.changeUp('$diff') : l10n.changeDown('${-diff}');
  }

  Widget _minutesCard(BuildContext context, PeriodStats stats, String locale) {
    final l10n = context.l10n;
    final buckets = stats.buckets;
    final dayFormat = DateFormat.MMMd(locale);
    final weekdayFormat = DateFormat.E(locale);
    // MinutesBucket มาจาก lib/models/period_stats.dart
    String nameOf(MinutesBucket b) => stats.weekly
        ? l10n.weekOf(dayFormat.format(b.start))
        : '${weekdayFormat.format(b.start)} ${dayFormat.format(b.start)}';

    // ป้ายแกนล่าง: 7 แท่ง = ทุกแท่ง (ชื่อวัน), มากกว่านั้น = แท่งแรก กลาง สุดท้าย
    final n = buckets.length;
    final axis = [
      for (var i = 0; i < n; i++)
        n <= 7
            ? weekdayFormat.format(buckets[i].start)
            : (i == 0 || i == n - 1 || i == n ~/ 2)
            ? dayFormat.format(buckets[i].start)
            : '',
    ];
    final busiest = buckets.reduce((a, b) => b.minutes > a.minutes ? b : a);
    // ChartCard มาจาก lib/widgets/charts.dart
    return ChartCard(
      title: l10n.statsMinutesTitle,
      summary: l10n.minutesSummary(
        stats.minutes,
        busiest.minutes,
        nameOf(busiest),
      ),
      table: [
        for (final b in buckets.reversed)
          if (b.minutes > 0) (nameOf(b), l10n.minutesValue(b.minutes)),
      ],
      // BarChart มาจาก lib/widgets/charts.dart
      chart: BarChart(
        values: [for (final b in buckets) b.minutes],
        axisLabels: axis,
        maxLabel: l10n.minutesValue,
        describe: (i) =>
            '${nameOf(buckets[i])} · ${l10n.minutesValue(buckets[i].minutes)}',
      ),
    );
  }

  Widget _scoresCard(BuildContext context, PeriodStats stats, String locale) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final points = stats.scores;
    final dayFormat = DateFormat.MMMd(locale);
    if (points.isEmpty) {
      return ChartCard(
        title: l10n.statsScoresTitle,
        summary: l10n.noScoresYet,
        table: const [],
        chart: Text(
          l10n.noScoresYet,
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      );
    }
    return ChartCard(
      title: l10n.statsScoresTitle,
      summary: l10n.scoresSummary(
        points.length,
        points.last.score,
        stats.averageScore ?? 0,
      ),
      table: [
        for (final p in points.reversed)
          ('${dayFormat.format(p.at)} · ${p.title}', '${p.score}'),
      ],
      // ScoreLineChart มาจาก lib/widgets/charts.dart
      chart: ScoreLineChart(
        scores: [for (final p in points) p.score],
        describe: (i) =>
            '${dayFormat.format(points[i].at)} · ${points[i].title} · ${points[i].score}',
      ),
    );
  }

  Widget _calendarCard(BuildContext context, DateTime today, String locale) {
    final theme = Theme.of(context);
    final l10n = context.l10n;
    final calendar = PeriodStats.calendar(logs, now: today);
    final firstDay = PeriodStats.weekStart(
      DateTime(
        today.year,
        today.month,
        today.day - (PeriodStats.calendarWeeks - 1) * 7,
      ),
    );
    final longest = PeriodStats.longestStreak(logs);
    final dayFormat = DateFormat.yMMMd(locale);
    // ป้ายวันแบบย่อ (Mon / จ. / 周一) แสดงแค่ จันทร์ พุธ ศุกร์ อาทิตย์ (ตัวเดียวแยกเสาร์/อาทิตย์ไม่ออก)
    final narrow = DateFormat.E(locale);
    final weekdays = [
      for (var d = 0; d < 7; d++)
        d.isEven
            ? narrow.format(
                DateTime(firstDay.year, firstDay.month, firstDay.day + d),
              )
            : '',
    ];
    final days = calendar.keys.toList()..sort((a, b) => b.compareTo(a));
    return ChartCard(
      title: l10n.statsCalendarTitle,
      summary: l10n.calendarSummary(calendar.length, longest),
      trailing: Text(
        l10n.longestStreak(longest),
        style: theme.textTheme.labelMedium?.copyWith(
          color: theme.colorScheme.tertiary,
        ),
      ),
      table: [
        for (final d in days)
          (dayFormat.format(d), l10n.minutesValue(calendar[d]!)),
      ],
      // ReadingCalendar มาจาก lib/widgets/charts.dart
      chart: ReadingCalendar(
        minutesByDay: calendar,
        firstDay: firstDay,
        today: today,
        weeks: PeriodStats.calendarWeeks,
        weekdayLabels: weekdays,
        describe: (day, minutes) =>
            '${dayFormat.format(day)} · ${l10n.minutesValue(minutes)}',
      ),
    );
  }

  Widget _topicsCard(BuildContext context, PeriodStats stats) {
    final l10n = context.l10n;
    final topics = stats.topics;
    final most = topics.first.count;
    // TopicCount มาจาก lib/models/period_stats.dart
    String name(TopicCount t) =>
        // tagLabel มาจาก lib/l10n/l10n.dart
        t.tag == null ? l10n.otherTopics : tagLabel(t.tag!, l10n);
    String value(TopicCount t) => t.averageScore == null
        ? '${t.count}'
        : l10n.topicValue(t.count, t.averageScore!);
    return ChartCard(
      title: l10n.statsTopicsTitle,
      summary: l10n.topicsSummary(name(topics.first), topics.first.count),
      table: [for (final t in topics) (name(t), value(t))],
      chart: Column(
        children: [
          for (final t in topics)
            // TopicBar มาจาก lib/widgets/charts.dart
            TopicBar(
              icon: t.tag == null
                  ? Icons.more_horiz
                  // ArticleTag มาจาก lib/models/article_tag.dart
                  : ArticleTag.fromId(t.tag!)?.icon ?? Icons.tag,
              label: name(t),
              fraction: t.count / most,
              value: value(t),
            ),
        ],
      ),
    );
  }
}

class _EmptyPeriod extends StatelessWidget {
  const _EmptyPeriod({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Row(
          children: [
            Icon(Icons.insights_outlined, color: theme.colorScheme.secondary),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                text,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
