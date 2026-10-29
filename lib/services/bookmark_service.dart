import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/article.dart';

/// บทความที่บันทึกไว้ (ปุ่มบุ๊กมาร์กบนหน้าอ่าน)
/// ตอนนี้แค่เก็บไว้ในเครื่อง แยกตามผู้ใช้ (key `bookmarks_<uid>`) ยังไม่มีหน้ารายการ
class BookmarkService {
  BookmarkService._();
  static final instance = BookmarkService._();

  String? _uid;
  String get _key => 'bookmarks_$_uid';

  /// readKey ของบทความที่บันทึกไว้ (widget ฟังค่านี้เพื่อสลับไอคอน)
  final ValueNotifier<Set<String>> saved = ValueNotifier(const {});
  Map<String, dynamic> _items = {};

  /// งานโหลดล่าสุด: toggle ต้องรอให้โหลดเสร็จก่อน ไม่งั้นจะเขียนทับรายการเดิมด้วยรายการว่าง
  Future<void> _loading = Future.value();

  Future<void> load(String uid) {
    if (_uid == uid) return _loading;
    _uid = uid;
    return _loading = _read(uid);
  }

  Future<void> _read(String uid) async {
    Map<String, dynamic> items;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('bookmarks_$uid');
      items = raw == null
          ? {}
          : Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      items = {};
    }
    // ระหว่างรอ ผู้ใช้อาจ logout/เปลี่ยนบัญชีไปแล้ว → ทิ้งผลของบัญชีเก่า
    if (_uid != uid) return;
    _items = items;
    saved.value = _items.keys.toSet();
  }

  bool isSaved(Article article) => saved.value.contains(article.readKey);

  /// บันทึก ↔ เลิกบันทึก คืนค่า true ถ้าตอนนี้ถูกบันทึกอยู่
  Future<bool> toggle(Article article) async {
    await _loading;
    final key = article.readKey;
    if (_items.containsKey(key)) {
      _items.remove(key);
    } else {
      _items[key] = {
        'title': article.title,
        'url': article.url,
        'language': article.language.code,
        'savedAt': DateTime.now().toIso8601String(),
      };
    }
    saved.value = _items.keys.toSet();
    if (_uid != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_key, jsonEncode(_items));
    }
    return _items.containsKey(key);
  }

  void clear() {
    _uid = null;
    _items = {};
    saved.value = const {};
  }
}
