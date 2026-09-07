import 'package:flutter_riverpod/flutter_riverpod.dart';

// 🌟 هذا المتغير يراقب حالة القائمة الجانبية في التطبيق بأكمله
final isDrawerOpenProvider = StateProvider<bool>((ref) => false);