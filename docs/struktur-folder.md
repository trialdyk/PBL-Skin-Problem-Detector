# Struktur Folder

```
PBL-Skin-Problem-Detector/
├── mobile/                           # Aplikasi Flutter
│   ├── lib/
│   │   ├── main.dart                 # Entry point + DI + root widget
│   │   ├── app_router.dart           # Konfigurasi go_router + guard auth
│   │   ├── core/                     # Konfigurasi aplikasi (API base URL, OAuth)
│   │   ├── business/
│   │   │   ├── bloc/                 # (placeholder — default pakai Cubit)
│   │   │   └── cubit/                # State management
│   │   ├── data/
│   │   │   ├── models/               # Model data + skala GEA
│   │   │   ├── repositories/         # Pemilik state sesi & orkestrasi
│   │   │   └── services/             # Logika murni / akses platform / HTTP
│   │   │       ├── auth/             # 1 file ≈ 1 endpoint auth
│   │   │       └── scan/             # Contoh endpoint protected
│   │   └── presentation/
│   │       ├── screens/              # Layar (halaman)
│   │       ├── widgets/              # Widget yang dipakai ulang
│   │       └── theme/                # Token warna, tema, font
│   ├── test/                         # Widget test
│   ├── assets/images/                # Gambar & logo
│   ├── tools/                        # Script bantu (olah SVG logo)
│   ├── android/ ios/ web/ windows/ linux/ macos/   # Folder platform (generated)
│   └── pubspec.yaml                  # Dependensi & metadata
├── backend/                          # API server (FastAPI + PostgreSQL)
├── machine-learning/                 # Dataset, training, dan model
├── model-comparator/                 # Web pembanding model IGA0–IGA4
└── docs/                             # Dokumentasi (folder ini)
```

Bagian di bawah ini menjelaskan isi `mobile/`; path yang disebut relatif
terhadap folder tersebut.

## `lib/` — File Inti

| File | Tanggung jawab |
|---|---|
| `main.dart` | Membuat repository & Cubit, `MultiBlocProvider`, `ShadcnApp.router` |
| `app_router.dart` | `GoRouter`, daftar route, redirect guard, `_AuthRefresh` |
| `core/api_config.dart` | `ApiConfig.baseUrl` + `googleServerClientId`; bisa di-override lewat `--dart-define` |

## `lib/business/cubit/`

| File | Isi |
|---|---|
| `auth_cubit.dart` | `AuthCubit` — login, login Google, logout, toggle S&K |
| `auth_state.dart` | `AuthState` + enum `AuthStatus` |
| `scan_cubit.dart` | `ScanCubit` — seluruh alur scan (foto → interview → diagnosa) |
| `scan_state.dart` | `ScanState`, enum `ScanPhase`, model `ChatMessage` |
| `home_cubit.dart` | `HomeCubit` — ganti tab beranda |
| `home_state.dart` | `HomeState` — `tabIndex` |

## `lib/data/models/`

| File | Isi |
|---|---|
| `gea_scale.dart` | `GeaScale` (tabel grade 0–5) + `GeaGradeInfo` |
| `gea_result.dart` | `GeaResult` — hasil akhir (grade, label ID/EN, deskripsi) |
| `interview_answers.dart` | `InterviewAnswers` + enum `GenderOption`, `SkinTypeOption` |
| `scan_session.dart` | `ScanSession` (3 path foto, interview, hasil) + enum `SelfieAngle` |
| `user_model.dart` | `UserModel` — `email`, `fullName`, `accessToken` + `fromAuthJson` |
| `article_item.dart` | `ArticleItem` — data artikel edukasi di beranda |

## `lib/data/repositories/`

| File | Isi |
|---|---|
| `auth_repository.dart` | Menyimpan `_currentUser`, meneruskan ke `AuthService`, membuka `api` (token Bearer) |
| `scan_repository.dart` | Menyimpan `_session`, mengatur foto/interview, memanggil diagnosa |

## `lib/data/services/`

| File | Isi |
|---|---|
| `api_client.dart` | `http.Client` bersama + header `Authorization: Bearer` saat `auth: true` |
| `gea_diagnosis_service.dart` | Hitung grade GEA (rule-based) |
| `face_scan_analyzer.dart` | ML Kit: deteksi wajah, cek cahaya & sudut |
| `image_pick_service.dart` | Ambil gambar dari kamera/galeri (`image_picker`) |

