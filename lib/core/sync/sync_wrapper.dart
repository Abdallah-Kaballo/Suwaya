import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'sync_service.dart';

// مزود لمراقبة حالة تسجيل الدخول من Supabase مباشرة
final authStateProvider = StreamProvider<AuthState>((ref) {
  return Supabase.instance.client.auth.onAuthStateChange;
});

class GlobalSyncWrapper extends ConsumerStatefulWidget {
  final Widget child;
  const GlobalSyncWrapper({super.key, required this.child});

  @override
  ConsumerState<GlobalSyncWrapper> createState() => _GlobalSyncWrapperState();
}

class _GlobalSyncWrapperState extends ConsumerState<GlobalSyncWrapper> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // 1. مزامنة صامتة فور تشغيل التطبيق
    Future.microtask(() => ref.read(syncServiceProvider).syncAll());
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // 2. مزامنة صامتة في كل مرة يعود فيها المستخدم للتطبيق من الخلفية
    if (state == AppLifecycleState.resumed) {
      ref.read(syncServiceProvider).syncAll();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 3. مراقبة تسجيل الدخول: فور ربط الحساب بجوجل، يتم دمج البيانات محلياً وسحابياً
    ref.listen<AsyncValue<AuthState>>(authStateProvider, (previous, next) {
      final event = next.value?.event;
      if (event == AuthChangeEvent.signedIn || event == AuthChangeEvent.userUpdated) {
        ref.read(syncServiceProvider).syncAll();
      }
    });

    return widget.child; // لا يؤثر على الواجهة أبداً، مجرد مستشعر بالخلفية
  }
}