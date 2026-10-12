from functools import wraps
from django.http import HttpResponseForbidden
from django.shortcuts import redirect
from django.contrib import messages


def role_required(*allowed_roles):
    """
    Decorator to restrict access based on user role.
    Superusers automatically bypass role restrictions.
    """
    def decorator(view_func):
        @wraps(view_func)
        def _wrapped_view(request, *args, **kwargs):
            if not request.user.is_authenticated:
                messages.warning(request, "Please log in to access this page.")
                return redirect(f"/login/?next={request.path}")
            
            if request.user.is_superuser or getattr(request.user, 'role', None) in allowed_roles:
                return view_func(request, *args, **kwargs)
            
            messages.error(request, "Access Denied: You do not have the required permissions.")
            return HttpResponseForbidden("SECURITY ALERT: Insufficient clearance level.")
        return _wrapped_view
    return decorator
