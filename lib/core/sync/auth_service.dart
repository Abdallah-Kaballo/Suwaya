import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart'; // 🌟 الاستيراد الجديد

class AuthService {
  final _supabase = Supabase.instance.client;
  
  // 🌟 جلب المفتاح بأمان من ملف الأسرار
  final String _webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
  
  // 🌟 استخدام API الإصدار السابع (v7) 
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  bool _googleInitialized = false;

  Future<void> _ensureGoogleInitialized() async {
    if (_googleInitialized) return;
    await _googleSignIn.initialize(serverClientId: _webClientId);
    _googleInitialized = true;
  }

  Future<void> signInAnonymously() async {
    final session = _supabase.auth.currentSession;
    if (session == null) {
      try {
        await _supabase.auth.signInAnonymously();
        debugPrint('✅ تم تسجيل الدخول كضيف خفي بنجاح');
      } catch (e) {
        debugPrint('❌ خطأ في المصادقة الخفية: $e');
      }
    }
  }

  // 🌟 ترجع null إذا نجحت، وترجع نص الخطأ إذا فشلت
  Future<String?> signInWithGoogle() async {
    try {
      await _ensureGoogleInitialized();

      if (!_googleSignIn.supportsAuthenticate()) {
        return 'هذه المنصة لا تدعم تسجيل الدخول المباشر لجوجل.';
      }

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication; 
      final String? idToken = googleAuth.idToken;

      if (idToken == null) return 'نجح الاتصال بجوجل، لكن لم نستلم ID Token.';

      await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
      );

      return null; // ✅ نجاح (لا يوجد خطأ)

    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return 'تم الإلغاء بواسطة المستخدم.';
      } else {
        // 🌟 استبدلنا e.message بـ e.toString()
        return 'خطأ Google (Code: ${e.code}): ${e.toString()}';
      }
    } catch (e) {
      return 'خطأ عام: $e';
    }
  }

  Future<void> signOut() async {
    try {
      await _ensureGoogleInitialized();
      await _googleSignIn.signOut();
    } catch (_) {}

    await _supabase.auth.signOut();
    await signInAnonymously();
  }

  User? get currentUser => _supabase.auth.currentUser;
  bool get isAnonymous => currentUser?.isAnonymous ?? true;
}

final authServiceProvider = Provider((ref) => AuthService());