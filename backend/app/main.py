from fastapi import Depends, FastAPI, HTTPException, status
from sqlalchemy.orm import Session

from app.auth import create_access_token, hash_password, verify_password
from app.db import Base, engine, get_db
from app.deps import get_current_user, require_role
from app.models import User
from app.schemas import LoginIn, TokenOut, UserCreate, UserOut


app = FastAPI(title="BEMS API", version="0.1.0")


@app.on_event("startup")
def _startup() -> None:
    # For local/dev convenience. In production use Alembic migrations.
    Base.metadata.create_all(bind=engine)


@app.post("/auth/login", response_model=TokenOut)
def login(payload: LoginIn, db: Session = Depends(get_db)) -> TokenOut:
    user = db.query(User).filter(User.email == payload.email).one_or_none()
    if user is None or not verify_password(payload.password, user.password_hash):
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail="Invalid credentials")
    token = create_access_token(subject=user.email, role=user.role)
    return TokenOut(access_token=token)


@app.post("/auth/logout")
def logout() -> dict:
    # Stateless JWT: client discards token.
    # (Optional future: server-side revocation list / refresh token rotation)
    return {"ok": True}


@app.get("/me", response_model=UserOut)
def me(user: User = Depends(get_current_user)) -> UserOut:
    return UserOut(id=user.id, name=user.name, email=user.email, org=user.org, role=user.role)


@app.post("/users", response_model=UserOut)
def create_user(
    payload: UserCreate,
    db: Session = Depends(get_db),
    _: User = Depends(require_role("admin")),
) -> UserOut:
    exists = db.query(User).filter(User.email == payload.email).count()
    if exists:
        raise HTTPException(status_code=status.HTTP_409_CONFLICT, detail="Email already exists")
    user = User(
        name=payload.name,
        email=str(payload.email),
        org=payload.org,
        role=payload.role,
        password_hash=hash_password(payload.password),
    )
    db.add(user)
    db.commit()
    db.refresh(user)
    return UserOut(id=user.id, name=user.name, email=user.email, org=user.org, role=user.role)

