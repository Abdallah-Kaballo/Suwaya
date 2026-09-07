import 'package:supabase_flutter/supabase_flutter.dart';
// 🌟 أضفنا اسماً مستعاراً للحزمة لفك أي تعارض مع ملفاتك القديمة
import 'package:google_sign_in/google_sign_in.dart' as g_auth;


class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;

  // 🌟 مراقبة حالة الدخول (مستمع لحظي)
  Stream<AuthState> get authStateChanges => _supabase.auth.onAuthStateChange;

  // 🌟 جلب المستخدم الحالي
  User? get currentUser => _supabase.auth.currentUser;

  // 🌟 التحقق مما إذا كان المستخدم ضيفاً (غير مسجل)
  bool get isAnonymous => currentUser == null;

  // 🌟 تسجيل الدخول بواسطة جوجل
  Future<AuthResponse?> signInWithGoogle() async {
    const webClientId = '416871298633-cajdtghfht4re9k9pvr2s649e3f9ofu2.apps.googleusercontent.com'; 
    const iosClientId = 'YOUR_IOS_CLIENT_ID'; 

    // 🌟 استخدام البادئة g_auth هنا
    final googleSignIn = g_auth.GoogleSignIn.instance;

await googleSignIn.initialize(
  clientId: iosClientId,
  serverClientId: webClientId,
);

final googleUser = await googleSignIn.authenticate(
  scopeHint: const ['openid', 'email', 'profile'],
);

final googleAuth = googleUser.authentication;
final idToken = googleAuth.idToken;

final authorization = await googleUser.authorizationClient
    .authorizationForScopes(const ['openid', 'email', 'profile']);

final accessToken = authorization?.accessToken;

if (idToken == null || accessToken == null) {
  throw 'حدث خطأ: لا يمكن العثور على رموز المصادقة من جوجل.';
}

    // تمرير مفاتيح جوجل إلى Supabase
    return await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
  }

  // 🌟 تسجيل الخروج
  Future<void> signOut() async {
    // 🌟 استخدام البادئة g_auth هنا
    await g_auth.GoogleSignIn.instance.signOut();
    await _supabase.auth.signOut();
  }
}