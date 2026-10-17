from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login as auth_login, logout as auth_logout, update_session_auth_hash
from django.contrib.auth import get_user_model
from django.db.models import Q
from django.contrib import messages
from django.contrib.auth import views as auth_views
from django.urls import reverse_lazy, reverse
from Apps.Auth.decorators import role_required
import secrets
from datetime import timedelta
from django.utils import timezone
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.conf import settings
from django.http import JsonResponse
import time
import logging

logger = logging.getLogger(__name__)
from .forms import (
    ProfileEditForm, CustomPasswordChangeForm, UserCreateForm, UserEditForm,
    RegisterForm, ForgotPasswordRequestForm, ForgotPasswordVerifyOtpForm,
    ForgotPasswordSetPasswordForm
)

User = get_user_model()


def _mask_email(email):
    if not email or '@' not in email:
        return email
    user_part, domain_part = email.split('@', 1)
    if len(user_part) <= 2:
        masked_user = user_part[0] + '*'
    else:
        masked_user = user_part[0] + '*' * (len(user_part) - 2) + user_part[-1]
    return f"{masked_user}@{domain_part}"


def forgot_password_request_view(request):
    """Step 1: Enter email and send 6-digit OTP code."""
    if request.user.is_authenticated:
        return redirect('inventory:dashboard')

    if request.method == 'POST':
        form = ForgotPasswordRequestForm(request.POST)
        if form.is_valid():
            email = form.cleaned_data['email']
            user = User.objects.filter(email__iexact=email, is_active=True).first()

            otp = f"{secrets.randbelow(900000) + 100000}"
            now_ts = timezone.now().timestamp()

            request.session['reset_email'] = email
            request.session['reset_otp'] = otp
            request.session['reset_expires'] = now_ts + (10 * 60)  # 10 minutes
            request.session['reset_attempts'] = 0
            request.session['reset_last_sent'] = now_ts
            request.session['reset_verified'] = False

            # Send Email
            subject = f"[InvenStock] Your Password Reset Code: {otp}"
            context = {
                'otp': otp,
                'email': email,
                'user': user,
                'expiry_minutes': 10
            }
            html_message = render_to_string('auth/password_reset_otp_email.html', context)
            plain_message = strip_tags(html_message)

            try:
                send_mail(
                    subject,
                    plain_message,
                    settings.DEFAULT_FROM_EMAIL,
                    [email],
                    html_message=html_message,
                    fail_silently=False
                )
                messages.success(request, f"A 6-digit verification code has been sent to {_mask_email(email)}.")
            except Exception as e:
                logger.error(f"Failed to send password reset email to {email}: {e}")
                messages.error(request, "Unable to send verification email. Please check your internet connection or try again later.")

            return redirect('auth:password-reset-verify')
        else:
            messages.error(request, "Please check the email address entered.")
    else:
        form = ForgotPasswordRequestForm()

    return render(request, 'auth/password_reset.html', {'form': form})


def forgot_password_verify_view(request):
    """Step 2: Enter and verify the 6-digit OTP code."""
    if request.user.is_authenticated:
        return redirect('inventory:dashboard')

    email = request.session.get('reset_email')
    expected_otp = request.session.get('reset_otp')
    expires = request.session.get('reset_expires', 0)

    if not email or not expected_otp:
        messages.warning(request, "Please enter your email to request a reset code first.")
        return redirect('auth:password-reset')

    now_ts = timezone.now().timestamp()
    if now_ts > expires:
        messages.error(request, "Your verification code has expired. Please request a new code.")
        return redirect('auth:password-reset')

    attempts = request.session.get('reset_attempts', 0)
    if attempts >= 5:
        messages.error(request, "Too many incorrect attempts. Please request a new code.")
        return redirect('auth:password-reset')

    if request.method == 'POST':
        form = ForgotPasswordVerifyOtpForm(request.POST)
        if form.is_valid():
            submitted_otp = form.cleaned_data['otp']
            if submitted_otp == str(expected_otp).strip():
                request.session['reset_verified'] = True
                messages.success(request, "Code verified successfully! Now choose your new password.")
                return redirect('auth:password-reset-set-password')
            else:
                attempts += 1
                request.session['reset_attempts'] = attempts
                remaining = 5 - attempts
                if remaining > 0:
                    messages.error(request, f"Invalid verification code. {remaining} attempt(s) remaining.")
                else:
                    messages.error(request, "Too many incorrect attempts. Please request a new code.")
                    return redirect('auth:password-reset')
        else:
            messages.error(request, "Please enter a valid 6-digit code.")
    else:
        form = ForgotPasswordVerifyOtpForm()

    seconds_remaining = max(0, int(expires - now_ts))
    context = {
        'form': form,
        'masked_email': _mask_email(email),
        'seconds_remaining': seconds_remaining,
    }
    return render(request, 'auth/password_reset_verify.html', context)


