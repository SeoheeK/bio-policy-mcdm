from pydantic import BaseModel, EmailStr, Field


class UserOut(BaseModel):
    id: int
    name: str
    email: EmailStr
    org: str
    role: str


class UserCreate(BaseModel):
    name: str = Field(max_length=200)
    email: EmailStr
    org: str = Field(default="", max_length=200)
    role: str = Field(pattern=r"^(admin|researcher|guest)$")
    password: str = Field(min_length=8, max_length=128)


class LoginIn(BaseModel):
    email: EmailStr
    password: str


class TokenOut(BaseModel):
    access_token: str
    token_type: str = "bearer"

