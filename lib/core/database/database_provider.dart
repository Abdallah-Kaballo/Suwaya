import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar_community/isar.dart';

// 🌟 DI حقيقي: سيتم حقن القيمة الفعلية عند بدء تشغيل التطبيق
final isarProvider = Provider<Isar>((ref) {
  throw UnimplementedError('لم يتم تهيئة قاعدة بيانات Isar بعد');
});