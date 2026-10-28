import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/spacing.dart';

/// การ์ดสถิติที่ "เล่นเปิดตัว" ทุกครั้งที่หน้าจอแสดง (เลียนแบบ effect นับแต้มสะสม):
///
///   0%–30%   การ์ดขยายจาก 85% → 100% พร้อม fade เข้า
///   15%–45%  ป้ายชื่อค่อยๆ พิมพ์ทีละตัวอักษร
///   20%–100% ตัวเลขวิ่งจาก 0 ไปค่าจริง: เร็วมากตอนแรกแล้วค่อยๆ ช้าลง (easeOutExpo)
///   60%–100% คำอธิบายใต้ตัวเลข fade ตามมา
///
/// ใช้ AnimationController ตัวเดียว + Interval แบ่งช่วงเวลาให้แต่ละส่วน
/// อยากให้เล่นใหม่: เปลี่ยน Key ของ widget (Flutter จะสร้าง State ใหม่ → initState เริ่มเล่นอีกรอบ)
class StatRevealCard extends StatefulWidget {
  const StatRevealCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.unit,
    required this.caption,
    this.highlight = false,
    this.prominent = false,
    this.delay = Duration.zero,
  });

  final IconData icon;
  final String label;

  /// null = ยังไม่มีข้อมูล (แสดง –)
  final int? value;
  final String unit;
  final String caption;
  final bool highlight;

  /// การ์ดหลักของหน้า: พื้นโทนสีหลัก ตัวเลขใหญ่ (ใช้ได้ใบเดียวต่อหน้า)
  final bool prominent;

  /// หน่วงก่อนเริ่ม ใช้ให้การ์ดหลายใบเปิดตัวไล่กัน
  final Duration delay;

  @override
  State<StatRevealCard> createState() => _StatRevealCardState();
}

class _StatRevealCardState extends State<StatRevealCard>
    with TickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1600),
  );

  late final Animation<double> _card = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0, 0.3, curve: Curves.easeOutBack),
  );
  late final Animation<double> _typing = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.15, 0.45),
  );
  late final Animation<double> _count = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.2, 1, curve: Curves.easeOutExpo),
  );
  late final Animation<double> _caption = CurvedAnimation(
    parent: _controller,
    curve: const Interval(0.6, 1, curve: Curves.easeOut),
  );

  /// นับต่อจากค่าเดิม เมื่อค่าเปลี่ยนหลังเปิดตัวจบแล้ว (เช่น เพิ่งบันทึกบทความใหม่)
  late final AnimationController _recount = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  );
  int _from = 0;

  /// ตัวเลขที่แสดงตอนนี้
  int get _shown {
    final value = widget.value ?? 0;
    if (_recount.value > 0) {
      final t = Curves.easeOutExpo.transform(_recount.value);
      return (_from + (value - _from) * t).round();
    }
    // ระหว่างเปิดตัว: ถ้าค่าเปลี่ยนกลางทาง (cache → ข้อมูลจริงจาก server) นับต่อไปหาค่าใหม่เลย ไม่เริ่มใหม่
    return (value * _count.value).round();
  }

  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // เริ่มครั้งเดียว ตรงนี้อ่าน MediaQuery ได้ (initState ยังอ่านไม่ได้)
    if (_started) return;
    _started = true;
    // เปิด Reduce Motion ในเครื่อง → แสดงสถานะสุดท้ายทันที ไม่มี animation
    if (AppMotion.reduced(context)) {
      _controller.value = 1;
      return;
    }
    Future.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void didUpdateWidget(StatRevealCard old) {
    super.didUpdateWidget(old);
    // ค่าเปลี่ยนหลังเปิดตัวจบแล้ว → นับจากเลขเดิมไปเลขใหม่ (ไม่เล่นเปิดตัวทั้งการ์ดซ้ำ)
    // Reduce Motion: ไม่นับ แสดงเลขใหม่ทันที (_count อยู่ที่ 1 แล้ว)
    if (old.value != widget.value &&
        _controller.isCompleted &&
        !AppMotion.reduced(context)) {
      _from = old.value ?? 0;
      _recount.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _recount.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final accent = widget.highlight ? scheme.primary : scheme.onSurface;
    final prominent = widget.prominent;
    final valueStyle = prominent
        ? theme.textTheme.displaySmall
        : theme.textTheme.headlineSmall;
    final unitStyle = prominent
        ? theme.textTheme.titleMedium
        : theme.textTheme.labelSmall;

    return AnimatedBuilder(
      animation: Listenable.merge([_controller, _recount]),
      builder: (context, _) {
        final label = widget.label;
        final shownChars = (label.characters.length * _typing.value).ceil();
        final value = widget.value;
        return Opacity(
          opacity: _card.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.85 + 0.15 * _card.value,
            child: Card(
              color: prominent
                  ? scheme.primaryContainer.withValues(alpha: 0.35)
                  : null,
              child: Padding(
                padding: EdgeInsets.all(
                  prominent ? AppSpacing.md : AppSpacing.sm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(widget.icon, size: 16, color: accent),
                        const SizedBox(width: AppSpacing.xxs),
                        Flexible(
                          child: Text(
                            // ใช้ characters เพื่อไม่ตัดกลางสระ/วรรณยุกต์ไทย
                            label.characters.take(shownChars).toString(),
                            style: theme.textTheme.labelMedium,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: AlignmentDirectional.centerStart,
                      child: Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: value == null ? '–' : '$_shown',
                              style: valueStyle?.copyWith(color: accent),
                            ),
                            TextSpan(text: ' ${widget.unit}', style: unitStyle),
                          ],
                        ),
                      ),
                    ),
                    Opacity(
                      opacity: _caption.value,
                      child: Text(
                        widget.caption,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// ตัวเลขที่วิ่งนับขึ้นจาก 0 (ใช้กับคะแนนในหน้าสรุป) แบบเดียวกับการ์ดสถิติ
class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({super.key, required this.value, this.style});

  final int value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final tabular = style?.copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    if (AppMotion.reduced(context)) {
      return Text(value.toString(), style: tabular);
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: const Duration(milliseconds: 1300),
      curve: Curves.easeOutExpo,
      builder: (context, animated, _) =>
          Text(animated.round().toString(), style: tabular),
    );
  }
}

/// ป้าย "+X นาที" ที่เด้งขึ้น ใช้ตอนได้เวลาอ่านเพิ่ม
class EarnedBadge extends StatelessWidget {
  const EarnedBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.bolt, size: 18, color: scheme.onTertiaryContainer),
          const SizedBox(width: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: scheme.onTertiaryContainer),
          ),
        ],
      ),
    );
    // Reduce Motion: แสดงป้ายทันที ไม่เด้ง
    if (AppMotion.reduced(context)) return badge;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 900),
      curve: Curves.elasticOut, // เด้งเกินนิดหนึ่งแล้วค่อยเข้าที่
      builder: (context, t, child) => Transform.scale(
        scale: 0.6 + 0.4 * t,
        child: Opacity(opacity: math.min(1, math.max(0, t)), child: child),
      ),
      child: badge,
    );
  }
}
