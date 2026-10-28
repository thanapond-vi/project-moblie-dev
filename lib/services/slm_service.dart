import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';
import '../core/config.dart';
import '../l10n/l10n.dart';
import '../models/ai_evaluation.dart';
import '../models/article_tag.dart';
import '../models/content_language.dart';

/// คุยกับ AI บน Groq (LLM `qwen/qwen3.8-27b` ของ Alibaba) ใช้ 2 งาน:
/// 1) [evaluate]: ให้คะแนนคำสรุป + Feedback + แนะนำแท็ก (ตอบเป็น JSON)
/// 2) [dailyGreeting]: คิดคำทักทายประจำวันสั้นๆ สำหรับหน้าแรก
///
/// Groq ใช้ API รูปแบบเดียวกับ OpenAI: POST {baseUrl}/chat/completions
/// แอปเป็นคนระบุชื่อโมเดลใน field `model` เอง (ค่า GROQ_MODEL ใน .env) Groq ไม่ได้เลือกให้
/// และ response จะส่งชื่อโมเดลที่รันจริงกลับมาใน field `model` ด้วย
class SlmService {
  SlmService({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const _timeout = Duration(seconds: 30);

  /// prompt เขียนเป็นภาษาอังกฤษ (โมเดลทำตามคำสั่งภาษาอังกฤษได้แม่นที่สุด)
  /// แล้วบอกให้ตอบเป็นภาษาของแอปที่ผู้ใช้เลือก
  ///
  /// ไม่ให้โมเดลเดาคะแนนเอง: ให้ไล่ประเด็นหลักของบทความทีละข้อ ว่าคำสรุปครอบคลุมไหม
  /// พร้อมยกคำจากคำสรุปมาเป็นหลักฐาน แล้วแอปคำนวณคะแนนเองใน [scoreOf]
  static String _gradePrompt(ContentLanguage language) {
    final tagIds = ArticleTag.values.map((t) => t.id).join(', ');
    return '''
You check a learner's summary of an article, point by point.
1. List the article's 6 to 8 most important ideas, spread across the whole article (not only the opening). Mark each "core" (the article is about it)
   or "detail" (supporting fact). Ignore lists of seasons/numbers, tables, footnotes and references.
2. For EACH idea, search the WHOLE learner summary before deciding. The summary may be in a
   different language from the article: compare meaning, not wording.
   - covered: true if the summary states the idea (paraphrase counts). Copy the exact words from
     the summary that show it into "evidence".
   - covered: false only if the idea is truly absent. Then "evidence" is "".
3. List claims in the summary that contradict the article in "accuracyIssues" (empty if none).
4. Write aiFeedback (2-4 sentences): what the summary did well, then ONLY the ideas you marked
   covered: false. If none are missing, say so. Never invent missing points.
Also choose 1 to ${ArticleTag.maxPerArticle} tags that describe the ARTICLE, only from this list: $tagIds.
Respond with JSON only, no other text, in this exact shape:
{"keyPoints": [{"point": "<idea>", "importance": "core|detail", "covered": true, "evidence": "<exact words from the summary>"}], "accuracyIssues": ["<wrong claim>"], "aiFeedback": "<text>", "tags": ["<tag>"]}
Write point, accuracyIssues and aiFeedback in ${language.aiLanguage}; keep evidence exactly as written in the summary.''';
  }

  /// คำนวณคะแนน 0–100 จากรายการประเด็นที่โมเดลตรวจ
  ///
  /// - ประเด็น core หนัก 2 เท่าของ detail
  /// - ครอบคลุม + หลักฐานมีอยู่ในคำสรุปจริง = เต็ม
  ///   ครอบคลุมแต่หาหลักฐานในคำสรุปไม่เจอ (โมเดลอาจถอดความ) = ครึ่งเดียว
  /// - ข้อมูลผิดหักข้อละ 10 (สูงสุด 30)
  /// คืน null ถ้าไม่มีรายการประเด็น (ให้ไปใช้คะแนนที่โมเดลตอบมาแทน)
  @visibleForTesting
  static int? scoreOf(
    List<dynamic>? keyPoints,
    List<dynamic>? accuracyIssues,
    String summary,
  ) {
    if (keyPoints == null || keyPoints.isEmpty) return null;
    final haystack = _normalize(summary);
    var total = 0.0;
    var earned = 0.0;
    for (final p in keyPoints.whereType<Map>()) {
      final weight = p['importance'] == 'detail' ? 1.0 : 2.0;
      total += weight;
      if (p['covered'] != true) continue;
      // โมเดลมักยกหลายช่วงมาต่อกันด้วย "..." จึงเช็กทีละช่วงว่ามีอยู่ในคำสรุปทุกช่วง
      final fragments = '${p['evidence'] ?? ''}'
          .split(RegExp(r'\.{3}|…'))
          .map(_normalize)
          .where((f) => f.isNotEmpty)
          .toList();
      final found = fragments.isNotEmpty && fragments.every(haystack.contains);
      earned += found ? weight : weight / 2;
    }
    if (total == 0) return null;
    final issues = (accuracyIssues ?? const [])
        .where((i) => '$i'.trim().isNotEmpty)
        .length;
    final penalty = (issues * 10).clamp(0, 30);
    return ((earned / total) * 100 - penalty).round().clamp(0, 100);
  }

  /// ตัวพิมพ์เล็ก + ช่องว่างเดียว + ไม่สนเครื่องหมายวรรคตอนหัวท้าย (ไว้เทียบหลักฐานกับคำสรุป)
  static String _normalize(String text) => text
      .toLowerCase()
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'''^[\s"'.,;:!?…]+|[\s"'.,;:!?…]+$'''), '');

