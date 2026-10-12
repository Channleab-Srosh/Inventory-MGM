# Project Handover & Progress Document: JolNaPu (InvenStock)

> **Document Created:** October 10, 2026  
> **Repository:** `stock_inventory_django_final`  
> **Current Working Branch:** `develop/leab`  
> **Status:** Work Preserved & Handover Ready  

---

## 1. Project Overview & Technology Stack

**JolNaPu (InvenStock)** is a multi-location stock and inventory management web application developed in Python and Django. The platform manages end-to-end supply chain logistics across warehouse depots and retail storefronts, featuring atomic inter-node stock transfers, stock intakes, retail sales deductions, telemetry audit logs, and analytics reports.

### Technology Stack
* **Language & Framework:** Python 3.13, Django 5.x
* **Database:** SQLite 3 (`db.sqlite3` for local development); MySQL (`mysqlclient`) / PostgreSQL (`psycopg2-binary`) compatible
* **Configuration:** `python-decouple` (`.env`)
* **Frontend:** Django Templates, Bootstrap 5.3, Bootstrap Icons (`bi`), Material Design Icons (`mdi`), Chart.js
* **Reporting & Exports:** `openpyxl` (Excel .xlsx), `reportlab` (PDF generation), Python standard `csv`
* **Email System:** Django `django.core.mail` with SMTP backend (Gmail TLS configured)
* **Image Processing:** `Pillow` (Product images and user profile pictures)

---

## 2. Original Requirements & Feature Roadmap

The system was conceived to provide:
1. **Multi-Location Inventory Architecture**: Track discrete inventory counts per SKU across multiple physical locations (Warehouses and Stores) using an intermediate relation (`ProductLocation`).
2. **Transaction Integrity (Concurrency-Safe)**: Atomic transactions with row-level locks (`select_for_update()`) to prevent race conditions during concurrent stock intakes, sales, and inter-location transfers.
3. **Role-Based Access Control (RBAC)**:
   * **ADMIN (Administrator)**: Unrestricted access, system user management, locations, and catalog configuration.
   * **MANAGER (Warehouse Manager)**: Catalog management, stock intakes, transfers, and report generation.
   * **STAFF (Store Cashier / Staff)**: Stock deductions (sales), catalog viewing, self-profile management.
4. **Audit Trail & Telemetry**: Immutable logging (`InventoryLog`) capturing every quantity delta, source location, destination location, operator, timestamp, and reference number.
5. **Analytics & Automated Reporting**: Dynamic dashboard KPI metrics, low-stock notifications, stock movement timeline charts, and multi-format exports (Excel, PDF, CSV).
6. **Authentication & User Lifecycle**: Login, logout, self-registration for staff, profile updates with avatars, password change, and OTP-based email password recovery.

---

## 3. Feature Status Breakdown

Each feature is marked according to strict verification standards:

