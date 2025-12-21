from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    model_config = SettingsConfigDict(env_prefix="BEMS_", extra="ignore")

    # DB
    database_url: str = "sqlite+pysqlite:///./bems.db"

    # Auth
    jwt_secret_key: str = "dev-only-change-me"
    jwt_algorithm: str = "HS256"
    access_token_exp_minutes: int = 60


settings = Settings()

