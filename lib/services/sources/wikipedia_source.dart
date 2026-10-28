import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../../core/app_exception.dart';
import '../../l10n/l10n.dart';
import '../../models/article.dart';
import '../../models/content_language.dart';
import '../../models/reading_topic.dart';
import 'article_source.dart';

/// แหล่งข้อมูล Wikipedia (ฟรี ไม่ต้องใช้ API key) รองรับ English / Chinese / Thai
///
/// ทำ 2 ขั้น (async ทั้งคู่):
///   1) ขอรายชื่อบทความสุ่มพร้อมความยาว
///      - สุ่มทุกหมวด: generator=random
///      - หมวดยอดฮิต: list=search + srsort=random / ค้นเอง: srsort=relevance (50 เรื่องที่ตรงที่สุด)
///        ทั้งสองแบบได้จำนวนผลทั้งหมด (totalhits) มาด้วย ใช้ตัดสินว่า "อ่านครบหมวดแล้ว"
///      ตัดเรื่องที่ผู้ใช้อ่านแล้วออก แล้วเลือกเรื่องที่ยาวพอสำหรับอ่าน
///   2) ดึงเนื้อหาเต็มของเรื่องนั้นแบบ plain text (ถ้าเนื้อหาจริงสั้นเกินไป ลองเรื่องถัดไป)
class WikipediaSource implements ArticleSource {
  WikipediaSource({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;
  final _random = Random();

  static const _timeout = Duration(seconds: 15);
  static const _maxWikitextBytes = 150000;
  static const _maxAttempts = 3;
  static const _batch = 50;

  /// จำกัดความยาวที่แสดง ไม่ให้หน้าจอหนักเกินไป
  static const _maxDisplayChars = 20000;

  /// Wikimedia ขอให้ระบุ User-Agent ที่บอกว่าเป็นแอปอะไร
  static const _headers = {
    HttpHeaders.userAgentHeader:
        'KEEP-ReadRecall/1.0 (Flutter student project)',
    'Api-User-Agent': 'KEEP-ReadRecall/1.0 (Flutter student project)',
  };

  @override
  String get id => 'wikipedia';

  @override
  String get name => 'Wikipedia';

  @override
  Set<ContentLanguage> get languages => ContentLanguage.values.toSet();

  Uri _api(ContentLanguage language, Map<String, String> params) =>
      Uri.https(language.wikiHost, '/w/api.php', {
        'format': 'json',
        'formatversion': '2',
        // ภาษาจีน: ให้ Wikipedia แปลงเป็นตัวย่อ (简体)
        if (language.wikiVariant != null) 'variant': language.wikiVariant!,
        ...params,
      });

  @override
  Future<Article> fetchRandomArticle({
    required ContentLanguage language,
    required ReadingTopic topic,
    required Set<String> excludeKeys,
  }) async {
    try {
      // ---- 1) หารายชื่อบทความที่ยังไม่เคยอ่าน (สุ่มได้สูงสุด 3 รอบ) ----
      var candidates = <_Candidate>[];
      for (var round = 0; round < _maxAttempts && candidates.isEmpty; round++) {
        final batch = await _randomBatch(language, topic, round);
        candidates = batch.items
            .where(
              (c) => !excludeKeys.contains(
                Article.readKeyOf(id, language.code, c.pageId),
              ),
            )
            .toList();
        // ไล่ดูผลค้นหาครบทุกเรื่องแล้ว แต่อ่านไปหมดแล้ว
        // = หมวดนี้ไม่เหลือบทความใหม่จริงๆ ไม่ต้องสุ่มซ้ำ
        if (candidates.isEmpty && batch.isComplete) {
          if (batch.items.isEmpty) throw AppException(tr.errNoArticle);
          throw const TopicExhaustedException();
        }
      }
      if (candidates.isEmpty) throw AppException(tr.noNewArticles);

      // เรียง: เรื่องที่ยาวพอดี (สุ่มลำดับ) ก่อน แล้วตามด้วยเรื่องที่เหลือจากยาวไปสั้น
      final suitable =
          candidates
              .where(
                (c) =>
                    c.length >= language.minWikitextBytes &&
                    c.length <= _maxWikitextBytes,
              )
              .toList()
            ..shuffle(_random);
      final others = candidates.where((c) => !suitable.contains(c)).toList()
        ..sort((a, b) => b.length.compareTo(a.length));

      // ---- 2) ดึงเนื้อหาเต็ม ----
      Article? best;
      for (final picked in [...suitable, ...others].take(_maxAttempts)) {
        final article = await _fetchContent(language, picked, topic);
        if (article == null) continue;
        if (article.content.length >= language.minContentChars) return article;
        if (best == null || article.content.length > best.content.length) {
          best = article;
        }
      }
      if (best == null) throw AppException(tr.errArticleEmpty);
      return best;
    } on AppException {
      rethrow;
    } on TopicExhaustedException {
      rethrow;
    } on TimeoutException {
      throw AppException(tr.errWikiTimeout);
    } on SocketException {
      throw AppException(tr.errNoInternet);
    } catch (_) {
      throw AppException(tr.errWikiLoad);
    }
  }

  /// สุ่มรายชื่อบทความ 1 ชุด พร้อมขนาด (bytes ของ wikitext)
  /// [round] = รอบที่เท่าไร: คำค้นเองเรียงตามความเกี่ยวข้อง จึงเลื่อนไปชุดถัดไปทุกรอบ (ไม่ได้ชุดเดิมซ้ำ)
  Future<_Batch> _randomBatch(
    ContentLanguage language,
    ReadingTopic topic,
    int round,
  ) async {
    if (topic.isAny) {
      final json = await _getJson(
        _api(language, {
          'action': 'query',
          'generator': 'random',
          'grnnamespace': '0', // เฉพาะบทความ ไม่เอาหน้าพูดคุย/หมวดหมู่
          'grnlimit': '$_batch',
          'prop': 'info',
        }),
      );
      final pages = (json['query']?['pages'] as List?) ?? const [];
      return _Batch(
        [for (final p in pages) _Candidate.fromJson(p, 'length')],
        isComplete: false, // สุ่มจากทั้ง Wikipedia ไม่มีวันหมด
      );
    }

    final json = await _getJson(
      _api(language, {
        'action': 'query',
        'list': 'search',
        'srsearch': topic.preset?.searchQuery ?? topic.query!.trim(),
        // หมวดยอดฮิต: สุ่มจากทั้งหมวด (หลายหมื่นเรื่อง)
        // คำค้นเอง: เอา 50 เรื่องที่ "ตรงที่สุด" มาก่อน แล้วค่อยสุ่มในนั้น (ขั้นตอนถัดไปสุ่มลำดับให้)
        //   ถ้าสุ่มจากทุกหน้าที่มีคำนั้น จะได้บทความที่แค่เอ่ยถึงคำนั้นผ่านๆ
        'srsort': topic.preset != null ? 'random' : 'relevance',
        if (topic.preset == null) 'sroffset': '${round * _batch}',
        'srnamespace': '0',
        'srlimit': '$_batch',
        'srinfo': 'totalhits', // จำนวนบทความทั้งหมดในหมวดนี้
        'srprop': 'size', // ขนาดบทความ (ใช้เลือกเรื่องที่ยาวพอ)
      }),
    );
    final results = (json['query']?['search'] as List?) ?? const [];
    final total = (json['query']?['searchinfo']?['totalhits'] as num?) ?? 0;
    // ครบแล้ว = ชุดนี้ไล่ไปถึงเรื่องสุดท้ายของผลค้นหาทั้งหมด
    final seen = (topic.preset == null ? round * _batch : 0) + results.length;
    return _Batch([
      for (final r in results) _Candidate.fromJson(r, 'size'),
    ], isComplete: total <= seen);
  }

  Future<Article?> _fetchContent(
    ContentLanguage language,
    _Candidate picked,
    ReadingTopic topic,
  ) async {
    final json = await _getJson(
      _api(language, {
        'action': 'query',
        'pageids': '${picked.pageId}',
        'prop': 'extracts|info',
        'inprop': 'url${language.wikiVariant != null ? '|varianttitles' : ''}',
        'explaintext': '1', // ขอเป็นข้อความล้วน ไม่เอา HTML
        // หัวข้อมาเป็น "== ชื่อ ==" จะได้รู้แน่ว่าบรรทัดไหนคือหัวข้อ (cleanExtract แปลงกลับเป็นบรรทัดธรรมดา)
        'exsectionformat': 'wiki',
      }),
    );
    final page = (json['query']?['pages'] as List?)?.first;
    final cleaned = cleanExtractWithHeadings(
      (page?['extract'] as String?)?.trim() ?? '',
    );
    final text = cleaned.text;
    if (text.isEmpty) return null;
    return Article(
      sourceId: id,
      pageId: picked.pageId,
      // ภาษาจีน: variant แปลงแค่เนื้อหา ชื่อเรื่องต้องใช้ varianttitles
      title:
          page?['varianttitles']?[language.wikiVariant] as String? ??
          page?['title'] as String? ??
          picked.title,
      content: text,
      url: page?['fullurl'] as String? ?? '',
      language: language,
      topic: topic.tag,
      headings: cleaned.headings,
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final response = await _client
        .get(uri, headers: _headers)
        .timeout(_timeout);
    if (response.statusCode == 429) {
      // Wikimedia จำกัดจำนวน request ต่อ IP ถ้ากดสุ่มถี่เกินไป
      throw AppException(tr.errWikiRateLimit);
    }
    if (response.statusCode != 200) {
      throw AppException(tr.errWikiStatus('${response.statusCode}'));
    }
    return jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
  }

  /// เทมเพลตวิกิที่ครบคู่ เช่น {{efn|เชิงอรรถ}} (เอาชั้นในสุดก่อน แล้ววนจนหมด เผื่อซ้อนกัน)
  static final _template = RegExp(r'\{\{[^{}]*\}\}');

  /// ตัวเปิดเทมเพลตที่ไม่มีตัวปิด เช่น "{{efn|" (เก็บข้อความต่อท้ายไว้ เพราะไม่รู้ว่าจบตรงไหน)
  static final _templateOpener = RegExp(r'\{\{[^{}|\n]*\|?');

  /// บรรทัดหัวข้อแบบ wiki เช่น "== ประวัติ ==" หรือหัวข้อย่อย "=== ยุคแรก ==="
  static final _heading = RegExp(r'^(=+)\s*(.*?)\s*=+$');

  /// หัวข้อท้ายบทความที่ไม่ใช่เนื้อหา: เจอแล้วตัดทิ้งตั้งแต่ตรงนั้นจนจบ
  static const _endSections = {
    'อ้างอิง',
    'แหล่งข้อมูลอื่น',
    'ดูเพิ่ม',
    'หมายเหตุ',
    'เชิงอรรถ',
    'References',
    'External links',
    'See also',
    'Notes',
    'Further reading',
    '参考文献',
    '参考资料',
    '参见',
    '外部链接',
    '注释',
  };

  /// หัวข้อที่เนื้อหาของตัวเองสั้นกว่านี้ (และไม่มีหัวข้อย่อยที่มีเนื้อหา) = เนื้อหาจริงเป็นตาราง/รายการที่ถูกตัดไป
  /// เช่น "ผู้เล่น" เหลือแค่ "ณ 31 สิงหาคม ค.ศ.2025" กับหมายเหตุใต้ตาราง จึงตัดทั้งหัวข้อ
  static const _minSectionChars = 200;

  /// ตัดส่วนท้ายที่ไม่ใช่เนื้อหา (อ้างอิง/แหล่งข้อมูลอื่น), หัวข้อที่ไม่มีเนื้อหา,
  /// โค้ดเทมเพลตวิกิที่หลุดมา และบรรทัดว่างซ้ำ
  @visibleForTesting
  static String cleanExtract(String text) =>
      cleanExtractWithHeadings(text).text;

  /// เหมือน [cleanExtract] แต่คืนรายชื่อหัวข้อที่เหลืออยู่ด้วย (ให้หน้าอ่านแสดงหัวข้อเป็นตัวหนา)
  @visibleForTesting
  static ({String text, List<String> headings}) cleanExtractWithHeadings(
    String text,
  ) {
    var result = text;
    // Wikipedia แปลงเทมเพลตเป็นข้อความไม่ได้ทุกตัว บางหน้าจึงมี {{efn|...}} ติดมาใน extract
    while (_template.hasMatch(result)) {
      result = result.replaceAll(_template, '');
    }
    result = result
        .replaceAll(_templateOpener, ' ')
        .replaceAll('}}', '')
        .replaceAll(RegExp(r'[ \t]{2,}'), ' ');
    final sectioned = _dropThinSections(result);
    result = sectioned.text;
    for (final marker in const [
      '\nอ้างอิง\n',
      '\nแหล่งข้อมูลอื่น\n',
      '\nดูเพิ่ม\n',
      '\nReferences\n',
      '\nExternal links\n',
      '\nSee also\n',
      '\nNotes\n',
      '\n参考文献\n',
      '\n参见\n',
      '\n外部链接\n',
      '\n注释\n',
    ]) {
      final index = result.indexOf(marker);
      if (index > 0) result = result.substring(0, index);
    }
    result = result.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    if (result.length > _maxDisplayChars) {
      result = '${result.substring(0, _maxDisplayChars)}…';
    }
    return (text: result, headings: sectioned.headings);
  }

  /// แยกเป็นหัวข้อตามบรรทัด "== ... ==" แล้ว:
  /// - ตัดทุกอย่างตั้งแต่หัวข้อท้ายบทความ (อ้างอิง ฯลฯ)
  /// - ตัดหัวข้อที่เนื้อหาสั้นเกินไปและไม่มีหัวข้อย่อยที่เก็บไว้
  /// - แปลงหัวข้อที่เหลือกลับเป็นบรรทัดธรรมดา (หน้าอ่าน/TTS/AI ใช้ข้อความรูปแบบเดิม)
  static ({String text, List<String> headings}) _dropThinSections(String text) {
    final intro = <String>[];
    final sections = <_Section>[];
    for (final line in text.split('\n')) {
      final match = _heading.firstMatch(line.trim());
      if (match == null) {
        (sections.isEmpty ? intro : sections.last.lines).add(line);
        continue;
      }
      final title = match.group(2)!;
      if (_endSections.contains(title)) break;
      sections.add(_Section(match.group(1)!.length, title));
    }

    // ไล่จากท้ายขึ้นมา: หัวข้อแม่ที่เนื้อหาสั้นยังเก็บไว้ ถ้ามีหัวข้อย่อยข้างใต้ที่ถูกเก็บ
    final keep = List.filled(sections.length, false);
    for (var i = sections.length - 1; i >= 0; i--) {
      var childKept = false;
      for (
        var j = i + 1;
        j < sections.length && sections[j].level > sections[i].level;
        j++
      ) {
        if (keep[j]) {
          childKept = true;
          break;
        }
      }
      keep[i] = childKept || sections[i].body.length >= _minSectionChars;
    }

    final out = StringBuffer(intro.join('\n').trim());
    final headings = <String>[];
    for (var i = 0; i < sections.length; i++) {
      if (!keep[i]) continue;
      headings.add(sections[i].title);
      out.write('\n\n${sections[i].title}');
      if (sections[i].body.isNotEmpty) out.write('\n\n${sections[i].body}');
    }
    return (text: out.toString(), headings: headings);
  }
}

/// หัวข้อ 1 หัวข้อของบทความ (level 2 = "==", 3 = "===" ...)
class _Section {
  _Section(this.level, this.title);

  final int level;
  final String title;
  final List<String> lines = [];

  String get body => lines.join('\n').trim();
}

class _Candidate {
  const _Candidate(this.pageId, this.title, this.length);

  factory _Candidate.fromJson(dynamic json, String lengthKey) => _Candidate(
    (json['pageid'] as num?)?.toInt() ?? 0,
    json['title'] as String? ?? '',
    (json[lengthKey] as num?)?.toInt() ?? 0,
  );

  final int pageId;
  final String title;
  final int length;
}

class _Batch {
  const _Batch(this.items, {required this.isComplete});

  final List<_Candidate> items;

  /// true = ได้บทความในหมวดนี้ครบทุกเรื่องแล้ว (ใช้ตัดสินว่า "อ่านครบ")
  final bool isComplete;
}
