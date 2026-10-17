from django.shortcuts import render, redirect, get_object_or_404
from django.http import HttpResponse
from django.contrib import messages
from django.db.models import Sum, Count, Q
from django.core.exceptions import ValidationError
from django.core.paginator import Paginator
from django.utils import timezone
from datetime import timedelta
from Apps.Auth.decorators import role_required
from .models import Product, Location, ProductLocation, InventoryLog, Supplier, Category
from .services import InventoryService
from .forms import CategoryForm, SupplierForm, ProductForm, StockInForm, StockOutForm, LocationForm, StockAdjustmentForm
from .exports import (
    generate_reports_excel, generate_reports_pdf, generate_reports_csv,
    generate_products_excel, generate_products_csv
)



# ─────────────────────────────────────────────
#  Dashboard
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER', 'STAFF')
def dashboard_view(request):
    total_products = Product.objects.count()
    total_locations = Location.objects.count()

    low_stock_products = []
    for product in Product.objects.prefetch_related('stocks', 'stocks__location').all():
        total_qty = sum(stock.quantity for stock in product.stocks.all())
        if total_qty <= product.low_stock_alert:
            low_stock_products.append({
                'product': product,
                'total_qty': total_qty,
                'threshold': product.low_stock_alert
            })

    recent_logs = InventoryLog.objects.select_related(
        'product', 'source_location', 'destination_location', 'performed_by'
    ).order_by('-created_at')[:10]

    stock_aggregates = ProductLocation.objects.aggregate(total_units=Sum('quantity'))

    today = timezone.now().date()
    stock_out_today = InventoryLog.objects.filter(
        log_type='STOCK_OUT', created_at__date=today
    ).count()

    # Chart data: last 7 days stock in vs stock out
    chart_labels = []
    chart_stock_in = []
    chart_stock_out = []
    for i in range(6, -1, -1):
        day = today - timedelta(days=i)
        chart_labels.append(day.strftime('%b %d'))
        in_qty = InventoryLog.objects.filter(
            log_type='STOCK_IN', created_at__date=day
        ).aggregate(total=Sum('quantity_changed'))['total'] or 0
        out_qty = InventoryLog.objects.filter(
            log_type='STOCK_OUT', created_at__date=day
        ).aggregate(total=Sum('quantity_changed'))['total'] or 0
        chart_stock_in.append(in_qty)
        chart_stock_out.append(abs(out_qty))

    # Calculate out of stock count (products with total stock = 0)
    out_of_stock_count = sum(
        1 for p in Product.objects.prefetch_related('stocks').all()
        if sum(s.quantity for s in p.stocks.all()) == 0
    )

    context = {
        'total_products': total_products,
        'total_locations': total_locations,
        'total_suppliers': Supplier.objects.filter(status='ACTIVE').count(),
        'total_categories': Category.objects.filter(status='ACTIVE').count(),
        'low_stock_count': len(low_stock_products),
        'out_of_stock_count': out_of_stock_count,
        'stock_out_today': stock_out_today,
        'low_stock_products': low_stock_products[:5],
        'recent_logs': recent_logs,
        'total_units': stock_aggregates['total_units'] or 0,
        'user_role': getattr(request.user, 'role', 'GUEST'),
        'chart_labels': chart_labels,
        'chart_stock_in': chart_stock_in,
        'chart_stock_out': chart_stock_out,
    }
    return render(request, 'inventory/dashboard.html', context)


# ─────────────────────────────────────────────
#  Products
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER', 'STAFF')
def product_list_view(request):
    query = request.GET.get('q', '').strip()
    category_filter = request.GET.get('category', '')
    status_filter = request.GET.get('status', '')

    products = Product.objects.prefetch_related('stocks__location').select_related('supplier', 'category').all()

    if query:
        products = products.filter(Q(name__icontains=query) | Q(sku__icontains=query))
    if category_filter:
        products = products.filter(category_id=category_filter)
    if status_filter:
        products = products.filter(status=status_filter)

    paginator = Paginator(products, 15)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    categories = Category.objects.filter(status='ACTIVE')

    context = {
        'page_obj': page_obj,
        'products': page_obj,
        'query': query,
        'category_filter': category_filter,
        'category_filter_id': int(category_filter) if category_filter else None,
        'status_filter': status_filter,
        'categories': categories,
        'status_choices': Product.STATUS_CHOICES,
    }
    return render(request, 'inventory/product_list.html', context)