| Feature / Subsystem | Status | Verification & Notes |
| :--- | :---: | :--- |
| **Custom User Model & RBAC** | `COMPLETED` | Custom `User` model inheriting `AbstractUser` with `ROLE_CHOICES` ('ADMIN', 'MANAGER', 'STAFF'), status flag, phone, profile avatar. Role-based view decorator `@role_required` functioning properly. |
| **Core Database Schema** | `COMPLETED` | `Category`, `Supplier`, `Location`, `Product`, `ProductLocation`, and `InventoryLog` defined with proper foreign keys, constraints, and cascading rules. |
| **Database Migrations** | `COMPLETED` | All migrations applied (`Auth: 0001, 0002`, `Inventory: 0001, 0002`). Schema is up-to-date in `db.sqlite3`. |
| **Data Seeder CLI Command** | `COMPLETED` | `python manage.py seed_data` populates sample locations, suppliers, products, product stocks, and test accounts. |
| **Stock Transfer Engine** | `COMPLETED` | Verified in `Apps.Inventory.services.InventoryService.transfer_stock`. Uses `@transaction.atomic` and `select_for_update()`. Prevents overdrafts and records `InventoryLog`. |
| **Stock Intake / Stock In** | `COMPLETED` | Verified in `InventoryService.intake_stock` and `stock_in_view`. Updates location stock and creates `STOCK_IN` log. |
| **Stock Deduct / Stock Out** | `COMPLETED` | Verified in `InventoryService.checkout_stock` and `stock_out_view`. Prevents negative inventory and creates `STOCK_OUT` log. |
| **Audit Logs / Stock History** | `COMPLETED` | Verified at `/stock-history/`. Filters by date range, transaction type, and SKU search. |
| **Dashboard Analytics & KPIs** | `COMPLETED` | Verified at `/`. Displays SKU counts, total stock units across locations, low-stock alert counters, out-of-stock counters, and 7-day movement chart. |
| **Export Engine (Reports: Excel, PDF, CSV)** | `COMPLETED` | Verified at `/reports/export/excel/`, `/reports/export/pdf/`, `/reports/export/csv/`. File streams return HTTP 200 with complete data tables. |
| **Export Engine (Products: Excel, CSV)** | `COMPLETED` | Verified at `/products/export/excel/`, `/products/export/csv/`. File streams return HTTP 200 with product list and quantities. |
| **User Authentication (Login / Logout)** | `COMPLETED` | Standard session-based login and logout verified. |
| **User Profile & Password Change** | `COMPLETED` | Profile view (`/profile/`), profile edit (`/profile/edit/`), and change password (`/profile/change-password/`) verified HTTP 200 for authenticated user. |
| **User Self-Registration** | `COMPLETED` | Verified end-to-end. Submits `/register/` -> creates active user with role `STAFF` -> redirects cleanly. |
| **Password Reset via 6-Digit OTP** | `COMPLETED` | Verified end-to-end. Step 1 generates 6-digit OTP -> Step 2 verifies OTP with session verification flag -> Step 3 resets password -> user successfully signs in with new password. |
| **User Management View (`/users/`)** | `COMPLETED` | Verified HTTP 200 for ADMIN. Access restricted from STAFF (returns HTTP 403 Forbidden). |
| **Supplier Listing View (`/suppliers/`)** | `COMPLETED` | Verified HTTP 200. Resolved `product_count` annotation clash via model property setter. |
| **Category Listing View (`/categories/`)** | `COMPLETED` | Verified HTTP 200. Resolved `product_count` annotation clash via model property setter. Registered in Django Admin. |
| **Automated Test Suite (Unit/Integration)** | `NOT STARTED` | `Ran 0 tests in 0.000s`. No unit or regression tests currently exist in `Apps/Auth/tests.py` or `Apps/Inventory/tests.py`. |
| **Barcode / QR Code Generation & Scanning** | `NOT STARTED` | Not yet started. |
| **Automated Low-Stock Email Alerts** | `NOT STARTED` | Not yet started. |

---

## 4. Tracked File Changes & New Assets

