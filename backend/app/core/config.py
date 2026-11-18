"""Centralized application settings loaded from environment variables."""

from functools import lru_cache

from pydantic import computed_field, model_validator
from pydantic_settings import BaseSettings, SettingsConfigDict

_DEV_JWT_SECRET = "dermascan-dev-only-secret-do-not-use-in-production"


class Settings(BaseSettings):
    """Application settings for DermaScan backend."""

    model_config = SettingsConfigDict(
        env_file=".env",
        env_file_encoding="utf-8",
        case_sensitive=False,
        extra="ignore",
    )

    app_name: str = "DermaScan Backend"
    app_env: str = "development"
    debug: bool = True

    db_host: str = "localhost"
    db_port: int = 5434
    db_user: str = "postgres"
    db_password: str = ""
    db_name: str = "dermascan"
    db_ssl_mode: str = "disable"

    jwt_secret_key: str = _DEV_JWT_SECRET
    jwt_algorithm: str = "HS256"
    jwt_expire_minutes: int = 60 * 24

    # Google: Web OAuth client ID (audience for Google ID tokens from the app).
    google_client_id: str = ""

    # Inference model shipped in app/ml/artifacts (relative paths resolve against backend/).
    ml_model_path: str = "app/ml/artifacts/dermascan_custom_cnn.tflite"
    ml_input_size: int = 160
    ml_max_upload_mb: int = 10

    # Scan history photos on local disk (relative paths resolve against backend/).
    history_upload_dir: str = "uploads/history"
    history_max_upload_mb: int = 10

    # LLM recommendation (OpenAI-compatible endpoint, e.g. InferHub).
    llm_base_url: str = "https://api.inferhub.dev/v1"
    llm_api_key: str = ""
    llm_model: str = "ocg/glm-5.1"
    llm_timeout_seconds: float = 45.0


    # SMTP — used to send registration verification codes (Gmail app password, etc.).
    smtp_host: str = "smtp.gmail.com"
    smtp_port: int = 587
    smtp_user: str = ""
    smtp_pass: str = ""
    smtp_from: str = ""
    # How long a 6-digit verification code stays valid.
    email_verification_expire_minutes: int = 15

    @model_validator(mode="after")
    def _require_jwt_secret_outside_development(self) -> "Settings":
        if self.app_env != "development" and self.jwt_secret_key == _DEV_JWT_SECRET:
            raise ValueError("JWT_SECRET_KEY must be set outside development")
        return self

    @property
    def smtp_sender(self) -> str:
        """From-address for outbound mail (falls back to SMTP_USER)."""
        return (self.smtp_from or self.smtp_user).strip()

    @property
    def smtp_configured(self) -> bool:
        return bool(self.smtp_host and self.smtp_user and self.smtp_pass and self.smtp_sender)

    @property
    def llm_configured(self) -> bool:
        """Whether the OpenAI-compatible LLM endpoint has a base URL, key, and model."""
        return bool(
            self.llm_base_url.strip()
            and self.llm_api_key.strip()
            and self.llm_model.strip()
        )

    @computed_field  # type: ignore[prop-decorator]
    @property
    def database_url(self) -> str:
        """SQLAlchemy URL for PostgreSQL via psycopg3."""
        return (
            f"postgresql+psycopg://{self.db_user}:{self.db_password}"
            f"@{self.db_host}:{self.db_port}/{self.db_name}"
            f"?sslmode={self.db_ssl_mode}"
        )


@lru_cache
def get_settings() -> Settings:
    """Return a cached Settings instance."""
    return Settings()