def forgot_password_resend_view(request):
    """Resend a fresh 6-digit OTP with a 60-second cooldown."""
    email = request.session.get('reset_email')
    if not email:
        return redirect('auth:password-reset')

    last_sent = request.session.get('reset_last_sent', 0)
    now_ts = timezone.now().timestamp()
    if now_ts - last_sent < 60:
        wait_seconds = int(60 - (now_ts - last_sent))
        messages.warning(request, f"Please wait {wait_seconds} more second(s) before requesting a new code.")
        return redirect('auth:password-reset-verify')

    new_otp = f"{secrets.randbelow(900000) + 100000}"
    request.session['reset_otp'] = new_otp
    request.session['reset_expires'] = now_ts + (10 * 60)
    request.session['reset_attempts'] = 0
    request.session['reset_last_sent'] = now_ts

    subject = f"[InvenStock] Your New Password Reset Code: {new_otp}"
    context = {
        'otp': new_otp,
        'email': email,
        'expiry_minutes': 10
    }
    html_message = render_to_string('auth/password_reset_otp_email.html', context)
    plain_message = strip_tags(html_message)

    try:
        send_mail(
            subject,
            plain_message,
            settings.DEFAULT_FROM_EMAIL,
            [email],
            html_message=html_message,
            fail_silently=False
        )
        messages.success(request, f"A new verification code has been sent to {_mask_email(email)}.")
    except Exception as e:
        logger.error(f"Failed to resend password reset email to {email}: {e}")
        messages.error(request, "Unable to send verification email. Please check your internet connection or try again later.")

    return redirect('auth:password-reset-verify')


def forgot_password_set_password_view(request):
    """Step 3: Set and confirm new password."""
    if request.user.is_authenticated:
        return redirect('inventory:dashboard')

    email = request.session.get('reset_email')
    verified = request.session.get('reset_verified', False)

    if not email or not verified:
        messages.warning(request, "Please verify your code before resetting your password.")
        return redirect('auth:password-reset')

    if request.method == 'POST':
        form = ForgotPasswordSetPasswordForm(request.POST)
        if form.is_valid():
            new_password = form.cleaned_data['new_password1']
            user = User.objects.filter(email__iexact=email, is_active=True).first()
            if user:
                user.set_password(new_password)
                user.save()

                # Clean up session keys
                for k in ['reset_email', 'reset_otp', 'reset_expires', 'reset_attempts', 'reset_last_sent', 'reset_verified']:
                    request.session.pop(k, None)

                messages.success(request, "Your password has been reset successfully! Please sign in with your new password.")
                return redirect('auth:login')
            else:
                messages.error(request, "User account not found. Please try again.")
                return redirect('auth:password-reset')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = ForgotPasswordSetPasswordForm()

    return render(request, 'auth/password_reset_set_password.html', {'form': form, 'masked_email': _mask_email(email)})



def login_view(request):
    if request.user.is_authenticated:
        return redirect('inventory:dashboard')

    if request.GET.get('session_expired') == '1':
        existing_msgs = [m.message for m in messages.get_messages(request)]
        expected = "Your session has expired due to inactivity. Please log in again to continue."
        if expected not in existing_msgs:
            messages.warning(request, expected)

    if request.method == 'POST':
        username = (request.POST.get('username') or '').strip()
        password = request.POST.get('password') or ''

        if not username:
            messages.error(request, "Please enter your username.")
            return render(request, 'auth/login.html')

        if not password:
            messages.error(request, "Please enter your password.")
            return render(request, 'auth/login.html', {'entered_username': username})

        # Check if username exists in the system
        user_obj = User.objects.filter(username=username).first()
        if not user_obj:
            messages.error(request, f"No account found with username '{username}'. Please check your username or register.")
            return render(request, 'auth/login.html', {'entered_username': username})

        # Check if password is correct
        if not user_obj.check_password(password):
            messages.error(request, "Incorrect password. Please check your password and try again.")
            return render(request, 'auth/login.html', {'entered_username': username})

        # Check if account is active
        if user_obj.status != 'ACTIVE' or not user_obj.is_active:
            messages.error(request, f"Account '{username}' is currently inactive. Please contact your administrator.")
            return render(request, 'auth/login.html', {'entered_username': username})

        # Perform authentication & login
        user = authenticate(request, username=username, password=password)
        if user is not None:
            auth_login(request, user)
            request.session['last_activity'] = time.time()
            if getattr(user, 'must_change_password', False):
                messages.warning(
                    request,
                    "Welcome! You are using a temporary password. Please choose a new permanent password to continue."
                )
                return redirect('auth:change-password')

            messages.success(request, f"Welcome back, {user.get_full_name() or user.username}!")
            next_url = request.GET.get('next') or request.POST.get('next') or 'inventory:dashboard'
            return redirect(next_url)
        else:
            messages.error(request, "Authentication failed. Please verify your credentials and try again.")
            return render(request, 'auth/login.html', {'entered_username': username})

    return render(request, 'auth/login.html')