### Modified Working Files
* [`Apps/Auth/forms.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Auth/forms.py): Added `RegisterForm`, `CustomPasswordResetForm`, `CustomSetPasswordForm`, `ForgotPasswordRequestForm`, `ForgotPasswordVerifyOtpForm`, and `ForgotPasswordSetPasswordForm`.
* [`Apps/Auth/urls.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Auth/urls.py): Added paths for `register`, `password-reset`, `password-reset-verify`, `password-reset-resend`, `password-reset-set-password`.
* [`Apps/Auth/views.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Auth/views.py): Added `register_view`, `forgot_password_request_view`, `forgot_password_verify_view`, `forgot_password_resend_view`, `forgot_password_set_password_view`. *(Note: missing `User = get_user_model()` at module scope).*
* [`Apps/Inventory/urls.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/urls.py): Added export URL routes for reports (Excel, PDF, CSV) and products (Excel, CSV).
* [`Apps/Inventory/views.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/views.py): Added `_get_report_data` helper and export view functions (`export_reports_excel_view`, `export_reports_pdf_view`, `export_reports_csv_view`, `export_products_excel_view`, `export_products_csv_view`).
* [`Core/templates/auth/login.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/login.html): Connected "Forgot password?" link to `auth:password-reset` and added "Sign Up" link to `auth:register`.
* [`Core/templates/inventory/product_list.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/inventory/product_list.html): Added dropdown menu for Excel and CSV product exports.
* [`Core/templates/inventory/reports.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/inventory/reports.html): Activated action buttons for Excel, PDF, and CSV reports with query parameters.
* [`StockInventory/settings.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/StockInventory/settings.py): Added Gmail SMTP settings and decouple fallbacks.
* [`requirements.txt`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/requirements.txt): Appended `openpyxl>=3.1.0` and `reportlab>=4.0.0`.

### Newly Created Files (Untracked)
* [`Apps/Inventory/exports.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/exports.py): Complete export generator module supporting styled Excel workbooks, custom PDF report tables, and standard CSV format.
* [`Core/templates/auth/register.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/register.html): User-facing self-service registration template for staff accounts.
* [`Core/templates/auth/password_reset.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset.html): Step 1 email input page for OTP reset.
* [`Core/templates/auth/password_reset_verify.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset_verify.html): Step 2 6-digit OTP code entry with countdown and resend button.
* [`Core/templates/auth/password_reset_set_password.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset_set_password.html): Step 3 new password entry with confirmation and validation indicators.
* [`Core/templates/auth/password_reset_otp_email.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset_otp_email.html): Styled HTML email template containing OTP verification code.
* [`Core/templates/auth/password_reset_complete.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset_complete.html): Django fallback reset template.
* [`Core/templates/auth/password_reset_confirm.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset_confirm.html): Django fallback reset template.
* [`Core/templates/auth/password_reset_done.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset_done.html): Django fallback reset template.
* [`Core/templates/auth/password_reset_email.html`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset_email.html): Django fallback reset template.
* [`Core/templates/auth/password_reset_subject.txt`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Core/templates/auth/password_reset_subject.txt): Fallback reset subject text.

---

## 5. Existing Project Architecture & Folder Structure

```
stock_inventory_django_final/
├── manage.py                          # Django management script
├── requirements.txt                   # Project package dependencies
├── .env                               # Environment configurations (secret key, DB, email)
├── db.sqlite3                         # Local SQLite database
├── PROJECT_PROGRESS.md                # Project handover document (this file)
│
├── StockInventory/                    # Project Configuration Package
│   ├── settings.py                    # Installed apps, auth model, DB, email backend
│   ├── urls.py                        # Root URL router
│   ├── wsgi.py                        # WSGI entry point
│   └── asgi.py                        # ASGI entry point
│
├── Apps/                              # Modular Django Apps
│   ├── Auth/                          # Authentication & Access Control
│   │   ├── models.py                  # Custom User model (role, status, profile)
│   │   ├── forms.py                   # Profile, Password, Registration, and OTP forms
│   │   ├── views.py                   # Auth flows, OTP views, User CRUD
│   │   ├── urls.py                    # /login/, /register/, /forgot-password/, /profile/, /users/
│   │   ├── decorators.py              # @role_required decorator
│   │   ├── admin.py                   # CustomUserAdmin
│   │   └── migrations/                # 0001_initial, 0002_model_updates
│   │
│   └── Inventory/                     # Inventory Management Core Domain
│       ├── models.py                  # Category, Supplier, Location, Product, ProductLocation, InventoryLog
│       ├── forms.py                   # CategoryForm, SupplierForm, ProductForm, StockInForm, StockOutForm, LocationForm
│       ├── views.py                   # Dashboard, catalog, stock in/out/transfer, history, exports
│       ├── services.py                # Concurrency-safe business logic (select_for_update)
│       ├── exports.py                 # Multi-format report and product generators (Excel, PDF, CSV)
│       ├── urls.py                    # Root / routes and inventory endpoints
│       ├── admin.py                   # Admin registrations for models
│       ├── migrations/                # 0001_initial, 0002_model_updates
│       └── management/commands/
│           └── seed_data.py           # Database demo seed utility
│
└── Core/                              # UI Presentation & Static Assets
    ├── views.py                       # Legacy core dashboard view
    ├── urls.py                        # /core/ routes
    ├── templates/                     # Global & application templates
    │   ├── core/                      # base.html, base-auth.html, navbar, sidebar
    │   ├── auth/                      # Login, register, profile, settings, OTP templates
    │   └── inventory/                 # Dashboard, products, forms, transfer, history, reports
    └── static/                        # CSS, JS, Vendor plugins, images
```

