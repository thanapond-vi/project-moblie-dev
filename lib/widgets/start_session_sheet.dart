import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/article_tag.dart';
import '../models/reading_topic.dart';
import '../services/settings_service.dart';
import '../services/sources/article_source.dart';
import 'motion_widgets.dart';
import '../core/spacing.dart';

// ReadingTopic มาจาก lib/models/reading_topic.dart
/// แผ่นเลือกหมวดก่อนสุ่มบทความ: สุ่มทุกหมวด / หมวดยอดฮิต 5 หมวด / พิมพ์ค้นหัวข้อเอง
/// คืนค่า null ถ้าผู้ใช้ปิดแผ่นโดยไม่กดเริ่ม
Future<ReadingTopic?> showStartSessionSheet(BuildContext context) {
  return showModalBottomSheet<ReadingTopic>(
    context: context,
    isScrollControlled: true, // ให้แผ่นเลื่อนขึ้นเหนือคีย์บอร์ดตอนพิมพ์ค้นหา
    builder: (context) => const _StartSessionSheet(),
  );
}

class _StartSessionSheet extends StatefulWidget {
  const _StartSessionSheet();

  @override
  State<_StartSessionSheet> createState() => _StartSessionSheetState();
}

class _StartSessionSheetState extends State<_StartSessionSheet> {
  final _searchController = TextEditingController();

  // ArticleTag มาจาก lib/models/article_tag.dart
  /// null = สุ่มทุกหมวด
  ArticleTag? _preset;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  /// พิมพ์ค้นเองมีผลเหนือปุ่มหมวด (พิมพ์แล้วปุ่มหมวดจะไม่ถูกเลือก)
  ReadingTopic get _topic {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) return ReadingTopic.search(query);
    return _preset == null ? ReadingTopic.any : ReadingTopic.preset(_preset!);
  }

  @override
  Widget build(BuildContext context) {
    // context.l10n มาจาก lib/l10n/l10n.dart
    final l10n = context.l10n;
    final theme = Theme.of(context);
    // SettingsService มาจาก lib/services/settings_service.dart
    final settings = SettingsService.instance;
    // ArticleSources มาจาก lib/services/sources/article_source.dart
    final source = ArticleSources.byId(settings.sourceId.value);
    final searching = _searchController.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        // ดันเนื้อหาขึ้นเท่าความสูงคีย์บอร์ด
        padding: EdgeInsets.only(
          // AppSpacing มาจาก lib/core/spacing.dart
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpacing.xs),
                    child: Text(
                      l10n.chooseTopicTitle,
                      style: theme.textTheme.headlineSmall,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: l10n.close,
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xs),
            // แหล่ง·ภาษา และเวลาอ่านต่อรอบ (ตั้งค่าได้ใน Settings)
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                _InfoPill(
                  icon: Icons.public,
                  label:
                      '${source.name} · ${settings.articleLanguage.value.label}',
                ),
                _InfoPill(
                  icon: Icons.timer_outlined,
                  label: '${settings.timerMinutes.value} ${l10n.unitMinutes}',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.popularTopics, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              children: [
                // EntranceFade มาจาก lib/widgets/motion_widgets.dart
                EntranceFade(
                  // SelectedScale มาจาก lib/widgets/motion_widgets.dart
                  child: SelectedScale(
                    selected: !searching && _preset == null,
                    child: ChoiceChip(
                      // คงไอคอนหมวดไว้ตอนเลือก (สถานะเลือกดูจากสีพื้น + ขยายเล็กน้อย)
                      showCheckmark: false,
                      avatar: const Icon(Icons.shuffle, size: 18),
                      label: Text(l10n.anyTopic),
                      selected: !searching && _preset == null,
                      onSelected: (_) => setState(() {
                        _preset = null;
                        _searchController.clear();
                      }),
                    ),
                  ),
                ),
                for (final (i, tag) in ArticleTag.values.indexed)
                  EntranceFade(
                    index: i + 1,
                    child: SelectedScale(
                      selected: !searching && _preset == tag,
                      child: ChoiceChip(
                        showCheckmark: false,
                        avatar: Icon(tag.icon, size: 18),
                        label: Text(tag.label(l10n)),
                        selected: !searching && _preset == tag,
                        onSelected: (_) => setState(() {
                          _preset = tag;
                          _searchController.clear();
                        }),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            Text(l10n.searchTopic, style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            TextField(
              controller: _searchController,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: l10n.searchTopicHint,
                prefixIcon: const Icon(Icons.search),
                isDense: true,
              ),
              onChanged: (_) => setState(() {}),
              onSubmitted: (_) => Navigator.pop(context, _topic),
            ),
            const SizedBox(height: AppSpacing.xl),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _topic),
              icon: const Icon(Icons.auto_stories),
              label: Text(l10n.startReading),
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline,
                  size: 16,
                  color: theme.colorScheme.tertiary,
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: Text(
                    l10n.topicSheetHint,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// ป้ายข้อมูลเล็ก (ไอคอน + ข้อความ) บนพื้นผิวขั้นถัดไป
class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: ShapeDecoration(
        color: scheme.surfaceContainer,
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
              style: theme.textTheme.labelMedium?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
