import 'dart:typed_data';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';

/// Bọc Firebase Storage (FR 4.8 — khối "Report Export").
///
/// Mọi file nằm dưới `reports/{uid}/` để Security Rules chặn được chéo user.
class StorageService {
  StorageService({FirebaseStorage? storage, FirebaseAuth? auth})
      : _storage = storage ?? FirebaseStorage.instance,
        _auth = auth ?? FirebaseAuth.instance;

  final FirebaseStorage _storage;
  final FirebaseAuth _auth;

  /// Upload PDF report và trả về download URL để hiển thị trên màn Profile.
  ///
  /// Ném [StateError] nếu chưa đăng nhập — rules sẽ từ chối, nên chặn sớm
  /// ở đây cho thông báo dễ hiểu hơn `permission-denied`.
  Future<String> uploadReportPdf({
    required Uint8List bytes,
    required String topic,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      throw StateError('Phải đăng nhập trước khi upload report.');
    }

    final safeTopic = _slugify(topic);
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final ref = _storage.ref('reports/$uid/${safeTopic}_$stamp.pdf');

    await ref.putData(
      bytes,
      SettableMetadata(contentType: 'application/pdf'),
    );
    return ref.getDownloadURL();
  }

  /// Danh sách report đã upload của user hiện tại (mới nhất trước).
  Future<List<Reference>> listMyReports() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const [];
    final result = await _storage.ref('reports/$uid').listAll();
    return result.items.reversed.toList();
  }

  Future<void> delete(Reference ref) => ref.delete();

  static String _slugify(String input) {
    final slug = input
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
        .replaceAll(RegExp(r'^_+|_+$'), '');
    return slug.isEmpty ? 'report' : slug;
  }
}
