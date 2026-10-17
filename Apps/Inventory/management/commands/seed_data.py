from django.core.management.base import BaseCommand
from django.utils import timezone
from datetime import timedelta
from decimal import Decimal
import uuid
from Apps.Auth.models import User
from Apps.Inventory.models import Category, Supplier, Location, Product, ProductLocation, InventoryLog


def _make_ref(prefix):
    return f"{prefix}-{timezone.now().strftime('%Y%m%d')}-{uuid.uuid4().hex[:4].upper()}"


class Command(BaseCommand):
    help = 'Seeds complete demo data supporting all inventory cases (In Stock, Low Stock, Out of Stock, Discontinued, Inactive, Multi-Location)'

    def handle(self, *args, **options):
        self.stdout.write(self.style.NOTICE("Starting comprehensive database demo seeding..."))

        # ─────────────────────────────────────────────
        # 1. Users
        # ─────────────────────────────────────────────
        users_data = [
            {'username': 'admin', 'email': 'admin@invenstock.com', 'role': 'ADMIN', 'first_name': 'System', 'last_name': 'Administrator', 'is_staff': True, 'is_superuser': True},
            {'username': 'manager', 'email': 'manager@invenstock.com', 'role': 'MANAGER', 'first_name': 'Sarah', 'last_name': 'Jenkins', 'is_staff': False, 'is_superuser': False},
            {'username': 'staff', 'email': 'staff@invenstock.com', 'role': 'STAFF', 'first_name': 'Alex', 'last_name': 'Rivera', 'is_staff': False, 'is_superuser': False},
        ]

        users = {}
        for u in users_data:
            user, created = User.objects.get_or_create(
                username=u['username'],
                defaults={
                    'email': u['email'],
                    'role': u['role'],
                    'first_name': u['first_name'],
                    'last_name': u['last_name'],
                    'status': 'ACTIVE',
                    'is_staff': u['is_staff'],
                    'is_superuser': u['is_superuser'],
                    'must_change_password': False,
                }
            )
            user.set_password('password123')
            user.role = u['role']
            user.status = 'ACTIVE'
            user.must_change_password = False
            user.is_staff = u['is_staff']
            user.is_superuser = u['is_superuser']
            user.save()
            users[u['username']] = user
            action = "Created" if created else "Updated"
            self.stdout.write(f" - {action} user: {user.username} ({user.role}) [Password: password123]")

        # ─────────────────────────────────────────────
        # 2. Categories
        # ─────────────────────────────────────────────
        categories_data = [
            {'name': 'Laptops & Computers', 'description': 'Workstations, gaming laptops, and mini PCs'},
            {'name': 'Monitors & Displays', 'description': 'Ultrawide, 4K UHD, and high refresh gaming monitors'},
            {'name': 'Keyboards & Mice', 'description': 'Mechanical keyboards, wireless mice, and desk accessories'},
            {'name': 'Audio & Headsets', 'description': 'Studio headphones, microphones, and speakers'},
            {'name': 'Networking & Storage', 'description': 'Wi-Fi 7 routers, NVMe SSDs, and external storage'},
            {'name': 'Accessories & Cables', 'description': 'Hubs, webcams, adapters, and mounting hardware'},
        ]
        categories = {}
        for cat_info in categories_data:
            cat, _ = Category.objects.get_or_create(name=cat_info['name'], defaults=cat_info)
            categories[cat_info['name']] = cat
        self.stdout.write(f" - Seeded {len(categories)} product categories.")

        # ─────────────────────────────────────────────
        # 3. Suppliers
        # ─────────────────────────────────────────────
        suppliers_data = [
            {'name': 'Apex Logistics & Tech', 'contact_email': 'contact@apexlogistics.io', 'contact_phone': '+1 (555) 234-5678'},
            {'name': 'Nordic Components Corp', 'contact_email': 'supply@nordiccorp.eu', 'contact_phone': '+44 20 7946 0912'},
            {'name': 'Pacific Rim Electronics', 'contact_email': 'orders@pacificrimelec.com', 'contact_phone': '+81 3 5555 0143'},
            {'name': 'Global Silicon Supplies Ltd', 'contact_email': 'sales@globalsilicon.com', 'contact_phone': '+1 (555) 890-1234'},
        ]
        suppliers = {}
        for s in suppliers_data:
            supp, _ = Supplier.objects.get_or_create(name=s['name'], defaults=s)
            suppliers[s['name']] = supp
        self.stdout.write(f" - Seeded {len(suppliers)} suppliers.")

        # ─────────────────────────────────────────────
        # 4. Multi-Location Storage Nodes
        # ─────────────────────────────────────────────
        locations_data = [
            {'name': 'Central Regional Hub (WH-01)', 'location_type': 'WAREHOUSE'},
            {'name': 'North Distribution Depot (WH-02)', 'location_type': 'WAREHOUSE'},
            {'name': 'Downtown Flagship Store (ST-01)', 'location_type': 'STORE'},
            {'name': 'Westfield Mall Store (ST-02)', 'location_type': 'STORE'},
        ]
        locations = {}
        for loc_data in locations_data:
            loc, _ = Location.objects.get_or_create(name=loc_data['name'], defaults=loc_data)
            locations[loc_data['name']] = loc

        wh_01 = locations['Central Regional Hub (WH-01)']
        wh_02 = locations['North Distribution Depot (WH-02)']
        st_01 = locations['Downtown Flagship Store (ST-01)']
        st_02 = locations['Westfield Mall Store (ST-02)']
        self.stdout.write(f" - Seeded {len(locations)} location storage nodes.")

        # ─────────────────────────────────────────────
        # 5. Products Supporting ALL Demo Cases
        # ─────────────────────────────────────────────
        demo_products = [
            # CASE 1: In Stock (Ample inventory across all warehouses & retail stores)
            {
                'sku': 'SKU-LAP-001',
                'name': 'Titan Ultra Pro Laptop 16"',
                'description': 'High-performance mobile workstation with 32GB RAM & 1TB NVMe SSD',
                'category': categories['Laptops & Computers'],
                'supplier': suppliers['Apex Logistics & Tech'],
                'retail_price': Decimal('1899.00'),
                'cost_price': Decimal('1250.00'),
                'low_stock_alert': 10,
                'status': 'ACTIVE',
                'stocks': {wh_01: 45, wh_02: 20, st_01: 6, st_02: 4},  # Total: 75 (> 10)
            },
            {
                'sku': 'SKU-KBD-003',
                'name': 'Mechanical RGB Wireless Keyboard',
                'description': 'Hot-swappable tactile switches with aircraft aluminum chassis',
                'category': categories['Keyboards & Mice'],
                'supplier': suppliers['Pacific Rim Electronics'],
                'retail_price': Decimal('129.50'),
                'cost_price': Decimal('65.00'),
                'low_stock_alert': 15,
                'status': 'ACTIVE',
                'stocks': {wh_01: 120, wh_02: 60, st_01: 25, st_02: 15},  # Total: 220 (> 15)
            },
            {
                'sku': 'SKU-MOU-004',
                'name': 'Precision Ergonomic Mouse',
                'description': 'Dual-mode Bluetooth/2.4GHz optical sensor with 26K DPI precision',
                'category': categories['Keyboards & Mice'],
                'supplier': suppliers['Pacific Rim Electronics'],
                'retail_price': Decimal('79.99'),
                'cost_price': Decimal('38.00'),
                'low_stock_alert': 20,
                'status': 'ACTIVE',
                'stocks': {wh_01: 80, wh_02: 40, st_01: 15, st_02: 5},  # Total: 140 (> 20)
            },

            # CASE 2: In Stock at Main Hub Only (Ideal for demonstrating Stock Transfer to stores)
            {
                'sku': 'SKU-NET-006',
                'name': 'Enterprise Wi-Fi 7 Mesh Router',
                'description': 'Tri-band gigabit mesh access point with 10Gbps WAN and enterprise security',
                'category': categories['Networking & Storage'],
                'supplier': suppliers['Apex Logistics & Tech'],
                'retail_price': Decimal('349.00'),
                'cost_price': Decimal('210.00'),
                'low_stock_alert': 8,
                'status': 'ACTIVE',
                'stocks': {wh_01: 60, wh_02: 0, st_01: 0, st_02: 0},  # Total: 60, stores empty
            },

            # CASE 3: Low Stock Alert (Stock <= Alert Threshold -> Yellow Warning Badge)
            {
                'sku': 'SKU-HDP-005',
                'name': 'Studio ANC Wireless Headphones',
                'description': 'Active noise-canceling over-ear studio headphones with 40-hour battery',
                'category': categories['Audio & Headsets'],
                'supplier': suppliers['Nordic Components Corp'],
                'retail_price': Decimal('249.00'),
                'cost_price': Decimal('140.00'),
                'low_stock_alert': 15,  # Alert threshold is 15, current total is 4!
                'status': 'ACTIVE',
                'stocks': {wh_01: 2, wh_02: 0, st_01: 2, st_02: 0},  # Total: 4 (<= 15) -> LOW STOCK
            },
            {
                'sku': 'SKU-SSD-007',
                'name': 'Pro Extreme 2TB NVMe SSD',
                'description': 'PCIe Gen 4.0 x4 internal solid state drive with 7450 MB/s read speed',
                'category': categories['Networking & Storage'],
                'supplier': suppliers['Global Silicon Supplies Ltd'],
                'retail_price': Decimal('189.99'),
                'cost_price': Decimal('115.00'),
                'low_stock_alert': 10,  # Alert threshold is 10, current total is 3!
                'status': 'ACTIVE',
                'stocks': {wh_01: 0, wh_02: 0, st_01: 2, st_02: 1},  # Total: 3 (<= 10) -> LOW STOCK
            },

            # CASE 4: Out of Stock (Total Stock == 0 -> Red Out-of-Stock Alert)
            {
                'sku': 'SKU-MON-002',
                'name': 'Curved 34" Gaming Monitor 165Hz',
                'description': 'Ultrawide Quad HD HDR Display with integrated USB-C 90W power delivery',
                'category': categories['Monitors & Displays'],
                'supplier': suppliers['Nordic Components Corp'],
                'retail_price': Decimal('499.99'),
                'cost_price': Decimal('320.00'),
                'low_stock_alert': 5,
                'status': 'ACTIVE',
                'stocks': {wh_01: 0, wh_02: 0, st_01: 0, st_02: 0},  # Total: 0 -> OUT OF STOCK
            },
            {
                'sku': 'SKU-WCH-008',
                'name': 'Ultra 4K Streamer Webcam',
                'description': 'HDR auto-framing 4K webcam with dual stereo noise-reduction microphones',
                'category': categories['Accessories & Cables'],
                'supplier': suppliers['Pacific Rim Electronics'],
                'retail_price': Decimal('119.00'),
                'cost_price': Decimal('62.00'),
                'low_stock_alert': 8,
                'status': 'ACTIVE',
                'stocks': {wh_01: 0, wh_02: 0, st_01: 0, st_02: 0},  # Total: 0 -> OUT OF STOCK
            },

            # CASE 5: Discontinued Product (Status='DISCONTINUED')
            {
                'sku': 'SKU-LEG-009',
                'name': 'Legacy VGA to DVI Adapter Cable',
                'description': 'End-of-life analog video adapter cable (retained for historic warranty stock)',
                'category': categories['Accessories & Cables'],
                'supplier': suppliers['Pacific Rim Electronics'],
                'retail_price': Decimal('19.99'),
                'cost_price': Decimal('5.00'),
                'low_stock_alert': 5,
                'status': 'DISCONTINUED',
                'stocks': {wh_01: 8, wh_02: 0, st_01: 0, st_02: 0},  # Total: 8, Discontinued
            },

            # CASE 6: Inactive / Seasonal Product (Status='INACTIVE' -> hidden from operational forms)
            {
                'sku': 'SKU-TMP-010',
                'name': 'Holiday RGB Lightbar Setup (Seasonal)',
                'description': 'Seasonal lighting setup (currently deactivated from active ordering cycles)',
                'category': categories['Accessories & Cables'],
                'supplier': suppliers['Apex Logistics & Tech'],
                'retail_price': Decimal('89.00'),
                'cost_price': Decimal('42.00'),
                'low_stock_alert': 10,
                'status': 'INACTIVE',
                'stocks': {wh_01: 25, wh_02: 0, st_01: 0, st_02: 0},  # Total: 25, Inactive
            },
        ]

        admin_user = users['admin']
        manager_user = users['manager']

        for p_info in demo_products:
            stocks_map = p_info.pop('stocks')
            sku = p_info['sku']

            product, _ = Product.objects.get_or_create(sku=sku, defaults=p_info)
            for field, val in p_info.items():
                setattr(product, field, val)
            product.save()

            # Set location stocks
            for loc, qty in stocks_map.items():
                pl, _ = ProductLocation.objects.get_or_create(
                    product=product,
                    location=loc,
                    defaults={'quantity': qty}
                )
                pl.quantity = qty
                pl.save()

            # Ensure zero stock for any locations not in stocks_map
            for loc in [wh_01, wh_02, st_01, st_02]:
                if loc not in stocks_map:
                    pl, _ = ProductLocation.objects.get_or_create(
                        product=product,
                        location=loc,
                        defaults={'quantity': 0}
                    )
                    pl.quantity = 0
                    pl.save()

            total_units = product.total_stock
            badge = product.stock_status
            self.stdout.write(f" - [{badge:12}] {product.sku}: {product.name} ({total_units} units, Status: {product.status})")

        # ─────────────────────────────────────────────
        # 6. Realistic Inventory Audit Logs
        # ─────────────────────────────────────────────
        # Add rich transaction logs for today & recent days if logs are sparse
        now = timezone.now()
        logs_to_create = [
            {
                'product': Product.objects.get(sku='SKU-LAP-001'),
                'quantity_changed': 20,
                'log_type': 'STOCK_IN',
                'source_location': None,
                'destination_location': wh_01,
                'reason': 'Direct shipment delivery from Apex Logistics (PO batch)',
                'reference_no': _make_ref('PO'),
                'performed_by': admin_user,
                'created_at': now - timedelta(hours=3),
            },
            {
                'product': Product.objects.get(sku='SKU-LAP-001'),
                'quantity_changed': -2,
                'log_type': 'STOCK_OUT',
                'source_location': st_01,
                'destination_location': None,
                'reason': 'Corporate bulk client checkout',
                'reference_no': _make_ref('SO'),
                'performed_by': manager_user,
                'created_at': now - timedelta(hours=1),
            },
            {
                'product': Product.objects.get(sku='SKU-KBD-003'),
                'quantity_changed': 15,
                'log_type': 'TRANSFER',
                'source_location': wh_01,
                'destination_location': st_01,
                'reason': 'Store replenishment to Flagship branch',
                'reference_no': _make_ref('TRF'),
                'performed_by': admin_user,
                'created_at': now - timedelta(minutes=45),
            },
            {
                'product': Product.objects.get(sku='SKU-HDP-005'),
                'quantity_changed': -4,
                'log_type': 'STOCK_OUT',
                'source_location': st_01,
                'destination_location': None,
                'reason': 'Retail weekend promotion customer checkout',
                'reference_no': _make_ref('SO'),
                'performed_by': manager_user,
                'created_at': now - timedelta(minutes=20),
            },
            {
                'product': Product.objects.get(sku='SKU-MON-002'),
                'quantity_changed': -10,
                'log_type': 'STOCK_OUT',
                'source_location': wh_01,
                'destination_location': None,
                'reason': 'Esports tournament order dispatch - depleted inventory',
                'reference_no': _make_ref('SO'),
                'performed_by': admin_user,
                'created_at': now - timedelta(days=1, hours=2),
            },
            {
                'product': Product.objects.get(sku='SKU-SSD-007'),
                'quantity_changed': -7,
                'log_type': 'STOCK_OUT',
                'source_location': st_01,
                'destination_location': None,
                'reason': 'Workstation upgrade hardware package sale',
                'reference_no': _make_ref('SO'),
                'performed_by': manager_user,
                'created_at': now - timedelta(days=2),
            },
        ]

        for log_data in logs_to_create:
            created_at = log_data.pop('created_at')
            log = InventoryLog.objects.create(**log_data)
            # Update created_at timestamp explicitly
            InventoryLog.objects.filter(id=log.id).update(created_at=created_at)

        self.stdout.write(self.style.SUCCESS("\n[OK] Demo database seeding completed successfully!"))
        self.stdout.write(self.style.SUCCESS("All test and demo cases are fully populated and active."))
