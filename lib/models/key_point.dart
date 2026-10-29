/// ประเด็นสำคัญ 1 ข้อของบทความ ที่ AI ตรวจว่าคำสรุปของผู้ใช้ครอบคลุมหรือยัง
class KeyPoint {
  const KeyPoint({
    required this.point,
    required this.core,
    required this.covered,
  });

  final String point;

  /// true = ใจความหลักของบทความ, false = รายละเอียดสนับสนุน
  final bool core;

  /// คำสรุปพูดถึงประเด็นนี้แล้ว
  final bool covered;

  Map<String, dynamic> toMap() => {
    'point': point,
    'core': core,
    'covered': covered,
  };

  /// อ่านได้ทั้งรูปแบบที่เก็บใน Firestore และรูปแบบที่โมเดลตอบ (importance: core|detail)
  /// คืน null ถ้าไม่มีข้อความประเด็น
  static KeyPoint? fromMap(Map<dynamic, dynamic> map) {
    var point = '${map['point'] ?? ''}'.trim();
    if (point.isEmpty) return null;
    if (point.length > maxLength) point = '${point.substring(0, maxLength)}…';
    return KeyPoint(
      point: point,
      core: map['core'] is bool
          ? map['core'] as bool
          : map['importance'] != 'detail',
      covered: map['covered'] == true,
    );
  }

  /// จำกัดจำนวนและความยาว: ข้อมูลมาจากโมเดล AI และถูกเก็บลง Firestore (เอกสารสูงสุด 1 MB)
  static const maxPoints = 10;
  static const maxLength = 300;

  static List<KeyPoint> listFrom(List<dynamic>? raw) => [
    for (final item in raw ?? const [])
      if (item is Map) ?KeyPoint.fromMap(item),
  ].take(maxPoints).toList();
}
