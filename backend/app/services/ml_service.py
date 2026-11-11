"""TFLite inference for acne severity (custom CNN, IGA0-IGA4).

The shipped model is ``app/ml/artifacts/dermascan_custom_cnn.tflite`` (Fadillah
Dama). Its input is ``[1, 160, 160, 3]`` float32 RGB in 0-255 because the model
starts with ``layers.Rescaling(1./255)``, and its output is a 5-way softmax in
training order ``IGA0..IGA4``.
"""

from __future__ import annotations

import io
import threading
from pathlib import Path
from typing import TYPE_CHECKING, Any

from app.core.config import get_settings

if TYPE_CHECKING:  # pragma: no cover - only for type checkers
    import numpy as np

MODEL_ID = "dermascan-custom-cnn-v1"

# Output order == training order (labels.txt next to the notebook).
IGA_LABELS: tuple[str, ...] = ("IGA0", "IGA1", "IGA2", "IGA3", "IGA4")

# IGA and GEA share the same names for 0-4. GEA 5 (very severe) has no model
# class, so it can never be predicted.
IGA_TO_GEA: tuple[int, ...] = (0, 1, 2, 3, 4)

# Indonesian labels shown by the mobile app (mirrors GeaScale in Flutter).
GEA_LABELS_ID: tuple[str, ...] = (
    "Bersih",
    "Hampir bersih",
    "Ringan",
    "Sedang",
    "Berat",
)

_BACKEND_ROOT = Path(__file__).resolve().parents[2]

_interpreter: Any | None = None
_input_index = 0
_output_index = 0
# A TFLite interpreter is not thread-safe; FastAPI runs handlers in a thread pool.
_interpreter_lock = threading.Lock()


class ModelUnavailableError(Exception):
    """Raised when the inference runtime or the model file is not available."""


class InvalidImageError(Exception):
    """Raised when the uploaded bytes are not a decodable image."""


INSTALL_HINT = "inference dependencies are missing (pip install -r requirements-ml.txt)"


def _numpy() -> Any:
    """Import numpy lazily so the API still boots without requirements-ml."""
    try:
        import numpy
    except ImportError as exc:  # pragma: no cover - depends on the environment
        raise ModelUnavailableError(INSTALL_HINT) from exc
    return numpy


def _pillow() -> tuple[Any, Any, Any]:
    """Return ``(Image, ImageOps, UnidentifiedImageError)``, imported lazily."""
    try:
        from PIL import Image, ImageOps, UnidentifiedImageError
    except ImportError as exc:  # pragma: no cover - depends on the environment
        raise ModelUnavailableError(INSTALL_HINT) from exc
    return Image, ImageOps, UnidentifiedImageError


def model_path() -> Path:
    """Return the absolute model path (relative settings resolve against backend/)."""
    raw_path = Path(get_settings().ml_model_path)
    return raw_path if raw_path.is_absolute() else _BACKEND_ROOT / raw_path


def _load_interpreter() -> Any:
    """Load the interpreter once, preferring ai-edge-litert over TensorFlow."""
    global _interpreter, _input_index, _output_index

    if _interpreter is not None:
        return _interpreter

    artifact = model_path()
    if not artifact.is_file():
        raise ModelUnavailableError(f"model file missing: {artifact}")

    try:
        from ai_edge_litert.interpreter import Interpreter
    except ImportError:
        try:
            from tensorflow.lite.python.interpreter import Interpreter
        except ImportError as exc:  # pragma: no cover - depends on the environment
            raise ModelUnavailableError("inference runtime is not installed") from exc

    interpreter = Interpreter(model_path=str(artifact))
    interpreter.allocate_tensors()
    _input_index = int(interpreter.get_input_details()[0]["index"])
    _output_index = int(interpreter.get_output_details()[0]["index"])
    _interpreter = interpreter
    return interpreter


def preprocess(data: bytes, size: int) -> np.ndarray:
    """Decode, orient and resize one image into the model input tensor.

    Pixels stay in 0-255: the model normalizes internally with ``Rescaling``.
    """
    np = _numpy()
    Image, ImageOps, unidentified = _pillow()

    try:
        with Image.open(io.BytesIO(data)) as raw:
            image = ImageOps.exif_transpose(raw).convert("RGB")
            resized = image.resize((size, size), Image.BILINEAR)
            array = np.array(resized, dtype=np.float32)
    except (unidentified, OSError, ValueError) as exc:
        raise InvalidImageError("undecodable image") from exc

    return array[None, :, :, :]


def predict_probabilities(data: bytes) -> list[float]:
    """Return the 5 softmax probabilities (IGA0..IGA4) for one image."""
    np = _numpy()
    interpreter = _load_interpreter()
    tensor = preprocess(data, get_settings().ml_input_size)

    with _interpreter_lock:
        interpreter.set_tensor(_input_index, tensor)
        interpreter.invoke()
        output = interpreter.get_tensor(_output_index)

    return [float(value) for value in np.asarray(output, dtype=np.float32).reshape(-1)]


def average_probabilities(all_probabilities: list[list[float]]) -> list[float]:
    """Return the element-wise mean of several probability vectors."""
    np = _numpy()
    stacked = np.asarray(all_probabilities, dtype=np.float32)
    return [float(value) for value in stacked.mean(axis=0).reshape(-1)]


def top_index(probabilities: list[float]) -> int:
    """Return the index of the most likely class."""
    np = _numpy()
    return int(np.argmax(np.asarray(probabilities, dtype=np.float32)))


def grade_for(index: int) -> int:
    """Map a model class index to its GEA grade (clamped to the 5 known classes)."""
    return IGA_TO_GEA[max(0, min(index, len(IGA_TO_GEA) - 1))]


def label_for(index: int) -> str:
    """Return the model class name for a class index."""
    return IGA_LABELS[max(0, min(index, len(IGA_LABELS) - 1))]


def grade_label_for(grade: int) -> str:
    """Return the Indonesian label for a GEA grade."""
    return GEA_LABELS_ID[max(0, min(grade, len(GEA_LABELS_ID) - 1))]


def scores_for(probabilities: list[float]) -> list[dict[str, object]]:
    """Build ``ClassScore`` payloads in model order."""
    return [
        {
            "label": label_for(index),
            "grade": grade_for(index),
            "probability": float(probability),
        }
        for index, probability in enumerate(probabilities)
    ]


def reset_interpreter() -> None:
    """Drop the cached interpreter (used by tests and after a config change)."""
    global _interpreter
    with _interpreter_lock:
        _interpreter = None