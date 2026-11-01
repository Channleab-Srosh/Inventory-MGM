import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Standard reusable UI components matching the modern pill & soft periwinkle design system

/// 1. AppButton: Standard button with full pill radius (999px), loading state, icons, and variants
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isOutlined;
  final Color? backgroundColor;
  final Color? textColor;
  final double height;
  final double? width;

  const AppButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isOutlined = false,
    this.backgroundColor,
    this.textColor,
    this.height = 48,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveWidth = width ?? double.infinity;
    final primaryBg = backgroundColor ?? AppColors.primary;
    final primaryFg = textColor ?? Colors.white;

    final content = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(
                isOutlined ? (textColor ?? AppColors.primaryDark) : Colors.white,
              ),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: isOutlined
                      ? (textColor ?? AppColors.primaryDark)
                      : primaryFg,
                ),
              ),
            ],
          );

    return SizedBox(
      width: effectiveWidth,
      height: height,
      child: isOutlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: BorderSide(
                  color: backgroundColor ?? AppColors.border,
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              child: content,
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBg,
                foregroundColor: primaryFg,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                ),
              ),
              child: content,
            ),
    );
  }
}

/// 2. AppTextField: Standard text form field with clean subtle borders, icons, validation
class AppTextField extends StatelessWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final String? initialValue;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onEditingComplete;
  final int maxLines;
  final bool readOnly;
  final bool enabled;

  const AppTextField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.initialValue,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.textInputAction,
    this.validator,
    this.onChanged,
    this.onEditingComplete,
    this.maxLines = 1,
    this.readOnly = false,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      initialValue: initialValue,
      obscureText: obscureText,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      validator: validator,
      onChanged: onChanged,
      onEditingComplete: onEditingComplete,
      maxLines: maxLines,
      readOnly: readOnly,
      enabled: enabled,
      style: const TextStyle(
        fontSize: 14,
        color: AppColors.text,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.card,
        labelText: label,
        hintText: hint,
        prefixIcon: prefixIcon != null ? Icon(prefixIcon, size: 20, color: AppColors.secondaryText) : null,
        suffixIcon: suffixIcon,
      ),
    );
  }
}

/// 3. AppCard: Standard rounded card with pure white surface, 16px radius, and soft diffused drop shadow
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? color;
  final double radius;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.margin = const EdgeInsets.symmetric(vertical: 4),
    this.onTap,
    this.color,
    this.radius = AppTheme.cardRadius,
  });

  @override
  Widget build(BuildContext context) {
    final cardContent = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(radius),
          child: Padding(
            padding: padding ?? EdgeInsets.zero,
            child: child,
          ),
        ),
      ),
    );

    return cardContent;
  }
}

/// 4. StatusBadge: Standard full-pill (999px) status badge with semantic pastel backgrounds
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color? backgroundColor;
  final IconData? icon;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.backgroundColor,
    this.icon,
  });

  factory StatusBadge.inStock() => const StatusBadge(
        label: 'In Stock',
        color: AppColors.inStockText,
        backgroundColor: AppColors.inStockBg,
      );

  factory StatusBadge.lowStock() => const StatusBadge(
        label: 'Low Stock',
        color: AppColors.lowStockText,
        backgroundColor: AppColors.lowStockBg,
      );

  factory StatusBadge.outOfStock() => const StatusBadge(
        label: 'Out of Stock',
        color: AppColors.outOfStockText,
        backgroundColor: AppColors.outOfStockBg,
      );

  factory StatusBadge.active() => const StatusBadge(
        label: 'Active',
        color: AppColors.inStockText,
        backgroundColor: AppColors.inStockBg,
      );

  factory StatusBadge.inactive() => const StatusBadge(
        label: 'Inactive',
        color: AppColors.secondaryText,
        backgroundColor: Color(0xFFF0F1F5),
      );

  factory StatusBadge.admin() => const StatusBadge(
        label: 'ADMIN',
        color: AppColors.primaryDark,
        backgroundColor: AppColors.primaryActive,
        icon: Icons.shield_outlined,
      );

  factory StatusBadge.warehouseManager() => const StatusBadge(
        label: 'WAREHOUSE MANAGER',
        color: AppColors.lowStockText,
        backgroundColor: AppColors.lowStockBg,
        icon: Icons.warehouse_outlined,
      );

  factory StatusBadge.staff() => const StatusBadge(
        label: 'STAFF',
        color: Color(0xFF0284C7),
        backgroundColor: Color(0xFFE0F2FE),
        icon: Icons.badge_outlined,
      );

  factory StatusBadge.role(String role) {
    final r = role.toUpperCase();
    if (r == 'ADMIN') return StatusBadge.admin();
    if (r == 'WAREHOUSE_MANAGER' || r == 'WAREHOUSE MANAGER') {
      return StatusBadge.warehouseManager();
    }
    return StatusBadge.staff();
  }

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? color.withValues(alpha: 0.12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// 5. LoadingWidget: Standard centered loading indicator
class LoadingWidget extends StatelessWidget {
  final String? message;
  const LoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
            color: AppColors.primaryDark,
            strokeWidth: 3,
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.secondaryText,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// 6. ErrorState: Reusable error display with retry action
class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const ErrorState({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.danger),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: AppColors.text,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              AppButton(
                label: 'Try Again',
                width: 140,
                height: 40,
                onPressed: onRetry,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 7. ResponsiveContainer: Helper for adapting layout across small/large screens
class ResponsiveContainer extends StatelessWidget {
  final Widget child;
  final double maxWidth;

  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = 600,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// 8. AppFilterChip: Reusable pill-shaped filter chip (999px)
/// Active chips use light lavender fill (#EBE8FC); inactive chips use pure white with subtle borders
class AppFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onSelected;
  final IconData? icon;
  final Color? color;

  const AppFilterChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onSelected,
    this.icon,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final activeTextColor = color != null ? color! : AppColors.primaryDark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onSelected,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.primaryActive : AppColors.card,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: selected
                  ? AppColors.primary.withValues(alpha: 0.4)
                  : AppColors.border,
              width: 1,
            ),
            boxShadow: const [
              BoxShadow(
                color: Color(0x041A1A1A),
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(
                  icon,
                  size: 15,
                  color: selected ? activeTextColor : AppColors.secondaryText,
                ),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? activeTextColor : AppColors.secondaryText,
                  letterSpacing: -0.1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
