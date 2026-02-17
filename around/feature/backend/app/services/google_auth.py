from google.auth.transport.requests import Request
from google.oauth2 import id_token
from app.core.config import settings


class GoogleAuthError(Exception):
    pass


def verify_google_id_token(token: str) -> dict:
    if not settings.GOOGLE_WEB_CLIENT_ID:
        raise GoogleAuthError("GOOGLE_WEB_CLIENT_ID is not set")

    try:
        payload = id_token.verify_oauth2_token(
            token,
            Request(),
            settings.GOOGLE_WEB_CLIENT_ID,
        )
    except Exception as e:
        raise GoogleAuthError(f"Invalid Google token: {e}") from e

    email = payload.get("email")
    email_verified = payload.get("email_verified")
    if not isinstance(email, str) or not email:
        raise GoogleAuthError("Google token does not contain email")
    if email_verified is not True:
        raise GoogleAuthError("Google email is not verified")

    return payload