### `lib/data/services/auth/`

Satu file ≈ satu endpoint; detail pola ada di
[fetching_api.md](fetching_api.md).

| File | Isi |
|---|---|
| `auth.dart` | Barrel export domain auth |
| `auth_service.dart` | Facade: consent check, panggil endpoint, simpan token |
| `auth_login.dart` | `POST /auth/login` |
| `auth_register.dart` | `POST /auth/register` (layar registrasi belum ada) |
| `auth_google.dart` | `GoogleSignIn` → `POST /auth/google` |
| `auth_exception.dart` | `AuthException` (pesan siap tampil) |

### `lib/data/services/scan/`

Contoh domain endpoint **protected**; belum dipanggil layar mana pun.

| File | Isi |
|---|---|
| `scan.dart` | Barrel export domain scan |
| `scan_service.dart` | Facade `ScanService` |
| `scan_status.dart` | `GET /users/status` dengan `auth: true` |

## `lib/presentation/screens/`

| File | Layar | Route |
|---|---|---|
| `splash_screen.dart` | Splash | `/splash` |
| `welcome_screen.dart` | Sambutan | `/welcome` |
| `login_screen.dart` | Login | `/login` |
| `terms_screen.dart` | Syarat & Ketentuan | `/terms` |
| `privacy_screen.dart` | Kebijakan Privasi | `/privacy` |
| `home_screen.dart` | Beranda (3 tab: Home/Artikel/Profil) | `/home` |
| `articles_screen.dart` | Daftar artikel (tab) | — |
| `article_detail_screen.dart` | Detail artikel | `/articles/detail` |
| `scan_photo_screen.dart` | Hub foto 3 sudut | `/scan` |
| `scan_capture_screen.dart` | Kamera langsung | `/scan/capture` |
| `scan_upload_screen.dart` | Unggah dari galeri | `/scan/upload` |
| `scan_confirm_screen.dart` | Konfirmasi foto | `/scan/confirm` |
| `interview_screen.dart` | Interview chat | `/scan/interview` |
| `diagnosis_screen.dart` | Hasil GEA | `/scan/result` |

## `lib/presentation/widgets/`

| File | Isi |
|---|---|
| `app_widgets.dart` | `IconTile`, `TapCard`, `SectionHeader`, `AppTextLink`, `AppButton`, `AppHeader`, `showHint`, `showComingSoon` |
| `app_bottom_nav.dart` | `AppBottomNav`, `NavIndex`, `handleBottomNavTap` |
| `chat_bubbles.dart` | `ChatBubbleBot`, `ChatBubbleUser`, `ChatTypingBubble`, `InterviewStepProgress` |
| `dermascan_brand_logo.dart` | Logo brand (aset/SVG) |
| `gea_result_badge.dart` | Badge besar hasil GEA |
| `gea_scale_bar.dart` | Bar skala 0–5 |
| `google_logo.dart` | Logo Google (SVG) |
| `selfie_angle_progress.dart` | Indikator 3 sudut (layar kamera) |
| `selfie_slot.dart` | Slot unggah foto per sudut |
| `spotlight_coach.dart` | Sorotan/panduan pada layar kamera |

## `lib/presentation/theme/`

| File | Isi |
|---|---|
| `app_colors.dart` | Palet brand + `gradeColor`/`onGrade`/`dangerSurface`/`dangerInk` |
| `app_theme.dart` | `ThemeData` shadcn + `ColorScheme` |
| `app_font.dart` | Helper `appFont(...)` (Plus Jakarta Sans) |

## `test/`

| File | Isi |
|---|---|
| `widget_test.dart` | Splash → login lewat tombol Mulai; welcome bebas overflow di 6 ukuran layar |
| `login_screen_test.dart` | Tata letak login, panel/bubble galat, skala teks & kontras |

## `tools/`

Script Python sekali pakai untuk mengolah aset SVG logo
(`extract_mark_svg.py`, `inspect_logo_svg.py`, `strip_tagline_svg.py`). Bukan
bagian dari build aplikasi.

## Catatan

- `business/bloc/` hanya berisi `.gitkeep` — proyek memakai **Cubit**, bukan
  Bloc penuh, tetapi folder disiapkan untuk ekspansi.
- Folder platform (`android/`, `ios/`, dst.) adalah hasil `flutter create` dan
  jarang diubah manual.
- Jangan menaruh URL backend di layar/service: pakai `core/api_config.dart`.
