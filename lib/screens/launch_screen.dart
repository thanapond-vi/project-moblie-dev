import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';

import '../core/motion.dart';
import '../core/spacing.dart';
import '../core/theme.dart';
import '../l10n/l10n.dart';
import '../widgets/keep_logo.dart';

/// หน้าเปิดแอป: ประกอบโลโก้ → โคมไฟกะพริบเหมือนหลอดไฟเก่า (มีเสียง) → สว่างนิ่ง + KEEP + สโลแกน
///
/// - กะพริบช้าและไม่มืดสนิท (ต่ำสุด 30% ของความสว่าง) ไม่เกิน 2 ครั้งต่อวินาที ปลอดภัยต่อผู้ไวต่อแสง
/// - เปิด Reduce Motion → โลโก้นิ่งเต็มดวง ไม่กะพริบ ไม่มีเสียง
/// - แตะที่ไหนก็ได้เพื่อข้าม
class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key, required this.onDone, this.sound = true});

  final VoidCallback onDone;

  /// เล่นเสียงไฟกะพริบ (ตามสวิตช์ใน Settings) เสียงยังเงียบตามสวิตช์ปิดเสียงของเครื่องเสมอ
  final bool sound;

  /// ความยาวทั้งหมดของอนิเมชัน
  static const total = Duration(milliseconds: 3600);

  /// ช่วงกะพริบ (สัดส่วนของ [total]) ตรงกับไฟล์เสียง assets/sounds/lamp_flicker.wav
  static const flickerStart = 0.30;
  static const flickerEnd = 0.70;

  /// ความสว่างของลำแสงช่วงกะพริบ: (ความยาวเป็นวินาที, ค่าเริ่ม, ค่าจบ) รวม 1.44 วินาที
  /// ไฟติดครั้งแรก → หรี่ → สว่างขึ้น → หรี่ → สว่างนิ่ง
  static final flicker = TweenSequence<double>([
    for (final (seconds, from, to) in const [
      (0.10, 0.0, 0.7),
      (0.18, 0.7, 0.7),
      (0.02, 0.7, 0.3),
      (0.12, 0.3, 0.3),
      (0.02, 0.3, 0.85),
      (0.26, 0.85, 0.85),
      (0.02, 0.85, 0.35),
      (0.14, 0.35, 0.35),
      (0.02, 0.35, 1.0),
      (0.56, 1.0, 1.0),
    ])
      TweenSequenceItem(
        tween: Tween(begin: from, end: to),
        weight: seconds,
      ),
  ]);

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen>
    with SingleTickerProviderStateMixin {
  late final _controller = AnimationController(
    vsync: this,
    duration: LaunchScreen.total,
  );
  AudioPlayer? _player;
  Timer? _timer;
  bool _started = false;
  bool _done = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    // AppMotion มาจาก lib/core/motion.dart
    if (AppMotion.reduced(context)) {
      // ไม่มีอนิเมชัน: แสดงโลโก้เต็มดวงสั้นๆ แล้วไปต่อ
      _controller.value = 1;
      _timer = Timer(const Duration(milliseconds: 900), _finish);
      return;
    }
    // จบอนิเมชัน → ค้างโลโก้ที่สว่างนิ่งไว้อีกนิด แล้วไปต่อ
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _timer = Timer(const Duration(milliseconds: 300), _finish);
      }
    });
    _controller.forward();
    if (widget.sound) _prepareSound();
  }

  /// เตรียมไฟล์เสียงไว้ก่อน แล้วเริ่มเล่นตอนไฟเริ่มกะพริบพอดี
  Future<void> _prepareSound() async {
    try {
      final player = _player = AudioPlayer();
      // ambient: เงียบตามสวิตช์ปิดเสียง และเล่นซ้อนกับเพลงที่ผู้ใช้ฟังอยู่ (ไม่หยุดเพลงเขา)
      await player.setAudioContext(
        AudioContextConfig(
          respectSilence: true,
          focus: AudioContextConfigFocus.mixWithOthers,
        ).build(),
      );
      await player.setSource(AssetSource('sounds/lamp_flicker.wav'));
      final startAt = LaunchScreen.total * LaunchScreen.flickerStart;
      final wait = startAt - LaunchScreen.total * _controller.value;
      if (wait > Duration.zero) await Future<void>.delayed(wait);
      if (mounted && !_done) await player.resume();
    } catch (_) {
      // เสียงเป็นแค่ของตกแต่ง เล่นไม่ได้ก็ไปต่อเงียบๆ
    }
  }

  void _finish() {
    if (_done || !mounted) return;
    _done = true;
    _player?.stop();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _player?.dispose();
    super.dispose();
  }

  /// ค่า 0–1 ของช่วงเวลาหนึ่งในอนิเมชัน พร้อม curve
  double _phase(double start, double end, [Curve curve = Curves.linear]) =>
      curve.transform(
        ((_controller.value - start) / (end - start)).clamp(0.0, 1.0),
      );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    // ReadingLampColors มาจาก lib/core/theme.dart
    final lampColors = ReadingLampColors.of(context);
    // AppTheme มาจาก lib/core/theme.dart
    final wordmark = AppTheme.wordmarkLarge(context);
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _finish,
        child: Semantics(
          label: 'KEEP. ${context.l10n.tagline}',
          // ผู้ใช้โปรแกรมอ่านหน้าจอ/สวิตช์ข้ามได้เหมือนการแตะ
          button: true,
          // context.l10n มาจาก lib/l10n/l10n.dart
          hint: context.l10n.skipIntro,
          onTap: _finish,
          excludeSemantics: true,
          child: Center(
            child: AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                final lamp = _phase(0, 0.30, AppMotion.entranceCurve);
                final book = _phase(0.08, 0.38, AppMotion.entranceCurve);
                final beam = LaunchScreen.flicker.transform(
                  _phase(LaunchScreen.flickerStart, LaunchScreen.flickerEnd),
                );
                final word = _phase(0.72, 0.92, AppMotion.entranceCurve);
                final tagline = _phase(0.78, 0.98, AppMotion.entranceCurve);
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // แสงอำพันรอบโลโก้ สว่างตามลำแสง (กะพริบไปพร้อมกัน)
                    Container(
                      width: 220,
                      height: 220,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            lampColors.glowHalo.withValues(
                              alpha: 0.18 * beam * lampColors.glowStrength,
                            ),
                            lampColors.glowHalo.withValues(alpha: 0),
                          ],
                        ),
                      ),
                      // KeepLogo มาจาก lib/widgets/keep_logo.dart
                      child: KeepLogo(
                        size: 120,
                        lamp: lamp,
                        book: book,
                        beam: beam,
                        lampShift: -14 * (1 - lamp),
                        bookShift: 14 * (1 - book),
                      ),
                    ),
                    // AppSpacing มาจาก lib/core/spacing.dart
                    const SizedBox(height: AppSpacing.md),
                    Opacity(
                      opacity: word,
                      child: Transform.translate(
                        offset: Offset(0, AppMotion.entranceRise * (1 - word)),
                        // letterSpacing เว้นท้ายตัวสุดท้ายด้วย → ดันด้านหน้าเท่ากันให้อยู่กลางจริง
                        child: Padding(
                          padding: EdgeInsetsDirectional.only(
                            start: wordmark.letterSpacing ?? 0,
                          ),
                          child: Text('KEEP', style: wordmark),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Opacity(
                      opacity: tagline,
                      child: Text(
                        context.l10n.tagline,
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}
