# Brand & Logo Context — PBL Skin Problem Detector

Dokumen ini dipakai sebagai konteks untuk generate logo aplikasi (skills / AI image / designer).

Sumber kebenaran warna: `lib/presentation/theme/app_colors.dart`.

---

## 1. Product

| Field | Value |
|---|---|
| App name | Skin Problem Detector |
| Short name | SPD / Skin Detector |
| Domain | Skincare, acne detection, GEA scale |
| Platform | Flutter Android app |
| Tone | Soft, modern, medical-friendly, trustworthy |
| Not | Cold clinical, cyberpunk, generic AI purple |

Tagline (opsional):
> Analisis kulit berbasis skala GEA

---

## 2. Color palette (wajib)

### Primary brand (crimson pink)

| Token | Hex | RGB | Usage in logo |
|---|---|---|---|
| brand | `#BE185D` | 190, 24, 93 | Main mark / icon fill |
| brandBright | `#D63A6A` | 214, 58, 106 | Highlight / gradient end |
| brandDeep | `#A8154F` | 168, 21, 79 | Depth / shadow |
| brandSoft | `#FFE4EC` | 255, 228, 236 | Soft background plate |
| brandLight | `#F9A8C4` | 249, 168, 196 | Accent ring / secondary shape |

### Neutrals

| Token | Hex | Usage in logo |
|---|---|---|
| white | `#FFFFFF` | App icon bg / reverse logo |
| page | `#FFF8FA` | Light canvas |
| muted | `#FFF0F4` | Soft alternate bg |
| border | `#F8DCE5` | Thin outline (opsional) |
| ink | `#1F1A1D` | Wordmark dark |
| inkMuted | `#5E4553` | Tagline |

### Supporting accents (jangan dominan di logo)

| Token | Hex | Notes |
|---|---|---|
| accent | `#F97316` | Optional tiny accent only |
| amber | `#F59E0B` | Optional tiny accent only |

### Camera / dark surfaces (untuk variant dark icon)

| Token | Hex |
|---|---|
| cameraBg | `#18181B` |
| cameraOverlay | `#09090B` |

### GEA grade colors (boleh jadi inspirasi gradasi, jangan jadi warna utama logo)

| Grade | Hex |
|---|---|
| 0 | `#86C99B` |
| 1 | `#B7C77A` |
| 2 | `#EAC95B` |
| 3 | `#EE9B4E` |
| 4 | `#E0603F` |
| 5 | `#B4342B` |

---

## 3. Typography

| Role | Font |
|---|---|
| App UI | Plus Jakarta Sans |
| Wordmark logo | Plus Jakarta Sans Bold / ExtraBold |
| Tagline | Plus Jakarta Sans Medium |

---

## 4. Layout & visual language (dari UI app)

- Soft rounded corners (radius ~18–24px)
- White cards on blush/pink page background
- Clean spacing, minimal clutter
- Splash mark sekarang: rounded square + face-scan icon centered
- Feel: approachable skincare tech, not harsh medical

Bentuk yang cocok:
- Rounded square app icon
- Soft circle badge
- Abstract face / scan frame / gentle droplet / leaf-skin hybrid

Hindari:
- Sharp jagged shapes
- Heavy neon glow
- 3D chrome / glassmorphism berlebih
- Purple gradient AI look
- Too many colors (>3 di mark utama)

---

## 5. Logo variants yang dibutuhkan

1. **App icon** — mark only, rounded square, readable at 48–1024px
2. **Primary logo** — mark + wordmark “Skin Problem Detector”
3. **Compact logo** — mark + short name “SPD”
4. **Monochrome** — ink `#1F1A1D` on white, and white on brand `#BE185D`
5. **Favicon / small** — simplified mark, no thin lines

---

## 6. Prompt untuk generate logo

### Prompt utama (EN)

```text
Create a modern mobile app logo for "Skin Problem Detector", a skincare acne analysis app using the GEA scale.

Style: soft, clean, medical-friendly, rounded, minimal.
Primary colors: crimson pink #BE185D and bright pink #D63A6A.
Optional soft background plate: #FFE4EC.
Wordmark color: near-black #1F1A1D.
Typography feel: Plus Jakarta Sans bold.

Mark concept: abstract face-scan / gentle skin analysis symbol (not realistic face photo).
Shape language: rounded corners, simple geometry, high clarity as Android app icon.
No purple gradients, no neon glow, no clutter, no photorealistic skin, no medical cross cliché.
Provide: 1) app icon mark on soft pink or white, 2) horizontal logo with wordmark.
```

### Prompt singkat (ID)

```text
Buat logo aplikasi mobile Skin Problem Detector.
Warna utama #BE185D dan #D63A6A, latar soft #FFE4EC atau putih.
Gaya modern, rounded, soft medical/skincare, mark scan wajah abstrak.
Wordmark Plus Jakarta Sans bold warna #1F1A1D.
Tanpa ungu, tanpa glow neon, tanpa foto realistis.
Hasil: app icon + logo horizontal mark+teks.
```

### Negative prompt

```text
purple gradient, neon glow, cyberpunk, photorealistic face, acne close-up photo, cluttered details, thin unreadable lines, 3D chrome, glassmorphism overload, hospital red cross, generic AI logo
```

---

## 7. Acceptance checklist

- [ ] Dominan crimson/pink brand, bukan warna lain
- [ ] Readable sebagai app icon kecil
- [ ] Cocok di splash (rounded tile) dan beranda
- [ ] Ada versi light & dark/mono
- [ ] Terasa skincare + tech, bukan klinik kaku
- [ ] Nama “Skin Problem Detector” tetap terbaca di wordmark
