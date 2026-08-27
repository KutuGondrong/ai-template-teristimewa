class AppError(Exception):
    code: str = "app_error"
    status_code: int = 400

    def __init__(self, message: str) -> None:
        self.message = message
        super().__init__(message)


class InvalidEmailError(AppError):
    code = "invalid_email"
    status_code = 400


class WeakPasswordError(AppError):
    code = "weak_password"
    status_code = 400


class EmailTakenError(AppError):
    code = "email_taken"
    status_code = 409


class InvalidCredentialsError(AppError):
    code = "invalid_credentials"
    status_code = 401


class NotFoundError(AppError):
    code = "not_found"
    status_code = 404


class RateLimitError(AppError):
    code = "rate_limited"
    status_code = 429
