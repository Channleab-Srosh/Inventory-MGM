from django.shortcuts import render, redirect, get_object_or_404
from django.contrib.auth import authenticate, login as auth_login, logout as auth_logout, update_session_auth_hash
from django.contrib.auth import get_user_model
from django.contrib import messages
from django.contrib.auth import views as auth_views
from django.urls import reverse_lazy
from Apps.Auth.decorators import role_required
import secrets
from datetime import timedelta
from django.utils import timezone
from django.core.mail import send_mail
from django.template.loader import render_to_string
from django.utils.html import strip_tags
from django.conf import settings
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
                # Still allow user to verify (especially in local dev)
                messages.info(request, f"Verification code generated: {otp}")

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
        'dev_otp': expected_otp if settings.DEBUG else None
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
        messages.info(request, f"New verification code generated: {new_otp}")

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

    if request.method == 'POST':
        username = request.POST.get('username')
        password = request.POST.get('password')

        user = authenticate(request, username=username, password=password)
        if user is not None:
            if user.status == 'ACTIVE':
                auth_login(request, user)
                messages.success(request, f"Welcome back, {user.get_full_name() or user.username}!")
                next_url = request.GET.get('next') or request.POST.get('next') or 'inventory:dashboard'
                return redirect(next_url)
            else:
                messages.error(request, "Your account is currently inactive. Contact your administrator.")
        else:
            messages.error(request, "Invalid username or password. Please try again.")

    return render(request, 'auth/login.html')


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
    if request.method == 'POST':
        form = CustomPasswordChangeForm(request.user, request.POST)
        if form.is_valid():
            user = form.save()
            update_session_auth_hash(request, user)
            messages.success(request, "Password changed successfully.")
            return redirect('auth:profile')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = CustomPasswordChangeForm(request.user)
    return render(request, 'auth/change_password.html', {'form': form})


@role_required('ADMIN', 'MANAGER', 'STAFF')
def settings_view(request):
    return render(request, 'auth/settings.html')


# ─────────────────────────────────────────────
#  User Management (Admin only)
# ─────────────────────────────────────────────
@role_required('ADMIN')
def user_list_view(request):
    users = User.objects.all().order_by('-date_joined')
    context = {'users': users}
    return render(request, 'auth/user_list.html', context)


@role_required('ADMIN')
def user_create_view(request):
    if request.method == 'POST':
        form = UserCreateForm(request.POST)
        if form.is_valid():
            user = form.save()
            messages.success(request, f"User '{user.username}' created successfully.")
            return redirect('auth:user-list')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = UserCreateForm()
    return render(request, 'auth/user_form.html', {'form': form, 'page_title': 'Create User', 'form_action': 'Create'})


@role_required('ADMIN')
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


@role_required('ADMIN')
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