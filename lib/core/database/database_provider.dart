import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';
import 'local_db_service.dart';

// 🟢 هذا المزود هو "الموزع" الذي سيمرر قاعدة البيانات للمستودعات
// مستقبلاً، يمكننا استبداله بقاعدة بيانات وهمية (Mock) لاختبار التطبيق
final isarProvider = Provider<Isar>((ref) {
  // حالياً نستخدم الـ static كجسر مؤقت حتى ننظف main.dart كلياً
  return LocalDbService.isar; 
});