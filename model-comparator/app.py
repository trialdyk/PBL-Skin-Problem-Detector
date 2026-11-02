import json
import os
import threading
import time
from pathlib import Path

os.environ.setdefault("TF_CPP_MIN_LOG_LEVEL", "2")

import keras
import numpy as np
import tensorflow as tf
from flask import Flask, jsonify, request, send_from_directory
from PIL import Image, ImageOps, UnidentifiedImageError

BASE_DIR = Path(__file__).parent
REGISTRY_PATH = BASE_DIR / "models.json"

app = Flask(__name__, static_folder="static", static_url_path="/static")
app.config["MAX_CONTENT_LENGTH"] = 10 * 1024 * 1024


class KerasModel:
    def __init__(self, path):
        self.model = keras.saving.load_model(path, compile=False)
        self.input_h, self.input_w = self.model.input_shape[1:3]
        self.num_classes = self.model.output_shape[-1]
        self.lock = threading.Lock()

    def predict(self, x):
        with self.lock:
            return np.asarray(self.model(x, training=False))[0]


class TFLiteModel:
    def __init__(self, path):
        self.interp = tf.lite.Interpreter(model_path=str(path))
        self.interp.allocate_tensors()
        self.inp = self.interp.get_input_details()[0]
        self.out = self.interp.get_output_details()[0]
        self.input_h, self.input_w = self.inp["shape"][1:3].tolist()
        self.num_classes = int(self.out["shape"][-1])
        self.lock = threading.Lock()

    def predict(self, x):
        with self.lock:
            self.interp.set_tensor(self.inp["index"], x.astype(self.inp["dtype"]))
            self.interp.invoke()
            return self.interp.get_tensor(self.out["index"])[0].copy()


LOADERS = {".keras": KerasModel, ".tflite": TFLiteModel}


def load_registry():
    entries = json.loads(REGISTRY_PATH.read_text(encoding="utf-8"))
    registry = {}
    for entry in entries:
        path = BASE_DIR / entry["file"]
        print(f"Memuat {entry['name']} dari {path} ...")
        runner = LOADERS[path.suffix](path)
        labels = entry.get("labels", [])
        if len(labels) != runner.num_classes:
            labels = [f"Kelas {i}" for i in range(runner.num_classes)]
        registry[entry["id"]] = {
            "id": entry["id"],
            "name": entry["name"],
            "description": entry.get("description", ""),
            "labels": labels,
            "content_crop": entry.get("content_crop", False),
            "runner": runner,
        }
        print(f"  siap: input {runner.input_w}x{runner.input_h}, {runner.num_classes} kelas")
    return registry


MODELS = load_registry()
DEFAULT_MODEL_ID = next(iter(MODELS))


def trim_black_borders(img, threshold=10):
    """Buang baris/kolom tepi yang seluruhnya hitam (letterbox); gambar biasa tidak berubah."""
    mask = np.asarray(img).max(axis=2) > threshold
    rows = np.flatnonzero(mask.any(axis=1))
    cols = np.flatnonzero(mask.any(axis=0))
    if rows.size == 0:
        return img
    return img.crop((cols[0], rows[0], cols[-1] + 1, rows[-1] + 1))


@app.get("/")
def index():
    return send_from_directory(app.static_folder, "index.html")


@app.get("/api/models")
def list_models():
    return jsonify(
        default=DEFAULT_MODEL_ID,
        models=[
            {
                "id": m["id"],
                "name": m["name"],
                "description": m["description"],
                "input_size": [m["runner"].input_w, m["runner"].input_h],
                "labels": m["labels"],
            }
            for m in MODELS.values()
        ],
    )


def read_upload():
    """Baca file 'image' dari request. Mengembalikan (gambar, None) atau (None, response_error)."""
    upload = request.files.get("image")
    if upload is None or upload.filename == "":
        return None, (jsonify(error="Belum ada gambar yang diupload."), 400)
    try:
        img = Image.open(upload.stream)
        return ImageOps.exif_transpose(img).convert("RGB"), None
    except (UnidentifiedImageError, OSError):
        return None, (jsonify(error="File bukan gambar yang valid."), 400)


def run_model(entry, img):
    runner = entry["runner"]
    if entry["content_crop"]:
        img = trim_black_borders(img)

    # Semua model sudah punya Rescaling/Normalization sendiri,
    # jadi input cukup float32 RGB 0-255 tanpa preprocessing tambahan.
    img = img.resize((runner.input_w, runner.input_h), Image.BILINEAR)
    x = np.asarray(img, dtype="float32")[None]

    start = time.perf_counter()
    probs = runner.predict(x)
    elapsed_ms = (time.perf_counter() - start) * 1000

    labels = entry["labels"]
    top = int(np.argmax(probs))
    return {
        "model": {"id": entry["id"], "name": entry["name"], "description": entry["description"]},
        "top": {"index": top, "label": labels[top], "probability": float(probs[top])},
        "predictions": [
            {"index": i, "label": labels[i], "probability": float(p)}
            for i, p in enumerate(probs)
        ],
        "inference_ms": round(elapsed_ms, 1),
    }


@app.post("/api/predict")
def predict():
    model_id = request.form.get("model", DEFAULT_MODEL_ID)
    entry = MODELS.get(model_id)
    if entry is None:
        return jsonify(error=f"Model '{model_id}' tidak dikenal."), 400

    img, error = read_upload()
    if error:
        return error
    return jsonify(run_model(entry, img))


@app.post("/api/compare")
def compare():
    img, error = read_upload()
    if error:
        return error
    return jsonify(results=[run_model(entry, img) for entry in MODELS.values()])


@app.errorhandler(413)
def too_large(_):
    return jsonify(error="Ukuran gambar maksimal 10 MB."), 413


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=int(os.environ.get("PORT", 5000)))
