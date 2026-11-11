# Arsitektur

Aplikasi memakai pola **berlapis (layered)** dengan pemisahan tegas antara
data, logika bisnis, dan tampilan. Arah dependensi selalu dari luar ke dalam:

```
presentation  →  business  →  data
   (UI)          (Cubit)      (models, repositories, services)
```

Lapisan UI tidak pernah memanggil *service* secara langsung; ia selalu lewat
Cubit.

## Diagram Lapisan

```mermaid
flowchart TD
    subgraph P["presentation/ — UI"]
        S["screens/*"]
        W["widgets/*"]
        T["theme/*"]
    end
    subgraph B["business/ — logika UI"]
        C["cubit/*  (Cubit + State)"]
    end
    subgraph D["data/ — sumber data"]
        M["models/*"]
        R["repositories/*"]
        SV["services/*"]
    end

    S --> C
    W --> T
    S --> W
    C --> R
    R --> SV
    R --> M
    SV --> M
```

## Titik Masuk & Dependency Injection

`lib/main.dart` melakukan **DI manual** (tanpa `get_it`/`provider` paket lain):
repository dibuat sekali di `initState`, lalu Cubit di-*provide* ke seluruh
widget lewat `MultiBlocProvider`.

```dart
// main.dart (ringkas)
_authRepository = AuthRepository(AuthService());
_scanRepository = ScanRepository(
  GeaDiagnosisService(),
  mlPredict: MlPredict(_authRepository.api), // ApiClient yang sama → Bearer ikut
);
_authCubit      = AuthCubit(_authRepository);
_scanCubit      = ScanCubit(_scanRepository);
_router         = createRouter(_authCubit);
```

`AuthCubit` dan `ScanCubit` berumur **sepanjang aplikasi** (lifecycle widget
root) dan di-`close()` di `dispose`. `HomeCubit` berbeda: dibuat per-route di
`/home` karena hanya mengatur tab lokal.

Aplikasi di-*render* lewat `ShadcnApp.router` dengan `themeMode: ThemeMode.light`
dan `routerConfig: _router`.

## State Management — Cubit

Tiga Cubit, masing-masing dengan State `Equatable`-nya:

| Cubit | State | Tanggung jawab | Umur |
|---|---|---|---|
| `AuthCubit` | `AuthState` | Login/logout, status sesi, centang S&K | App-wide |
| `ScanCubit` | `ScanState` | Seluruh alur scan: foto → interview → hasil | App-wide |
| `HomeCubit` | `HomeState` | Tab aktif di beranda | Per-route `/home` |

**Pola umum setiap state:** field `copyWith(...)` dengan flag `clearError` /
`clearUser` / `clearPhotos` untuk membedakan "tidak diubah" dari "di-set null".
Semua state `extends Equatable` agar rebuild hanya terjadi saat nilai berubah.

`ScanCubit` menyimpan satu field non-state: `leftYawSign` (tanda yaw saat foto
sisi kiri diambil) — dipakai lintas layar kamera untuk memvalidasi sisi kanan.

### Fase alur scan (`ScanPhase`)

`ScanState.phase` adalah mesin status alur scan:

```
intro → capturing → confirming → interviewing → diagnosing → result
                └→ uploading → confirming
```

| Fase | Arti |
|---|---|
| `intro` | Belum mulai / kembali ke hub foto |
| `capturing` | Mengambil foto via kamera langsung |
| `uploading` | Mengunggah foto dari galeri |
| `confirming` | 3 foto siap, menunggu konfirmasi |
| `interviewing` | Sedang menjawab 5 pertanyaan chat |
| `diagnosing` | Sedang menghitung hasil (mock delay) |
| `result` | Hasil GEA tersedia |

## Routing — go_router

`lib/app_router.dart` membuat `GoRouter` dengan **redirect guard** berbasis
`AuthCubit`.

```mermaid
flowchart LR
    A["Akses route"] --> B{"Login?"}
    B -- "Tidak" --> C{"Route publik?"}
    C -- "Ya" --> D["Izinkan"]
    C -- "Tidak" --> E["→ /splash"]
    B -- "Ya" --> F{"Route publik?"}
    F -- "Ya" --> G["→ /home"]
    F -- "Tidak" --> D
```

- **Route publik:** `/splash`, `/welcome`, `/login`, `/terms`, `/privacy`.
- Router mendengarkan perubahan auth via `_AuthRefresh` (sebuah
  `ChangeNotifier` yang men-subscribe stream `AuthCubit`), sehingga login/logout
  otomatis memicu evaluasi ulang redirect.

