from django.urls import path
from . import views

app_name = 'inventory'

urlpatterns = [
    # Dashboard
    path('', views.dashboard_view, name='dashboard'),

    # Products
    path('products/', views.product_list_view, name='product-list'),
    path('products/add/', views.product_add_view, name='product-add'),
    path('products/<int:pk>/', views.product_detail_view, name='product-detail'),
    path('products/<int:pk>/edit/', views.product_edit_view, name='product-edit'),
    path('products/<int:pk>/delete/', views.product_delete_view, name='product-delete'),

    # Categories
    path('categories/', views.category_list_view, name='category-list'),
    path('categories/add/', views.category_add_view, name='category-add'),
    path('categories/<int:pk>/edit/', views.category_edit_view, name='category-edit'),
    path('categories/<int:pk>/delete/', views.category_delete_view, name='category-delete'),

    # Suppliers
    path('suppliers/', views.supplier_list_view, name='supplier-list'),
    path('suppliers/add/', views.supplier_add_view, name='supplier-add'),
    path('suppliers/<int:pk>/', views.supplier_detail_view, name='supplier-detail'),
    path('suppliers/<int:pk>/edit/', views.supplier_edit_view, name='supplier-edit'),
    path('suppliers/<int:pk>/delete/', views.supplier_delete_view, name='supplier-delete'),

    # Stock Operations
    path('stock-in/', views.stock_in_view, name='stock-in'),
    path('stock-out/', views.stock_out_view, name='stock-out'),
    path('stock-adjust/', views.stock_adjust_view, name='stock-adjust'),
    path('api/stock-level/', views.get_stock_level_api, name='api-stock-level'),

    # Stock History
    path('stock-history/', views.stock_history_view, name='stock-history'),

    # Reports & Exports
    path('reports/', views.reports_view, name='reports'),
    path('reports/export/excel/', views.export_reports_excel_view, name='reports-export-excel'),
    path('reports/export/pdf/', views.export_reports_pdf_view, name='reports-export-pdf'),
    path('reports/export/csv/', views.export_reports_csv_view, name='reports-export-csv'),
    path('products/export/excel/', views.export_products_excel_view, name='products-export-excel'),
    path('products/export/csv/', views.export_products_csv_view, name='products-export-csv'),

    # Locations
    path('locations/', views.location_list_view, name='location-list'),
    path('locations/add/', views.location_add_view, name='location-add'),
    path('locations/<int:pk>/edit/', views.location_edit_view, name='location-edit'),
    path('locations/<int:pk>/delete/', views.location_delete_view, name='location-delete'),

    # Legacy URLs (redirect to new)

    path('transfer/', views.stock_transfer_view, name='transfer'),
    path('checkout/', views.stock_checkout_view, name='checkout'),
    path('intake/', views.stock_intake_view, name='intake'),
    path('logs/', views.inventory_logs_view, name='logs'),
]
