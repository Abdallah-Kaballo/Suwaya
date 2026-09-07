import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'auth_service.dart';

// 🌟 مزود خدمة المصادقة الأساسي
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

// 🌟 مزود يراقب أي تغيير في حالة تسجيل الدخول/الخروج
final authStateProvider = StreamProvider<AuthState>((ref) {
  return ref.watch(authServiceProvider).authStateChanges;
});

// 🌟 مزود يسهل الوصول لبيانات المستخدم الحالي مباشرة
final currentUserProvider = Provider<User?>((ref) {
  // نجعل هذا المزود يعيد بناء نفسه كلما تغيرت حالة المصادقة
  ref.watch(authStateProvider);
  return ref.watch(authServiceProvider).currentUser;
});