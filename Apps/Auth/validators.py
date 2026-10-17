import re
import secrets
import string
from django.core.exceptions import ValidationError
from django.utils.translation import gettext as _


SPECIAL_CHARACTERS = r'!@#$%^&*()_+-=[]{};\':"|,.<>/?~`'
SPECIAL_CHAR_REGEX = re.compile(r'[!@#$%^&*()_+\-=\[\]{};\':"\\|,.<>\/?~`]')


class StrongPasswordValidator:
    """
    Django password validator enforcing:
    - Minimum length 8 characters
    - At least one uppercase letter (A-Z)
    - At least one lowercase letter (a-z)
    - At least one digit (0-9)
    - At least one special character
    """
    def __init__(self, min_length=8):
        self.min_length = min_length

    def validate(self, password, user=None):
        errors = []
        if len(password) < self.min_length:
            errors.append(
                ValidationError(
                    _("Password must be at least %(min_length)d characters long."),
                    code='password_too_short',
                    params={'min_length': self.min_length},
                )
            )
        if not re.search(r'[A-Z]', password):
            errors.append(
                ValidationError(
                    _("Password must contain at least one uppercase letter (A-Z)."),
                    code='password_no_upper',
                )
            )
        if not re.search(r'[a-z]', password):
            errors.append(
                ValidationError(
                    _("Password must contain at least one lowercase letter (a-z)."),
                    code='password_no_lower',
                )
            )
        if not re.search(r'[0-9]', password):
            errors.append(
                ValidationError(
                    _("Password must contain at least one number (0-9)."),
                    code='password_no_number',
                )
            )
        if not SPECIAL_CHAR_REGEX.search(password):
            errors.append(
                ValidationError(
                    _("Password must contain at least one special character (!@#$%^&* etc.)."),
                    code='password_no_special',
                )
            )

        if errors:
            raise ValidationError(errors)

    def get_help_text(self):
        return _(
            f"Your password must be at least {self.min_length} characters long and include uppercase letters, "
            "lowercase letters, numbers, and special characters."
        )


def validate_strong_password(password):
    """
    Standalone function validator that checks password strength and returns
    a list of missing criteria or raises a single ValidationError.
    """
    if not password:
        raise ValidationError(_("Password is required."))

    missing = []
    if len(password) < 8:
        missing.append("at least 8 characters")
    if not re.search(r'[A-Z]', password):
        missing.append("one uppercase letter (A-Z)")
    if not re.search(r'[a-z]', password):
        missing.append("one lowercase letter (a-z)")
    if not re.search(r'[0-9]', password):
        missing.append("one number (0-9)")
    if not SPECIAL_CHAR_REGEX.search(password):
        missing.append("one special character (!@#$%^&* etc.)")

    if missing:
        msg = f"Password must include: {', '.join(missing)}."
        raise ValidationError(_(msg), code='weak_password')


def generate_strong_temporary_password(length=12):
    """
    Generates a cryptographically secure random password guaranteed to contain:
    - Uppercase letters
    - Lowercase letters
    - Digits
    - Special characters
    """
    uppers = string.ascii_uppercase
    lowers = string.ascii_lowercase
    digits = string.digits
    specials = "!@#$%^&*-_+"

    # Guarantee at least 2 of each category for extra resilience
    password = [
        secrets.choice(uppers),
        secrets.choice(uppers),
        secrets.choice(lowers),
        secrets.choice(lowers),
        secrets.choice(digits),
        secrets.choice(digits),
        secrets.choice(specials),
        secrets.choice(specials),
    ]

    all_chars = uppers + lowers + digits + specials
    remaining = max(0, length - len(password))
    password += [secrets.choice(all_chars) for _ in range(remaining)]

    import random
    rng = random.SystemRandom()
    rng.shuffle(password)
    return "".join(password)
