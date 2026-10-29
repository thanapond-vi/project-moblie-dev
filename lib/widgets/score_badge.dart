import 'package:flutter/material.dart';

import '../core/spacing.dart';
import '../core/motion.dart';
import '../l10n/l10n.dart';
import 'animated_counter.dart';

/// ระดับความจำจากคะแนน AI: ใช้สีเดียวกันทุกหน้า (ป้ายคะแนน แถบความจำ วงคะแนน)
/// คะแนนต่ำใช้สีอำพัน "ควรทบทวน" ไม่ใช้สีแดง: คะแนนต่ำไม่ใช่ความผิดพลาด แค่ถึงเวลาอ่านซ้ำ
enum ScoreLevel {
  mastered,
  good,
  review,
  none;

  static ScoreLevel of(int? score) {
    if (score == null) return none;
    if (score >= 80) return mastered;
    if (score >= 60) return good;
    return review;
  }

  /// สีเส้น/ตัวเลขบนพื้นผิวปกติ
  Color color(ColorScheme scheme) => switch (this) {
    mastered => scheme.primary,
    good => scheme.secondary,
    review => scheme.tertiary,
    // outline บนพื้นสว่างได้ contrast แค่ ~3.3:1 ไม่พอสำหรับตัวหนังสือ (ต้อง 4.5:1)
    none => scheme.onSurfaceVariant,
  };

  /// คู่สีพื้น + ตัวอักษรสำหรับป้ายทึบ
  (Color, Color) container(ColorScheme scheme) => switch (this) {
    mastered => (scheme.primaryContainer, scheme.onPrimaryContainer),
    good => (scheme.secondaryContainer, scheme.onSecondaryContainer),
    review => (scheme.tertiaryContainer, scheme.onTertiaryContainer),
    none => (scheme.surfaceContainerHigh, scheme.onSurfaceVariant),
  };

  IconData get icon => switch (this) {
    mastered => Icons.verified,
    good => Icons.check_circle_outline,
    review => Icons.refresh,
    none => Icons.hourglass_empty,
  };

  String label(AppLocalizations l10n) => switch (this) {
    mastered => l10n.scoreMastered,
    good => l10n.scoreGood,
    review => l10n.scoreReview,
    none => l10n.notEvaluated,
  };
}

/// วงกลมแสดงคะแนน สีเปลี่ยนตามช่วงคะแนน (null = ยังไม่ได้ประเมิน)
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.size = 52});

  final int? score;
  final double size;

  static Color colorFor(int? score, ColorScheme scheme) =>
      ScoreLevel.of(score).color(scheme);

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

/// ป้ายคะแนนทึบแบบเม็ดยา (ไอคอนระดับ + ตัวเลข) ใช้บนการ์ดประวัติ
class ScorePill extends StatelessWidget {
  const ScorePill({super.key, required this.score});

  final int? score;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = ScoreLevel.of(score);
    final (bg, fg) = level.container(theme.colorScheme);
    return Semantics(
      label: score == null
          ? context.l10n.notEvaluated
          : context.l10n.scoreSemantics(score!, level.label(context.l10n)),
      excludeSemantics: true,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.xs + 2,
          vertical: AppSpacing.xxs,
        ),
        decoration: ShapeDecoration(color: bg, shape: const StadiumBorder()),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(level.icon, size: 16, color: fg),
            const SizedBox(width: AppSpacing.xxs),
            Text(
              score?.toString() ?? '–',
              style: theme.textTheme.labelMedium?.copyWith(
                color: fg,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// วงแหวนคะแนน: เส้นวงกลมยาวตามคะแนน สีตามระดับ ตัวเลขนับขึ้นตรงกลาง
/// โปรแกรมอ่านหน้าจออ่านเป็น "คะแนน 85, จำได้แม่น" (ไม่พึ่งสีอย่างเดียว)
class ScoreRing extends StatelessWidget {
  const ScoreRing({super.key, required this.score, this.size = 104});

  final int score;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final level = ScoreLevel.of(score);
    final color = level.color(scheme);
    return Semantics(
      label: context.l10n.scoreSemantics(score, level.label(context.l10n)),
      excludeSemantics: true,
      child: SizedBox.square(
        dimension: size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: score / 100),
              duration: AppMotion.reduced(context)
                  ? Duration.zero
                  : const Duration(milliseconds: 1300),
              curve: AppMotion.entranceCurve,
              builder: (context, value, _) => CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: color,
                backgroundColor: scheme.surfaceContainerHigh,
              ),
            ),
            // ย่อให้พอดีวงเมื่อขยายตัวอักษร
            Padding(
              padding: EdgeInsets.all(size * 0.2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedCounter(
                      key: ValueKey(score),
                      value: score,
                      style: theme.textTheme.displaySmall?.copyWith(
                        color: color,
                      ),
                    ),
                    Text(
                      '/100',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
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
