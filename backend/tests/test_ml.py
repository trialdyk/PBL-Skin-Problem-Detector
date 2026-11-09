"""Tests for the ML prediction pipeline and the protected ``/ml`` router."""

from __future__ import annotations

import io
from collections.abc import Generator

import pytest
from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker
from sqlalchemy.pool import StaticPool

from app.core.security import create_access_token, hash_password
from app.db.database import Base
from app.dependencies import get_db
from app.main import app
from app.models import User
from app.routers import ml as ml_router
from app.services import ml_service

# Inferensi butuh paket di requirements-ml.txt; tanpa itu semua test ML di-skip
# (aplikasi tetap bisa start karena ml_service mengimpor numpy/PIL secara lazy).
np = pytest.importorskip("numpy", reason="install requirements-ml.txt")
Image = pytest.importorskip("PIL.Image", reason="install requirements-ml.txt")

EMAIL = "pengguna@gmail.com"
PASSWORD = "skinscan123"
UNAUTHORIZED_DETAIL = "Sesi tidak valid atau sudah berakhir. Silakan masuk kembali."


def _runtime_available() -> bool:
    """Return True when a TFLite interpreter package can be imported."""
    try:
        from ai_edge_litert.interpreter import Interpreter  # noqa: F401
    except ImportError:
        try:
            from tensorflow.lite.python.interpreter import Interpreter  # noqa: F401
        except ImportError:
            return False
    return True


requires_model = pytest.mark.skipif(
    not _runtime_available() or not ml_service.model_path().is_file(),
    reason="inference runtime or model artifact is unavailable",
)


def make_photo(color: tuple[int, int, int] = (214, 176, 160), size: int = 48) -> bytes:
    """Return a solid-colour PNG, standing in for a selfie."""
    buffer = io.BytesIO()
    Image.new("RGB", (size, size), color).save(buffer, format="PNG")
    return buffer.getvalue()


@pytest.fixture
def db() -> Generator[Session, None, None]:
    engine = create_engine(
        "sqlite://",
        connect_args={"check_same_thread": False},
        poolclass=StaticPool,
    )
    Base.metadata.create_all(engine)
    session = sessionmaker(bind=engine)()
    session.add(User(email=EMAIL, password_hash=hash_password(PASSWORD), full_name="Pengguna"))
    session.commit()
    yield session
    session.close()
    engine.dispose()


@pytest.fixture
def client(db: Session) -> Generator[TestClient, None, None]:
    app.dependency_overrides[get_db] = lambda: db
    yield TestClient(app)
    app.dependency_overrides.pop(get_db, None)


@pytest.fixture
def auth_header(db: Session) -> dict[str, str]:
    user = db.query(User).one()
    return {"Authorization": f"Bearer {create_access_token(str(user.id))}"}


# --- pure helpers -----------------------------------------------------------


@pytest.mark.parametrize(
    ("index", "expected"),
    [(0, 0), (1, 1), (2, 2), (3, 3), (4, 4), (5, 4), (-2, 0)],
)
def test_grade_for_maps_classes_to_gea(index: int, expected: int) -> None:
    assert ml_service.grade_for(index) == expected


def test_label_helpers_use_model_order() -> None:
    assert [ml_service.label_for(index) for index in range(5)] == list(ml_service.IGA_LABELS)
    assert ml_service.label_for(99) == "IGA4"
    assert ml_service.grade_label_for(0) == "Bersih"
    assert ml_service.grade_label_for(4) == "Berat"


def test_scores_for_keeps_model_order_and_grades() -> None:
    scores = ml_service.scores_for([0.1, 0.2, 0.3, 0.25, 0.15])

    assert [score["label"] for score in scores] == list(ml_service.IGA_LABELS)
    assert [score["grade"] for score in scores] == [0, 1, 2, 3, 4]


def test_average_probabilities_is_element_wise_mean() -> None:
    mean = ml_service.average_probabilities(
        [[1.0, 0.0, 0.0, 0.0, 0.0], [0.0, 1.0, 0.0, 0.0, 0.0]]
    )

    assert mean == pytest.approx([0.5, 0.5, 0.0, 0.0, 0.0])


def test_preprocess_builds_float32_model_tensor() -> None:
    tensor = ml_service.preprocess(make_photo((214, 176, 160)), 160)

    assert tensor.shape == (1, 160, 160, 3)
    assert tensor.dtype == np.float32
    # Pixels stay unscaled because the model starts with Rescaling(1./255).
    assert 0.0 <= float(tensor.min()) and float(tensor.max()) <= 255.0
    assert float(tensor[0, :, :, 0].mean()) == pytest.approx(214.0, abs=2.0)


def test_preprocess_honours_requested_size() -> None:
    assert ml_service.preprocess(make_photo(), 64).shape == (1, 64, 64, 3)


def test_preprocess_rejects_undecodable_bytes() -> None:
    with pytest.raises(ml_service.InvalidImageError):
        ml_service.preprocess(b"bukan gambar", 160)