def session_keep_alive_view(request):
    """
    Heartbeat AJAX endpoint to reset inactivity timer when user clicks 'Stay Signed In'.
    """
    if not request.user.is_authenticated:
        return JsonResponse({'status': 'expired', 'message': 'Session expired.'}, status=401)

    now = time.time()
    request.session['last_activity'] = now
    timeout = getattr(settings, 'SESSION_IDLE_TIMEOUT', 1800)
    return JsonResponse({'status': 'ok', 'remaining': timeout})


def register_view(request):
    """Public self-registration. All self-registered users get STAFF role."""
    if request.user.is_authenticated:
        return redirect('inventory:dashboard')

    if request.method == 'POST':
        form = RegisterForm(request.POST)
        if form.is_valid():
            user = form.save()
            auth_login(request, user)
            messages.success(request, f"Welcome, {user.get_full_name() or user.username}! Your account has been created.")
            return redirect('inventory:dashboard')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = RegisterForm()
    return render(request, 'auth/register.html', {'form': form})


def logout_view(request):
    auth_logout(request)
    messages.info(request, "You have been safely logged out.")
    return redirect('auth:login')


@role_required('ADMIN', 'MANAGER', 'STAFF')
def profile_view(request):
    return render(request, 'auth/profile.html', {'user_profile': request.user})


@role_required('ADMIN', 'MANAGER', 'STAFF')
def profile_edit_view(request):
    if request.method == 'POST':
        form = ProfileEditForm(request.POST, request.FILES, instance=request.user)
        if form.is_valid():
            form.save()
            messages.success(request, "Profile updated successfully.")
            return redirect('auth:profile')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = ProfileEditForm(instance=request.user)
    return render(request, 'auth/profile_edit.html', {'form': form})


@role_required('ADMIN', 'MANAGER', 'STAFF')
def change_password_view(request):
    is_first_login = getattr(request.user, 'must_change_password', False)
    if request.method == 'POST':
        form = CustomPasswordChangeForm(request.user, request.POST)
        if form.is_valid():
            user = form.save()
            if getattr(user, 'must_change_password', False):
                user.must_change_password = False
                user.save(update_fields=['must_change_password'])
                update_session_auth_hash(request, user)
                messages.success(request, "Your password has been changed successfully! Welcome to your dashboard.")
                return redirect('inventory:dashboard')
            else:
                update_session_auth_hash(request, user)
                messages.success(request, "Password changed successfully.")
                return redirect('auth:profile')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = CustomPasswordChangeForm(request.user)

    template_name = 'auth/first_login_password.html' if is_first_login else 'auth/change_password.html'
    return render(request, template_name, {'form': form, 'is_first_login': is_first_login})


@role_required('ADMIN', 'MANAGER', 'STAFF')
def settings_view(request):
    return render(request, 'auth/settings.html')


# ─────────────────────────────────────────────
#  User Management (Admin & Manager)
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER')
def user_list_view(request):
    query = request.GET.get('q', '').strip()
    role_filter = request.GET.get('role', '').strip()
    status_filter = request.GET.get('status', '').strip()

    users = User.objects.all().order_by('-date_joined')
    if query:
        users = users.filter(
            Q(username__icontains=query) |
            Q(first_name__icontains=query) |
            Q(last_name__icontains=query) |
            Q(email__icontains=query)
        )
    if role_filter:
        users = users.filter(role=role_filter)
    if status_filter:
        users = users.filter(status=status_filter)

    context = {
        'users': users,
        'query': query,
        'role_filter': role_filter,
        'status_filter': status_filter,
        'role_choices': User.ROLE_CHOICES,
        'status_choices': User.STATUS_CHOICES,
    }
    return render(request, 'auth/user_list.html', context)


