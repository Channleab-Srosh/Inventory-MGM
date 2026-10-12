from django.contrib import admin
from .models import Category, Supplier, Location, Product, ProductLocation, InventoryLog


class ProductLocationInline(admin.TabularInline):
    model = ProductLocation
    extra = 1


@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ('name', 'status', 'created_at')
    search_fields = ('name',)
    list_filter = ('status',)


@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    list_display = ('name', 'contact_email', 'contact_phone')
    search_fields = ('name', 'contact_email')


@admin.register(Location)
class LocationAdmin(admin.ModelAdmin):
    list_display = ('name', 'location_type')
    list_filter = ('location_type',)
    search_fields = ('name',)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):
    list_display = ('sku', 'name', 'retail_price', 'cost_price', 'supplier', 'low_stock_alert')
    search_fields = ('sku', 'name')
    list_filter = ('supplier',)
    inlines = [ProductLocationInline]


@admin.register(ProductLocation)
class ProductLocationAdmin(admin.ModelAdmin):
    list_display = ('product', 'location', 'quantity')
    list_filter = ('location',)
    search_fields = ('product__name', 'product__sku', 'location__name')


@admin.register(InventoryLog)
class InventoryLogAdmin(admin.ModelAdmin):
    list_display = ('product', 'log_type', 'quantity_changed', 'source_location', 'destination_location', 'created_at')
    list_filter = ('log_type', 'created_at')
    search_fields = ('product__name', 'product__sku', 'reason')
    readonly_fields = ('created_at',)
