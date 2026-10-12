# Alur Pengguna & Navigasi

## Diagram Alur Utama

```mermaid
flowchart TD
    Start([App dibuka]) --> Splash["/splash — SplashScreen<br/>(auto 1,8 detik)"]
    Splash --> Welcome["/welcome — WelcomeScreen"]
    Welcome -->|"Mulai Sekarang"| Login["/login — LoginScreen"]
    Login -->|"Login berhasil"| Home["/home — HomeScreen"]
    Login -.->|"Google (mock)"| Home

    Home -->|"Mulai Analisis Kulit"| Scan["/scan — ScanPhotoScreen<br/>Hub foto 3 sudut"]
    Scan -->|"Ketuk kartu sudut"| Capture["/scan/capture?angle=…<br/>ScanCaptureScreen"]
    Capture -->|"Foto tersimpan, kembali"| Scan
    Scan -->|"Panduan → Unggah dari Galeri"| Upload["/scan/upload<br/>ScanUploadScreen"]
    Scan -->|"Lanjut ke Kuesioner"| Interview["/scan/interview<br/>InterviewScreen"]
    Upload -->|"Lanjutkan"| Confirm["/scan/confirm<br/>ScanConfirmScreen"]
    Confirm -->|"Lanjutkan"| Interview
    Confirm -->|"Selfie Ulang"| Scan
    Interview -->|"5 pertanyaan / Lewati"| Result["/scan/result<br/>DiagnosisScreen"]
    Result -->|"Kembali ke Beranda"| Home
```

## Langkah demi Langkah

### 1. Splash → Welcome

`SplashScreen` menampilkan logo & nama aplikasi, lalu `Timer` 1.800 ms
otomatis `context.go('/welcome')`.

`WelcomeScreen` memperkenalkan 3 fitur (Scan 3 sudut, Interview singkat, Hasil
skala GEA) dan tombol **Mulai Sekarang** → `/login`.

### 2. Login

`LoginScreen` memakai `AuthCubit`. Saat submit, layar otomatis menyalakan
centang S&K + privasi (`togglePrivacy(true)`, `toggleTerms(true)`) lalu memanggil
`login(...)`. Bila status menjadi `authenticated`, `listener` melakukan
`context.go('/home')`.

- **Email/password** — divalidasi `AuthService` (tidak boleh kosong).
- **Google** — *mock*: langsung login dengan email contoh
  `pengguna@gmail.com`.
- Tombol **Daftar Sekarang** memunculkan toast "Belum tersedia di versi
  prototipe."

### 3. Beranda

`HomeScreen` mengelola 3 tab lewat `HomeCubit` (bukan bottom nav):

| Tab | Cara membuka |
|---|---|
| Beranda (`_tabHome`) | Default |
| Artikel (`_tabArticles`) | Ketuk kartu **Tentang Skala Global Acne (GEA)** |
| Profil (`_tabProfile`) | Ketuk avatar di `AppHeader` |

Kartu **Mulai Analisis Kulit** memulai alur scan (`/scan`).

### 4. Alur Scan (2 jalur)

Ada **dua cara** mengumpulkan 3 foto, dan keduanya bertemu di interview.

**Jalur A — Kamera langsung (per sudut):**

1. `/scan` (`ScanPhotoScreen`) menampilkan 3 kartu sudut: **Tampak Depan**,
   **Sisi Kiri**, **Sisi Kanan**. Kartu terkunci sampai sisi sebelumnya selesai
   (kiri butuh depan; kanan butuh kiri).
2. Ketuk kartu → `/scan/capture?angle=<front|left|right>`.
3. `ScanCaptureScreen` menganalisis frame kamera (ML Kit): indikator **Cahaya**,
   **Wajah**, **Sudut** harus hijau. Bila siap, muncul hitungan **3-2-1** dan
   foto diambil otomatis (atau lewat tombol).
4. Setelah tersimpan, layar `pop()` kembali ke hub. Ulangi untuk 3 sudut.
5. Tombol **Lanjut ke Kuesioner (Langkah 2)** → `continueToInterview()` →
   `/scan/interview`.

**Jalur B — Unggah dari galeri:**

1. Di `/scan`, tombol **Panduan Ulang Foto** membuka dialog; pilih **Unggah dari
   Galeri** → `/scan/upload`.
2. `ScanUploadScreen` menyediakan 3 slot (depan/kiri/kanan). Tombol
   **Lanjutkan** aktif setelah 3 foto → `/scan/confirm`.
3. `ScanConfirmScreen` menampilkan pratinjau + **Lanjutkan** → interview, atau
   **Selfie Ulang** → `retakePhotos()` → `/scan`.

> Pada kamera mode berurutan (`/scan/capture` tanpa `angle`), setelah 3 sudut
> selesai alur juga melewati `/scan/confirm`.

### 5. Interview (chat)

`InterviewScreen` adalah chat 5 pertanyaan dengan indikator progres. Setiap
jawaban langsung tersimpan ke `ScanSession.interview`.

| # | Pertanyaan | Nilai yang disimpan |
|---|---|---|
| 0 | Jenis kelamin | `gender` |
| 1 | Umur | `age` |
| 2 | Pakai sunscreen | `usesSunscreen` |
| 3 | Tipe kulit | `skinType` |
| 4 | Sering makanan pemicu | `unhealthyFoodOften` |

Tombol **Lewati** memanggil `skipInterview()` (jawaban `skipped: true`) dan
langsung diagnosa.

### 6. Hasil

Setelah pertanyaan ke-5, `ScanCubit` masuk fase `diagnosing` lalu `result`, dan
`InterviewScreen` otomatis `context.go('/scan/result')`.

`DiagnosisScreen` menampilkan: pratinjau foto depan, `GeaResultBadge` (angka
besar + label), `GeaScaleBar` 0–5, penjelasan grade, dan catatan bahwa hasil
masih rule-based. Tombol **Kembali ke Beranda** memanggil `resetFlow()` lalu
`/home`.

## Bottom Navigation

`AppBottomNav` dipakai di layar beranda dan hub foto. Itemnya:

| Indeks (`NavIndex`) | Label | Aksi (`handleBottomNavTap`) |
|---|---|---|
| `home` (0) | Beranda | `onHome()` atau `go('/home')` |
| `photo` (1) | Foto | `push('/scan')` (bila belum di sana) |
| `interview` (2) | Wawancara | Lanjut interview bila foto lengkap; jika belum → toast |
| `report` (3) | Laporan GEA | Buka hasil bila sudah ada; jika belum → toast |

```mermaid
flowchart TD
    Tap["Tap item nav"] --> Q{"Item mana?"}
    Q -->|Beranda| H["/home"]
    Q -->|Foto| P["push /scan"]
    Q -->|Wawancara| I{"Foto lengkap?"}
    I -->|Ya| IV["continueToInterview → /scan/interview"]
    I -->|Tidak| T1["Toast: ambil 3 foto dulu"]
    Q -->|Laporan GEA| R{"Ada hasil?"}
    R -->|Ya| RR["push /scan/result"]
    R -->|Tidak| T2["Toast: belum ada hasil"]
```