@role_required('ADMIN', 'MANAGER')
def product_add_view(request):
    if request.method == 'POST':
        form = ProductForm(request.POST, request.FILES)
        if form.is_valid():
            product = form.save()
            messages.success(request, f"Product '{product.name}' created successfully.")
            return redirect('inventory:product-list')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = ProductForm()

    context = {
        'form': form,
        'page_title': 'Add Product',
        'form_action': 'Add',
    }
    return render(request, 'inventory/product_form.html', context)


@role_required('ADMIN', 'MANAGER')
def product_edit_view(request, pk):
    product = get_object_or_404(Product, pk=pk)
    if request.method == 'POST':
        form = ProductForm(request.POST, request.FILES, instance=product)
        if form.is_valid():
            form.save()
            messages.success(request, f"Product '{product.name}' updated successfully.")
            return redirect('inventory:product-detail', pk=product.pk)
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = ProductForm(instance=product)

    context = {
        'form': form,
        'product': product,
        'page_title': 'Edit Product',
        'form_action': 'Update',
    }
    return render(request, 'inventory/product_form.html', context)


@role_required('ADMIN', 'MANAGER', 'STAFF')
def product_detail_view(request, pk):
    product = get_object_or_404(Product, pk=pk)
    stock_history = InventoryLog.objects.filter(product=product).select_related(
        'performed_by', 'source_location', 'destination_location'
    )[:20]
    context = {
        'product': product,
        'stock_history': stock_history,
    }
    return render(request, 'inventory/product_detail.html', context)


@role_required('ADMIN')
def product_delete_view(request, pk):
    product = get_object_or_404(Product, pk=pk)
    if request.method == 'POST':
        name = product.name
        product.delete()
        messages.success(request, f"Product '{name}' deleted successfully.")
        return redirect('inventory:product-list')
    return redirect('inventory:product-list')


# ─────────────────────────────────────────────
#  Categories
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER', 'STAFF')
def category_list_view(request):
    query = request.GET.get('q', '').strip()
    categories = Category.objects.annotate(product_count=Count('products')).order_by('name')
    if query:
        categories = categories.filter(name__icontains=query)
    context = {
        'categories': categories,
        'form': CategoryForm(),
        'query': query,
    }
    return render(request, 'inventory/category_list.html', context)


@role_required('ADMIN', 'MANAGER')
def category_add_view(request):
    if request.method == 'POST':
        form = CategoryForm(request.POST)
        if form.is_valid():
            category = form.save()
            messages.success(request, f"Category '{category.name}' created successfully.")
        else:
            messages.error(request, "Please correct the errors below.")
    return redirect('inventory:category-list')


@role_required('ADMIN', 'MANAGER')
def category_edit_view(request, pk):
    category = get_object_or_404(Category, pk=pk)
    if request.method == 'POST':
        form = CategoryForm(request.POST, instance=category)
        if form.is_valid():
            form.save()
            messages.success(request, f"Category '{category.name}' updated successfully.")
        else:
            messages.error(request, "Please correct the errors below.")
    return redirect('inventory:category-list')


@role_required('ADMIN')
def category_delete_view(request, pk):
    category = get_object_or_404(Category, pk=pk)
    if request.method == 'POST':
        name = category.name
        category.delete()
        messages.success(request, f"Category '{name}' deleted.")
    return redirect('inventory:category-list')


# ─────────────────────────────────────────────
#  Suppliers
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER', 'STAFF')
def supplier_list_view(request):
    query = request.GET.get('q', '').strip()
    suppliers = Supplier.objects.annotate(product_count=Count('products')).order_by('name')
    if query:
        suppliers = suppliers.filter(Q(name__icontains=query) | Q(contact_email__icontains=query))
    context = {
        'suppliers': suppliers,
        'query': query,
    }
    return render(request, 'inventory/supplier_list.html', context)


@role_required('ADMIN', 'MANAGER')
def supplier_add_view(request):
    if request.method == 'POST':
        form = SupplierForm(request.POST)
        if form.is_valid():
            supplier = form.save()
            messages.success(request, f"Supplier '{supplier.name}' created successfully.")
            return redirect('inventory:supplier-list')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = SupplierForm()
    return render(request, 'inventory/supplier_form.html', {'form': form, 'page_title': 'Add Supplier', 'form_action': 'Add'})


