"""Outbound email via SMTP (registration verification codes)."""

from __future__ import annotations

import logging
import smtplib
import ssl
from email.message import EmailMessage

from app.core.config import Settings, get_settings

logger = logging.getLogger(__name__)


class EmailSendError(Exception):
    """Raised when SMTP is misconfigured or the provider rejects the message."""


def send_verification_code(to_email: str, code: str, *, settings: Settings | None = None) -> None:
    """Send a 6-digit verification code to ``to_email``.

    In development, if SMTP is not configured, the code is logged and the call
    succeeds so local/register tests can still run. Outside development, missing
    SMTP credentials raise ``EmailSendError``.
    """
    cfg = settings or get_settings()
    subject = "Kode verifikasi DermaScan"
    body = (
        f"Halo,\n\n"
        f"Kode verifikasi akun DermaScan Anda adalah: {code}\n\n"
        f"Kode berlaku {cfg.email_verification_expire_minutes} menit. "
        f"Jangan bagikan kode ini kepada siapa pun.\n\n"
        f"— Tim DermaScan\n"
    )

    if not cfg.smtp_configured:
        if cfg.app_env == "development":
            logger.warning(
                "SMTP not configured — verification code for %s is %s (dev only)",
                to_email,
                code,
            )
            return
        raise EmailSendError(
            "SMTP belum dikonfigurasi. Set SMTP_HOST, SMTP_USER, SMTP_PASS, SMTP_FROM."
        )

    message = EmailMessage()
    message["Subject"] = subject
    message["From"] = cfg.smtp_sender
    message["To"] = to_email
    message.set_content(body)

    try:
        with smtplib.SMTP(cfg.smtp_host, cfg.smtp_port, timeout=20) as smtp:
            smtp.ehlo()
            smtp.starttls(context=ssl.create_default_context())
            smtp.ehlo()
            smtp.login(cfg.smtp_user, cfg.smtp_pass)
            smtp.send_message(message)
    except Exception as exc:  # noqa: BLE001 — surface as EmailSendError
        logger.exception("Failed to send verification email to %s", to_email)
        raise EmailSendError("Gagal mengirim email verifikasi. Coba lagi nanti.") from exc
