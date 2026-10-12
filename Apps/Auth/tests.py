from django.test import TestCase, Client
from django.urls import reverse
from django.contrib.auth import get_user_model

User = get_user_model()


class AuthModelAndAccessTests(TestCase):
    def setUp(self):
        self.admin_user = User.objects.create_superuser(
            username='admin_test',
            email='admin_test@example.com',
            password='AdminPass123!'
        )
        self.admin_user.role = 'ADMIN'
        self.admin_user.save()

        self.staff_user = User.objects.create_user(
            username='staff_test',
            email='staff_test@example.com',
            password='StaffPass123!',
            role='STAFF'
        )

    def test_superuser_has_access(self):
        client = Client()
        client.force_login(self.admin_user)
        response = client.get(reverse('auth:user-list'))
        self.assertEqual(response.status_code, 200)

    def test_staff_restricted_from_admin_views(self):
        client = Client()
        client.force_login(self.staff_user)
        response = client.get(reverse('auth:user-list'))
        self.assertEqual(response.status_code, 403)


class RegistrationTests(TestCase):
    def test_registration_creates_staff_user(self):
        client = Client()
        data = {
            'username': 'new_staff',
            'email': 'newstaff@example.com',
            'first_name': 'New',
            'last_name': 'Staff',
            'password1': 'StrongPass123!',
            'password2': 'StrongPass123!',
        }
        response = client.post(reverse('auth:register'), data)
        self.assertEqual(response.status_code, 302)

        user = User.objects.get(username='new_staff')
        self.assertEqual(user.role, 'STAFF')
        self.assertTrue(user.is_active)
        self.assertTrue(user.check_password('StrongPass123!'))

    def test_registration_password_mismatch(self):
        client = Client()
        data = {
            'username': 'new_staff_2',
            'email': 'newstaff2@example.com',
            'password1': 'StrongPass123!',
            'password2': 'DifferentPass123!',
        }
        response = client.post(reverse('auth:register'), data)
        self.assertEqual(response.status_code, 200)
        self.assertFalse(User.objects.filter(username='new_staff_2').exists())


class PasswordResetOtpTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='otp_user',
            email='otp_user@example.com',
            password='OldPassword123!',
            role='STAFF'
        )

    def test_otp_flow_end_to_end(self):
        client = Client()

        # Step 1: Request OTP
        req_res = client.post(reverse('auth:password-reset'), {'email': 'otp_user@example.com'})
        self.assertEqual(req_res.status_code, 302)
        otp = client.session.get('reset_otp')
        self.assertIsNotNone(otp)
        self.assertEqual(len(str(otp)), 6)

        # Step 2: Verify OTP
        verify_res = client.post(reverse('auth:password-reset-verify'), {'otp': otp})
        self.assertEqual(verify_res.status_code, 302)
        self.assertTrue(client.session.get('reset_verified'))

        # Step 3: Set New Password
        new_pass = 'NewPassword456!'
        set_res = client.post(reverse('auth:password-reset-set-password'), {
            'new_password1': new_pass,
            'new_password2': new_pass
        })
        self.assertEqual(set_res.status_code, 302)

        # Check authentication with new password
        self.user.refresh_from_db()
        self.assertTrue(self.user.check_password(new_pass))
