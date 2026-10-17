from django.contrib.auth.models import AbstractUser
from django.db import models


class User(AbstractUser):
    ROLE_CHOICES = (
        ('ADMIN', 'Administrator'),
        ('MANAGER', 'Warehouse Manager'),
        ('STAFF', 'Staff'),
    )
    STATUS_CHOICES = (
        ('ACTIVE', 'Active'),
        ('INACTIVE', 'Inactive'),
    )
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='STAFF')
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='ACTIVE')
    profile_picture = models.ImageField(upload_to='profiles/', blank=True, null=True)
    phone = models.CharField(max_length=20, blank=True, null=True)
    must_change_password = models.BooleanField(
        default=False,
        help_text="Designates whether the user must change their password on next login."
    )

    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"