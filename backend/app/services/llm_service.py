"""LLM-powered personalized skincare recommendation service (OpenAI-compatible)."""

from __future__ import annotations

import time
from typing import Any

from openai import OpenAI

from app.core.config import Settings, get_settings

_GENDER_LABELS: dict[str, str] = {
    "male": "Laki-laki",
    "female": "Perempuan",
    "prefer_not_to_say": "Lebih memilih tidak menjawab",
}

_SKIN_TYPE_LABELS: dict[str, str] = {
    "oily": "Berminyak",
    "dry": "Kering",
    "combination": "Kombinasi",
    "sensitive": "Sensitif",
    "normal": "Normal",
}

_IGA_SCALE_GUIDE = (
    "0 = Bersih, 1 = Hampir bersih, 2 = Ringan, "
    "3 = Sedang, 4 = Berat, 5 = Sangat berat"
)

_SYSTEM_PROMPT = (
    "Kamu adalah asisten edukasi perawatan kulit DermaScan berbahasa Indonesia. "
    "Tugasmu memberikan rekomendasi perawatan jerawat yang personal, praktis, "
    "aman, dan mudah dipahami berdasarkan tingkat keparahan jerawat skala IGA/GEA "
    "serta jawaban profil kulit pengguna.\n\n"
    "Aturan wajib:\n"
    "- Gunakan bahasa Indonesia yang ramah, ringkas, dan jelas untuk pengguna awam.\n"
    "- Sesuaikan saran secara spesifik dengan kondisi IGA dan jawaban profil kulit "
    "(tipe kulit, kebiasaan sunscreen, pola makan pemicu, usia, dan jenis kelamin).\n"
    "- Jangan membuat tabel markdown. Gunakan poin-poin singkat agar nyaman dibaca di layar ponsel.\n"
    "- Jangan meresepkan obat keras atau obat resep dokter (mis. isotretinoin, antibiotik oral, "
    "atau steroid topikal). Boleh menyebut bahan skincare OTC umum yang relevan secara hati-hati.\n"
    "- Jika tingkat keparahan Sedang hingga Sangat Berat (IGA >= 3), tekankan anjuran konsultasi "
    "langsung ke dokter atau dokter spesialis kulit (Sp.KK/Sp.DVE).\n"
    "- Akhiri dengan catatan singkat bahwa rekomendasi ini bersifat edukatif dan bukan pengganti "
    "diagnosis maupun penanganan medis dokter.\n\n"
    "Susun jawaban dalam 4 bagian singkat:\n"
    "1. Ringkasan Kondisi\n"
    "2. Rutinitas Skincare yang Disarankan\n"
    "3. Kebiasaan & Gaya Hidup\n"
    "4. Kapan Perlu ke Dokter"
)


class LlmError(Exception):
    """Base error for LLM recommendation generation."""


class LlmNotConfiguredError(LlmError):
    """Raised when LLM API credentials or model settings are missing."""


class LlmGenerationError(LlmError):
    """Raised when the LLM endpoint fails or returns an empty response."""


def is_configured(settings: Settings | None = None) -> bool:
    """Return True when the LLM base URL, API key, and model are configured."""
    cfg = settings or get_settings()
    return cfg.llm_configured


def _build_client(settings: Settings) -> OpenAI:
    return OpenAI(
        base_url=settings.llm_base_url.strip(),
        api_key=settings.llm_api_key.strip(),
        timeout=settings.llm_timeout_seconds,
    )


def _format_bool(value: Any, *, true_label: str, false_label: str) -> str:
    if value is True:
        return true_label
    if value is False:
        return false_label
    return "Tidak diisi"


def _format_interview_lines(interview: dict[str, Any]) -> list[str]:
    if interview.get("skipped") is True:
        return ["- Status kuesioner: Pengguna melewati pertanyaan profil kulit."]

    gender = _GENDER_LABELS.get(str(interview.get("gender") or ""), "Tidak diisi")
    age_val = interview.get("age")
    age = f"{age_val} tahun" if isinstance(age_val, int) else "Tidak diisi"
    sunscreen = _format_bool(
        interview.get("uses_sunscreen"),
        true_label="Ya, rutin memakai sunscreen",
        false_label="Jarang / tidak memakai sunscreen",
    )
    skin_type = _SKIN_TYPE_LABELS.get(str(interview.get("skin_type") or ""), "Tidak diisi")
    unhealthy_food = _format_bool(
        interview.get("unhealthy_food_often"),
        true_label="Sering konsumsi makanan pemicu (gorengan, manis, dll.)",
        false_label="Jarang konsumsi makanan pemicu",
    )
    return [
        f"- Jenis kelamin: {gender}",
        f"- Umur: {age}",
        f"- Penggunaan sunscreen: {sunscreen}",
        f"- Tipe kulit: {skin_type}",
        f"- Konsumsi makanan tidak sehat/pemicu: {unhealthy_food}",
    ]


