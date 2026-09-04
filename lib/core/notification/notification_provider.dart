import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'notification_service.dart';

// مزود خدمة الإشعارات ليتم حقنها في أي مكان في التطبيق بسهولة وبدون Singletons
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});