---

## 6. API Endpoints & Routes Overview

| Path | Name | Method | Allowed Roles | Description | Status |
| :--- | :--- | :---: | :---: | :--- | :---: |
| `/` | `inventory:dashboard` | GET | Authenticated | Main KPI dashboard & charts | `COMPLETED` |
| `/products/` | `inventory:product-list` | GET | ADMIN, MANAGER, STAFF | Product catalog with filters | `COMPLETED` |
| `/products/add/` | `inventory:product-add` | GET, POST | ADMIN, MANAGER | Create new product SKU | `COMPLETED` |
| `/products/<pk>/` | `inventory:product-detail`| GET | ADMIN, MANAGER, STAFF | Product details & locations | `COMPLETED` |
| `/products/<pk>/edit/` | `inventory:product-edit` | GET, POST | ADMIN, MANAGER | Edit product details | `COMPLETED` |
| `/products/<pk>/delete/`| `inventory:product-delete`| POST | ADMIN | Delete product | `COMPLETED` |
| `/products/export/excel/`| `inventory:products-export-excel`| GET | ADMIN, MANAGER, STAFF | Download products spreadsheet | `COMPLETED` |
| `/products/export/csv/` | `inventory:products-export-csv` | GET | ADMIN, MANAGER, STAFF | Download products CSV | `COMPLETED` |
| `/categories/` | `inventory:category-list`| GET | ADMIN, MANAGER, STAFF | List categories | `IN PROGRESS` |
| `/categories/add/` | `inventory:category-add` | POST | ADMIN, MANAGER | Create category | `COMPLETED` |
| `/categories/<pk>/edit/`| `inventory:category-edit`| POST | ADMIN, MANAGER | Edit category | `COMPLETED` |
| `/categories/<pk>/delete/`| `inventory:category-delete`| POST | ADMIN | Delete category | `COMPLETED` |
| `/suppliers/` | `inventory:supplier-list`| GET | ADMIN, MANAGER, STAFF | List suppliers | `IN PROGRESS` (Crash) |
| `/suppliers/add/` | `inventory:supplier-add` | GET, POST | ADMIN, MANAGER | Create supplier | `COMPLETED` |
| `/suppliers/<pk>/` | `inventory:supplier-detail`| GET | ADMIN, MANAGER, STAFF | Supplier detail & products | `COMPLETED` |
| `/suppliers/<pk>/edit/`| `inventory:supplier-edit`| GET, POST | ADMIN, MANAGER | Edit supplier | `COMPLETED` |
| `/suppliers/<pk>/delete/`| `inventory:supplier-delete`| POST | ADMIN | Delete supplier | `COMPLETED` |
| `/locations/` | `inventory:location-list`| GET | ADMIN, MANAGER, STAFF | List locations | `COMPLETED` |
| `/locations/add/` | `inventory:location-add` | POST | ADMIN, MANAGER | Create warehouse/store | `COMPLETED` |
| `/locations/<pk>/edit/`| `inventory:location-edit`| POST | ADMIN, MANAGER | Edit location | `COMPLETED` |
| `/locations/<pk>/delete/`| `inventory:location-delete`| POST | ADMIN | Delete unused location | `COMPLETED` |
| `/stock-in/` | `inventory:stock-in` | GET, POST | ADMIN, MANAGER | Record stock intake | `COMPLETED` |
| `/stock-out/` | `inventory:stock-out` | GET, POST | ADMIN, MANAGER, STAFF | Record sale checkout | `COMPLETED` |
| `/transfer/` | `inventory:transfer` | GET, POST | ADMIN, MANAGER | Inter-location transfer | `COMPLETED` |
| `/stock-history/` | `inventory:stock-history`| GET | ADMIN, MANAGER, STAFF | Filterable audit logs | `COMPLETED` |
| `/reports/` | `inventory:reports` | GET | ADMIN, MANAGER, STAFF | Analytics reports | `COMPLETED` |
| `/reports/export/excel/`| `inventory:reports-export-excel`| GET | ADMIN, MANAGER, STAFF | Download reports Excel | `COMPLETED` |
| `/reports/export/pdf/` | `inventory:reports-export-pdf` | GET | ADMIN, MANAGER, STAFF | Download reports PDF | `COMPLETED` |
| `/reports/export/csv/` | `inventory:reports-export-csv` | GET | ADMIN, MANAGER, STAFF | Download reports CSV | `COMPLETED` |
| `/login/` | `auth:login` | GET, POST | Anonymous | User sign in | `COMPLETED` |
| `/register/` | `auth:register` | GET, POST | Anonymous | Staff registration | `NEEDS TESTING` |
| `/logout/` | `auth:logout` | POST, GET | Authenticated | Sign out session | `COMPLETED` |
| `/forgot-password/` | `auth:password-reset` | GET, POST | Anonymous | Request 6-digit OTP | `IN PROGRESS` (Crash) |
| `/forgot-password/verify/` | `auth:password-reset-verify` | GET, POST | Anonymous | Verify OTP | `IN PROGRESS` |
| `/forgot-password/resend/` | `auth:password-reset-resend` | POST, GET | Anonymous | Resend OTP (60s cooldown) | `IN PROGRESS` |
| `/forgot-password/set-password/` | `auth:password-reset-set-password` | GET, POST | Anonymous | Reset to new password | `IN PROGRESS` (Crash) |
| `/profile/` | `auth:profile` | GET | Authenticated | View profile | `COMPLETED` |
| `/profile/edit/` | `auth:profile-edit` | GET, POST | Authenticated | Edit profile & avatar | `COMPLETED` |
| `/profile/change-password/` | `auth:change-password` | GET, POST | Authenticated | Change current password | `COMPLETED` |
| `/settings/` | `auth:settings` | GET | Authenticated | User settings view | `COMPLETED` |
| `/users/` | `auth:user-list` | GET | ADMIN | List system users | `COMPLETED` |
| `/users/create/` | `auth:user-create` | GET, POST | ADMIN | Admin creates user | `COMPLETED` |

