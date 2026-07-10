import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';

/// Bọc Firebase Remote Config (FR 4.8 — khối "Remote Config Demo").
///
/// Hai tham số dưới đây phải được tạo **và Publish** trên console; nếu chưa,
/// app rơi về [_defaults] chứ không lỗi.
class RemoteConfigService {
  RemoteConfigService({FirebaseRemoteConfig? remoteConfig})
      : _remoteConfig = remoteConfig ?? FirebaseRemoteConfig.instance;

  static const keyMaxJournals = 'max_journals_displayed';
  static const keyMaxKeywords = 'max_keywords_displayed';

  static const Map<String, Object> _defaults = {
    keyMaxJournals: 10,
    keyMaxKeywords: 15,
  };

  final FirebaseRemoteConfig _remoteConfig;

  /// Chỉ await phần cục bộ (defaults + settings) để app mở được ngay.
  /// [refresh] chạy nền: nếu mạng chậm, UI vẫn có giá trị default để hiển thị
  /// thay vì treo màn hình trắng tới 10 giây.
  Future<void> init() async {
    await _remoteConfig.setDefaults(_defaults);
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        // Mặc định 12 tiếng — trong lúc demo sẽ tưởng config không đổi.
        minimumFetchInterval: const Duration(minutes: 1),
      ),
    );
    unawaited(refresh());
  }

  /// Nuốt lỗi có chủ đích: mất mạng thì dùng giá trị đã cache / default,
  /// không được để màn Profile chết vì fetch config thất bại.
  Future<bool> refresh() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (_) {
      return false;
    }
  }

  int get maxJournalsDisplayed => _remoteConfig.getInt(keyMaxJournals);

  int get maxKeywordsDisplayed => _remoteConfig.getInt(keyMaxKeywords);
}
