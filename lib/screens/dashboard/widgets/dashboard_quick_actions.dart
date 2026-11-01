import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import 'package:inventory_management/core/theme/app_theme.dart';
import 'package:inventory_management/providers/auth_provider.dart';

/// Quick action shortcuts for the Dashboard with modern 999px pill buttons
class DashboardQuickActions extends StatelessWidget {
  const DashboardQuickActions({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canStockOut = auth.user?.canStockOut ?? true;
    final canManageProducts = auth.user?.canManageProducts ?? true;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          _ActionButton(
            icon: Icons.arrow_downward_rounded,
            label: 'Stock In',
            textColor: AppColors.inStockText,
            bgColor: AppColors.inStockBg,
            onTap: () => context.go('/stock?tab=in'),
          ),
          const SizedBox(width: 8),
          if (canStockOut) ...[
            _ActionButton(
              icon: Icons.arrow_upward_rounded,
              label: 'Stock Out',
              textColor: AppColors.outOfStockText,
              bgColor: AppColors.outOfStockBg,
              onTap: () => context.go('/stock?tab=out'),
            ),
            const SizedBox(width: 8),
          ],
          if (canManageProducts) ...[
            _ActionButton(
              icon: Icons.add_rounded,
              label: 'Add Product',
              textColor: AppColors.primaryDark,
              bgColor: AppColors.primaryActive,
              onTap: () => context.push('/products/add'),
            ),
            const SizedBox(width: 8),
          ],
          _ActionButton(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            textColor: const Color(0xFF0F766E),
            bgColor: const Color(0xFFCCFBF1),
            onTap: () => context.go('/reports'),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color textColor;
  final Color bgColor;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.textColor,
    required this.bgColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.pillRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(AppTheme.pillRadius),
            border: Border.all(
              color: textColor.withValues(alpha: 0.2),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: textColor),
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
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