def _format_probabilities(aggregate: dict[str, Any] | None) -> str | None:
    if not isinstance(aggregate, dict):
        return None
    preds = aggregate.get("predictions")
    if not isinstance(preds, list) or not preds:
        return None
    parts: list[str] = []
    for idx, prob in enumerate(preds):
        if isinstance(prob, (int, float)):
            parts.append(f"IGA{idx}: {prob * 100:.1f}%")
    return ", ".join(parts) if parts else None


def build_recommendation_messages(
    *,
    grade: int,
    grade_label: str,
    top_label: str | None,
    result_source: str,
    interview: dict[str, Any],
    aggregate: dict[str, Any] | None = None,
) -> list[dict[str, str]]:
    """Build chat completion messages combining IGA prediction and interview answers."""
    source_desc = (
        "Analisis foto wajah dengan model CNN"
        if result_source == "ml"
        else "Estimasi rule-based dari jawaban kuesioner (analisis foto tidak tersedia)"
    )
    iga_code = top_label or f"IGA{grade}"

    lines = [
        "Berikut data hasil pemindaian kulit pengguna:",
        f"- Skala referensi IGA/GEA: {_IGA_SCALE_GUIDE}",
        f"- Hasil tingkat keparahan: IGA {grade} ({grade_label}) [{iga_code}]",
        f"- Sumber hasil: {source_desc}",
    ]
    prob_summary = _format_probabilities(aggregate)
    if prob_summary:
        lines.append(f"- Distribusi probabilitas model: {prob_summary}")

    lines.append("")
    lines.append("Profil kulit dari pertanyaan pengguna:")
    lines.extend(_format_interview_lines(interview))
    lines.append("")
    lines.append("Berikan rekomendasi perawatan kulit yang paling relevan untuk pengguna ini.")

    return [
        {"role": "system", "content": _SYSTEM_PROMPT},
        {"role": "user", "content": "\n".join(lines)},
    ]


def generate_recommendation(
    *,
    grade: int,
    grade_label: str,
    top_label: str | None,
    result_source: str,
    interview: dict[str, Any],
    aggregate: dict[str, Any] | None = None,
    settings: Settings | None = None,
    client: Any | None = None,
) -> tuple[str, dict[str, Any]]:
    """Call the configured OpenAI-compatible LLM and return ``(text, meta_json)``."""
    cfg = settings or get_settings()
    if client is None and not is_configured(cfg):
        raise LlmNotConfiguredError("Layanan AI belum dikonfigurasi (LLM_API_KEY kosong).")

    active_client = client or _build_client(cfg)
    messages = build_recommendation_messages(
        grade=grade,
        grade_label=grade_label,
        top_label=top_label,
        result_source=result_source,
        interview=interview,
        aggregate=aggregate,
    )

    started = time.perf_counter()
    try:
        response = active_client.chat.completions.create(
            model=cfg.llm_model.strip(),
            messages=messages,
            temperature=0.4,
            max_tokens=1500,
        )
    except Exception as exc:
        raise LlmGenerationError(f"Gagal memanggil layanan LLM: {exc}") from exc
    elapsed_ms = (time.perf_counter() - started) * 1000

    choices = getattr(response, "choices", None) or []
    content = ""
    if choices:
        message = getattr(choices[0], "message", None)
        raw_content = getattr(message, "content", None)
        if isinstance(raw_content, str):
            content = raw_content.strip()

    if not content:
        raise LlmGenerationError("Respons LLM kosong.")

    meta: dict[str, Any] = {
        "model": getattr(response, "model", None) or cfg.llm_model.strip(),
        "latency_ms": round(elapsed_ms, 1),
    }
    usage = getattr(response, "usage", None)
    if usage is not None:
        meta["usage"] = {
            "prompt_tokens": getattr(usage, "prompt_tokens", None),
            "completion_tokens": getattr(usage, "completion_tokens", None),
            "total_tokens": getattr(usage, "total_tokens", None),
        }

    return content, meta
