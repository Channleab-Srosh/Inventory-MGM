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


class SessionIdleTimeoutAndLoginRequiredTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(
            username='active_staff',
            email='active_staff@example.com',
            password='StaffPass123!',
            role='STAFF'
        )

    def test_first_open_website_requires_login(self):
        """Visiting root URL '/' unauthenticated must redirect directly to login page."""
        client = Client()
        response = client.get('/', follow=False)
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, '/login/')

    def test_protected_page_redirects_to_login_with_next(self):
        """Visiting a protected page unauthenticated must redirect to /login/?next=..."""
        client = Client()
        response = client.get('/products/', follow=False)
        self.assertEqual(response.status_code, 302)
        self.assertTrue(response.url.startswith('/login/?next=/products/'))

    def test_public_pages_accessible_unauthenticated(self):
        """Public pages like login and forgot password must be accessible without login."""
        client = Client()
        res_login = client.get('/login/')
        self.assertEqual(res_login.status_code, 200)
        res_forgot = client.get('/forgot-password/')
        self.assertEqual(res_forgot.status_code, 200)

    def test_authenticated_user_access_and_last_activity_updated(self):
        """Authenticated user gets 200 and last_activity is recorded in session."""
        client = Client()
        client.force_login(self.user)
        response = client.get('/')
        self.assertEqual(response.status_code, 200)
        self.assertIn('last_activity', client.session)

    def test_session_idle_timeout_expires_inactive_user(self):
        """User session expires after inactivity limit and redirects to login."""
        import time
        client = Client()
        client.force_login(self.user)

        # Manually set last_activity to 2 hours ago (exceeding 30m timeout)
        session = client.session
        session['last_activity'] = time.time() - 7200
        session.save()

        # Making a request after timeout triggers logout
        response = client.get('/products/', follow=False)
        self.assertEqual(response.status_code, 302)
        self.assertTrue(response.url.startswith('/login/?next=/products/'))

        # Verify user is logged out
        self.assertNotIn('_auth_user_id', client.session)

    def test_session_keep_alive_endpoint(self):
        """Keep-alive heartbeat updates last_activity for authenticated user."""
        client = Client()
        # Unauthenticated keep-alive returns 401
        res_anon = client.get('/session-keep-alive/')
        self.assertEqual(res_anon.status_code, 401)

        # Authenticated keep-alive returns 200 OK
        client.force_login(self.user)
        res_auth = client.get('/session-keep-alive/')
        self.assertEqual(res_auth.status_code, 200)
        data = res_auth.json()
        self.assertEqual(data.get('status'), 'ok')


class LoginSpecificAlertsTests(TestCase):
    def setUp(self):
        self.active_user = User.objects.create_user(
            username='valid_user',
            email='valid_user@example.com',
            password='ValidPassword123!',
            status='ACTIVE'
        )
        self.inactive_user = User.objects.create_user(
            username='inactive_user',
            email='inactive@example.com',
            password='ValidPassword123!',
            status='INACTIVE'
        )

    def test_missing_username_alert(self):
        client = Client()
        response = client.post('/login/', {'username': '', 'password': 'somepassword'}, follow=True)
        messages_text = [m.message for m in response.context['messages']]
        self.assertTrue(any('enter your username' in m.lower() for m in messages_text))

    def test_missing_password_alert(self):
        client = Client()
        response = client.post('/login/', {'username': 'valid_user', 'password': ''}, follow=True)
        messages_text = [m.message for m in response.context['messages']]
        self.assertTrue(any('enter your password' in m.lower() for m in messages_text))

    def test_username_does_not_exist_alert(self):
        client = Client()
        response = client.post('/login/', {'username': 'ghost_user', 'password': 'anypassword'}, follow=True)
        messages_text = [m.message for m in response.context['messages']]
        self.assertTrue(any('no account found with username' in m.lower() for m in messages_text))

    def test_incorrect_password_alert(self):
        client = Client()
        response = client.post('/login/', {'username': 'valid_user', 'password': 'WrongPassword999'}, follow=True)
        messages_text = [m.message for m in response.context['messages']]
        self.assertTrue(any('incorrect password' in m.lower() for m in messages_text))

    def test_inactive_account_alert(self):
        client = Client()
        response = client.post('/login/', {'username': 'inactive_user', 'password': 'ValidPassword123!'}, follow=True)
        messages_text = [m.message for m in response.context['messages']]
        self.assertTrue(any('inactive' in m.lower() for m in messages_text))

    def test_successful_login(self):
        client = Client()
        response = client.post('/login/', {'username': 'valid_user', 'password': 'ValidPassword123!'}, follow=False)
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, '/')


class AdminUserViewDeleteTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin_boss',
            email='admin_boss@example.com',
            password='AdminPassword123!',
            role='ADMIN'
        )
        self.staff = User.objects.create_user(
            username='target_worker',
            email='target_worker@example.com',
            password='WorkerPass123!',
            role='STAFF'
        )

    def test_admin_can_view_user_detail(self):
        client = Client()
        client.force_login(self.admin)
        response = client.get(f'/users/{self.staff.pk}/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'target_worker')

    def test_staff_cannot_view_user_detail(self):
        client = Client()
        client.force_login(self.staff)
        response = client.get(f'/users/{self.admin.pk}/')
        self.assertEqual(response.status_code, 403)

    def test_admin_can_delete_user(self):
        client = Client()
        client.force_login(self.admin)
        response = client.post(f'/users/{self.staff.pk}/delete/', follow=True)
        self.assertEqual(response.status_code, 200)
        self.assertFalse(User.objects.filter(pk=self.staff.pk).exists())

    def test_admin_cannot_delete_self(self):
        client = Client()
        client.force_login(self.admin)
        response = client.post(f'/users/{self.admin.pk}/delete/', follow=True)
        self.assertEqual(response.status_code, 200)
        self.assertTrue(User.objects.filter(pk=self.admin.pk).exists())
        messages_text = [m.message for m in response.context['messages']]
        self.assertTrue(any('cannot delete your own account' in m.lower() for m in messages_text))

    def test_staff_cannot_delete_user(self):
        client = Client()
        client.force_login(self.staff)
        response = client.post(f'/users/{self.admin.pk}/delete/', follow=True)
        self.assertEqual(response.status_code, 403)
        self.assertTrue(User.objects.filter(pk=self.admin.pk).exists())


from django.core import mail
from django.core.exceptions import ValidationError
from Apps.Auth.validators import validate_strong_password, generate_strong_temporary_password


class StrongPasswordValidationTests(TestCase):
    def test_valid_strong_password(self):
        # Should not raise ValidationError
        try:
            validate_strong_password("SecurePass#2026!")
        except ValidationError:
            self.fail("validate_strong_password unexpectedly raised ValidationError on a valid password!")

    def test_password_too_short(self):
        with self.assertRaises(ValidationError) as ctx:
            validate_strong_password("Aa1!")
        self.assertTrue("at least 8 characters" in str(ctx.exception))

    def test_password_missing_uppercase(self):
        with self.assertRaises(ValidationError) as ctx:
            validate_strong_password("lowercase123!@#")
        self.assertTrue("uppercase letter" in str(ctx.exception))

    def test_password_missing_lowercase(self):
        with self.assertRaises(ValidationError) as ctx:
            validate_strong_password("UPPERCASE123!@#")
        self.assertTrue("lowercase letter" in str(ctx.exception))

    def test_password_missing_number(self):
        with self.assertRaises(ValidationError) as ctx:
            validate_strong_password("LettersOnly!@#$")
        self.assertTrue("one number" in str(ctx.exception))

    def test_password_missing_special_char(self):
        with self.assertRaises(ValidationError) as ctx:
            validate_strong_password("NoSpecialChar123")
        self.assertTrue("special character" in str(ctx.exception))

    def test_generated_temporary_password_satisfies_strength(self):
        for _ in range(10):
            temp_pass = generate_strong_temporary_password(12)
            self.assertGreaterEqual(len(temp_pass), 12)
            try:
                validate_strong_password(temp_pass)
            except ValidationError as e:
                self.fail(f"Generated password '{temp_pass}' failed strength validation: {e}")


class AdminCreateUserAutoPasswordAndEmailTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin_boss',
            email='admin_boss@example.com',
            password='AdminPassword123!',
            role='ADMIN'
        )

    def test_admin_create_user_generates_password_and_sends_email(self):
        client = Client()
        client.force_login(self.admin)

        mail.outbox.clear()
        post_data = {
            'username': 'new_staff_member',
            'first_name': 'John',
            'last_name': 'Doe',
            'email': 'newstaff@example.com',
            'role': 'STAFF',
            'status': 'ACTIVE',
        }
        response = client.post('/users/create/', post_data, follow=True)
        self.assertEqual(response.status_code, 200)

        # Check user created in database
        new_user = User.objects.filter(username='new_staff_member').first()
        self.assertIsNotNone(new_user)
        self.assertEqual(new_user.email, 'newstaff@example.com')
        self.assertTrue(new_user.must_change_password)

        # Check welcome email sent to staff
        self.assertEqual(len(mail.outbox), 1)
        sent_email = mail.outbox[0]
        self.assertIn('newstaff@example.com', sent_email.to)
        self.assertIn('Your Account Credentials', sent_email.subject)
        self.assertIn('new_staff_member', sent_email.body)
        self.assertIn('temporary password', sent_email.body.lower())


