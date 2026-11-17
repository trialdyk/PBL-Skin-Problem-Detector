"""Outbound email via SMTP (registration verification codes)."""

from __future__ import annotations

import html
import logging
import smtplib
import ssl
from email.message import EmailMessage

from app.core.config import Settings, get_settings

logger = logging.getLogger(__name__)

# Brand palette aligned with mobile AppColors (crimson pink + blush).
_BRAND = "#BE185D"
_BRAND_SOFT = "#FFE4EC"
_PAGE = "#FFF8FA"
_INK = "#1F1A1D"
_MUTED = "#5E4553"
_BORDER = "#F8DCE5"
_WHITE = "#FFFFFF"


class EmailSendError(Exception):
    """Raised when SMTP is misconfigured or the provider rejects the message."""


def _plain_body(code: str, expire_minutes: int) -> str:
    return (
        "Halo,\n\n"
        f"Kode verifikasi akun DermaScan Anda adalah: {code}\n\n"
        f"Kode berlaku {expire_minutes} menit. "
        "Jangan bagikan kode ini kepada siapa pun.\n\n"
        "Jika Anda tidak meminta kode ini, abaikan email ini.\n\n"
        "— Tim DermaScan\n"
    )


def _html_body(code: str, expire_minutes: int) -> str:
    safe_code = html.escape(code)
    digits = "".join(
        (
            "<td style=\"padding:0 4px;\">"
            f"<div style=\"width:40px;height:48px;line-height:48px;text-align:center;"
            f"font-size:22px;font-weight:700;letter-spacing:1px;color:{_BRAND};"
            f"background:{_BRAND_SOFT};border-radius:10px;border:1px solid {_BORDER};"
            f"font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;\">"
            f"{html.escape(digit)}</div></td>"
        )
        for digit in code
    )
    return f"""\
<!DOCTYPE html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Kode verifikasi DermaScan</title>
</head>
<body style="margin:0;padding:0;background:{_PAGE};">
  <table role="presentation" width="100%" cellspacing="0" cellpadding="0"
         style="background:{_PAGE};padding:28px 12px;">
    <tr>
      <td align="center">
        <table role="presentation" width="100%" cellspacing="0" cellpadding="0"
               style="max-width:480px;background:{_WHITE};border-radius:16px;
                      border:1px solid {_BORDER};overflow:hidden;">
          <tr>
            <td style="background:linear-gradient(135deg,{_BRAND} 0%,#D63A6A 100%);
                       padding:22px 28px;">
              <p style="margin:0;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                         font-size:20px;font-weight:800;color:{_WHITE};letter-spacing:0.2px;">
                DermaScan
              </p>
              <p style="margin:6px 0 0;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                         font-size:13px;color:rgba(255,255,255,0.9);">
                Verifikasi email akun Anda
              </p>
            </td>
          </tr>
          <tr>
            <td style="padding:28px;">
              <p style="margin:0 0 12px;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                         font-size:16px;font-weight:700;color:{_INK};">
                Halo,
              </p>
              <p style="margin:0 0 22px;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                         font-size:14px;line-height:1.55;color:{_MUTED};">
                Gunakan kode berikut untuk mengaktifkan akun DermaScan Anda:
              </p>
              <table role="presentation" cellspacing="0" cellpadding="0" align="center"
                     style="margin:0 auto 22px;">
                <tr>
                  {digits}
                </tr>
              </table>
              <p style="margin:0 0 8px;text-align:center;
                         font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                         font-size:13px;color:{_MUTED};">
                Atau salin kode ini:
                <strong style="color:{_INK};letter-spacing:2px;">{safe_code}</strong>
              </p>
              <table role="presentation" width="100%" cellspacing="0" cellpadding="0"
                     style="margin-top:18px;background:{_PAGE};border-radius:12px;
                            border:1px solid {_BORDER};">
                <tr>
                  <td style="padding:14px 16px;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                             font-size:13px;line-height:1.5;color:{_MUTED};">
                    Kode berlaku <strong style="color:{_INK};">{expire_minutes} menit</strong>.
                    Jangan bagikan kepada siapa pun. Jika Anda tidak meminta kode ini,
                    abaikan email ini.
                  </td>
                </tr>
              </table>
            </td>
          </tr>
          <tr>
            <td style="padding:0 28px 24px;font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                       font-size:12px;color:{_MUTED};">
              — Tim DermaScan
            </td>
          </tr>
        </table>
        <p style="margin:16px 0 0;max-width:480px;
                   font-family:Segoe UI,Roboto,Helvetica,Arial,sans-serif;
                   font-size:11px;line-height:1.45;color:#9A7A88;">
          Email otomatis. Mohon tidak membalas pesan ini.
        </p>
      </td>
    </tr>
  </table>
</body>
</html>
"""


def send_verification_code(to_email: str, code: str, *, settings: Settings | None = None) -> None:
    """Send a 6-digit verification code to ``to_email``.

    In development, if SMTP is not configured, the code is logged and the call
    succeeds so local/register tests can still run. Outside development, missing
    SMTP credentials raise ``EmailSendError``.
    """
    cfg = settings or get_settings()
    subject = "Kode verifikasi DermaScan"
    plain = _plain_body(code, cfg.email_verification_expire_minutes)
    rich = _html_body(code, cfg.email_verification_expire_minutes)

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
    message.set_content(plain)
    message.add_alternative(rich, subtype="html")

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
