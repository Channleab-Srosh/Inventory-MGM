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

    def test_staff_does_not_see_empty_actions_column_in_categories_and_locations(self):
        client = Client()
        client.force_login(self.staff)

        # In categories, staff should NOT see Actions table header
        cat_res = client.get(reverse('inventory:category-list'))
        self.assertEqual(cat_res.status_code, 200)
        self.assertNotContains(cat_res, '<th>Actions</th>')

        # In locations, staff should NOT see Actions table header
        loc_res = client.get(reverse('inventory:location-list'))
        self.assertEqual(loc_res.status_code, 200)
        self.assertNotContains(loc_res, '<th>Actions</th>')

        # Admin DOES see Actions table header
        client.force_login(self.admin)
        cat_admin = client.get(reverse('inventory:category-list'))
        self.assertContains(cat_admin, '<th>Actions</th>')
        loc_admin = client.get(reverse('inventory:location-list'))
        self.assertContains(loc_admin, '<th>Actions</th>')


from decimal import Decimal
from Apps.Inventory.forms import ProductForm, StockInForm, StockOutForm


class NegativeValidationTests(TestCase):
    def setUp(self):
        self.category = Category.objects.create(name='Test Category')
        self.loc = Location.objects.create(name='Test Loc', location_type='WAREHOUSE')
        self.product = Product.objects.create(
            name='Test Valid Product',
            retail_price=Decimal('10.00'),
            cost_price=Decimal('5.00'),
            low_stock_alert=5
        )

    def test_product_negative_retail_price_model(self):
        prod = Product(name='Bad Retail', retail_price=Decimal('-1.00'), cost_price=Decimal('5.00'))
        with self.assertRaises(ValidationError):
            prod.full_clean()

    def test_product_negative_cost_price_model(self):
        prod = Product(name='Bad Cost', retail_price=Decimal('10.00'), cost_price=Decimal('-0.50'))
        with self.assertRaises(ValidationError):
            prod.full_clean()

    def test_product_negative_low_stock_alert_model(self):
        prod = Product(name='Bad Alert', low_stock_alert=-5)
        with self.assertRaises(ValidationError):
            prod.full_clean()

    def test_product_form_rejects_negative_prices(self):
        form = ProductForm(data={
            'name': 'Negative Form Test',
            'retail_price': '-15.00',
            'cost_price': '-5.00',
            'low_stock_alert': '-2',
            'status': 'ACTIVE',
        })
        self.assertFalse(form.is_valid())
        self.assertIn('retail_price', form.errors)
        self.assertIn('cost_price', form.errors)
        self.assertIn('low_stock_alert', form.errors)

    def test_stock_in_form_rejects_negative_or_zero_quantity(self):
        form_zero = StockInForm(data={'product': self.product.id, 'location': self.loc.id, 'quantity': 0})
        self.assertFalse(form_zero.is_valid())
        self.assertIn('quantity', form_zero.errors)

        form_neg = StockInForm(data={'product': self.product.id, 'location': self.loc.id, 'quantity': -10})
        self.assertFalse(form_neg.is_valid())
        self.assertIn('quantity', form_neg.errors)

    def test_stock_out_form_rejects_negative_or_zero_quantity(self):
        form_zero = StockOutForm(data={'product': self.product.id, 'location': self.loc.id, 'quantity': 0})
        self.assertFalse(form_zero.is_valid())
        self.assertIn('quantity', form_zero.errors)

        form_neg = StockOutForm(data={'product': self.product.id, 'location': self.loc.id, 'quantity': -5})
        self.assertFalse(form_neg.is_valid())
        self.assertIn('quantity', form_neg.errors)

    def test_transfer_stock_rejects_negative_quantity(self):
        loc2 = Location.objects.create(name='Dest Loc', location_type='STORE')
        with self.assertRaises(ValidationError):
            InventoryService.transfer_stock(
                product_id=self.product.id,
                source_location_id=self.loc.id,
                destination_location_id=loc2.id,
                quantity=-5
            )


class StockOutCustomReferenceNumberTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_superuser(
            username='stock_boss',
            email='stock_boss@example.com',
            password='AdminPassword123!',
            role='ADMIN'
        )
        self.loc = Location.objects.create(name='Warehouse Alpha', location_type='WAREHOUSE')
        self.product = Product.objects.create(name='Widget Alpha', status='ACTIVE')
        ProductLocation.objects.create(product=self.product, location=self.loc, quantity=100)

    def test_stock_out_with_custom_reference_number(self):
        client = Client()
        client.force_login(self.user)

        custom_ref = 'CUSTOM-SO-99988'
        response = client.post(reverse('inventory:stock-out'), {
            'product': self.product.id,
            'location': self.loc.id,
            'quantity': 10,
            'reference_no': custom_ref,
            'note': 'Sold to VIP customer'
        }, follow=True)

        self.assertEqual(response.status_code, 200)
        log = InventoryLog.objects.filter(reference_no=custom_ref).first()
        self.assertIsNotNone(log)
        self.assertEqual(log.product, self.product)
        self.assertEqual(log.quantity_changed, -10)

    def test_stock_out_auto_generates_reference_when_blank(self):
        client = Client()
        client.force_login(self.user)

        response = client.post(reverse('inventory:stock-out'), {
            'product': self.product.id,
            'location': self.loc.id,
            'quantity': 5,
            'reference_no': '',
            'note': 'Blank reference test'
        }, follow=True)

        self.assertEqual(response.status_code, 200)
        # Should have auto-generated reference with prefix SO-
        log = InventoryLog.objects.filter(product=self.product, quantity_changed=-5).first()
        self.assertIsNotNone(log)
        self.assertTrue(log.reference_no.startswith('SO-'))


class StockAuditAdjustmentTests(TestCase):
    def setUp(self):
        self.admin = User.objects.create_superuser(
            username='adj_admin',
            email='adj_admin@example.com',
            password='AdminPassword123!',
            role='ADMIN'
        )
        self.manager = User.objects.create_user(
            username='adj_manager',
            email='adj_manager@example.com',
            password='ManagerPassword123!',
            role='MANAGER'
        )
        self.staff = User.objects.create_user(
            username='adj_staff',
            email='adj_staff@example.com',
            password='StaffPassword123!',
            role='STAFF'
        )
        self.location = Location.objects.create(name='Audit Warehouse', location_type='WAREHOUSE')
        self.product = Product.objects.create(name='Audit Product', status='ACTIVE')
        ProductLocation.objects.create(product=self.product, location=self.location, quantity=25)

    def test_stock_adjust_successful(self):
        client = Client()
        client.force_login(self.manager)

        response = client.post(reverse('inventory:stock-adjust'), {
            'product': self.product.id,
            'location': self.location.id,
            'new_quantity': 22,
            'reference_no': 'ADJ-AUDIT-01',
            'note': 'Found 3 broken units during shelf audit'
        }, follow=True)

        self.assertEqual(response.status_code, 200)
        stock = ProductLocation.objects.get(product=self.product, location=self.location)
        self.assertEqual(stock.quantity, 22)

        log = InventoryLog.objects.get(reference_no='ADJ-AUDIT-01')
        self.assertEqual(log.log_type, 'ADJUSTMENT')
        self.assertEqual(log.quantity_changed, -3)
        self.assertEqual(log.performed_by, self.manager)

    def test_stock_adjust_negative_validation_rejected(self):
        client = Client()
        client.force_login(self.admin)

        response = client.post(reverse('inventory:stock-adjust'), {
            'product': self.product.id,
            'location': self.location.id,
            'new_quantity': -5,
            'note': 'Invalid count'
        })

        # Form should be invalid and not update stock
        stock = ProductLocation.objects.get(product=self.product, location=self.location)
        self.assertEqual(stock.quantity, 25)
        self.assertFalse(InventoryLog.objects.filter(quantity_changed=-30).exists())

    def test_staff_cannot_access_stock_adjust(self):
        client = Client()
        client.force_login(self.staff)

        # GET request by staff should be forbidden / 403
        response = client.get(reverse('inventory:stock-adjust'))
        self.assertEqual(response.status_code, 403)