class FirstLoginForcePasswordChangeTests(TestCase):
    def setUp(self):
        # Create user with temporary password and must_change_password=True
        self.temp_pass = generate_strong_temporary_password(12)
        self.staff_user = User.objects.create_user(
            username='temp_staff',
            email='temp_staff@example.com',
            password=self.temp_pass,
            role='STAFF',
            status='ACTIVE'
        )
        self.staff_user.must_change_password = True
        self.staff_user.save()

    def test_login_redirects_to_change_password_on_first_login(self):
        client = Client()
        response = client.post('/login/', {
            'username': 'temp_staff',
            'password': self.temp_pass
        }, follow=False)
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, '/profile/change-password/')

    def test_cannot_access_dashboard_while_must_change_password(self):
        client = Client()
        client.force_login(self.staff_user)

        # Try to visit root/dashboard
        response = client.get('/', follow=False)
        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, '/profile/change-password/')

    def test_submitting_weak_password_fails(self):
        client = Client()
        client.force_login(self.staff_user)

        response = client.post('/profile/change-password/', {
            'old_password': self.temp_pass,
            'new_password1': 'weakpass',
            'new_password2': 'weakpass',
        }, follow=True)
        self.assertEqual(response.status_code, 200)

        # User must still have must_change_password=True
        self.staff_user.refresh_from_db()
        self.assertTrue(self.staff_user.must_change_password)

    def test_submitting_strong_password_clears_must_change_password(self):
        client = Client()
        client.force_login(self.staff_user)

        new_strong_pass = 'BrandNewP@ssw0rd!2026'
        response = client.post('/profile/change-password/', {
            'old_password': self.temp_pass,
            'new_password1': new_strong_pass,
            'new_password2': new_strong_pass,
        }, follow=False)

        self.assertEqual(response.status_code, 302)
        self.assertEqual(response.url, '/')

        self.staff_user.refresh_from_db()
        self.assertFalse(self.staff_user.must_change_password)
        self.assertTrue(self.staff_user.check_password(new_strong_pass))


class UserManagementViewAndFilterTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin_filter_user',
            email='admin_filter@example.com',
            password='AdminPassword123!',
            role='ADMIN'
        )
        self.manager = User.objects.create_user(
            username='manager_user',
            email='manager@example.com',
            password='ManagerPass123!',
            role='MANAGER'
        )
        self.staff = User.objects.create_user(
            username='staff_alice',
            first_name='Alice',
            last_name='Wonder',
            email='alice@example.com',
            password='StaffPass123!',
            role='STAFF',
            status='ACTIVE'
        )
        self.inactive_staff = User.objects.create_user(
            username='staff_bob',
            first_name='Bob',
            last_name='Builder',
            email='bob@example.com',
            password='StaffPass123!',
            role='STAFF',
            status='INACTIVE'
        )

    def test_admin_and_manager_can_view_user_detail(self):
        client = Client()
        for user in [self.admin, self.manager]:
            client.force_login(user)
            response = client.get(f'/users/{self.staff.pk}/')
            self.assertEqual(response.status_code, 200)
            self.assertContains(response, 'Alice Wonder')
            self.assertContains(response, 'alice@example.com')

    def test_user_list_search_and_filter(self):
        client = Client()
        client.force_login(self.admin)

        # Search by name/username
        res = client.get('/users/?q=Alice')
        self.assertEqual(res.status_code, 200)
        self.assertContains(res, 'Alice')
        self.assertNotContains(res, 'Bob Builder')

        # Filter by role
        res = client.get('/users/?role=MANAGER')
        self.assertEqual(res.status_code, 200)
        self.assertContains(res, 'manager_user')
        self.assertNotContains(res, 'staff_alice')

        # Filter by status
        res = client.get('/users/?status=INACTIVE')
        self.assertEqual(res.status_code, 200)
        self.assertContains(res, 'staff_bob')
        self.assertNotContains(res, 'staff_alice')




