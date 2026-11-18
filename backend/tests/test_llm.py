"""Tests for LLM recommendation prompt building and OpenAI client integration."""

from __future__ import annotations

from types import SimpleNamespace

import pytest

from app.core.config import Settings
from app.services import llm_service


def _fake_client(content: str | None = "Gunakan pembersih lembut.", model: str = "ocg/glm-5.1"):
    captured: dict = {}

    class _Completions:
        def create(self, **kwargs):
            captured.update(kwargs)
            return SimpleNamespace(
                model=model,
                choices=[SimpleNamespace(message=SimpleNamespace(content=content))],
                usage=SimpleNamespace(prompt_tokens=120, completion_tokens=80, total_tokens=200),
            )

    client = SimpleNamespace(chat=SimpleNamespace(completions=_Completions()))
    return client, captured


def test_build_messages_includes_iga_and_interview_answers() -> None:
    messages = llm_service.build_recommendation_messages(
        grade=3,
        grade_label="Sedang",
        top_label="IGA3",
        result_source="ml",
        interview={
            "gender": "female",
            "age": 22,
            "uses_sunscreen": False,
            "skin_type": "oily",
            "unhealthy_food_often": True,
            "skipped": False,
        },
        aggregate={"predictions": [0.05, 0.1, 0.2, 0.55, 0.1]},
    )

    assert len(messages) == 2
    assert messages[0]["role"] == "system"
    user_msg = messages[1]["content"]
    assert "IGA 3 (Sedang) [IGA3]" in user_msg
    assert "Perempuan" in user_msg
    assert "22 tahun" in user_msg
    assert "Jarang / tidak memakai sunscreen" in user_msg
    assert "Berminyak" in user_msg
    assert "Sering konsumsi makanan pemicu" in user_msg
    assert "IGA3: 55.0%" in user_msg


def test_build_messages_handles_skipped_interview() -> None:
    messages = llm_service.build_recommendation_messages(
        grade=1,
        grade_label="Hampir bersih",
        top_label="IGA1",
        result_source="rule_based",
        interview={"skipped": True},
    )
    user_msg = messages[1]["content"]
    assert "IGA 1 (Hampir bersih)" in user_msg
    assert "melewati pertanyaan profil kulit" in user_msg


def test_generate_recommendation_requires_api_key() -> None:
    settings = Settings(llm_api_key="", _env_file=None)
    with pytest.raises(llm_service.LlmNotConfiguredError):
        llm_service.generate_recommendation(
            grade=2,
            grade_label="Ringan",
            top_label="IGA2",
            result_source="ml",
            interview={"skipped": True},
            settings=settings,
        )


def test_generate_recommendation_returns_text_and_meta() -> None:
    settings = Settings(
        llm_base_url="https://api.inferhub.dev/v1",
        llm_api_key="sk-test",
        llm_model="ocg/glm-5.1",
        _env_file=None,
    )
    client, captured = _fake_client("1. Ringkasan Kondisi\nJerawat ringan.")

    text, meta = llm_service.generate_recommendation(
        grade=2,
        grade_label="Ringan",
        top_label="IGA2",
        result_source="ml",
        interview={"age": 20, "skin_type": "combination"},
        settings=settings,
        client=client,
    )

    assert text == "1. Ringkasan Kondisi\nJerawat ringan."
    assert captured["model"] == "ocg/glm-5.1"
    assert meta["model"] == "ocg/glm-5.1"
    assert meta["usage"]["total_tokens"] == 200


def test_generate_recommendation_rejects_empty_response() -> None:
    settings = Settings(llm_api_key="sk-test", _env_file=None)
    client, _ = _fake_client("   ")

    with pytest.raises(llm_service.LlmGenerationError):
        llm_service.generate_recommendation(
            grade=2,
            grade_label="Ringan",
            top_label="IGA2",
            result_source="ml",
            interview={},
            settings=settings,
            client=client,
        )


def test_generate_recommendation_wraps_sdk_errors() -> None:
    settings = Settings(llm_api_key="sk-test", _env_file=None)

    class _BoomCompletions:
        def create(self, **kwargs):
            raise RuntimeError("upstream timeout")

    client = SimpleNamespace(chat=SimpleNamespace(completions=_BoomCompletions()))

    with pytest.raises(llm_service.LlmGenerationError, match="upstream timeout"):
        llm_service.generate_recommendation(
            grade=2,
            grade_label="Ringan",
            top_label="IGA2",
            result_source="ml",
            interview={},
            settings=settings,
            client=client,
        )
