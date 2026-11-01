import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/radius.dart';
import '../core/spacing.dart';
import '../l10n/l10n.dart';

/// การ์ดกราฟ: หัวข้อ + บรรทัดค่าที่แตะเลือก + กราฟ และปุ่มสลับเป็นตาราง
///
/// - [summary] = คำอธิบายกราฟทั้งรูปสำหรับโปรแกรมอ่านหน้าจอ (กราฟเองไม่ถูกอ่านทีละจุด)
/// - [table] = ข้อมูลเดียวกันเป็นแถว (ป้าย, ค่า) ให้คนที่อ่านกราฟยากดูเป็นตัวหนังสือ
class ChartCard extends StatefulWidget {
  const ChartCard({
    super.key,
    required this.title,
    required this.summary,
    required this.table,
    required this.chart,
    this.trailing,
  });

  final String title;
  final String summary;
  final List<(String, String)> table;
  final Widget chart;

  /// ข้อมูลเสริมใต้หัวข้อ (เช่น วันติดกันยาวที่สุด)
  final Widget? trailing;

  @override
  State<ChartCard> createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  bool _asTable = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // context.l10n มาจาก lib/l10n/l10n.dart
    final l10n = context.l10n;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsetsDirectional.only(
          // AppSpacing มาจาก lib/core/spacing.dart
          start: AppSpacing.md,
          top: AppSpacing.xs,
          end: AppSpacing.xxs,
          bottom: AppSpacing.md,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Semantics(
                    header: true,
                    child: Text(
                      widget.title,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _asTable ? l10n.showChart : l10n.showTable,
                  icon: Icon(
                    _asTable ? Icons.bar_chart : Icons.table_rows_outlined,
                  ),
                  color: scheme.onSurfaceVariant,
                  onPressed: () => setState(() => _asTable = !_asTable),
                ),
              ],
            ),
            if (widget.trailing != null) ...[
              widget.trailing!,
              const SizedBox(height: AppSpacing.sm),
            ],
            Padding(
              padding: const EdgeInsetsDirectional.only(end: AppSpacing.sm),
              child: AnimatedSwitcher(
                // AppMotion มาจาก lib/core/motion.dart
                duration: AppMotion.reduced(context)
                    ? Duration.zero
                    : AppMotion.select,
                child: _asTable
                    ? _ChartTable(
                        key: const ValueKey('table'),
                        rows: widget.table,
                      )
                    : Semantics(
                        key: const ValueKey('chart'),
                        label: widget.summary,
                        child: widget.chart,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ChartTable extends StatelessWidget {
  const _ChartTable({super.key, required this.rows});

  final List<(String, String)> rows;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        for (final (label, value) in rows)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  value,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// บรรทัดค่าที่เลือก (อยู่เหนือกราฟตลอด ไม่ลอยทับข้อมูล) ยังไม่เลือก = คำแนะนำให้แตะ
class _SelectionLine extends StatelessWidget {
  const _SelectionLine({required this.text});

  final String? text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final selected = text != null;
    return ExcludeSemantics(
      child: Padding(
        padding: const EdgeInsets.only(bottom: AppSpacing.xs),
        child: Text(
          text ?? context.l10n.chartTapHint,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.labelMedium?.copyWith(
            color: selected ? scheme.onSurface : scheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// ค่า 0 → 1 ตอนกราฟปรากฏ (แท่งโตจากฐาน / เส้นค่อยๆ ลาก) ปิดเมื่อเปิด Reduce Motion
class _Grow extends StatelessWidget {
  const _Grow({required this.builder, required this.dataKey});

  final Widget Function(double t) builder;

  /// เปลี่ยนชุดข้อมูล (เช่น เปลี่ยนช่วงเวลา) = เล่นใหม่
  final Object dataKey;

  @override
  Widget build(BuildContext context) {
    if (AppMotion.reduced(context)) return builder(1);
    return TweenAnimationBuilder<double>(
      key: ValueKey(dataKey),
      tween: Tween(begin: 0, end: 1),
      duration: Durations.long4,
      curve: AppMotion.entranceCurve,
      builder: (context, t, _) => builder(t),
    );
  }
}

// ---------------------------------------------------------------------------
// กราฟแท่ง: เวลาอ่านรายวัน/รายสัปดาห์
// ---------------------------------------------------------------------------

/// กราฟแท่งแนวตั้ง สีเดียว (primary) แตะแท่งเพื่อดูค่า
class BarChart extends StatefulWidget {
  const BarChart({
    super.key,
    required this.values,
    required this.axisLabels,
    required this.describe,
    required this.maxLabel,
    this.height = 160,
  });

  final List<int> values;

  /// ป้ายใต้แท่ง (ว่าง = ไม่แสดงใต้แท่งนั้น)
  final List<String> axisLabels;

  /// ข้อความเมื่อแตะแท่งที่ i เช่น "จ. 2 พ.ย. · 12 นาที"
  final String Function(int index) describe;

  /// ป้ายเส้นบนสุดของกราฟ (ค่าสูงสุด)
  final String Function(int max) maxLabel;
  final double height;

  @override
  State<BarChart> createState() => _BarChartState();
}

class _BarChartState extends State<BarChart> {
  int? _selected;

  @override
  void didUpdateWidget(BarChart old) {
    super.didUpdateWidget(old);
    if (old.values.length != widget.values.length) _selected = null;
  }

  int _indexAt(double dx, double width) => (dx / width * widget.values.length)
      .floor()
      .clamp(0, widget.values.length - 1);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final max = widget.values.fold(0, (a, b) => a > b ? a : b);
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectionLine(
          text: _selected == null ? null : widget.describe(_selected!),
        ),
        if (max > 0)
          ExcludeSemantics(
            child: Text(widget.maxLabel(max), style: labelStyle),
          ),
        LayoutBuilder(
          builder: (context, constraints) => GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTapDown: (d) => setState(
              () => _selected = _indexAt(
                d.localPosition.dx,
                constraints.maxWidth,
              ),
            ),
            child: _Grow(
              dataKey: Object.hashAll(widget.values),
              builder: (t) => CustomPaint(
                size: Size(constraints.maxWidth, widget.height),
                painter: _BarPainter(
                  values: widget.values,
                  max: max,
                  progress: t,
                  selected: _selected,
                  bar: scheme.primary,
                  empty: scheme.surfaceContainerHigh,
                  grid: scheme.outlineVariant,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xxs),
        ExcludeSemantics(
          // แท่งน้อย (≤ 7): ป้ายอยู่ใต้แต่ละแท่ง / แท่งเยอะ: ป้ายที่มีชิดซ้าย-กลาง-ขวา ไม่ล้นขอบ
          child: widget.values.length <= 7
              ? Row(
                  children: [
                    for (final label in widget.axisLabels)
                      Expanded(
                        child: Text(
                          label,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          softWrap: false,
                          style: labelStyle,
                        ),
                      ),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    for (final label in widget.axisLabels)
                      if (label.isNotEmpty) Text(label, style: labelStyle),
                  ],
                ),
        ),
      ],
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.values,
    required this.max,
    required this.progress,
    required this.selected,
    required this.bar,
    required this.empty,
    required this.grid,
  });

  final List<int> values;
  final int max;
  final double progress;
  final int? selected;
  final Color bar;
  final Color empty;
  final Color grid;

  @override
  void paint(Canvas canvas, Size size) {
    // เส้นฐานและเส้นค่าสูงสุด (จางๆ ไม่แย่งความสนใจจากแท่ง)
    final gridPaint = Paint()
      ..color = grid
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      gridPaint,
    );
    canvas.drawLine(Offset.zero, Offset(size.width, 0), gridPaint);

    if (values.isEmpty) return;
    final slot = size.width / values.length;
    final width = (slot * 0.6).clamp(2.0, 24.0);
    for (var i = 0; i < values.length; i++) {
      final cx = slot * i + slot / 2;
      final v = values[i];
      if (v == 0 || max == 0) {
        // วันที่ไม่ได้อ่าน: ตอเล็กๆ ให้เห็นว่ามีวันนั้นอยู่
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(cx - width / 2, size.height - 2, width, 2),
            const Radius.circular(1),
          ),
          Paint()..color = empty,
        );
        continue;
      }
      final h = (size.height - 2) * (v / max) * progress;
      final dim = selected != null && selected != i;
      canvas.drawRRect(
        RRect.fromRectAndCorners(
          Rect.fromLTWH(cx - width / 2, size.height - h, width, h),
          topLeft: const Radius.circular(4),
          topRight: const Radius.circular(4),
        ),
        Paint()..color = dim ? bar.withValues(alpha: 0.45) : bar,
      );
    }
  }

  @override
  bool shouldRepaint(_BarPainter old) =>
      old.values != values ||
      old.progress != progress ||
      old.selected != selected ||
      old.bar != bar;
}

// ---------------------------------------------------------------------------
// กราฟเส้น: คะแนนตามเวลา
// ---------------------------------------------------------------------------

/// คะแนน 0–100 เรียงตามเวลา (จุดละ 1 บทความ) มีเส้นประเกณฑ์ 60 และ 80
class ScoreLineChart extends StatefulWidget {
  const ScoreLineChart({
    super.key,
    required this.scores,
    required this.describe,
    this.height = 160,
  });

  final List<int> scores;
  final String Function(int index) describe;
  final double height;

  /// เกณฑ์ระดับ "จำได้ดี" และ "จำได้แม่น" (ตรงกับ ScoreLevel)
  static const thresholds = [60, 80];

  @override
  State<ScoreLineChart> createState() => _ScoreLineChartState();
}

class _ScoreLineChartState extends State<ScoreLineChart> {
  int? _selected;

  @override
  void didUpdateWidget(ScoreLineChart old) {
    super.didUpdateWidget(old);
    if (old.scores.length != widget.scores.length) _selected = null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectionLine(
          text: _selected == null ? null : widget.describe(_selected!),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: (d) {
                final n = widget.scores.length;
                if (n == 0) return;
                // จุดที่ใกล้นิ้วที่สุดในแนวนอน
                final x = _ScorePainter.inset;
                final step = n == 1 ? 0.0 : (width - 2 * x) / (n - 1);
                final i = step == 0
                    ? 0
                    : ((d.localPosition.dx - x) / step).round().clamp(0, n - 1);
                setState(() => _selected = i);
              },
              child: _Grow(
                dataKey: Object.hashAll(widget.scores),
                builder: (t) => CustomPaint(
                  size: Size(width, widget.height),
                  painter: _ScorePainter(
                    scores: widget.scores,
                    progress: t,
                    selected: _selected,
                    line: scheme.primary,
                    ring: scheme.surfaceContainerLow,
                    grid: scheme.outlineVariant,
                    label: theme.textTheme.labelSmall!.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}

class _ScorePainter extends CustomPainter {
  _ScorePainter({
    required this.scores,
    required this.progress,
    required this.selected,
    required this.line,
    required this.ring,
    required this.grid,
    required this.label,
  });

  /// ระยะเว้นซ้าย/ขวา ไม่ให้จุดแรก/สุดท้ายชิดขอบ
  static const inset = 8.0;

  final List<int> scores;
  final double progress;
  final int? selected;
  final Color line;
  final Color ring;
  final Color grid;
  final TextStyle label;

  @override
  void paint(Canvas canvas, Size size) {
    const top = 8.0;
    final h = size.height - top - 4;
    double y(num score) => top + h * (1 - score / 100);

    // เส้นประเกณฑ์ 60 / 80 + ตัวเลขกำกับทางขวา
    final dash = Paint()
      ..color = grid
      ..strokeWidth = 1;
    for (final t in ScoreLineChart.thresholds) {
      final yy = y(t);
      for (var x = 0.0; x < size.width - 24; x += 8) {
        canvas.drawLine(Offset(x, yy), Offset(x + 4, yy), dash);
      }
      final tp = TextPainter(
        text: TextSpan(text: '$t', style: label),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(size.width - tp.width, yy - tp.height / 2));
    }
    canvas.drawLine(Offset(0, y(0)), Offset(size.width, y(0)), dash);

    if (scores.isEmpty) return;
    final n = scores.length;
    final usable = size.width - 2 * inset - 24;
    final step = n == 1 ? 0.0 : usable / (n - 1);
    Offset at(int i) =>
        Offset(n == 1 ? inset + usable / 2 : inset + step * i, y(scores[i]));

    // เส้นค่อยๆ ลากจากซ้ายไปขวาตาม progress
    final visible = ((n - 1) * progress).clamp(0, n - 1).toDouble();
    if (n > 1) {
      final path = Path()..moveTo(at(0).dx, at(0).dy);
      final whole = visible.floor();
      for (var i = 1; i <= whole; i++) {
        path.lineTo(at(i).dx, at(i).dy);
      }
      if (whole < n - 1) {
        final frac = visible - whole;
        final p = Offset.lerp(at(whole), at(whole + 1), frac)!;
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(
        path,
        Paint()
          ..color = line
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    // จุด 8 px + วงขอบสีพื้น 2 px (เห็นชัดแม้จุดทับเส้น) จุดที่เลือกใหญ่ขึ้น
    for (var i = 0; i < n; i++) {
      if (i > visible + 0.001) break;
      final r = i == selected ? 6.0 : 4.0;
      canvas.drawCircle(at(i), r + 2, Paint()..color = ring);
      canvas.drawCircle(at(i), r, Paint()..color = line);
    }
  }

  @override
  bool shouldRepaint(_ScorePainter old) =>
      old.scores != scores ||
      old.progress != progress ||
      old.selected != selected ||
      old.line != line;
}

// ---------------------------------------------------------------------------
// ปฏิทินการอ่าน 12 สัปดาห์
// ---------------------------------------------------------------------------

/// ตาราง 7 แถว (จันทร์–อาทิตย์) × N สัปดาห์ ช่องสว่างขึ้นตามนาทีที่อ่านในวันนั้น
/// สีเดียว (primary) ไล่ความทึบ 4 ระดับ วันนี้มีกรอบ
class ReadingCalendar extends StatefulWidget {
  const ReadingCalendar({
    super.key,
    required this.minutesByDay,
    required this.firstDay,
    required this.today,
    required this.weeks,
    required this.weekdayLabels,
    required this.describe,
  });

  final Map<DateTime, int> minutesByDay;

  /// วันจันทร์ของสัปดาห์แรก
  final DateTime firstDay;
  final DateTime today;
  final int weeks;

  /// ป้ายวันจันทร์–อาทิตย์ (7 ค่า ว่าง = ไม่แสดง)
  final List<String> weekdayLabels;
  final String Function(DateTime day, int minutes) describe;

  /// ความทึบตามนาที: 1–9 / 10–19 / 20–29 / 30+
  static double levelOf(int minutes) => switch (minutes) {
    0 => 0,
    < 10 => 0.35,
    < 20 => 0.6,
    < 30 => 0.8,
    _ => 1,
  };

  @override
  State<ReadingCalendar> createState() => _ReadingCalendarState();
}

class _ReadingCalendarState extends State<ReadingCalendar> {
  DateTime? _selected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final l10n = context.l10n;
    final labelStyle = theme.textTheme.labelSmall?.copyWith(
      color: scheme.onSurfaceVariant,
    );
    const gap = 3.0;
    const labelWidth = 32.0;

    Color cellColor(double level) => level == 0
        ? scheme.surfaceContainerHigh
        : scheme.primary.withValues(alpha: level);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SelectionLine(
          text: _selected == null
              ? null
              : widget.describe(
                  _selected!,
                  widget.minutesByDay[_selected!] ?? 0,
                ),
        ),
        LayoutBuilder(
          builder: (context, constraints) {
            final cell =
                ((constraints.maxWidth -
                            labelWidth -
                            gap * (widget.weeks - 1)) /
                        widget.weeks)
                    .clamp(8.0, 22.0);
            return ExcludeSemantics(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: labelWidth,
                    child: Column(
                      children: [
                        for (final label in widget.weekdayLabels)
                          SizedBox(
                            height: cell + gap,
                            child: Align(
                              alignment: AlignmentDirectional.centerStart,
                              child: Text(label, style: labelStyle),
                            ),
                          ),
                      ],
                    ),
                  ),
                  for (var w = 0; w < widget.weeks; w++)
                    Padding(
                      padding: EdgeInsetsDirectional.only(
                        end: w == widget.weeks - 1 ? 0 : gap,
                      ),
                      child: Column(
                        children: [
                          for (var d = 0; d < 7; d++)
                            _cell(
                              DateTime(
                                widget.firstDay.year,
                                widget.firstDay.month,
                                widget.firstDay.day + w * 7 + d,
                              ),
                              cell,
                              gap,
                              cellColor,
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        // คำอธิบายระดับสี: น้อย ▢▢▢▢▢ มาก
        ExcludeSemantics(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(l10n.legendLess, style: labelStyle),
              const SizedBox(width: AppSpacing.xxs),
              for (final level in const [0.0, 0.35, 0.6, 0.8, 1.0])
                Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 1.5),
                  decoration: BoxDecoration(
                    color: cellColor(level),
                    borderRadius: const BorderRadius.all(Radius.circular(3)),
                  ),
                ),
              const SizedBox(width: AppSpacing.xxs),
              Text(l10n.legendMore, style: labelStyle),
            ],
          ),
        ),
      ],
    );
  }

  Widget _cell(
    DateTime day,
    double size,
    double gap,
    Color Function(double) color,
  ) {
    final scheme = Theme.of(context).colorScheme;
    final future = day.isAfter(widget.today);
    final minutes = widget.minutesByDay[day] ?? 0;
    return Padding(
      padding: EdgeInsets.only(bottom: gap),
      child: GestureDetector(
        onTap: future ? null : () => setState(() => _selected = day),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            // วันในอนาคต (สัปดาห์นี้) = ไม่มีช่อง
            color: future
                ? scheme.surfaceContainerLow
                : color(ReadingCalendar.levelOf(minutes)),
            borderRadius: const BorderRadius.all(Radius.circular(3)),
            border: day == widget.today || day == _selected
                ? Border.all(color: scheme.onSurface, width: 1.5)
                : null,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// แท่งแนวนอน: หมวดที่อ่าน
// ---------------------------------------------------------------------------

/// 1 แถว = 1 หมวด: ไอคอน + ชื่อ, แท่งยาวตามจำนวนบทความ, จำนวน · คะแนนเฉลี่ย
class TopicBar extends StatelessWidget {
  const TopicBar({
    super.key,
    required this.icon,
    required this.label,
    required this.fraction,
    required this.value,
  });

  final IconData icon;
  final String label;

  /// ความยาวแท่งเทียบกับหมวดที่มากที่สุด (0–1)
  final double fraction;

  /// ข้อความท้ายแถว เช่น "3 · เฉลี่ย 72"
  final String value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xxs),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: scheme.onSurfaceVariant),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                value,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: scheme.onSurfaceVariant,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xxs),
          _Grow(
            dataKey: fraction,
            builder: (t) => ClipRRect(
              // AppRadius มาจาก lib/core/radius.dart
              borderRadius: AppRadius.pillAll,
              child: LinearProgressIndicator(
                value: fraction * t,
                minHeight: 6,
                color: scheme.primary,
                backgroundColor: scheme.surfaceContainerHigh,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
