import 'package:flutter/material.dart';

/// วงกลมแสดงคะแนน สีเปลี่ยนตามช่วงคะแนน (null = ยังไม่ได้ประเมิน)
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.size = 52});

  final int? score;
  final double size;

  static Color colorFor(int? score, ColorScheme scheme) {
    if (score == null) return scheme.outline;
    if (score >= 80) return scheme.primary;
    if (score >= 50) return scheme.tertiary;
    return scheme.error;
  }

  @override
  Widget build(BuildContext context) {
    final color = colorFor(score, Theme.of(context).colorScheme);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color.withValues(alpha: 0.12),
        border: Border.all(color: color, width: 2),
      ),
      // ตัวอักษรใหญ่ (Text Scale สูง) → ย่อให้พอดีวง ไม่ล้นออกนอกวงกลม
      child: Padding(
        padding: EdgeInsets.all(size * 0.12),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            score?.toString() ?? '–',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(color: color),
          ),
        ),
      ),
    );
  }
}
