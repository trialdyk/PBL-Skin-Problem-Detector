# Struktur Folder

```
PBL-Skin-Problem-Detector/
├── mobile/                           # Aplikasi Flutter
│   ├── lib/
│   │   ├── main.dart                 # Entry point + DI + root widget
│   │   ├── app_router.dart           # Konfigurasi go_router + guard auth
│   │   ├── business/
│   │   │   ├── bloc/                 # (placeholder — default pakai Cubit)
│   │   │   └── cubit/                # State management
│   │   ├── data/
│   │   │   ├── models/               # Model data + skala GEA
│   │   │   ├── repositories/         # Pemilik state sesi & orkestrasi
│   │   │   └── services/             # Logika murni / akses platform
│   │   └── presentation/
│   │       ├── screens/              # Layar (halaman)
│   │       ├── widgets/              # Widget yang dipakai ulang
│   │       └── theme/                # Token warna, tema, font
│   ├── test/
│   │   └── widget_test.dart          # Test render splash
│   ├── assets/                       # Gambar & logo
│   ├── tools/                        # Script bantu (olah SVG logo)
│   ├── android/ ios/ web/ windows/ linux/ macos/   # Folder platform (generated)
│   └── pubspec.yaml                  # Dependensi & metadata
├── backend/                          # API server (FastAPI + PostgreSQL)
├── machine-learning/                 # Dataset, training, dan model
└── docs/                             # Dokumentasi (folder ini)
```

Bagian di bawah ini menjelaskan isi `mobile/`; path yang disebut relatif
terhadap folder tersebut.

## `lib/` — File Inti

| File | Tanggung jawab |
|---|---|
| `main.dart` | Membuat repository & Cubit, `MultiBlocProvider`, `ShadcnApp.router` |
| `app_router.dart` | `GoRouter`, daftar route, redirect guard, `_AuthRefresh` |

## `lib/business/cubit/`

| File | Isi |
|---|---|
| `auth_cubit.dart` | `AuthCubit` — login, logout, toggle S&K |
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
| `user_model.dart` | `UserModel` — hanya `email` (mock) |

## `lib/data/repositories/`

| File | Isi |
|---|---|
| `auth_repository.dart` | Menyimpan `_currentUser`, meneruskan ke `AuthService` |
| `scan_repository.dart` | Menyimpan `_session`, mengatur foto/interview, memanggil diagnosa |

## `lib/data/services/`

| File | Isi |
|---|---|
| `auth_service.dart` | Login mock + `AuthException` |
| `gea_diagnosis_service.dart` | Hitung grade GEA (rule-based) |
| `face_scan_analyzer.dart` | ML Kit: deteksi wajah, cek cahaya & sudut |
| `image_pick_service.dart` | Ambil gambar dari kamera/galeri (`image_picker`) |

## `lib/presentation/screens/`

| File | Layar | Route |
|---|---|---|
| `splash_screen.dart` | Splash | `/splash` |
| `welcome_screen.dart` | Sambutan | `/welcome` |
| `login_screen.dart` | Login | `/login` |
| `home_screen.dart` | Beranda (3 tab: Home/Artikel/Profil) | `/home` |
| `articles_screen.dart` | Daftar artikel (tab) | — |
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
| `gea_result_badge.dart` | Badge besar hasil GEA |
| `gea_scale_bar.dart` | Bar skala 0–5 |
| `google_logo.dart` | Logo Google (SVG) |
| `selfie_angle_progress.dart` | Indikator 3 sudut (layar kamera) |
| `selfie_slot.dart` | Slot unggah foto per sudut |

## `lib/presentation/theme/`

| File | Isi |
|---|---|
| `app_colors.dart` | Palet brand + `gradeColor`/`onGrade`/`dangerSurface`/`dangerInk` |
| `app_theme.dart` | `ThemeData` shadcn + `ColorScheme` |
| `app_font.dart` | Helper `appFont(...)` (Plus Jakarta Sans) |

## Catatan

- `business/bloc/` hanya berisi `.gitkeep` — proyek memakai **Cubit**, bukan
  Bloc penuh, tetapi folder disiapkan untuk ekspansi.
- Folder platform (`android/`, `ios/`, dst.) adalah hasil `flutter create` dan
  jarang diubah manual.
