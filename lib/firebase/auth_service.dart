import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Bọc Firebase Authentication + Google Sign-In (FR 4.1).
///
/// Lưu ý: `google_sign_in` 7.x đã bỏ `signIn()` của 6.x. Luồng mới là
/// `initialize()` một lần rồi `authenticate()`, và token trả về chỉ còn
/// `idToken` — đủ để dựng credential cho Firebase.
class AuthService {
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
    await _googleSignIn.initialize();
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
      if (e.code == GoogleSignInExceptionCode.canceled) return null;
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
