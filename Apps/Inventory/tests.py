from django.test import TestCase, Client
from django.urls import reverse
from django.core.exceptions import ValidationError
from django.db.models import Count
from django.contrib.auth import get_user_model
from Apps.Inventory.models import Category, Supplier, Location, Product, ProductLocation, InventoryLog
from Apps.Inventory.services import InventoryService

User = get_user_model()


class InventoryServiceTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='inventory_admin',
            email='inv_admin@example.com',
            password='AdminPassword123!',
            role='ADMIN'
        )
        self.category = Category.objects.create(name='Hardware', status='ACTIVE')
        self.supplier = Supplier.objects.create(name='Global Tech', status='ACTIVE')
        self.loc_warehouse = Location.objects.create(name='Main Warehouse', location_type='WAREHOUSE')
        self.loc_store = Location.objects.create(name='Retail Store 1', location_type='STORE')

        self.product = Product.objects.create(
            sku='TEST-SKU-001',
            name='Test Product 1',
            category=self.category,
            supplier=self.supplier,
            retail_price=99.99,
            cost_price=50.00,
            status='ACTIVE'
        )

    def test_intake_stock(self):
        res = InventoryService.intake_stock(
            product_id=self.product.id,
            location_id=self.loc_warehouse.id,
            quantity=50,
            user=self.admin,
            reference_no='INTAKE-001'
        )
        self.assertTrue(res['success'])
        stock = ProductLocation.objects.get(product=self.product, location=self.loc_warehouse)
        self.assertEqual(stock.quantity, 50)
        self.assertTrue(InventoryLog.objects.filter(reference_no='INTAKE-001', log_type='STOCK_IN').exists())

    def test_transfer_stock(self):
        # Initial stock in warehouse
        InventoryService.intake_stock(
            product_id=self.product.id,
            location_id=self.loc_warehouse.id,
            quantity=30,
            user=self.admin
        )
        # Transfer 10 to retail store
        res = InventoryService.transfer_stock(
            product_id=self.product.id,
            source_location_id=self.loc_warehouse.id,
            destination_location_id=self.loc_store.id,
            quantity=10,
            user=self.admin,
            reference_no='TR-001'
        )
        self.assertTrue(res['success'])
        wh_stock = ProductLocation.objects.get(product=self.product, location=self.loc_warehouse)
        store_stock = ProductLocation.objects.get(product=self.product, location=self.loc_store)
        self.assertEqual(wh_stock.quantity, 20)
        self.assertEqual(store_stock.quantity, 10)
        self.assertTrue(InventoryLog.objects.filter(reference_no='TR-001', log_type='TRANSFER').exists())

    def test_transfer_insufficient_stock_fails(self):
        InventoryService.intake_stock(
            product_id=self.product.id,
            location_id=self.loc_warehouse.id,
            quantity=5,
            user=self.admin
        )
        with self.assertRaises(ValidationError):
            InventoryService.transfer_stock(
                product_id=self.product.id,
                source_location_id=self.loc_warehouse.id,
                destination_location_id=self.loc_store.id,
                quantity=50,
                user=self.admin
            )

    def test_checkout_stock(self):
        InventoryService.intake_stock(
            product_id=self.product.id,
            location_id=self.loc_store.id,
            quantity=15,
            user=self.admin
        )
        res = InventoryService.checkout_stock(
            product_id=self.product.id,
            location_id=self.loc_store.id,
            quantity=5,
            user=self.admin,
            reference_no='SALE-001'
        )
        self.assertTrue(res['success'])
        store_stock = ProductLocation.objects.get(product=self.product, location=self.loc_store)
        self.assertEqual(store_stock.quantity, 10)
        self.assertTrue(InventoryLog.objects.filter(reference_no='SALE-001', log_type='STOCK_OUT').exists())

    def test_checkout_overdraft_fails(self):
        InventoryService.intake_stock(
            product_id=self.product.id,
            location_id=self.loc_store.id,
            quantity=5,
            user=self.admin
        )
        with self.assertRaises(ValidationError):
            InventoryService.checkout_stock(
                product_id=self.product.id,
                location_id=self.loc_store.id,
                quantity=100,
                user=self.admin
            )


class InventoryViewsAndExportsTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='admin_views',
            email='admin_views@example.com',
            password='Password123!',
            role='ADMIN'
        )
        self.staff = User.objects.create_user(
            username='staff_views',
            email='staff_views@example.com',
            password='Password123!',
            role='STAFF'
        )
        self.category = Category.objects.create(name='Electronics')
        self.supplier = Supplier.objects.create(name='Micro Corp')
        self.product = Product.objects.create(
            sku='SKU-99',
            name='Gadget',
            category=self.category,
            supplier=self.supplier,
            retail_price=20.00,
            cost_price=10.00
        )

    def test_category_and_supplier_annotation(self):
        cat = Category.objects.annotate(product_count=Count('products')).get(id=self.category.id)
        self.assertEqual(cat.product_count, 1)

        sup = Supplier.objects.annotate(product_count=Count('products')).get(id=self.supplier.id)
        self.assertEqual(sup.product_count, 1)

    def test_export_views(self):
        client = Client()
        client.force_login(self.admin)

        for export_url, content_type_sub in [
            ('/reports/export/excel/', 'spreadsheetml'),
            ('/reports/export/pdf/', 'pdf'),
            ('/reports/export/csv/', 'csv'),
            ('/products/export/excel/', 'spreadsheetml'),
            ('/products/export/csv/', 'csv'),
        ]:
            response = client.get(export_url)
            self.assertEqual(response.status_code, 200, f"Failed on {export_url}")
            self.assertIn(content_type_sub, response['Content-Type'], f"Wrong type on {export_url}")

    def test_staff_restricted_views(self):
        client = Client()
        client.force_login(self.staff)

        # Staff cannot access product-add
        res = client.get(reverse('inventory:product-add'))
        self.assertEqual(res.status_code, 403)
