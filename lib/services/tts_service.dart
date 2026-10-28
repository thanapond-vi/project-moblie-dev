import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';

import '../core/app_exception.dart';
import '../models/content_language.dart';
import '../l10n/l10n.dart';

enum TtsStatus { stopped, playing, paused }

/// ตัวอ่านออกเสียง (Text-to-Speech)
///
/// เขียนเป็น abstract class เพื่อให้หน้าจอไม่ผูกกับ package ใด package หนึ่ง
/// ถ้าวันหลังอยากเปลี่ยนไปใช้ Cloud TTS ก็แค่เขียน class ใหม่ที่ implements TtsService
/// แล้วเปลี่ยนตรง `TtsService.create()` จุดเดียว หน้าจอไม่ต้องแก้
abstract class TtsService {
  static TtsService create() => DeviceTtsService();

  /// สถานะ เล่น / พัก / หยุด (หน้าจอใช้ ValueListenableBuilder ฟัง)
  ValueListenable<TtsStatus> get status;

  /// ย่อหน้าที่กำลังอ่าน (ใช้ไฮไลต์และเลื่อนจอตาม)
  ValueListenable<int> get currentParagraph;

  /// ตั้งภาษาเสียง ถ้าเครื่องไม่มีเสียงภาษานั้นจะ throw AppException
  Future<void> setLanguage(ContentLanguage language);

  /// ตัวคูณความเร็ว 1.0 = ปกติ
  Future<void> setRate(double multiplier);

  /// เริ่มอ่าน (หรืออ่านต่อจากย่อหน้าที่พักไว้)
  Future<void> play(List<String> paragraphs);

  /// พัก: หยุดเสียง แต่จำย่อหน้าไว้ กดเล่นอีกครั้งจะเริ่มที่ต้นย่อหน้าเดิม
  Future<void> pause();

  /// หยุด: หยุดเสียงและกลับไปเริ่มย่อหน้าแรก
  Future<void> stop();

  void dispose();
}

/// ใช้เสียงอ่านที่ติดมากับเครื่อง (iOS: AVSpeechSynthesizer, Android: TextToSpeech)
/// ผ่าน package flutter_tts: ฟรี ทำงานในเครื่อง ไม่ต้องใช้อินเทอร์เน็ต
class DeviceTtsService implements TtsService {
  DeviceTtsService() {
    // ให้ speak() รอจนพูดจบก่อนค่อย return จึงวนอ่านทีละย่อหน้าด้วย await ได้
    _tts.awaitSpeakCompletion(true);
    _tts.setErrorHandler((_) {
      _runId++;
      _status.value = TtsStatus.stopped;
    });
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      // playback = ยังได้ยินเสียงแม้เปิดโหมดเงียบ (ปุ่มด้านข้าง iPhone)
      _tts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback, [
        IosTextToSpeechAudioCategoryOptions.defaultToSpeaker,
      ]);
    }
  }

  final FlutterTts _tts = FlutterTts();
  final _status = ValueNotifier(TtsStatus.stopped);
  final _current = ValueNotifier(0);

  /// เลขรอบการเล่น: ทุกครั้งที่กดพัก/หยุด/เล่นใหม่ จะ +1
  /// loop ที่อ่านอยู่เช็กเลขนี้ ถ้าไม่ตรงแปลว่าถูกสั่งหยุดแล้ว ให้เลิกอ่านต่อ
  int _runId = 0;

  /// Android อ่านได้ไม่เกิน ~4,000 ตัวอักษรต่อครั้ง ย่อหน้าที่ยาวกว่านี้จึงต้องหั่นเป็นท่อน
  static const _maxChunk = 3000;

  @override
  ValueListenable<TtsStatus> get status => _status;

  @override
  ValueListenable<int> get currentParagraph => _current;

  @override
  Future<void> setLanguage(ContentLanguage language) async {
    final available = await _tts.isLanguageAvailable(language.ttsLocale);
    if (available != true) {
      throw AppException(tr.errTtsNoVoice(language.label));
    }
    await _tts.setLanguage(language.ttsLocale);
  }

  @override
  Future<void> setRate(double multiplier) async {
    // ค่าความเร็วของแต่ละระบบต่างกัน: iOS ปกติ = 0.5 (ช่วง 0–1), Android ปกติ = 1.0
    final rate = defaultTargetPlatform == TargetPlatform.iOS
        ? (0.5 * multiplier).clamp(0.1, 1.0)
        : multiplier;
    await _tts.setSpeechRate(rate.toDouble());
  }

  @override
  Future<void> play(List<String> paragraphs) async {
    if (paragraphs.isEmpty) return;
    final runId = ++_runId;
    if (_current.value >= paragraphs.length) _current.value = 0;
    _status.value = TtsStatus.playing;

    for (var i = _current.value; i < paragraphs.length; i++) {
      if (runId != _runId) return; // ถูกพัก/หยุดระหว่างทาง
      _current.value = i;
      for (final chunk in _chunks(paragraphs[i])) {
        await _tts.speak(chunk); // await: รอพูดท่อนนี้จบก่อน
        if (runId != _runId) return;
      }
    }
    // อ่านจบทั้งบทความ
    _status.value = TtsStatus.stopped;
    _current.value = 0;
  }

  @override
  Future<void> pause() async {
    _runId++;
    _status.value = TtsStatus.paused;
    await _tts.stop();
  }

  @override
  Future<void> stop() async {
    _runId++;
    _status.value = TtsStatus.stopped;
    _current.value = 0;
    await _tts.stop();
  }

  @override
  void dispose() {
    _runId++;
    _tts.stop();
    _status.dispose();
    _current.dispose();
  }

  /// หั่นข้อความยาวเป็นท่อน ตัดที่ช่องว่างใกล้ขอบ เพื่อไม่ให้ตัดกลางคำ
  static Iterable<String> _chunks(String text) sync* {
    var rest = text;
    while (rest.length > _maxChunk) {
      var cut = rest.lastIndexOf(' ', _maxChunk);
      if (cut < _maxChunk ~/ 2) cut = _maxChunk;
      yield rest.substring(0, cut);
      rest = rest.substring(cut).trimLeft();
    }
    if (rest.isNotEmpty) yield rest;
  }
}