@role_required('ADMIN', 'MANAGER')
def supplier_edit_view(request, pk):
    supplier = get_object_or_404(Supplier, pk=pk)
    if request.method == 'POST':
        form = SupplierForm(request.POST, instance=supplier)
        if form.is_valid():
            form.save()
            messages.success(request, f"Supplier '{supplier.name}' updated successfully.")
            return redirect('inventory:supplier-list')
        else:
            messages.error(request, "Please correct the errors below.")
    else:
        form = SupplierForm(instance=supplier)
    return render(request, 'inventory/supplier_form.html', {'form': form, 'supplier': supplier, 'page_title': 'Edit Supplier', 'form_action': 'Update'})


@role_required('ADMIN')
def supplier_delete_view(request, pk):
    supplier = get_object_or_404(Supplier, pk=pk)
    if request.method == 'POST':
        name = supplier.name
        supplier.delete()
        messages.success(request, f"Supplier '{name}' deleted.")
    return redirect('inventory:supplier-list')


@role_required('ADMIN', 'MANAGER', 'STAFF')
def supplier_detail_view(request, pk):
    supplier = get_object_or_404(Supplier, pk=pk)
    products = supplier.products.prefetch_related('stocks').all()
    context = {
        'supplier': supplier,
        'products': products,
    }
    return render(request, 'inventory/supplier_detail.html', context)


# ─────────────────────────────────────────────
#  Stock In
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER')
def stock_in_view(request):
    form = StockInForm()
    if request.method == 'POST':
        form = StockInForm(request.POST)
        if form.is_valid():
            product = form.cleaned_data['product']
            location = form.cleaned_data['location']
            quantity = form.cleaned_data['quantity']
            reference_no = form.cleaned_data.get('reference_no', '').strip() or None
            note = form.cleaned_data.get('note', '')
            try:
                result = InventoryService.intake_stock(
                    product_id=product.id,
                    location_id=location.id,
                    quantity=quantity,
                    user=request.user,
                    reason=note,
                    reference_no=reference_no,
                )
                messages.success(
                    request,
                    f"Stock In recorded. {product.name} updated to {result['current_quantity']} units at {location.name}. "
                    f"Reference: {result['log'].reference_no}"
                )
                return redirect('inventory:stock-in')
            except ValidationError as e:
                messages.error(request, str(e.message if hasattr(e, 'message') else e))
        else:
            messages.error(request, "Please correct the errors below.")


    context = {'form': form}
    return render(request, 'inventory/stock_in.html', context)


# ─────────────────────────────────────────────
#  Stock Out
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER', 'STAFF')
def stock_out_view(request):
    form = StockOutForm()
    if request.method == 'POST':
        form = StockOutForm(request.POST)
        if form.is_valid():
            product = form.cleaned_data['product']
            location = form.cleaned_data['location']
            quantity = form.cleaned_data['quantity']
            reference_no = form.cleaned_data.get('reference_no', '').strip() or None
            note = form.cleaned_data.get('note', '')
            try:
                result = InventoryService.checkout_stock(
                    product_id=product.id,
                    location_id=location.id,
                    quantity=quantity,
                    user=request.user,
                    reason=note,
                    reference_no=reference_no,
                )
                messages.success(
                    request,
                    f"Stock Out recorded. {product.name} remaining stock: {result['remaining_quantity']} units at {location.name}. "
                    f"Reference: {result['log'].reference_no}"
                )
                return redirect('inventory:stock-out')
            except ValidationError as e:
                messages.error(request, str(e.message if hasattr(e, 'message') else e))
        else:
            messages.error(request, "Please correct the errors below.")


    context = {'form': form}
    return render(request, 'inventory/stock_out.html', context)


