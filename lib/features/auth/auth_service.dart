import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(Supabase.instance.client);
});

class AuthService {
  final SupabaseClient _supabase;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  AuthService(this._supabase);

  Future<AuthResponse?> signInWithGoogle() async {
    try {
      final webClientId = dotenv.env['GOOGLE_WEB_CLIENT_ID'] ?? '';
      final iosClientId = dotenv.env['GOOGLE_IOS_CLIENT_ID'] ?? '';

      if (webClientId.isEmpty) {
        throw Exception(
          'لم يتم العثور على GOOGLE_WEB_CLIENT_ID في ملف .env',
        );
      }

      if (defaultTargetPlatform == TargetPlatform.iOS &&
          iosClientId.isEmpty) {
        throw Exception(
          'لم يتم العثور على GOOGLE_IOS_CLIENT_ID في ملف .env',
        );
      }

      if (!_googleSignIn.supportsAuthenticate()) {
        throw UnsupportedError(
          'تسجيل الدخول بهذه الطريقة غير مدعوم على هذه المنصة.',
        );
      }

      await _googleSignIn.initialize(
        clientId: defaultTargetPlatform == TargetPlatform.iOS
            ? iosClientId
            : null,
        serverClientId: webClientId,
      );

      final googleUser = await _googleSignIn.authenticate(
        scopeHint: const [
          'openid',
          'email',
          'profile',
        ],
      );

      final idToken = googleUser.authentication.idToken;

      final authorization = await googleUser.authorizationClient
          .authorizationForScopes(const [
        'openid',
        'email',
        'profile',
      ]);

      final accessToken = authorization?.accessToken;

      if (idToken == null || accessToken == null) {
        throw Exception(
          'لم يتم استلام رموز المصادقة من Google.',
        );
      }

      return await _supabase.auth.signInWithIdToken(
        provider: OAuthProvider.google,
        idToken: idToken,
        accessToken: accessToken,
      );
    } catch (error) {
      debugPrint('خطأ في تسجيل الدخول بواسطة Google: $error');
      rethrow;
    }
  }

  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (error) {
      debugPrint('خطأ أثناء تسجيل الخروج من Google: $error');
    }

    await _supabase.auth.signOut();
  }

  User? get currentUser => _supabase.auth.currentUser;

  Stream<AuthState> get authStateChanges {
    return _supabase.auth.onAuthStateChange;
  }
}