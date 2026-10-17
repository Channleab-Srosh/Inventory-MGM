from decimal import Decimal
from django import forms
from django.core.exceptions import ValidationError
from .models import Category, Supplier, Product, Location, InventoryLog


class CategoryForm(forms.ModelForm):
    class Meta:
        model = Category
        fields = ['name', 'description', 'status']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Category name'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'Optional description'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
        }


class LocationForm(forms.ModelForm):
    class Meta:
        model = Location
        fields = ['name', 'location_type']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'e.g. Main Warehouse'}),
            'location_type': forms.Select(attrs={'class': 'form-select'}),
        }


class SupplierForm(forms.ModelForm):
    class Meta:
        model = Supplier
        fields = ['name', 'contact_email', 'contact_phone', 'address', 'status']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'Supplier name'}),
            'contact_email': forms.EmailInput(attrs={'class': 'form-control', 'placeholder': 'supplier@example.com'}),
            'contact_phone': forms.TextInput(attrs={'class': 'form-control', 'placeholder': '+855 12 345 678'}),
            'address': forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'Full address'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
        }


class ProductForm(forms.ModelForm):
    def __init__(self, *args, **kwargs):
        super().__init__(*args, **kwargs)
        if 'category' in self.fields:
            self.fields['category'].empty_label = 'Select Category'
        if 'supplier' in self.fields:
            self.fields['supplier'].empty_label = 'Select Supplier'

    class Meta:
        model = Product
        fields = ['name', 'category', 'supplier', 'description', 'retail_price', 'cost_price', 'low_stock_alert', 'image', 'status']
        widgets = {
            'name': forms.TextInput(attrs={'class': 'form-control', 'placeholder': 'e.g. Wireless Ergonomic Mouse'}),
            'category': forms.Select(attrs={'class': 'form-select'}),
            'supplier': forms.Select(attrs={'class': 'form-select'}),
            'description': forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'e.g. High-precision 2.4GHz optical mouse with USB nano receiver'}),
            'retail_price': forms.NumberInput(attrs={'class': 'form-control', 'step': '0.01', 'min': '0', 'placeholder': '29.99'}),
            'cost_price': forms.NumberInput(attrs={'class': 'form-control', 'step': '0.01', 'min': '0', 'placeholder': '15.00'}),
            'low_stock_alert': forms.NumberInput(attrs={'class': 'form-control', 'min': '0', 'placeholder': '10'}),
            'image': forms.ClearableFileInput(attrs={'class': 'form-control'}),
            'status': forms.Select(attrs={'class': 'form-select'}),
        }

    def clean_retail_price(self):
        price = self.cleaned_data.get('retail_price')
        if price is not None and price < Decimal('0.00'):
            raise forms.ValidationError("Retail price cannot be negative.")
        return price

    def clean_cost_price(self):
        price = self.cleaned_data.get('cost_price')
        if price is not None and price < Decimal('0.00'):
            raise forms.ValidationError("Cost price cannot be negative.")
        return price

    def clean_low_stock_alert(self):
        alert = self.cleaned_data.get('low_stock_alert')
        if alert is not None and alert < 0:
            raise forms.ValidationError("Low stock alert threshold cannot be negative.")
        return alert


class StockInForm(forms.Form):
    product = forms.ModelChoiceField(
        queryset=Product.objects.filter(status='ACTIVE').order_by('name'),
        widget=forms.Select(attrs={'class': 'form-select', 'id': 'id_product'}),
        empty_label='Select Product'
    )
    location = forms.ModelChoiceField(
        queryset=Location.objects.all(),
        widget=forms.Select(attrs={'class': 'form-select'}),
        empty_label='Select Location'
    )
    quantity = forms.IntegerField(
        min_value=1,
        widget=forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'Enter quantity', 'min': '1'}),
        error_messages={'min_value': 'Quantity must be at least 1 and cannot be negative or zero.'}
    )
    reference_no = forms.CharField(
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter reference number (e.g. PO-20261017-001) or leave blank to auto-generate'
        }),
        help_text="Optional custom reference number. Leave blank to auto-generate."
    )
    note = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'Optional note about this stock-in'})
    )

    def clean_quantity(self):
        qty = self.cleaned_data.get('quantity')
        if qty is not None and qty <= 0:
            raise forms.ValidationError("Quantity must be greater than zero.")
        return qty


class StockOutForm(forms.Form):
    product = forms.ModelChoiceField(
        queryset=Product.objects.filter(status='ACTIVE').order_by('name'),
        widget=forms.Select(attrs={'class': 'form-select', 'id': 'id_product'}),
        empty_label='Select Product'
    )
    location = forms.ModelChoiceField(
        queryset=Location.objects.all(),
        widget=forms.Select(attrs={'class': 'form-select'}),
        empty_label='Select Location'
    )
    quantity = forms.IntegerField(
        min_value=1,
        widget=forms.NumberInput(attrs={'class': 'form-control', 'placeholder': 'Enter quantity', 'min': '1'}),
        error_messages={'min_value': 'Quantity must be at least 1 and cannot be negative or zero.'}
    )
    reference_no = forms.CharField(
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter reference number (e.g. SO-20241013-B7C1) or leave blank to auto-generate'
        }),
        help_text="Optional custom reference number. Leave blank to auto-generate."
    )
    note = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'Optional note about this stock-out'})
    )

    def clean_quantity(self):
        qty = self.cleaned_data.get('quantity')
        if qty is not None and qty <= 0:
            raise forms.ValidationError("Quantity must be greater than zero.")
        return qty


class StockAdjustmentForm(forms.Form):
    product = forms.ModelChoiceField(
        queryset=Product.objects.filter(status='ACTIVE').order_by('name'),
        widget=forms.Select(attrs={'class': 'form-select', 'id': 'id_product'}),
        empty_label='Select Product',
        error_messages={'required': 'Please select a product to audit.'}
    )
    location = forms.ModelChoiceField(
        queryset=Location.objects.all(),
        widget=forms.Select(attrs={'class': 'form-select', 'id': 'id_location'}),
        empty_label='Select Location',
        error_messages={'required': 'Please select a location.'}
    )
    new_quantity = forms.IntegerField(
        min_value=0,
        widget=forms.NumberInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter actual physical count',
            'min': '0',
            'id': 'id_new_quantity'
        }),
        error_messages={
            'required': 'Please enter the physical count verified on the shelf.',
            'min_value': 'Physical count cannot be negative (must be 0 or greater).'
        },
        help_text="Enter the actual physical count verified on the shelf (can be 0 or more)."
    )
    reference_no = forms.CharField(
        required=False,
        widget=forms.TextInput(attrs={
            'class': 'form-control',
            'placeholder': 'Enter reference number (e.g. ADJ-20261017-001) or leave blank to auto-generate'
        }),
        help_text="Optional custom reference number. Leave blank to auto-generate."
    )
    note = forms.CharField(
        required=False,
        widget=forms.Textarea(attrs={'class': 'form-control', 'rows': 3, 'placeholder': 'Reason for adjustment (e.g. Damaged during audit, shelf count discrepancy)'})
    )

    def clean_new_quantity(self):
        qty = self.cleaned_data.get('new_quantity')
        if qty is None:
            raise forms.ValidationError("Physical count cannot be empty.")
        if qty < 0:
            raise forms.ValidationError("Physical count cannot be negative (must be 0 or greater).")
        return qty

