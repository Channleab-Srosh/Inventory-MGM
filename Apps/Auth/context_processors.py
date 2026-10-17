from django.conf import settings


def session_settings(request):
    """
    Context processor to pass session timeout settings to templates.
    """
    return {
        'SESSION_IDLE_TIMEOUT': getattr(settings, 'SESSION_IDLE_TIMEOUT', 1800),
    }
