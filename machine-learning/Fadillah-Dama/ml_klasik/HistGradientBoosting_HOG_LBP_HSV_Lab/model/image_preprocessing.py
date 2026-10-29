import io
import json
from pathlib import Path
import cv2
import joblib
import numpy as np
from PIL import Image as PILImage
from skimage.feature import local_binary_pattern, hog
FEATURE_CONFIG = {
    "feature_version": "skin_contrast_v1",
    "feature_group": "skin",
    "spatial_descriptor_version": "spatial_v1",
    "image_size": [512, 512],
    "color_space": "RGB",
    "interpolation": "INTER_AREA",
    "grids": [1, 2],
    "histogram_bins": 16,
    "color_features": ["HSV", "Lab"],
    "mask": {"Cr": [130, 185], "Cb": [65, 140], "minimum_value": 40,
             "opening_kernel": 3, "minimum_fraction": 0.05,
             "fallback_rectangle": [51, 461, 51, 461]},
    "local_contrast_sigmas": [2, 4, 8],
    "redness_thresholds": [2, 4, 8],
    "dark_contrast_thresholds": [5, 10, 20],
    "component_area_bins": [1, 4, 16, 64, 256, 1024, 1000000000],
    "class_names": {"0": "Mild", "1": "Moderate", "2": "Severe", "3": "Very Severe"},
}


def hist(values, bins, limits):
    h = np.histogram(values, bins=bins, range=limits)[0].astype(np.float32)
    return h / max(float(h.sum()), 1)