# ─────────────────────────────────────────────
#  Stock Audit / Adjustment (MANUAL CHECK)
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER')
def stock_adjust_view(request):
    form = StockAdjustmentForm()
    if request.method == 'POST':
        form = StockAdjustmentForm(request.POST)
        if form.is_valid():
            product = form.cleaned_data['product']
            location = form.cleaned_data['location']
            new_quantity = form.cleaned_data['new_quantity']
            reference_no = form.cleaned_data.get('reference_no', '').strip() or None
            note = form.cleaned_data.get('note', '').strip()
            try:
                result = InventoryService.adjust_stock(
                    product_id=product.id,
                    location_id=location.id,
                    new_quantity=new_quantity,
                    user=request.user,
                    reason=note,
                    reference_no=reference_no,
                )
                diff = result['difference']
                diff_str = f"+{diff}" if diff > 0 else f"{diff}"
                messages.success(
                    request,
                    f"Stock Audit recorded for '{product.name}' at {location.name}. "
                    f"Adjusted to {result['new_quantity']} units (Net change: {diff_str}). "
                    f"Reference: {result['log'].reference_no}"
                )
                return redirect('inventory:stock-adjust')
            except ValidationError as e:
                messages.error(request, str(e.message if hasattr(e, 'message') else e))
            except Exception as e:
                messages.error(request, f"Adjustment failed: {str(e)}")
        else:
            messages.error(request, "Please correct the errors below.")

    context = {'form': form}
    return render(request, 'inventory/stock_adjust.html', context)


@role_required('ADMIN', 'MANAGER', 'STAFF')
def get_stock_level_api(request):
    """AJAX endpoint to get current quantity of a product at a specific location."""
    product_id = request.GET.get('product_id')
    location_id = request.GET.get('location_id')
    from django.http import JsonResponse
    if not product_id or not location_id:
        return JsonResponse({'quantity': 0})
    try:
        stock = ProductLocation.objects.filter(product_id=product_id, location_id=location_id).first()
        qty = stock.quantity if stock else 0
        return JsonResponse({'quantity': qty})
    except Exception:
        return JsonResponse({'quantity': 0})



# ─────────────────────────────────────────────
#  Stock Transfer (legacy)
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER')
def stock_transfer_view(request):
    products = Product.objects.all()
    locations = Location.objects.all()

    if request.method == 'POST':
        product_id = request.POST.get('product_id')
        source_id = request.POST.get('source_location_id')
        dest_id = request.POST.get('destination_location_id')
        quantity_str = request.POST.get('quantity')
        reason = request.POST.get('reason', '').strip()

        try:
            if not all([product_id, source_id, dest_id, quantity_str]):
                raise ValidationError("All fields are required.")
            quantity = int(quantity_str)
            if quantity <= 0:
                raise ValidationError("Transfer quantity must be greater than zero.")
            result = InventoryService.transfer_stock(
                product_id=product_id,
                source_location_id=source_id,
                destination_location_id=dest_id,
                quantity=quantity,
                user=request.user,
                reason=reason
            )
            messages.success(
                request,
                f"Successfully transferred {quantity} units. Source stock: {result['source_remaining']}, Destination stock: {result['dest_total']}."
            )
            return redirect('inventory:transfer')
        except ValidationError as e:
            messages.error(request, str(e.message if hasattr(e, 'message') else e))
        except Exception as e:
            messages.error(request, f"Transfer failed: {str(e)}")

    context = {'products': products, 'locations': locations}
    return render(request, 'inventory/stock_transfer.html', context)


# ─────────────────────────────────────────────
#  Stock History / Logs
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER', 'STAFF')
def stock_history_view(request):
    query = request.GET.get('q', '').strip()
    log_type = request.GET.get('type', '')
    show_all = request.GET.get('all') == '1'
    today_str = timezone.localdate().strftime('%Y-%m-%d')

    if show_all:
        date_from = ''
        date_to = ''
    else:
        date_from = request.GET.get('date_from', '').strip()
        date_to = request.GET.get('date_to', '').strip()

        # Catch current date if user did not select
        if not date_from:
            date_from = today_str
        if not date_to:
            date_to = today_str

    logs = InventoryLog.objects.select_related(
        'product', 'source_location', 'destination_location', 'performed_by'
    ).order_by('-created_at')

    if query:
        logs = logs.filter(Q(product__name__icontains=query) | Q(product__sku__icontains=query) | Q(reference_no__icontains=query))
    if log_type:
        logs = logs.filter(log_type=log_type)
    if date_from:
        logs = logs.filter(created_at__date__gte=date_from)
    if date_to:
        logs = logs.filter(created_at__date__lte=date_to)

    paginator = Paginator(logs, 20)
    page_number = request.GET.get('page')
    page_obj = paginator.get_page(page_number)

    context = {
        'page_obj': page_obj,
        'logs': page_obj,
        'query': query,
        'selected_type': log_type,
        'date_from': date_from,
        'date_to': date_to,
        'show_all': show_all,
        'current_date': today_str,
        'log_types': InventoryLog.LOG_TYPES,
    }
    return render(request, 'inventory/stock_history.html', context)


