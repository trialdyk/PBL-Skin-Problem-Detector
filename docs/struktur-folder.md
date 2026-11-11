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
│   │   │       ├── ml/               # 1 file ≈ 1 endpoint ML (prediksi CNN)
│   │   │       └── scan/             # Contoh endpoint protected
│   │   └── presentation/
│   │       ├── screens/              # Layar (halaman)
│   │       ├── widgets/              # Widget yang dipakai ulang
│   │       └── theme/                # Token warna, tema, font
│   ├── test/                         # Widget test
│   ├── assets/images/                # Gambar & logo
│   ├── assets/audio/                 # Efek suara (tick countdown, rana)
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
| `gea_result.dart` | `GeaResult` — hasil akhir (grade, label ID/EN, deskripsi, `source`) |
| `result_source.dart` | `ResultSource` — asal hasil: `ml` (CNN) atau `ruleBased` (interview) |
| `interview_answers.dart` | `InterviewAnswers` + enum `GenderOption`, `SkinTypeOption` |
| `scan_session.dart` | `ScanSession` (3 path foto, interview, hasil) + enum `SelfieAngle` |
| `user_model.dart` | `UserModel` — `email`, `fullName`, `accessToken` + `fromAuthJson` |
| `article_item.dart` | `ArticleItem` — data artikel edukasi di beranda |

## `lib/data/repositories/`

| File | Isi |
|---|---|
| `auth_repository.dart` | Menyimpan `_currentUser`, meneruskan ke `AuthService`, membuka `api` (token Bearer) |
| `scan_repository.dart` | Menyimpan `_session`, mengatur foto/interview, diagnosa CNN → fallback rule-based |

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

### `lib/data/services/ml/`

Domain inferensi; dipanggil `ScanRepository` saat diagnosa.

| File | Isi |
|---|---|
| `ml.dart` | Barrel export domain ML |
| `ml_predict.dart` | `POST /ml/predict` (multipart 1–3 foto) + interface `MlPredictor` |
| `ml_prediction.dart` | `MlPrediction` — grade GEA, `top_label`, model, probabilitas |
| `ml_exception.dart` | `MlException` (untuk log; repo langsung fallback) |

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

## `lib/presentation/audio/`

Efek suara pendek untuk umpan balik UI. Ditaruh di layer presentation (bukan
`data/services/`) karena bukan akses data, dan dipakai langsung oleh layar.

| File | Isi |
|---|---|
| `app_sound_player.dart` | `AppSoundPlayer` (interface) + `AssetSoundPlayer` (MP3 di `assets/audio/`) |

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
| `ml_predict_test.dart` | `MlPredict`: multipart + Bearer, parsing grade, error 503/jaringan/body rusak |
| `scan_repository_test.dart` | CNN dipakai saat sukses; fallback rule-based saat gagal/tanpa foto |
| `app_sound_player_test.dart` | Aset audio termuat, guard galat, kontrak 3 tick + 1 shutter |

## `tools/`

Script Python sekali pakai untuk mengolah aset SVG logo
(`extract_mark_svg.py`, `inspect_logo_svg.py`, `strip_tagline_svg.py`). Bukan
bagian dari build aplikasi.

`tools/audio_src/` menyimpan **audio sumber asli** (tidak ikut dibundel, karena
hanya `assets/` yang masuk pubspec): `countdown_tick_3beeps.mp3` (satu file
berisi 3 dentuman + 0,6 s hening di awal) dan `shutter_source.mp3`. File di
`assets/audio/` adalah hasil potong dari sumber tersebut, dibuat dengan ffmpeg:

```
# tick: ambil dentuman pertama (0,610-0,700 s), buang hening awal, normalisasi
ffmpeg -i tools/audio_src/countdown_tick_3beeps.mp3 \
  -af "atrim=start=0.610:end=0.700,asetpts=PTS-STARTPTS,volume=8.9dB,afade=t=out:st=0.062:d=0.028" \
  -ac 1 -ar 44100 -c:a libmp3lame -b:a 96k assets/audio/countdown_tick.mp3

# shutter: buang 95 ms hening di awal, normalisasi
ffmpeg -i tools/audio_src/shutter_source.mp3 \
  -af "atrim=start=0.090:end=0.315,asetpts=PTS-STARTPTS,volume=4dB,afade=t=out:st=0.195:d=0.030" \
  -ac 1 -ar 44100 -c:a libmp3lame -b:a 96k assets/audio/shutter.mp3
```

Spesifikasi akhir `assets/audio/`: MP3 mono 44,1 kHz 96 kbps, tanpa leading
silence (`countdown_tick` 90 ms, `shutter` 225 ms), peak ≈ −4 dBFS. Leading
silence wajib nol — itulah penyebab utama bunyi terasa telat.

## Catatan

- `business/bloc/` hanya berisi `.gitkeep` — proyek memakai **Cubit**, bukan
  Bloc penuh, tetapi folder disiapkan untuk ekspansi.
- Folder platform (`android/`, `ios/`, dst.) adalah hasil `flutter create` dan
  jarang diubah manual.
- Jangan menaruh URL backend di layar/service: pakai `core/api_config.dart`.
