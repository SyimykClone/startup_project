from pydantic import BaseModel, EmailStr, Field
from typing import Optional

class RegisterIn(BaseModel):
    username: str = Field(min_length=3, max_length=20)
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)

class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=6, max_length=128)


class GoogleAuthIn(BaseModel):
    id_token: str = Field(min_length=10)


class AuthOut(BaseModel):
    access_token: str
    token_type: str = "bearer"


class AuthMeOut(BaseModel):
    id: int
    username: str
    email: EmailStr
    avatar_url: Optional[str] = None