  Future<AiEvaluation> evaluate({
    required ContentLanguage language,
    required String articleTitle,
    required String originalContent,
    required String userSummary,
  }) async {
    final reply = await _chat(
      system: _gradePrompt(language),
      user:
          'Article title: $articleTitle\n\n'
          'Original article:\n"""\n$originalContent\n"""\n\n'
          'Learner summary:\n"""\n$userSummary\n"""',
      json: true,
      temperature: 0, // 0 = ตรวจแบบเดิมทุกครั้ง คะแนนคงที่
    );
    return _parseEvaluation(reply.content, reply.model, userSummary);
  }

  /// คำทักทายประจำวัน 1 ประโยค (ให้กำลังใจและชวนเรียนรู้) ในภาษาของแอป
  /// [date] ใส่ใน prompt เพื่อให้แต่ละวันได้คำทักทายไม่ซ้ำกัน
  Future<String> dailyGreeting({
    required ContentLanguage language,
    required DateTime date,
  }) async {
    final reply = await _chat(
      system:
          'You write the one-line greeting at the top of a reading-practice app. '
          'Reply with ONE short, warm question or nudge (max 12 words) that '
          'invites the user to learn something today. Vary the theme with the '
          'date. No quotes, no hashtags, at most one emoji. '
          'Write it in ${language.aiLanguage}.',
      user:
          'Today is ${date.year}-${date.month}-${date.day} '
          '(weekday ${date.weekday}).',
      json: false,
      temperature: 0.9, // สูง = ได้คำทักทายหลากหลาย
    );
    final text = reply.content
        .replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '')
        .replaceAll('"', '')
        .trim()
        .split('\n')
        .first
        .trim();
    if (text.isEmpty || text.length > 120) {
      throw AppException(tr.errAiBadFormat);
    }
    return text;
  }

  static const _maxRetryWait = Duration(seconds: 10);

  /// เวลาที่ควรรอก่อนลองใหม่ จาก header retry-after (วินาที) ของ Groq
  /// คืน null ถ้าไม่มีค่า อ่านไม่ได้ หรือนานเกิน [_maxRetryWait]
  @visibleForTesting
  static Duration? retryWait(String? retryAfter) {
    final seconds = double.tryParse(retryAfter?.trim() ?? '');
    if (seconds == null || seconds < 0) return null;
    final wait = Duration(milliseconds: (seconds * 1000).ceil());
    return wait <= _maxRetryWait ? wait : null;
  }

  /// ส่ง 1 คำขอไปที่ Groq แล้วคืนข้อความที่ตอบ + ชื่อโมเดลที่ตอบจริง
  Future<({String content, String model})> _chat({
    required String system,
    required String user,
    required bool json,
    required double temperature,
  }) async {
    final apiKey = AppConfig.groqApiKey;
    if (apiKey.isEmpty) throw AppException(tr.errAiNotConfigured);

    try {
      Future<http.Response> send() => _client
          .post(
            Uri.parse('${AppConfig.groqBaseUrl}/chat/completions'),
            headers: {
              HttpHeaders.contentTypeHeader: 'application/json',
              HttpHeaders.authorizationHeader: 'Bearer $apiKey',
            },
            body: jsonEncode({
              'model': AppConfig.groqModel, // แอประบุโมเดลเอง
              'temperature': temperature,
              // บังคับให้ตอบเป็น JSON (ใช้ตอนให้คะแนน)
              if (json) 'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': system},
                {'role': 'user', 'content': user},
              ],
            }),
          )
          .timeout(_timeout);

      var response = await send();
      // โดนจำกัดจำนวนครั้ง (429): รอตามที่ Groq บอกใน retry-after แล้วลองใหม่เองอีก 1 ครั้ง
      // ถ้าต้องรอนานเกิน [_maxRetryWait] ให้ผู้ใช้กด "ลองใหม่" เองดีกว่าค้างหน้าจอ
      if (response.statusCode == 429) {
        final wait = retryWait(response.headers['retry-after']);
        if (wait != null) {
          await Future<void>.delayed(wait);
          response = await send();
        }
      }

      if (response.statusCode == 401) throw AppException(tr.errAiBadKey);
      if (response.statusCode == 404) {
        throw AppException(tr.errAiModelNotFound(AppConfig.groqModel));
      }
      if (response.statusCode == 429) throw AppException(tr.errAiRateLimit);
      if (response.statusCode != 200) {
        throw AppException(tr.errAiStatus('${response.statusCode}'));
      }

      final body =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return (
        content: body['choices']?[0]?['message']?['content'] as String? ?? '',
        // ชื่อโมเดลที่ Groq รันจริง อ่านจาก response ไม่ได้เอามาจาก .env
        model: body['model'] as String? ?? AppConfig.groqModel,
      );
    } on AppException {
      rethrow;
    } on TimeoutException {
      throw AppException(tr.errAiTimeout);
    } on SocketException {
      throw AppException(tr.errAiConnect);
    } catch (_) {
      throw AppException(tr.errAiRead);
    }
  }

  /// แปลงข้อความจากโมเดลเป็น AiEvaluation แบบระวังพลาด
  /// บางครั้งโมเดลตอบมีข้อความหรือ ```json ครอบมา จึงตัดเอาเฉพาะช่วง { ... }
  AiEvaluation _parseEvaluation(String content, String model, String summary) {
    // บางโมเดล (เช่น Qwen3) อาจคิดออกมาใน <think>...</think> ก่อนตอบ ตัดส่วนนั้นทิ้ง
    content = content.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start < 0 || end <= start) throw AppException(tr.errAiBadFormat);

    final Map<String, dynamic> json;
    try {
      json =
          jsonDecode(content.substring(start, end + 1)) as Map<String, dynamic>;
    } catch (_) {
      throw AppException(tr.errAiBadFormat);
    }

    // คะแนนจากการไล่เช็กประเด็นก่อน ถ้าโมเดลไม่ส่งรายการมา ค่อยใช้คะแนนที่โมเดลตอบตรงๆ
    final rawScore = json['aiScore'] ?? json['score'];
    final score =
        scoreOf(
          json['keyPoints'] as List?,
          json['accuracyIssues'] as List?,
          summary,
        ) ??
        (rawScore is num ? rawScore.round() : int.tryParse('$rawScore'));
    if (score == null) throw AppException(tr.errAiNoScore);

    final feedback = (json['aiFeedback'] ?? json['feedback'] ?? '')
        .toString()
        .trim();
    // เก็บเฉพาะแท็กที่อยู่ในรายการหมวดยอดฮิต (กันโมเดลแต่งแท็กใหม่เอง)
    final tags = ArticleTag.normalize(
      (json['tags'] as List?)?.where((t) => ArticleTag.fromId('$t') != null),
    );
    return AiEvaluation(
      score: score.clamp(0, 100),
      feedback: feedback.isEmpty ? tr.aiNoFeedback : feedback,
      model: model,
      tags: tags,
    );
  }
}