# ─────────────────────────────────────────────
#  Legacy logs view (keep URL compatibility)
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER')
def inventory_logs_view(request):
    return redirect('inventory:stock-history')


# ─────────────────────────────────────────────
#  Reports & Exports
# ─────────────────────────────────────────────
def _get_report_data(request):
    today = timezone.localdate()
    period = request.GET.get('period', 'month')

    if period == 'today':
        start_date = today
    elif period == 'week':
        start_date = today - timedelta(days=7)
    elif period == 'month':
        start_date = today - timedelta(days=30)
    else:
        # custom date range - default to current date if user not select
        start_date = request.GET.get('date_from', '').strip() or str(today)
        end_date = request.GET.get('date_to', '').strip() or str(today)
        try:
            from datetime import datetime
            start_date = datetime.strptime(str(start_date), '%Y-%m-%d').date()
            end_date = datetime.strptime(str(end_date), '%Y-%m-%d').date()
        except (ValueError, TypeError):
            start_date = today
            end_date = today

    if period != 'custom':
        end_date = today

    logs_qs = InventoryLog.objects.filter(created_at__date__gte=start_date, created_at__date__lte=end_date)

    total_stock_in = logs_qs.filter(log_type='STOCK_IN').aggregate(total=Sum('quantity_changed'))['total'] or 0
    total_stock_out = logs_qs.filter(log_type='STOCK_OUT').aggregate(total=Sum('quantity_changed'))['total'] or 0
    total_stock_out = abs(total_stock_out)

    all_products = Product.objects.prefetch_related('stocks', 'category', 'supplier').all()
    low_stock_list = []
    out_of_stock_list = []
    for product in all_products:
        total = product.total_stock
        if total == 0:
            out_of_stock_list.append(product)
        elif total <= product.low_stock_alert:
            low_stock_list.append(product)

    return period, start_date, end_date, total_stock_in, total_stock_out, low_stock_list, out_of_stock_list, logs_qs


@role_required('ADMIN', 'MANAGER', 'STAFF')
def reports_view(request):
    period, start_date, end_date, total_stock_in, total_stock_out, low_stock_list, out_of_stock_list, logs_qs = _get_report_data(request)
    context = {
        'period': period,
        'start_date': start_date,
        'end_date': end_date,
        'total_stock_in': total_stock_in,
        'total_stock_out': total_stock_out,
        'low_stock_count': len(low_stock_list),
        'out_of_stock_count': len(out_of_stock_list),
        'low_stock_list': low_stock_list[:10],
        'out_of_stock_list': out_of_stock_list[:10],
    }
    return render(request, 'inventory/reports.html', context)


