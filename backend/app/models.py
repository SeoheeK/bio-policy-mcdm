from sqlalchemy import String
from sqlalchemy.orm import Mapped, mapped_column

from app.db import Base


class User(Base):
    __tablename__ = "users"

    id: Mapped[int] = mapped_column(primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(200))
    email: Mapped[str] = mapped_column(String(320), unique=True, index=True)
    org: Mapped[str] = mapped_column(String(200), default="")
    role: Mapped[str] = mapped_column(String(50))  # admin | researcher | guest
    password_hash: Mapped[str] = mapped_column(String(255))

