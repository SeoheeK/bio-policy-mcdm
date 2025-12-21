from fastapi.testclient import TestClient
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from app.db import Base, get_db
from app.main import app
from app.models import User
from app.auth import hash_password


def make_client():
    engine = create_engine("sqlite+pysqlite:///:memory:", future=True)
    TestingSessionLocal = sessionmaker(bind=engine, autoflush=False, autocommit=False, future=True)
    Base.metadata.create_all(bind=engine)

    def override_get_db():
        db = TestingSessionLocal()
        try:
            yield db
        finally:
            db.close()

    app.dependency_overrides[get_db] = override_get_db
    return TestClient(app), TestingSessionLocal


def test_login_logout_me_flow():
    client, Session = make_client()
    with Session() as db:
        db.add(
            User(
                name="Admin",
                email="admin@example.com",
                org="KRIBB",
                role="admin",
                password_hash=hash_password("Password!1"),
            )
        )
        db.commit()

    r = client.post("/auth/login", json={"email": "admin@example.com", "password": "Password!1"})
    assert r.status_code == 200
    token = r.json()["access_token"]

    r = client.get("/me", headers={"Authorization": f"Bearer {token}"})
    assert r.status_code == 200
    assert r.json()["email"] == "admin@example.com"

    r = client.post("/auth/logout")
    assert r.status_code == 200
    assert r.json()["ok"] is True


def test_login_invalid_credentials():
    client, _ = make_client()
    r = client.post("/auth/login", json={"email": "nope@example.com", "password": "bad"})
    assert r.status_code == 401

