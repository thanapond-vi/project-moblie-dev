import 'package:flutter/material.dart';

import '../l10n/l10n.dart';
import '../models/article_tag.dart';
import '../models/reading_topic.dart';
import '../services/settings_service.dart';
import '../services/sources/article_source.dart';
import 'motion_widgets.dart';
import '../core/spacing.dart';

/// แผ่นเลือกหมวดก่อนสุ่มบทความ: สุ่มทุกหมวด / หมวดยอดฮิต 5 หมวด / พิมพ์ค้นหัวข้อเอง
/// คืนค่า null ถ้าผู้ใช้ปิดแผ่นโดยไม่กดเริ่ม
Future<ReadingTopic?> showStartSessionSheet(BuildContext context) {
  return showModalBottomSheet<ReadingTopic>(
    context: context,
    showDragHandle: true,
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
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final settings = SettingsService.instance;
    final source = ArticleSources.byId(settings.sourceId.value);
    final searching = _searchController.text.trim().isNotEmpty;

    return SafeArea(
      child: Padding(
        // ดันเนื้อหาขึ้นเท่าความสูงคีย์บอร์ด
        padding: EdgeInsets.only(
          left: AppSpacing.lg,
          right: AppSpacing.lg,
          bottom: AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(l10n.chooseTopicTitle, style: theme.textTheme.titleLarge),
            const SizedBox(height: 4),
            Text(
              l10n.readingFrom(
                source.name,
                settings.articleLanguage.value.label,
              ),
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Text(l10n.popularTopics, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                EntranceFade(
                  child: SelectedScale(
                    selected: !searching && _preset == null,
                    child: ChoiceChip(
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
            const SizedBox(height: 20),
            Text(l10n.searchTopic, style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
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
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, _topic),
              icon: const Icon(Icons.auto_stories),
              label: Text(l10n.startReading),
            ),
          ],
        ),
      ),
    );
  }
}
