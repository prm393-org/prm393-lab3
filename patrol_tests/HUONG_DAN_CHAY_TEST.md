# Hướng dẫn chạy Patrol E2E (11 test case)

Lab PRM393 — Journal Trend Analyzer. Suite nằm trong thư mục `patrol_tests/`.

## Kết quả gần nhất

| TC | Mô tả | File | Kết quả |
|----|--------|------|---------|
| **TC1** | Google Sign-In → Home | `authentication_test.dart` | ✅ Pass |
| **TC2** | Search topic → có kết quả | `publication_test.dart` | ✅ Pass |
| **TC3** | Mở publication detail | `publication_test.dart` | ✅ Pass |
| **TC4** | Tab Journals → list + KPI | `journal_test.dart` | ✅ Pass |
| **TC5** | Mở journal detail | `journal_test.dart` | ✅ Pass |
| **TC6** | Tab Keywords → list + KPI | `keyword_test.dart` | ✅ Pass |
| **TC7** | Mở keyword detail | `keyword_test.dart` | ✅ Pass |
| **TC8** | Profile hiện user đã login | `profile_test.dart` | ✅ Pass |
| **TC9** | Export PDF → có URL Storage | `export_test.dart` | ✅ Pass |
| **TC10** | Remote Config hiển thị | `remote_config_test.dart` | ✅ Pass |
| **TC11** | Sign out → Login | `authentication_test.dart` | ✅ Pass |

**Tổng: 11/11 pass**

---

## Điều kiện trước khi chạy

1. Emulator/device đang bật (`flutter devices`).
2. Đã cài Patrol CLI và có trong PATH.
3. Emulator đã login **Google account**.
4. Dung lượng `/data` đủ (khuyến nghị trống ≥ 2–3 GB).
5. **Stop** `flutter run` trước khi chạy Patrol (tránh xung đột APK).

---

## Lệnh chạy

### PowerShell

```powershell
cd D:\fpt\ky8\PRM393\prm393-lab3
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
```

Chạy tất cả:

```powershell
patrol test --device emulator-5554
```

Có nhiều Google account — chỉ định email:

```powershell
patrol test --device emulator-5554 --dart-define=PATROL_GOOGLE_EMAIL=you@gmail.com
```

### Git Bash

```bash
cd /d/fpt/ky8/PRM393/prm393-lab3
export PATH="$PATH:$LOCALAPPDATA/Pub/Cache/bin"
patrol test --device emulator-5554
```

Hoặc:

```bash
"$LOCALAPPDATA/Pub/Cache/bin/patrol.bat" test --device emulator-5554
```

---

## Chạy theo nhóm (PowerShell)

```powershell
# TC1 + TC11
patrol test --target patrol_tests/authentication_test.dart --device emulator-5554

# TC2 + TC3
patrol test --target patrol_tests/publication_test.dart --device emulator-5554

# TC4 + TC5
patrol test --target patrol_tests/journal_test.dart --device emulator-5554

# TC6 + TC7
patrol test --target patrol_tests/keyword_test.dart --device emulator-5554

# TC8
patrol test --target patrol_tests/profile_test.dart --device emulator-5554

# TC9
patrol test --target patrol_tests/export_test.dart --device emulator-5554

# TC10
patrol test --target patrol_tests/remote_config_test.dart --device emulator-5554
```

---

## Map file ↔ test case

```
patrol_tests/
├── helpers/patrol_helpers.dart   # login, search topic, đổi tab…
├── authentication_test.dart      # TC1, TC11
├── publication_test.dart         # TC2, TC3
├── journal_test.dart             # TC4, TC5
├── keyword_test.dart             # TC6, TC7
├── profile_test.dart             # TC8
├── export_test.dart              # TC9
└── remote_config_test.dart       # TC10
```

Selector: `lib/core/constants/widget_keys.dart`.

---

## Báo cáo

```
build/app/reports/androidTests/connected/debug/index.html
```

---

## Lỗi thường gặp

| Lỗi | Cách xử lý |
|-----|------------|
| `INSTALL_FAILED_INSUFFICIENT_STORAGE` | Tăng dung lượng AVD; `adb uninstall com.prm393.journal_trend_analyzer` |
| `patrol: command not found` | Thêm `%LOCALAPPDATA%\Pub\Cache\bin` vào PATH (PowerShell) hoặc `export PATH` (Git Bash) |
| Lệnh PowerShell fail trên Git Bash | Dùng cú pháp bash ở trên, không dùng `$env:Path` |
| Kẹt Login | Thêm Google account; `--dart-define=PATROL_GOOGLE_EMAIL=...` |
| OpenAlex 429 | Nghỉ 1–2 phút; chạy từng file; điền `OPENALEX_MAILTO` trong `.env` |
| Đang `flutter run` | Nhấn `q` quit rồi mới `patrol test` |
