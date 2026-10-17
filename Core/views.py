from django.shortcuts import render, redirect
from Apps.Auth.decorators import role_required


@role_required('ADMIN', 'MANAGER', 'STAFF')
def dashboard(request):
    return redirect('inventory:dashboard')