# Panduan Instalasi & Menjalankan

## Prasyarat

| Kebutuhan | Versi minimum | Catatan |
|---|---|---|
| Flutter SDK | **3.47.0** | Diambil dari `pubspec.lock` (`flutter: ">=3.47.0"`) |
| Dart SDK | **3.13.2** | Dideklarasikan di `pubspec.yaml` (`sdk: ^3.13.2`) |
| Android SDK | API 21+ | `minSdk = maxOf(flutter.minSdkVersion, 21)` — syarat ML Kit |

Verifikasi instalasi:

```bash
flutter --version
flutter doctor
```

> Referensi lingkungan yang sudah tervalidasi untuk proyek ini:
> **Flutter 3.47.7 / Dart 3.13.5**.

## Langkah Instalasi

Semua perintah `flutter` dijalankan dari folder `mobile/`; path file di bawah
juga relatif terhadap `mobile/`.

```bash
# 0. Masuk ke folder aplikasi Flutter
cd mobile

# 1. Ambil dependensi
flutter pub get

# 2. Jalankan (pilih device)
flutter run
```

Untuk melihat daftar device: `flutter devices`.

## Izin Platform

Izin berikut **sudah** dikonfigurasi di proyek.

**Android** (`android/app/src/main/AndroidManifest.xml`):

- `android.permission.CAMERA`
- `android.permission.READ_MEDIA_IMAGES`
- `android.permission.INTERNET`

**iOS** (`ios/Runner/Info.plist`):

- `NSCameraUsageDescription`
- `NSPhotoLibraryUsageDescription`

> Karena aplikasi memakai **kamera**, disarankan menjalankan di **perangkat
> fisik**. Emulator biasanya tidak menyediakan kamera depan yang andal untuk
> alur `/scan/capture`.

## Perintah Berguna

| Perintah | Fungsi |
|---|---|
| `flutter pub get` | Unduh dependensi |
| `flutter analyze` | Cek error & lint |
| `flutter test` | Jalankan test (`test/widget_test.dart`) |
| `flutter run` | Jalankan mode debug |
| `flutter run --release` | Jalankan mode rilis |
| `flutter build apk` | Build APK Android |
| `flutter build appbundle` | Build AAB Android |
| `flutter clean` | Bersihkan artefak build |

## Verifikasi

Setelah `pub get`, pastikan dua perintah ini lulus sebelum berkontribusi:

```bash
flutter analyze     # harapan: "No issues found!"
flutter test        # harapan: "All tests passed!"
```

## Troubleshooting

### 1. "requires SDK version ^3.13.2, version solving failed"

Artinya versi Dart/Flutter terpasang lebih rendah dari yang diminta. Solusi
(pilih salah satu):

```bash
# Opsi A — naikkan toolchain (disarankan; tidak mengubah pubspec.yaml)
flutter upgrade
```

Atau, bila tidak ingin meng-upgrade SDK, turunkan constraint di `pubspec.yaml`:

```yaml
environment:
  sdk: ^3.13.1   # sesuaikan dengan Dart terpasang
```

### 2. "Building with plugins requires symlink support" (Windows)

Muncul saat plugin butuh symlink. Aktifkan **Developer Mode**:

```powershell
start ms-settings:developers
```

Ini hanya diperlukan untuk **build desktop Windows**; tidak memengaruhi
`pub get`, `analyze`, `test`, atau build Android.

### 3. Kamera tidak muncul / "Tidak bisa membuka kamera depan"

- Pastikan izin kamera diberikan di pengaturan perangkat.
- Gunakan perangkat fisik (bukan emulator tanpa kamera).
- Periksa bahwa tidak ada aplikasi lain yang sedang memakai kamera.

### 4. File generated "berubah" terus di Git

Flutter menulis ulang file `generated_plugin_registrant` dengan akhir baris LF,
sedangkan Git (`core.autocrlf=true`) mengharapkannya berbeda. Proyek sudah
menyediakan `.gitattributes` yang meng-*pin* file tersebut ke LF. Bila masih
muncul, jalankan:

```bash
git add --renormalize .
```

## Catatan Analyzer

`analysis_options.yaml` men-*exclude* folder platform (`android/**`, `ios/**`,
`web/**`, `windows/**`, `macos/**`, `linux/**`, `build/**`) dari analisis, dan
memakai ruleset `package:flutter_lints/flutter.yaml`.
