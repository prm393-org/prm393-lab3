# Journal Trend Analyzer — PRM393 Lab 03

Ứng dụng Flutter phân tích xu hướng công bố khoa học, lấy dữ liệu từ [OpenAlex API](https://api.openalex.org) và tích hợp các dịch vụ Firebase (Authentication, Storage, Cloud Messaging, Analytics, Crashlytics, Remote Config).

Đây là bản mở rộng của Lab 02: giữ nguyên OpenAlex làm nguồn dữ liệu công bố, bổ sung nền tảng cloud, kiểm thử end-to-end bằng Patrol và quy trình AI-assisted code review.

> **Trạng thái:** Phần OpenAlex (search topic, danh sách/chi tiết publication, biểu đồ xu hướng, dashboard) đã chạy. Phần Firebase, Patrol và màn hình Login đang trong lộ trình triển khai — xem [Tiến độ](#tiến-độ-so-với-đề-bài).

---

## Tính năng

| Nhóm | Mô tả |
|------|-------|
| **Authentication** | Đăng nhập Google qua Firebase Auth, xem thông tin tài khoản, đăng xuất |
| **Home** | Tìm kiếm theo topic; dashboard tổng quan: tổng số publication, trung bình citation, năm sôi động nhất, tác giả/journal/paper nổi bật; biểu đồ xu hướng theo năm |
| **Publication Detail** | Title, authors, năm, journal, citation count, DOI, abstract, link tới bài gốc |
| **Journals** | Xếp hạng journal theo số publication, thống kê citation, biểu đồ đóng góp; vào chi tiết từng journal |
| **Keywords** | Keyword phổ biến/đang trending, thống kê tần suất, biểu đồ; chi tiết keyword kèm bảng xếp hạng tác giả |
| **Profile** | Thông tin user, Notification Center (FCM), export PDF lên Firebase Storage, demo Remote Config, demo Crashlytics |

---

## Yêu cầu môi trường

- Flutter SDK (Dart `^3.11.5`)
- Android device hoặc emulator
- Tài khoản Firebase + project đã tạo
- (Tuỳ chọn) OpenAlex API key — [đăng ký miễn phí](https://openalex.org/settings/api)

## Cài đặt

```bash
flutter pub get
cp .env.example .env
```

Điền `.env`:

```dotenv
OPENALEX_API_KEY=          # có thể để trống
OPENALEX_MAILTO=email@cua.ban   # để vào "polite pool" của OpenAlex
```

`.env` được nạp trong `main.dart` trước `runApp` qua `flutter_dotenv`, và được khai báo là asset trong `pubspec.yaml`. **Không commit `.env`.**

### Cấu hình Firebase

```bash
dart pub global activate flutterfire_cli
flutterfire configure
```

Lệnh trên sinh `lib/firebase_options.dart` và `android/app/google-services.json`. Sau đó bật trong Firebase Console: Authentication (Google provider), Storage, Cloud Messaging, Analytics, Crashlytics, Remote Config.

Remote Config cần ít nhất hai tham số:

| Key | Kiểu | Ý nghĩa |
|-----|------|---------|
| `max_journals_displayed` | number | Số journal tối đa hiển thị |
| `max_keywords_displayed` | number | Số keyword tối đa hiển thị |

## Chạy và kiểm thử

```bash
flutter run                               # chạy trên device/emulator
flutter analyze                           # lint (flutter_lints)
flutter test                              # unit + widget test
flutter test test/path/to/foo_test.dart   # một file test
flutter build apk                         # build APK
```

E2E với Patrol:

```bash
dart pub global activate patrol_cli
patrol test                                    # toàn bộ
patrol test --target patrol_tests/authentication_test.dart
```

---

## Kiến trúc

Đề bài yêu cầu **MVVM** với bốn lớp tách bạch: Models, Services, ViewModels, Views. Repo hiện dùng Clean Architecture tổ chức theo feature — tương thích với MVVM, chỉ khác tên gọi:

| MVVM (đề bài) | Trong repo này |
|---------------|----------------|
| Model | `domain/entities/` + `data/models/` |
| Service | `data/datasources/` + `core/network/api_client.dart` |
| ViewModel | `presentation/cubit/` (flutter_bloc Cubit) |
| View | `presentation/pages/` + `presentation/widgets/` |

Business logic nằm trong Cubit và use case, không nằm trong widget.

```
lib/
├── core/
│   ├── config/        AppConfig — đọc biến môi trường
│   ├── constants/     Endpoint, timeout, key SharedPrefs
│   ├── di/            GetIt service locator
│   ├── error/         Failure (domain) + Exception (data)
│   ├── navigation/    MainScaffold — BottomNavigationBar 4 tab
│   ├── network/       ApiClient (Dio), NetworkInfo
│   ├── router/        go_router, StatefulShellRoute
│   ├── theme/         Màu, typography, ThemeData
│   ├── usecase/       UseCase<T, Params> base class
│   ├── utils/         AbstractDecoder, NumberFormatter
│   └── widgets/       Loading / Error / Empty state
└── features/
    ├── home/          Tìm kiếm & khám phá topic
    ├── journal/       Danh sách journal + chi tiết publication
    ├── keywords/      Research dashboard, phân tích keyword
    ├── profile/       Cài đặt, tài khoản, demo Firebase
    ├── publication/   Model/repo/use case dùng chung cho Work
    └── shared/        SelectedTopicCubit, PendingSearchCubit
```

Mỗi feature chia ba lớp:

```
feature/
├── data/         datasource, model JSON, repository implementation
├── domain/       entity, repository interface, use case (pure Dart)
└── presentation/ cubit, page, widget
```

**Luồng dữ liệu:**

```
Page → Cubit → UseCase → Repository (interface) → RepositoryImpl → DataSource → ApiClient (Dio) → OpenAlex
```

**Xử lý lỗi:** datasource ném `*Exception` → repository bắt và trả `Either<Failure, T>` (dartz) → cubit map sang state loading / success / error.

**Điều hướng:** `StatefulShellRoute.indexedStack` với 4 branch (`/home`, `/journal`, `/keywords`, `/profile`), mỗi tab giữ nguyên state khi chuyển. Chi tiết publication nằm ở `/journal/detail/:workId`.

---

## Thư viện chính

| Mục đích | Package |
|----------|---------|
| State management | `flutter_bloc`, `equatable` |
| Dependency injection | `get_it` |
| HTTP | `dio` |
| Routing | `go_router` |
| Functional error handling | `dartz` |
| Biểu đồ | `fl_chart` |
| Local storage | `shared_preferences` |
| Cấu hình runtime | `flutter_dotenv` |
| Mở link ngoài | `url_launcher` |
| Kiểm tra mạng | `connectivity_plus` |

Firebase (`firebase_core`, `firebase_auth`, `google_sign_in`, `firebase_storage`, `firebase_messaging`, `firebase_analytics`, `firebase_crashlytics`, `firebase_remote_config`), `pdf`/`printing` cho export, và `patrol` cho E2E sẽ được thêm khi triển khai phần Firebase.

---

## Firebase Analytics events

Đề bài yêu cầu log đủ 7 event sau (kèm parameter khi có):

| Event | Parameters | Khi nào |
|-------|-----------|---------|
| `login` | — | Đăng nhập thành công |
| `search_topic` | `keyword` | User tìm một topic |
| `view_publication` | `publication_title`, `publication_year` | Mở trang chi tiết publication |
| `view_journal` | `journal_name` | Mở trang chi tiết journal |
| `view_keyword` | `keyword` | Mở trang chi tiết keyword |
| `export_pdf` | `topic` | Export và upload PDF report |
| `logout` | — | Đăng xuất |

Bằng chứng event đã ghi nhận (DebugView / Events dashboard) phải đưa vào report.

---

## OpenAlex API

Base URL `https://api.openalex.org`, entity chính là `/works`. `ApiClient` tự gắn `api_key` và `mailto` từ `.env`.

```bash
# Tìm publication theo topic, sắp theo citation
curl "https://api.openalex.org/works?search=machine+learning&sort=cited_by_count:desc&per_page=25"

# Aggregate số publication theo năm
curl "https://api.openalex.org/works?search=blockchain&group_by=publication_year"
```

Hai lưu ý khi đọc response:

- **Abstract** trả về dạng `abstract_inverted_index`, cần ghép lại — xem `core/utils/abstract_decoder.dart`.
- **Dehydrated objects:** nhiều nested object chỉ có `id` và `display_name`; trang chi tiết nên fetch full work theo ID.

Tài liệu: [Introduction](https://developers.openalex.org/api-reference/introduction) · [Filtering](https://developers.openalex.org/guides/filtering) · [Searching](https://developers.openalex.org/guides/searching) · [Grouping](https://developers.openalex.org/guides/grouping)

---

## Tiến độ so với đề bài

| Hạng mục | Trạng thái |
|----------|-----------|
| Home: search topic, trend chart, dashboard KPI | ✅ |
| Publication detail (abstract decode, DOI, link) | ✅ |
| Journals list + filter | ✅ |
| Research dashboard (keyword, ranking, scatter) | ✅ |
| Bottom navigation 4 tab | ✅ |
| Profile (settings cục bộ) | ✅ |
| Journal Detail screen | ⬜ |
| Keyword Detail screen (+ author ranking) | ⬜ |
| Login screen + Google Sign-In | ⬜ |
| Firebase: Storage, FCM, Analytics, Crashlytics, Remote Config | ⬜ |
| PDF export + upload | ⬜ |
| Patrol E2E (11 test case) | ⬜ |
| AI-assisted code review (≥ 3 findings) | ⬜ |

Phân tích chi tiết yêu cầu, mapping FR → màn hình và lộ trình triển khai: [LAB3_PHAN_TICH_DE_BAI.md](LAB3_PHAN_TICH_DE_BAI.md).

---

## Deliverables

- **Source code:** GitHub repo tên `PRM393_Lab03_StudentID`, gồm source, file cấu hình Firebase, Patrol test scripts, assets.
- **Project report:** PDF 5–10 trang — overview, kiến trúc, MVVM, thiết kế tích hợp Firebase, screenshot tính năng, Analytics events, Crashlytics report, Remote Config, kết quả Patrol, findings từ AI code review, khó khăn, bài học.
- **Demo video:** 5–10 phút — Google Sign-In, search topic, publication detail, journal/keyword/author analysis, PDF export + upload, push notification, Remote Config, Crashlytics, Patrol test, AI code review.

## Thang điểm

| Tiêu chí | Trọng số |
|----------|---------|
| Functional Requirements | 30% |
| Firebase Integration & Analytics | 25% |
| Patrol Automated Testing | 15% |
| Architecture (MVVM + Provider/Riverpod) | 10% |
| UI/UX and Application Quality | 10% |
| AI-Assisted Code Review | 5% |
| Report and Demonstration | 5% |
