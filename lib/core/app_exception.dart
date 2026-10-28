/// Exception กลางของแอป: service ทุกตัวแปลง error ภายใน (Firebase, HTTP, JSON)
/// ให้เป็น AppException ที่มีข้อความภาษาไทยพร้อมแสดงผู้ใช้
/// หน้าจอจึง catch แค่ชนิดเดียวแล้วโชว์ message ใน SnackBar ได้เลย
class AppException implements Exception {
  const AppException(this.message);

  final String message;

  @override
  String toString() => message;
}
