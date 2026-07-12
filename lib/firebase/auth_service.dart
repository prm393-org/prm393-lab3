import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Bọc Firebase Authentication + Google Sign-In (FR 4.1).
///
/// `google_sign_in` 7.x: gọi `initialize(serverClientId: …)` một lần rồi
/// `authenticate()`. `serverClientId` phải là **Web client ID** (client_type 3
/// trong `google-services.json`) — thiếu thì Android không cấp idToken / CredMan fail.
class AuthService {
  /// Web OAuth client từ `google-services.json` → `oauth_client` type 3.
  static const String webClientId =
      '659837143296-l4lmsa9vrk640f77fpanuvo61mrp5fdg.apps.googleusercontent.com';

  AuthService({FirebaseAuth? firebaseAuth, GoogleSignIn? googleSignIn})
      : _auth = firebaseAuth ?? FirebaseAuth.instance,
        _googleSignIn = googleSignIn ?? GoogleSignIn.instance;

  final FirebaseAuth _auth;
  final GoogleSignIn _googleSignIn;
  bool _initialized = false;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  bool get isSignedIn => _auth.currentUser != null;

  Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await _googleSignIn.initialize(serverClientId: webClientId);
    _initialized = true;
  }

  /// Trả về `null` khi người dùng tự đóng dialog chọn tài khoản — đây là
  /// hành vi bình thường, không phải lỗi, nên caller không cần bắt exception.
  Future<UserCredential?> signInWithGoogle() async {
    await _ensureInitialized();

    final GoogleSignInAccount account;
    try {
      account = await _googleSignIn.authenticate();
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        // SHA-1 sai / OAuth lệch thường bị map thành canceled kèm "[16] reauth".
        final desc = '${e.description ?? ''} ${e.toString()}'.toLowerCase();
        if (desc.contains('reauth') ||
            desc.contains('[16]') ||
            desc.contains('network_error')) {
          throw FirebaseAuthException(
            code: 'google-sign-in-config',
            message:
                'Google Sign-In failed. Add this machine\'s debug SHA-1 to '
                'Firebase (Project settings → Your apps), download a fresh '
                'google-services.json, then rebuild.',
          );
        }
        return null;
      }
      rethrow;
    }

    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw FirebaseAuthException(
        code: 'missing-id-token',
        message: 'Google không trả về idToken. Kiểm tra SHA-1 và '
            'oauth_client trong google-services.json.',
      );
    }

    return _auth.signInWithCredential(
      GoogleAuthProvider.credential(idToken: idToken),
    );
  }

  /// Đăng xuất khỏi cả Google lẫn Firebase. Thiếu vế Google thì lần đăng nhập
  /// sau sẽ bỏ qua dialog chọn tài khoản và im lặng dùng lại account cũ.
  Future<void> signOut() async {
    await _ensureInitialized();
    await _googleSignIn.signOut();
    await _auth.signOut();
  }
}
