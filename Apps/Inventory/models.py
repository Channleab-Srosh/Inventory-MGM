from django.db import models
from django.conf import settings


class Category(models.Model):
    """Product category for organizing inventory items."""
    STATUS_CHOICES = (
        ('ACTIVE', 'Active'),
        ('INACTIVE', 'Inactive'),
    )
    name = models.CharField(max_length=100, unique=True)
    description = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='ACTIVE')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        verbose_name_plural = 'Categories'
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def product_count(self):
        if hasattr(self, '_product_count'):
            return self._product_count
        return self.products.count()

    @product_count.setter
    def product_count(self, value):
        self._product_count = value


class Supplier(models.Model):
    """Supplier/vendor information for products."""
    STATUS_CHOICES = (
        ('ACTIVE', 'Active'),
        ('INACTIVE', 'Inactive'),
    )
    name = models.CharField(max_length=150, unique=True)
    contact_email = models.EmailField(blank=True, null=True)
    contact_phone = models.CharField(max_length=30, blank=True, null=True)
    address = models.TextField(blank=True, null=True)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='ACTIVE')
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def product_count(self):
        if hasattr(self, '_product_count'):
            return self._product_count
        return self.products.count()

    @product_count.setter
    def product_count(self, value):
        self._product_count = value


class Location(models.Model):
    """Warehouse or store location node."""
    TYPE_CHOICES = (
        ('WAREHOUSE', 'Warehouse Node'),
        ('STORE', 'Retail Store Front'),
    )
    name = models.CharField(max_length=100, unique=True)
    location_type = models.CharField(max_length=20, choices=TYPE_CHOICES)

    def __str__(self):
        return f"{self.name} ({self.get_location_type_display()})"


class Product(models.Model):
    """Core product/SKU record."""
    STATUS_CHOICES = (
        ('ACTIVE', 'Active'),
        ('INACTIVE', 'Inactive'),
        ('DISCONTINUED', 'Discontinued'),
    )
    sku = models.CharField(max_length=50, unique=True)
    name = models.CharField(max_length=100)
    description = models.TextField(blank=True, null=True)
    category = models.ForeignKey(
        Category, on_delete=models.SET_NULL, null=True, blank=True, related_name='products'
    )
    supplier = models.ForeignKey(
        Supplier, on_delete=models.SET_NULL, null=True, blank=True, related_name='products'
    )
    retail_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    cost_price = models.DecimalField(max_digits=10, decimal_places=2, default=0.00)
    low_stock_alert = models.IntegerField(default=5)
    image = models.ImageField(upload_to='products/', blank=True, null=True)
    status = models.CharField(max_length=15, choices=STATUS_CHOICES, default='ACTIVE')
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ['name']

    def __str__(self):
        return f"{self.sku} - {self.name}"

    @property
    def total_stock(self):
        return sum(stock.quantity for stock in self.stocks.all())

    @property
    def stock_status(self):
        total = self.total_stock
        if total == 0:
            return 'OUT_OF_STOCK'
        elif total <= self.low_stock_alert:
            return 'LOW_STOCK'
        return 'IN_STOCK'


class ProductLocation(models.Model):
    """Stock quantity at a specific location node."""
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='stocks')
    location = models.ForeignKey(Location, on_delete=models.CASCADE, related_name='stocks')
    quantity = models.PositiveIntegerField(default=0)

    class Meta:
        unique_together = ('product', 'location')

    def __str__(self):
        return f"{self.product.name} @ {self.location.name}: {self.quantity}"


class InventoryLog(models.Model):
    """Immutable audit log for all stock transactions."""
    LOG_TYPES = (
        ('STOCK_IN', 'Intake'),
        ('STOCK_OUT', 'Sale Checkout'),
        ('TRANSFER', 'Internal Relocation'),
        ('ADJUSTMENT', 'Manual Check'),
    )
    product = models.ForeignKey(Product, on_delete=models.CASCADE, related_name='logs')
    quantity_changed = models.IntegerField()
    log_type = models.CharField(max_length=20, choices=LOG_TYPES)
    source_location = models.ForeignKey(
        Location,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='log_sources'
    )
    destination_location = models.ForeignKey(
        Location,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='log_destinations'
    )
    reference_no = models.CharField(max_length=50, blank=True, null=True)
    reason = models.TextField(blank=True, null=True)
    performed_by = models.ForeignKey(
        settings.AUTH_USER_MODEL,
        on_delete=models.SET_NULL,
        null=True,
        blank=True,
        related_name='inventory_logs'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ['-created_at']

    def __str__(self):
        return f"[{self.log_type}] {self.product.sku} ({self.quantity_changed}) at {self.created_at:%Y-%m-%d %H:%M}"