---

## 7. Database Models & Schema

### `Apps.Auth`
1. **`User` (extends `AbstractUser`)**:
   * Fields: `role` (ADMIN, MANAGER, STAFF), `status` (ACTIVE, INACTIVE), `profile_picture` (ImageField), `phone` (CharField).

### `Apps.Inventory`
1. **`Category`**:
   * Fields: `name`, `description`, `status` (ACTIVE, INACTIVE), `created_at`.
   * Property: `product_count` (with setter supporting annotations).
2. **`Supplier`**:
   * Fields: `name`, `contact_email`, `contact_phone`, `address`, `status`, `created_at`.
   * Property: `product_count` (with setter supporting annotations).
3. **`Location`**:
   * Fields: `name`, `location_type` (WAREHOUSE, STORE).
4. **`Product`**:
   * Fields: `sku`, `name`, `description`, `category` (FK), `supplier` (FK), `retail_price`, `cost_price`, `low_stock_alert`, `image`, `status`, timestamps.
   * Properties: `total_stock`, `stock_status` ('OUT_OF_STOCK', 'LOW_STOCK', 'IN_STOCK').
5. **`ProductLocation`** (`unique_together = ('product', 'location')`):
   * Fields: `product` (FK), `location` (FK), `quantity` (PositiveIntegerField).