@role_required('ADMIN', 'MANAGER', 'STAFF')
def export_reports_excel_view(request):
    period, start_date, end_date, total_stock_in, total_stock_out, low_stock_list, out_of_stock_list, logs_qs = _get_report_data(request)
    buffer = generate_reports_excel(start_date, end_date, total_stock_in, total_stock_out, low_stock_list, out_of_stock_list, logs_qs)
    response = HttpResponse(
        buffer.getvalue(),
        content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
    response['Content-Disposition'] = f'attachment; filename="invenstock_report_{start_date}_to_{end_date}.xlsx"'
    return response


@role_required('ADMIN', 'MANAGER', 'STAFF')
def export_reports_pdf_view(request):
    period, start_date, end_date, total_stock_in, total_stock_out, low_stock_list, out_of_stock_list, logs_qs = _get_report_data(request)
    buffer = generate_reports_pdf(start_date, end_date, total_stock_in, total_stock_out, low_stock_list, out_of_stock_list, logs_qs)
    response = HttpResponse(buffer.getvalue(), content_type='application/pdf')
    response['Content-Disposition'] = f'attachment; filename="invenstock_report_{start_date}_to_{end_date}.pdf"'
    return response


@role_required('ADMIN', 'MANAGER', 'STAFF')
def export_reports_csv_view(request):
    period, start_date, end_date, total_stock_in, total_stock_out, low_stock_list, out_of_stock_list, logs_qs = _get_report_data(request)
    csv_data = generate_reports_csv(start_date, end_date, total_stock_in, total_stock_out, low_stock_list, out_of_stock_list, logs_qs)
    response = HttpResponse(csv_data, content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename="invenstock_report_{start_date}_to_{end_date}.csv"'
    return response


@role_required('ADMIN', 'MANAGER', 'STAFF')
def export_products_excel_view(request):
    query = request.GET.get('q', '').strip()
    category_filter = request.GET.get('category', '')
    status_filter = request.GET.get('status', '')

    products = Product.objects.prefetch_related('stocks__location').select_related('supplier', 'category').all()
    if query:
        products = products.filter(Q(name__icontains=query) | Q(sku__icontains=query))
    if category_filter:
        products = products.filter(category_id=category_filter)
    if status_filter:
        products = products.filter(status=status_filter)

    buffer = generate_products_excel(products)
    date_str = timezone.now().strftime('%Y%m%d')
    response = HttpResponse(
        buffer.getvalue(),
        content_type='application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
    )
    response['Content-Disposition'] = f'attachment; filename="invenstock_products_{date_str}.xlsx"'
    return response


@role_required('ADMIN', 'MANAGER', 'STAFF')
def export_products_csv_view(request):
    query = request.GET.get('q', '').strip()
    category_filter = request.GET.get('category', '')
    status_filter = request.GET.get('status', '')

    products = Product.objects.prefetch_related('stocks__location').select_related('supplier', 'category').all()
    if query:
        products = products.filter(Q(name__icontains=query) | Q(sku__icontains=query))
    if category_filter:
        products = products.filter(category_id=category_filter)
    if status_filter:
        products = products.filter(status=status_filter)

    csv_data = generate_products_csv(products)
    date_str = timezone.now().strftime('%Y%m%d')
    response = HttpResponse(csv_data, content_type='text/csv')
    response['Content-Disposition'] = f'attachment; filename="invenstock_products_{date_str}.csv"'
    return response


# ─────────────────────────────────────────────
#  Legacy views kept for URL compatibility
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER', 'STAFF')
def stock_checkout_view(request):
    return redirect('inventory:stock-out')


@role_required('ADMIN', 'MANAGER')
def stock_intake_view(request):
    return redirect('inventory:stock-in')


# ─────────────────────────────────────────────
#  Location Management
# ─────────────────────────────────────────────
@role_required('ADMIN', 'MANAGER', 'STAFF')
def location_list_view(request):
    query = request.GET.get('q', '').strip()
    locations = Location.objects.annotate(
        stock_count=Count('stocks')
    ).order_by('name')
    if query:
        locations = locations.filter(name__icontains=query)
    context = {
        'locations': locations,
        'form': LocationForm(),
        'query': query,
    }
    return render(request, 'inventory/location_list.html', context)


@role_required('ADMIN', 'MANAGER')
def location_add_view(request):
    if request.method == 'POST':
        form = LocationForm(request.POST)
        if form.is_valid():
            location = form.save()
            messages.success(request, f"Location '{location.name}' created successfully.")
        else:
            messages.error(request, "Please correct the errors below.")
    return redirect('inventory:location-list')


@role_required('ADMIN', 'MANAGER')
def location_edit_view(request, pk):
    location = get_object_or_404(Location, pk=pk)
    if request.method == 'POST':
        form = LocationForm(request.POST, instance=location)
        if form.is_valid():
            form.save()
            messages.success(request, f"Location '{location.name}' updated successfully.")
        else:
            messages.error(request, "Please correct the errors below.")
    return redirect('inventory:location-list')


@role_required('ADMIN')
def location_delete_view(request, pk):
    location = get_object_or_404(Location, pk=pk)
    if request.method == 'POST':
        name = location.name
        # Check if there's any stock at this location
        if location.stocks.exists():
            messages.error(request, f"Cannot delete '{name}' — it has active stock records. Remove stock first.")
        else:
            location.delete()
            messages.success(request, f"Location '{name}' deleted successfully.")
    return redirect('inventory:location-list')