@role_required('ADMIN', 'MANAGER')
def user_create_view(request):
    if request.method == 'POST':
        form = UserCreateForm(request.POST)
        if form.is_valid():
            user = form.save()
            temp_password = getattr(form, 'temp_password', None)

            # Send email with credentials and temporary password to staff
            login_url = request.build_absolute_uri(reverse('auth:login'))
            subject = f"[InvenStock] Your Account Credentials - Welcome {user.first_name or user.username}!"
            context = {
                'user': user,
                'temp_password': temp_password,
                'login_url': login_url,
            }
            html_message = render_to_string('auth/staff_account_created_email.html', context)
            plain_message = strip_tags(html_message)

            email_sent = False
            try:
                send_mail(
                    subject,
                    plain_message,
                    settings.DEFAULT_FROM_EMAIL,
                    [user.email],
                    html_message=html_message,
                    fail_silently=False,
                )
                email_sent = True
            except Exception as e:
                logger.error(f"Failed to send staff account email to {user.email}: {e}")

            if email_sent:
                messages.success(
                    request,
                    f"User '{user.username}' created successfully! Account credentials and a temporary password have been sent to {user.email}."
                )
            else:
                messages.warning(
                    request,
                    f"User '{user.username}' created successfully! However, the notification email could not be sent. "
                    f"Generated temporary password: {temp_password}"
                )
            return redirect('auth:user-list')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = UserCreateForm()
    return render(request, 'auth/user_form.html', {'form': form, 'page_title': 'Create User', 'form_action': 'Create'})


@role_required('ADMIN', 'MANAGER')
def user_edit_view(request, pk):
    user = get_object_or_404(User, pk=pk)
    if request.method == 'POST':
        form = UserEditForm(request.POST, instance=user)
        if form.is_valid():
            form.save()
            messages.success(request, f"User '{user.username}' updated successfully.")
            return redirect('auth:user-list')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = UserEditForm(instance=user)
    return render(request, 'auth/user_form.html', {'form': form, 'user_obj': user, 'page_title': 'Edit User', 'form_action': 'Update'})


@role_required('ADMIN', 'MANAGER')
def user_toggle_status_view(request, pk):
    user = get_object_or_404(User, pk=pk)
    if user == request.user:
        messages.error(request, "You cannot deactivate your own account.")
        return redirect('auth:user-list')
    if request.method == 'POST':
        if user.status == 'ACTIVE':
            user.status = 'INACTIVE'
            messages.warning(request, f"User '{user.username}' has been deactivated.")
        else:
            user.status = 'ACTIVE'
            messages.success(request, f"User '{user.username}' has been activated.")
        user.save()
    return redirect('auth:user-list')


@role_required('ADMIN', 'MANAGER')
def user_detail_view(request, pk):
    """Admin view to inspect user details, profile information, and activity telemetry."""
    user_obj = get_object_or_404(User, pk=pk)
    from Apps.Inventory.models import InventoryLog

    recent_logs = InventoryLog.objects.filter(performed_by=user_obj).select_related(
        'product', 'source_location', 'destination_location'
    ).order_by('-created_at')[:15]
    total_logs = InventoryLog.objects.filter(performed_by=user_obj).count()

    context = {
        'user_obj': user_obj,
        'recent_logs': recent_logs,
        'total_logs': total_logs,
    }
    return render(request, 'auth/user_detail.html', context)


@role_required('ADMIN')
def user_delete_view(request, pk):
    """Admin view to delete a user account with safety checks."""
    user_to_delete = get_object_or_404(User, pk=pk)

    if user_to_delete == request.user:
        messages.error(request, "You cannot delete your own account.")
        return redirect('auth:user-list')

    if user_to_delete.is_superuser:
        superuser_count = User.objects.filter(is_superuser=True).count()
        if superuser_count <= 1:
            messages.error(request, "Cannot delete the sole administrator account.")
            return redirect('auth:user-list')

    if request.method == 'POST':
        deleted_username = user_to_delete.username
        user_to_delete.delete()
        messages.success(request, f"User '{deleted_username}' has been successfully deleted.")
        return redirect('auth:user-list')

    return render(request, 'auth/user_confirm_delete.html', {'user_obj': user_to_delete})