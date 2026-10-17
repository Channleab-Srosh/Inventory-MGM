import uuid
from django.db import transaction
from django.core.exceptions import ValidationError
from django.utils import timezone
from .models import Product, Location, ProductLocation, InventoryLog


def _generate_reference_no(prefix: str) -> str:
    """Auto-generate a unique reference number like PO-20241013-A3F2."""
    date_str = timezone.now().strftime('%Y%m%d')
    suffix = uuid.uuid4().hex[:4].upper()
    return f"{prefix}-{date_str}-{suffix}"


class InventoryService:
    """
    Business logic layer for atomic inventory operations.
    Guarantees thread-safe row-locking (select_for_update) and transaction rollbacks.
    """

    @staticmethod
    @transaction.atomic
    def transfer_stock(product_id, source_location_id, destination_location_id, quantity, user=None, reason=None, reference_no=None):
        if quantity <= 0:
            raise ValidationError("Transfer quantity must be greater than zero.")

        if str(source_location_id) == str(destination_location_id):
            raise ValidationError("Source and destination locations cannot be identical.")

        if not reference_no:
            reference_no = _generate_reference_no('TRF')

        product = Product.objects.get(pk=product_id)
        source_loc = Location.objects.get(pk=source_location_id)
        dest_loc = Location.objects.get(pk=destination_location_id)

        try:
            source_stock = ProductLocation.objects.select_for_update().get(
                product=product,
                location=source_loc
            )
        except ProductLocation.DoesNotExist:
            raise ValidationError(f"No stock record found for {product.name} at {source_loc.name}.")

        if source_stock.quantity < quantity:
            raise ValidationError(
                f"Insufficient stock at {source_loc.name}. Available: {source_stock.quantity}, Requested: {quantity}."
            )

        source_stock.quantity -= quantity
        source_stock.save()

        dest_stock, _ = ProductLocation.objects.select_for_update().get_or_create(
            product=product,
            location=dest_loc,
            defaults={'quantity': 0}
        )
        dest_stock.quantity += quantity
        dest_stock.save()

        actor_name = user.username if user and user.is_authenticated else "System"
        audit_reason = reason or f"Transferred by {actor_name}"
        log = InventoryLog.objects.create(
            product=product,
            quantity_changed=quantity,
            log_type='TRANSFER',
            source_location=source_loc,
            destination_location=dest_loc,
            reason=audit_reason,
            reference_no=reference_no,
            performed_by=user if user and user.is_authenticated else None
        )

        return {
            'success': True,
            'source_remaining': source_stock.quantity,
            'dest_total': dest_stock.quantity,
            'log': log
        }

    @staticmethod
    @transaction.atomic
    def checkout_stock(product_id, location_id, quantity, user=None, reason=None, reference_no=None):
        if quantity <= 0:
            raise ValidationError("Checkout quantity must be greater than zero.")

        if not reference_no:
            reference_no = _generate_reference_no('SO')

        product = Product.objects.get(pk=product_id)
        location = Location.objects.get(pk=location_id)

        try:
            stock = ProductLocation.objects.select_for_update().get(
                product=product,
                location=location
            )
        except ProductLocation.DoesNotExist:
            raise ValidationError(f"No stock available for {product.name} at {location.name}.")

        if stock.quantity < quantity:
            raise ValidationError(
                f"Insufficient stock at {location.name}. Available: {stock.quantity}, Requested: {quantity}."
            )

        stock.quantity -= quantity
        stock.save()

        actor_name = user.username if user and user.is_authenticated else "System"
        audit_reason = reason or f"Sale checkout by {actor_name}"
        log = InventoryLog.objects.create(
            product=product,
            quantity_changed=-quantity,
            log_type='STOCK_OUT',
            source_location=location,
            destination_location=None,
            reason=audit_reason,
            reference_no=reference_no,
            performed_by=user if user and user.is_authenticated else None
        )

        return {
            'success': True,
            'remaining_quantity': stock.quantity,
            'log': log
        }

    @staticmethod
    @transaction.atomic
    def intake_stock(product_id, location_id, quantity, user=None, reason=None, reference_no=None):
        if quantity <= 0:
            raise ValidationError("Intake quantity must be greater than zero.")

        if not reference_no:
            reference_no = _generate_reference_no('PO')

        product = Product.objects.get(pk=product_id)
        location = Location.objects.get(pk=location_id)

        stock, _ = ProductLocation.objects.select_for_update().get_or_create(
            product=product,
            location=location,
            defaults={'quantity': 0}
        )
        stock.quantity += quantity
        stock.save()

        actor_name = user.username if user and user.is_authenticated else "System"
        audit_reason = reason or f"Stock intake received by {actor_name}"
        log = InventoryLog.objects.create(
            product=product,
            quantity_changed=quantity,
            log_type='STOCK_IN',
            source_location=None,
            destination_location=location,
            reason=audit_reason,
            reference_no=reference_no,
            performed_by=user if user and user.is_authenticated else None
        )

        return {
            'success': True,
            'current_quantity': stock.quantity,
            'log': log
        }

    @staticmethod
    @transaction.atomic
    def adjust_stock(product_id, location_id, new_quantity, user=None, reason=None):
        if new_quantity < 0:
            raise ValidationError("Stock quantity cannot be negative.")

        reference_no = _generate_reference_no('ADJ')

        product = Product.objects.get(pk=product_id)
        location = Location.objects.get(pk=location_id)

        stock, _ = ProductLocation.objects.select_for_update().get_or_create(
            product=product,
            location=location,
            defaults={'quantity': 0}
        )

        difference = new_quantity - stock.quantity
        stock.quantity = new_quantity
        stock.save()

        actor_name = user.username if user and user.is_authenticated else "System"
        audit_reason = reason or f"Manual stock count adjustment by {actor_name}"
        log = InventoryLog.objects.create(
            product=product,
            quantity_changed=difference,
            log_type='ADJUSTMENT',
            source_location=location,
            destination_location=None,
            reason=audit_reason,
            reference_no=reference_no,
            performed_by=user if user and user.is_authenticated else None
        )

        return {
            'success': True,
            'new_quantity': stock.quantity,
            'difference': difference,
            'log': log
        }