@requires_model
def test_predictions_are_stable_for_a_fixed_photo() -> None:
    """Guard the preprocessing contract (BILINEAR 160x160, raw pixels 0-255).

    If resizing, orientation or scaling changes, these numbers drift and the
    app silently starts grading differently.
    """
    probabilities = ml_service.predict_probabilities(make_photo())

    assert probabilities == pytest.approx(
        [0.998482, 0.000022, 0.001494, 0.000001, 0.0],
        abs=1e-4,
    )
    assert ml_service.top_index(probabilities) == 0
    assert ml_service.grade_for(0) == 0


# --- router ----------------------------------------------------------------


def test_predict_requires_bearer_token(client: TestClient) -> None:
    response = client.post("/ml/predict", files=[("files", ("front.png", make_photo()))])

    assert response.status_code == 401
    assert response.json()["detail"] == UNAUTHORIZED_DETAIL
    assert response.headers.get("www-authenticate") == "Bearer"


def test_predict_rejects_more_than_three_photos(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    files = [
        ("files", (f"photo{index}.png", make_photo(), "image/png")) for index in range(4)
    ]

    response = client.post("/ml/predict", files=files, headers=auth_header)

    assert response.status_code == 400
    assert response.json()["detail"] == ml_router.TOO_MANY_FILES_MESSAGE


def test_predict_rejects_empty_photo(client: TestClient, auth_header: dict[str, str]) -> None:
    response = client.post(
        "/ml/predict",
        files=[("files", ("front.png", b"", "image/png"))],
        headers=auth_header,
    )

    assert response.status_code == 400
    assert response.json()["detail"] == ml_router.EMPTY_FILE_MESSAGE


def test_predict_rejects_undecodable_photo(client: TestClient, auth_header: dict[str, str]) -> None:
    response = client.post(
        "/ml/predict",
        files=[("files", ("front.txt", b"bukan gambar", "text/plain"))],
        headers=auth_header,
    )

    assert response.status_code == 400
    assert response.json()["detail"] == ml_router.INVALID_IMAGE_MESSAGE


def test_predict_rejects_oversized_photo(client: TestClient, auth_header: dict[str, str]) -> None:
    too_big = b"\x00" * (10 * 1024 * 1024 + 1)

    response = client.post(
        "/ml/predict",
        files=[("files", ("big.png", too_big, "image/png"))],
        headers=auth_header,
    )

    assert response.status_code == 413


def test_predict_returns_503_when_model_is_unavailable(
    client: TestClient,
    auth_header: dict[str, str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    def unavailable() -> None:
        raise ml_service.ModelUnavailableError("no runtime")

    monkeypatch.setattr(ml_service, "_load_interpreter", unavailable)

    response = client.post(
        "/ml/predict",
        files=[("files", ("front.png", make_photo(), "image/png"))],
        headers=auth_header,
    )

    assert response.status_code == 503
    assert response.json()["detail"] == ml_router.MODEL_UNAVAILABLE_MESSAGE


def test_predict_returns_503_when_inference_deps_are_missing(
    client: TestClient,
    auth_header: dict[str, str],
    monkeypatch: pytest.MonkeyPatch,
) -> None:
    """The API must keep running when requirements-ml.txt is not installed."""

    def missing() -> None:
        raise ml_service.ModelUnavailableError(ml_service.INSTALL_HINT)

    monkeypatch.setattr(ml_service, "_numpy", missing)

    response = client.post(
        "/ml/predict",
        files=[("files", ("front.png", make_photo(), "image/png"))],
        headers=auth_header,
    )

    assert response.status_code == 503
    assert response.json()["detail"] == ml_router.MODEL_UNAVAILABLE_MESSAGE


@requires_model
def test_predict_returns_gea_grade_for_one_photo(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    response = client.post(
        "/ml/predict",
        files=[("files", ("front.png", make_photo(), "image/png"))],
        headers=auth_header,
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["model"] == ml_service.MODEL_ID
    assert len(payload["images"]) == 1

    image = payload["images"][0]
    assert image["filename"] == "front.png"
    assert image["top_label"] in ml_service.IGA_LABELS
    assert 0 <= image["grade"] <= 4
    assert image["grade_label"] in ml_service.GEA_LABELS_ID
    assert sum(score["probability"] for score in image["predictions"]) == pytest.approx(
        1.0, abs=1e-3
    )

    aggregate = payload["aggregate"]
    assert aggregate["top_label"] == image["top_label"]
    assert aggregate["grade"] == image["grade"]


@requires_model
def test_predict_averages_three_photos(
    client: TestClient,
    auth_header: dict[str, str],
) -> None:
    photos = [
        make_photo((214, 176, 160)),
        make_photo((120, 90, 80)),
        make_photo((240, 220, 210)),
    ]
    files = [
        ("files", (f"photo{index}.png", photo, "image/png"))
        for index, photo in enumerate(photos)
    ]

    response = client.post("/ml/predict", files=files, headers=auth_header)

    assert response.status_code == 200
    payload = response.json()
    assert len(payload["images"]) == 3

    per_image = np.array(
        [[score["probability"] for score in image["predictions"]] for image in payload["images"]]
    )
    aggregate = np.array([score["probability"] for score in payload["aggregate"]["predictions"]])

    assert aggregate == pytest.approx(per_image.mean(axis=0), abs=1e-6)
    assert payload["aggregate"]["grade"] == int(np.argmax(aggregate))
