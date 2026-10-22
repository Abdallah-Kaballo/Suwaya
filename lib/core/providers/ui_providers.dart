import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🌟 يراقب حالة القائمة الجانبية في التطبيق بأكمله
final isDrawerOpenProvider = StateProvider<bool>((ref) => false);

// 🌟 يراقب حالة وضع ملء الشاشة في البومودورو لإخفاء شريط التنقل السفلي بنعومة
final isPomodoroFullScreenProvider = StateProvider<bool>((ref) => false);

// 🌟 يراقب ما إذا كان إصبع المستخدم يلمس مساحة القرص الفلكي حالياً لعزل حركته
final isDialTouchActiveProvider = StateProvider<bool>((ref) => false);