| Path | Layar | Catatan |
|---|---|---|
| `/splash` | `SplashScreen` | Auto ke `/welcome` setelah 1,8 detik |
| `/welcome` | `WelcomeScreen` | |
| `/login` | `LoginScreen` | |
| `/home` | `HomeScreen` | Dibungkus `HomeCubit` |
| `/scan` | `ScanPhotoScreen` | Hub foto 3 sudut |
| `/scan/capture` | `ScanCaptureScreen` | Query `angle=front\|left\|right` |
| `/scan/upload` | `ScanUploadScreen` | |
| `/scan/confirm` | `ScanConfirmScreen` | |
| `/scan/interview` | `InterviewScreen` | |
| `/scan/result` | `DiagnosisScreen` | |

`ScanCaptureScreen` menerima sudut target lewat query string; bila `angle`
kosong, layar berjalan mode "3 sudut berurutan".

## Alur Data (contoh: membuat diagnosa)

```mermaid
sequenceDiagram
    participant U as UI (InterviewScreen)
    participant C as ScanCubit
    participant R as ScanRepository
    participant P as MlPredict (POST /ml/predict)
    participant S as GeaDiagnosisService
    participant M as GeaScale

    U->>C: answerSkinType(oily)
    C->>R: setInterview(updated)
    C-->>U: emit(state + pesan user)
    Note over C: setelah pertanyaan ke-5
    C->>C: _runDiagnosis()
    C->>R: diagnose()
    R->>P: call(photoPaths) — 1–3 foto, Bearer JWT
    alt CNN berhasil
        P-->>R: MlPrediction (grade GEA)
        R->>M: GeaResult.fromGrade(grade, source: ml)
    else gagal / tanpa foto
        R->>S: diagnose(answers)
        S->>M: GeaResult.fromGrade(grade)
        S-->>R: GeaResult (source: ruleBased)
    end
    R-->>C: GeaResult
    C-->>U: emit(phase = result)
```

## Repository & Service

- **Repository** = pemilik state sesi (in-memory) + orkestrasi service.
  - `AuthRepository`: menyimpan `_currentUser`, meneruskan login ke `AuthService`.
  - `ScanRepository`: menyimpan `_session` (`ScanSession`), mengatur foto,
    interview, lalu diagnosa: `POST /ml/predict` (CNN) → fallback rule-based
    bila gagal/tanpa foto.
- **Service** = logika murni, akses platform, atau akses jaringan — tanpa
  menyimpan state aplikasi.
  - `api_client.dart` — satu `http.Client` bersama; menambahkan header
    `Authorization: Bearer <token>` saat dipanggil dengan `auth: true`. Base URL
    berasal dari `core/api_config.dart`.
  - `auth/` — satu file per endpoint: `auth_login.dart` (`POST /auth/login`),
    `auth_register.dart` (`POST /auth/register`), `auth_google.dart`
    (`GoogleSignIn` → `POST /auth/google`). `auth_service.dart` adalah facade
    yang menyimpan token hasil login ke `ApiClient`; `auth_exception.dart`
    memuat `AuthException`.
  - `ml/` — `ml_predict.dart` (`POST /ml/predict`, multipart 1–3 foto, butuh
    `auth: true`), `ml_prediction.dart` (`MlPrediction`), `ml_exception.dart`.
    Dipanggil `ScanRepository` saat diagnosa.
  - `scan/` — contoh domain endpoint **protected** (`GET /users/status`) dan
    referensi pola `auth: true`. Belum dipanggil layar mana pun; lihat
    [fetching_api.md](fetching_api.md) §6.
  - `GeaDiagnosisService` — hitung grade GEA rule-based (**bukan** analisis
    citra); sekarang berperan sebagai fallback bila CNN gagal.
  - `FaceScanAnalyzer` — ML Kit: cahaya, keberadaan wajah, sudut.
  - `ImagePickService` — ambil gambar dari kamera/galeri.

## Tema

`lib/presentation/theme/` berisi token terpusat:

- `app_colors.dart` — palet brand (blush/crimson) + `gradeColor(0..5)` dan
  `onGrade(g)` untuk warna tingkat keparahan, serta `dangerSurface`/`dangerInk`
  untuk permukaan galat yang tetap terbaca.
- `app_theme.dart` — `ThemeData` shadcn (`ColorScheme` brand + tipografi).
- `app_font.dart` — helper `appFont(...)` untuk `TextStyle` manual
  (Plus Jakarta Sans, bobot eksplisit agar tidak faux-bold).

Detail warna & font ada di [panduan-pengembangan.md](panduan-pengembangan.md).
