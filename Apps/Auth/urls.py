from django.urls import path
from . import views

app_name = 'auth'

urlpatterns = [
    path('login/', views.login_view, name='login'),
    path('register/', views.register_view, name='register'),
    path('logout/', views.logout_view, name='logout'),
    path('forgot-password/', views.forgot_password_request_view, name='password-reset'),
    path('forgot-password/verify/', views.forgot_password_verify_view, name='password-reset-verify'),
    path('forgot-password/resend/', views.forgot_password_resend_view, name='password-reset-resend'),
    path('forgot-password/set-password/', views.forgot_password_set_password_view, name='password-reset-set-password'),
    path('profile/', views.profile_view, name='profile'),
    path('profile/edit/', views.profile_edit_view, name='profile-edit'),
    path('profile/change-password/', views.change_password_view, name='change-password'),
    path('settings/', views.settings_view, name='settings'),
    path('users/', views.user_list_view, name='user-list'),
    path('users/create/', views.user_create_view, name='user-create'),
    path('users/<int:pk>/', views.user_detail_view, name='user-detail'),
    path('users/<int:pk>/edit/', views.user_edit_view, name='user-edit'),
    path('users/<int:pk>/delete/', views.user_delete_view, name='user-delete'),
    path('users/<int:pk>/toggle-status/', views.user_toggle_status_view, name='user-toggle-status'),
    path('session-keep-alive/', views.session_keep_alive_view, name='session-keep-alive'),
]
