import time
from django.conf import settings
from django.contrib.auth import logout
from django.contrib import messages
from django.shortcuts import redirect


class SessionIdleTimeoutMiddleware:
    """
    Middleware to automatically expire user sessions after an inactivity period.
    Configurable via SESSION_IDLE_TIMEOUT in settings.py (default 1800 seconds = 30 minutes).
    """

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        if request.user.is_authenticated:
            timeout = getattr(settings, 'SESSION_IDLE_TIMEOUT', 1800)
            now = time.time()
            last_activity = request.session.get('last_activity')

            if last_activity:
                elapsed = now - last_activity
                if elapsed > timeout:
                    logout(request)
                    messages.warning(
                        request,
                        "Your session has expired due to inactivity. Please log in again to continue."
                    )
                    login_url = getattr(settings, 'LOGIN_URL', '/login/')
                    next_path = request.path
                    if next_path and next_path not in ('/', login_url):
                        return redirect(f"{login_url}?next={next_path}")
                    return redirect(login_url)

            # Update last activity timestamp for active user
            request.session['last_activity'] = now

        response = self.get_response(request)
        return response


class LoginRequiredMiddleware:
    """
    Middleware that enforces authentication across the website.
    - If user first opens the website ('/'), they are cleanly redirected to /login/.
    - If user accesses a protected path without login, they are redirected to /login/?next=... with a warning.
    - Public paths (login, register, forgot-password, admin, static, media) are exempt.
    """

    EXEMPT_PATHS = [
        '/login/',
        '/register/',
        '/logout/',
        '/forgot-password/',
        '/session-keep-alive/',
    ]

    def __init__(self, get_response):
        self.get_response = get_response

    def __call__(self, request):
        # Allow authenticated users
        if request.user.is_authenticated:
            if getattr(request.user, 'must_change_password', False):
                allowed_paths = ['/profile/change-password/', '/logout/']
                if not any(request.path.startswith(p) for p in allowed_paths):
                    existing_msgs = [m.message for m in messages.get_messages(request)]
                    warn_msg = "Please change your temporary password to continue."
                    if warn_msg not in existing_msgs:
                        messages.warning(request, warn_msg)
                    return redirect('auth:change-password')

            return self.get_response(request)

        path = request.path

        # Allow static files and media files
        if path.startswith(settings.STATIC_URL) or (settings.MEDIA_URL and path.startswith(settings.MEDIA_URL)):
            return self.get_response(request)

        # Allow Django admin login / URLs
        if path.startswith('/admin/'):
            return self.get_response(request)

        # Allow public auth endpoints
        for exempt in self.EXEMPT_PATHS:
            if path.startswith(exempt):
                return self.get_response(request)

        login_url = getattr(settings, 'LOGIN_URL', '/login/')

        # If user visits root '/', cleanly redirect to login without error banner
        if path == '/':
            return redirect(login_url)

        # If user visits any other protected page, redirect with warning message & next parameter
        messages.warning(request, "Please log in to access this page.")
        return redirect(f"{login_url}?next={request.get_full_path()}")