6. **`InventoryLog`**:
   * Fields: `product` (FK), `quantity_changed` (IntegerField), `log_type` (STOCK_IN, STOCK_OUT, TRANSFER, ADJUSTMENT), `source_location` (FK), `destination_location` (FK), `reference_no`, `reason`, `performed_by` (FK User), `created_at`.

---

## 8. Current Errors & Known Issues

### Resolved in Current Session
* [x] **Issue 1 Fixed**: `NameError: name 'User' is not defined` resolved by defining `User = get_user_model()` in [`Apps/Auth/views.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Auth/views.py#L21).
* [x] **Issue 2 Fixed**: `AttributeError: property 'product_count' of 'Supplier' object has no setter` resolved by adding `@product_count.setter` to both `Category` and `Supplier` in [`Apps/Inventory/models.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/models.py).
* [x] **Issue 3 Fixed**: `Category` registered with `@admin.register(Category)` in [`Apps/Inventory/admin.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/admin.py).
* [x] **decorators.py Fixed**: Replaced direct `request.user.role` access with safe `getattr(request.user, 'role', None)` in [`Apps/Auth/decorators.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Auth/decorators.py).

### Remaining Open Tasks
1. **Automated Test Suite**: Formal test cases in `Apps/Inventory/tests.py` and `Apps/Auth/tests.py` (currently using CLI test scripts).
2. **Barcode / QR Code Generation**: Planned for subsequent release.

---

## 9. Testing Completed & Testing Still Required

### Completed Verification
* [x] `manage.py check` runs cleanly with 0 syntax/configuration issues.
* [x] `showmigrations` verified: all migrations in `Auth` and `Inventory` are applied.
* [x] Django Test Client verification for authenticated user (`admin`):
  * Dashboard (`/`): 200 OK
  * Product list (`/products/`): 200 OK
  * Product add form (`/products/add/`): 200 OK
  * Category list (`/categories/`): 200 OK
  * Supplier list (`/suppliers/`): 200 OK
  * Location list (`/locations/`): 200 OK
  * Stock In (`/stock-in/`): 200 OK
  * Stock Out (`/stock-out/`): 200 OK
  * Stock Transfer (`/transfer/`): 200 OK
  * Stock History (`/stock-history/`): 200 OK
  * Reports analytics (`/reports/`): 200 OK
  * Export Reports to Excel (`/reports/export/excel/`): 200 OK
  * Export Reports to PDF (`/reports/export/pdf/`): 200 OK
  * Export Reports to CSV (`/reports/export/csv/`): 200 OK
  * Export Products to Excel (`/products/export/excel/`): 200 OK
  * Export Products to CSV (`/products/export/csv/`): 200 OK
  * Profile pages (`/profile/`, `/profile/edit/`, `/profile/change-password/`): 200 OK
  * User management (`/users/`, `/users/create/`): 200 OK
* [x] Django Test Client verification for unauthenticated user:
  * Login page (`/login/`): 200 OK
  * Register page (`/register/`): 200 OK
  * Forgot Password page (`/forgot-password/`): 200 OK
* [x] Role-Based Access Control (RBAC) Enforcement:
  * Staff accessing `/users/` -> 403 Forbidden (verified)
  * Staff accessing `/products/add/` -> 403 Forbidden (verified)
* [x] End-to-End Registration Workflow:
  * Form POST to `/register/` -> Creates active user with role `STAFF` -> 302 Redirect (verified)
* [x] End-to-End 6-Digit OTP Password Reset Workflow:
  * Step 1: POST email to `/forgot-password/` -> OTP generated in session (verified)
  * Step 2: POST OTP to `/forgot-password/verify/` -> Validates correctly and sets `reset_verified` (verified)
  * Step 3: POST new password to `/forgot-password/set-password/` -> Updates user password and clears session (verified)
  * Step 4: Login with updated password -> Authenticates successfully (verified)