def skin_features(rgb):
    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB)
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    yc = cv2.cvtColor(rgb, cv2.COLOR_RGB2YCrCb)
    # Perkiraan area kulit berdasarkan warna; bukan segmentasi lesi.
    mask = (
        (yc[:, :, 1] >= 130) & (yc[:, :, 1] <= 185)
        & (yc[:, :, 2] >= 65) & (yc[:, :, 2] <= 140)
        & (hsv[:, :, 2] > 40)
    )
    mask = cv2.morphologyEx(mask.astype(np.uint8), cv2.MORPH_OPEN, np.ones((3, 3), np.uint8)).astype(bool)
    fallback = mask.mean() < 0.05
    if fallback:
        mask[:] = False
        mask[51:461, 51:461] = True
    out = [float(fallback), float(mask.mean())]
    # Selisih terhadap Gaussian blur menangkap kemerahan dan area gelap lokal.
    signals = []
    for sigma in [2, 4, 8]:
        a = lab[:, :, 1].astype(np.float32)
        g = gray.astype(np.float32)
        signals.append((a - cv2.GaussianBlur(a, (0, 0), sigma), [2, 4, 8]))
        signals.append((cv2.GaussianBlur(g, (0, 0), sigma) - g, [5, 10, 20]))
    # Ringkasan global dan empat wilayah; hanya piksel dalam masker yang dipakai.
    for grid in [1, 2]:
        for iy in range(grid):
            for ix in range(grid):
                ys = slice(iy * 512 // grid, (iy + 1) * 512 // grid)
                xs = slice(ix * 512 // grid, (ix + 1) * 512 // grid)
                inside = mask[ys, xs]
                area = max(int(inside.sum()), 1)
                out.append(float(inside.mean()))
                for (space, limits) in [(hsv, [180, 256, 256]), (lab, [256, 256, 256])]:
                    for (c, limit) in enumerate(limits):
                        values = space[ys, xs, c][inside]
                        out.extend(hist(values, 16, (0, limit)))
                        out.extend(
                            np.percentile(values, [10, 25, 50, 75, 90]) / limit
                            if len(values) else np.zeros(5)
                        )
                        out.extend([values.mean() / limit, values.std() / limit] if len(values) else [0, 0])
                for (signal, thresholds) in signals:
                    values = signal[ys, xs][inside]
                    out.extend([values.mean() / 255, values.std() / 255] if len(values) else [0, 0])
                    for threshold in thresholds:
                        binary = ((signal[ys, xs] > threshold) & inside).astype(np.uint8)
                        # Kelompok piksel adalah statistik citra, bukan jumlah jerawat klinis.
                        (number, _, stats, _) = cv2.connectedComponentsWithStats(binary, connectivity=8)
                        areas = stats[1:, cv2.CC_STAT_AREA]
                        counts = np.histogram(areas, bins=[1, 4, 16, 64, 256, 1024, 1000000000.0])[0]
                        out.extend(counts / (area / 10000))
                        out.append(float(binary.sum() / area))
    result = np.asarray(out, dtype=np.float32)
    assert np.isfinite(result).all()
    return result


def spatial_features(rgb):
    """RGB uint8 512x512; fitur hanya berasal dari piksel, tanpa anotasi lesi."""
    gray = cv2.cvtColor(rgb, cv2.COLOR_RGB2GRAY)
    hsv = cv2.cvtColor(rgb, cv2.COLOR_RGB2HSV)
    lab = cv2.cvtColor(rgb, cv2.COLOR_RGB2LAB)
    # CLAHE menambah satu representasi tekstur dengan kontras lokal diperbaiki.
    equalized = cv2.createCLAHE(clipLimit=2, tileGridSize=(8, 8)).apply(gray)
    maps = [local_binary_pattern(gray, p, r, 'uniform') for (p, r) in [(8, 1), (16, 2), (24, 3)]]
    maps += [local_binary_pattern(equalized, 8, 1, 'uniform')]
    n_bins = [10, 18, 26, 10]
    (texture, colors, spots) = ([], [], [])
    # Respons area gelap pada tiga ukuran lingkungan.
    blackhats = [
        cv2.morphologyEx(
            gray, cv2.MORPH_BLACKHAT,
            cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (k, k)),
        )
        for k in [5, 11, 21]
    ]
    # 1 + 4 + 16 = 21 wilayah untuk mempertahankan informasi lokasi pola.
    for grid in [1, 2, 4]:
        for iy in range(grid):
            for ix in range(grid):
                ys = slice(iy * 512 // grid, (iy + 1) * 512 // grid)
                xs = slice(ix * 512 // grid, (ix + 1) * 512 // grid)
                for (m, bins) in zip(maps, n_bins):
                    texture.extend(hist(m[ys, xs], bins, (0, bins)))
                for (channel, limit) in enumerate([180, 256, 256]):
                    colors.extend(hist(hsv[ys, xs, channel], 16, (0, limit)))
                for channel in range(3):
                    values = lab[ys, xs, channel]
                    colors.extend(np.percentile(values, [10, 25, 50, 75, 90]) / 255)
                    colors.extend([values.mean() / 255, values.std() / 255])
                for m in blackhats:
                    values = m[ys, xs]
                    spots.extend([
                        values.mean() / 255, values.std() / 255,
                        np.mean(values > 10), np.mean(values > 20), np.mean(values > 40),
                    ])
    # HOG dihitung terpisah dari ringkasan grid di atas.
    small = cv2.resize(gray, (128, 128), interpolation=cv2.INTER_AREA)
    shape = hog(
        small, orientations=9, pixels_per_cell=(16, 16),
        cells_per_block=(2, 2), block_norm='L2-Hys', feature_vector=True,
    )
    return {
        'texture': np.asarray(texture, np.float32),
        'color': np.asarray(colors, np.float32),
        'spots': np.asarray(spots, np.float32),
        'hog': shape.astype(np.float32),
    }


def baca_rgb(sumber):
    if isinstance(sumber, dict):
        sumber = sumber.get('bytes') if sumber.get('bytes') is not None else sumber.get('path')
    isi = bytes(sumber) if isinstance(sumber, (bytes, bytearray)) else Path(sumber).read_bytes()
    with PILImage.open(io.BytesIO(isi)) as cek:
        cek.verify()
    bgr = cv2.imdecode(np.frombuffer(isi, dtype=np.uint8), cv2.IMREAD_COLOR)
    if bgr is None:
        raise ValueError('Gambar gagal dibaca OpenCV.')
    return cv2.cvtColor(bgr, cv2.COLOR_BGR2RGB)


def ekstraksi_fitur(rgb, konfigurasi=None):
    cfg = FEATURE_CONFIG if konfigurasi is None else konfigurasi
    for key in FEATURE_CONFIG:
        if key in {'n_features', 'feature_group'}:
            continue
        if cfg.get(key) != FEATURE_CONFIG[key]:
            raise ValueError(f'Konfigurasi fitur berbeda untuk {key}; gunakan versi kode yang cocok.')
    if rgb.dtype != np.uint8 or rgb.ndim != 3 or rgb.shape[2] != 3:
        raise ValueError('Masukan harus RGB uint8.')
    resized = cv2.resize(rgb, (512, 512), interpolation=cv2.INTER_AREA)
    fitur = skin_features(resized)
    group = cfg.get('feature_group', 'skin')
    if group == 'skin_spatial':
        blocks = spatial_features(resized)
        fitur = np.concatenate([fitur] + [blocks[k] for k in ['texture', 'color', 'spots', 'hog']])
    elif group != 'skin':
        raise ValueError('Kelompok fitur tidak dikenal.')
    if 'n_features' in cfg and fitur.size != cfg['n_features']:
        raise ValueError('Dimensi fitur berbeda dari konfigurasi.')
    return fitur


def prediksi_gambar_baru(sumber, model_path, config_path):
    model = joblib.load(model_path)
    cfg = json.loads(Path(config_path).read_text(encoding='utf-8'))
    fitur = ekstraksi_fitur(baca_rgb(sumber), cfg).reshape(1, -1)
    if fitur.shape[1] != model.n_features_in_:
        raise ValueError('Model dan fitur tidak cocok.')
    level = int(model.predict(fitur)[0])
    return {'level': level, 'severity': cfg['class_names'][str(level)]}