* [x] Concurrency-Safe Stock Transactions:
  * `InventoryService.intake_stock` (verified)
  * `InventoryService.transfer_stock` (verified)
  * `InventoryService.checkout_stock` (verified)

### Testing Still Required
* [ ] Formal unit test runner integration (`python manage.py test`) in CI/CD pipeline.

---

## 10. Exact Next Steps to Continue Development

When resuming in the next AI session, execute the following specific steps:

1. **Step 1: Fix `User` NameError in `Apps/Auth/views.py`**
   * Add `User = get_user_model()` directly below the imports in [`Apps/Auth/views.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Auth/views.py#L20).
   * Verify that `/users/` loads with HTTP 200.
2. **Step 2: Fix `product_count` Conflict in `Supplier` and `Category`**
   * Inspect [`Apps/Inventory/models.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/models.py#L24) and [`Apps/Inventory/views.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/views.py#L253).
   * Remove or rename the conflicting `@property def product_count` or change the annotation name so it doesn't collide with the property without a setter.
   * Verify `/suppliers/` and `/categories/` load with HTTP 200.
3. **Step 3: Test and Validate the OTP Password Reset Flow**
   * Test sending OTP, verifying code, and updating the password using Django test client or browser.
4. **Step 4: Register `Category` in Django Admin**
   * Add `@admin.register(Category)` in [`Apps/Inventory/admin.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/admin.py).
5. **Step 5: Write Core Automated Unit Tests**
   * Add test cases covering `InventoryService.transfer_stock`, `checkout_stock`, `intake_stock`, and authentication role protection in `Apps/Inventory/tests.py` and `Apps/Auth/tests.py`.

---

## 11. Important Constraints & Rules (Must Not Be Violated)

* **Preserve Atomic Safety:** Do not remove `@transaction.atomic` or `select_for_update()` in [`Apps/Inventory/services.py`](file:///D:/SETEC/Year4/Python/Pythond%20II/Visa_Inventory/stock_inventory_django_final/Apps/Inventory/services.py). Inventory safety relies on strict database row locking.
* **Preserve Role Enforcement:** Do not remove `@role_required` decorators from sensitive inventory and administrative views.
* **Keep Legacy URL Compatibility:** Maintain backwards compatibility for legacy endpoints (`/transfer/`, `/checkout/`, `/intake/`, `/logs/`).
* **Do Not Recreate Project or App Structure:** Do not reset settings, rewrite models, or delete existing migration files.
* **Staff Role Default:** Any self-registered user created via `/register/` MUST strictly receive `role='STAFF'`. Do not allow self-assigned `ADMIN` or `MANAGER` privileges.

---

## 12. PROMPT FOR THE NEXT AI SESSION

```text
You are continuing development on the JolNaPu (InvenStock) Django inventory management project.

Before making any code changes, complete the following prerequisites:
1. Read PROJECT_PROGRESS.md in the project root thoroughly to understand the project architecture, verified completed features, and identified issues.
2. Inspect the current files before editing. Do not overwrite working code, do not reset the database, and do not start a new project or restructure existing apps.
3. Your immediate task is to address the specific incomplete features and identified bugs outlined in Section 10 of PROJECT_PROGRESS.md:
   - Task A: Fix the NameError in Apps/Auth/views.py by defining `User = get_user_model()` and verify /users/ loads with HTTP 200.
   - Task B: Fix the AttributeError on Supplier and Category (`product_count` property collision with `.annotate(product_count=...)`) so /suppliers/ and /categories/ load with HTTP 200.
   - Task C: Verify the 6-digit OTP password reset flow and staff registration flow end-to-end.
   - Task D: Register Category in Apps/Inventory/admin.py.
4. Run tests or validation commands (e.g. via Django test client or manage.py check) after making changes.
5. In your response:
   - List the exact files modified.
   - Provide the test steps executed and the results.
   - Update PROJECT_PROGRESS.md to reflect newly verified features.
   - Stop after completing this agreed group of tasks and report remaining tasks.
```
