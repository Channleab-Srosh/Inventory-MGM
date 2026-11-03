import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/responsive.dart';
import '../../core/widgets/common_widgets.dart';

/// "More" hub with modern card styling
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final canManageUsers = user?.canManageUsers == true;

    final isWide = AppResponsive.isTabletOrDesktop(context);
    final hPad = AppResponsive.screenPadding(context);

    // ── Profile card ─────────────────────────────────────────────────────────
    final profileCard = GestureDetector(
      onTap: () => context.push('/profile'),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(AppTheme.bentoRadius),
          boxShadow: AppColors.lavenderShadow,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  user?.initials ?? 'U',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          user?.name ?? 'User',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.2,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.22),
                          borderRadius: BorderRadius.circular(AppTheme.pillRadius),
                        ),
                        child: Text(
                          user?.roleBadgeLabel ?? 'STAFF',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    user?.email ?? '',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 13,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'View & edit profile →',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.chevron_right_rounded,
                  color: Colors.white, 
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );

    // ── Menu sections ─────────────────────────────────────────────────────────
    final menuSections = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionLabel(label: 'INVENTORY OPERATIONS'),
        const SizedBox(height: 8),
        _MenuCard(items: [
          _MenuItem(
            icon: Icons.inventory_2_rounded,
            label: 'Products',
            subtitle: 'Catalog, pricing & product management',
            iconBgColor: const Color(0xFFFEF3C7),
            iconColor: const Color(0xFFD97706),
            onTap: () => context.push('/more/products'),
          ),
          if (user?.canViewCategories == true)
            _MenuItem(
              icon: Icons.category_rounded,
              label: 'Categories',
              subtitle: 'Organize catalog & categories',
              iconBgColor: const Color(0xFFEDE9FE),
              iconColor: const Color(0xFF7C3AED),
              onTap: () => context.push('/more/categories'),
            ),
          _MenuItem(
            icon: Icons.business_rounded,
            label: 'Suppliers',
            subtitle: 'Vendor contact & address records',
            iconBgColor: const Color(0xFFE0F2FE),
            iconColor: const Color(0xFF0284C7),
            onTap: () => context.push('/more/suppliers'),
          ),
          _MenuItem(
            icon: Icons.people_outline_rounded,
            label: 'Customers',
            subtitle: 'Customer directory & contacts',
            iconBgColor: const Color(0xFFDCFCE7),
            iconColor: const Color(0xFF16A34A),
            onTap: () => context.push('/more/customers'),
          ),
          _MenuItem(
            icon: Icons.history_rounded,
            label: 'Stock History',
            subtitle: 'Audit logs of in/out movements',
            iconBgColor: AppColors.lowStockBg,
            iconColor: AppColors.lowStockText,
            onTap: () => context.push('/history'),
          ),
        ]),
        const SizedBox(height: 16),

        const _SectionLabel(label: 'REPORTS & ANALYTICS'),
        const SizedBox(height: 8),
        _MenuCard(items: [
          _MenuItem(
            icon: Icons.bar_chart_rounded,
            label: 'Reports',
            subtitle: 'Summary, in/out reports, low stock',
            iconBgColor: AppColors.inStockBg,
            iconColor: AppColors.inStockText,
            onTap: () => context.push('/reports'),
          ),
        ]),
        const SizedBox(height: 16),

        if (canManageUsers) ...[
          const _SectionLabel(label: 'ADMINISTRATION'),
          const SizedBox(height: 8),
          _MenuCard(items: [
            _MenuItem(
              icon: Icons.people_rounded,
              label: 'User Management',
              subtitle: 'Manage accounts, roles, & access',
              iconBgColor: AppColors.primaryActive,
              iconColor: AppColors.primaryDark,
              onTap: () => context.push('/more/users'),
            ),
            _MenuItem(
              icon: Icons.settings_rounded,
              label: 'System Settings',
              subtitle: 'Currency, thresholds, & alerts',
              iconBgColor: const Color(0xFFF0F1F5),
              iconColor: AppColors.secondaryText,
              onTap: () => context.push('/more/settings'),
            ),
          ]),
          const SizedBox(height: 16),
        ],

        const _SectionLabel(label: 'ACCOUNT'),
        const SizedBox(height: 8),
        _MenuCard(items: [
          _MenuItem(
            icon: Icons.person_rounded,
            label: 'My Profile',
            subtitle: 'Account details & change password',
            iconBgColor: AppColors.primaryActive,
            iconColor: AppColors.primaryDark,
            onTap: () => context.push('/profile'),
          ),
          _MenuItem(
            icon: Icons.logout_rounded,
            label: 'Logout',
            subtitle: 'Sign out of this session',
            iconBgColor: AppColors.outOfStockBg,
            iconColor: AppColors.outOfStockText,
            onTap: () => _confirmLogout(context, auth),
          ),
        ]),
        const SizedBox(height: 24),

        Center(
          child: Text(
            'Inventory Manager v1.0.0 · ${user?.roleDisplayName ?? "Staff"}',
            style: const TextStyle(
              color: AppColors.secondaryText,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(height: 80),
      ],
    );

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: isWide
            // ── Tablet/Desktop: two-column layout ────────────────────────────
            ? SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                child: Center(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                        maxWidth: AppResponsive.contentMaxWidth(context)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 14, bottom: 16),
                          child: Text(
                            'More',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.6,
                              color: AppColors.text,
                            ),
                          ),
                        ),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Left column: profile card
                            SizedBox(
                              width: 280,
                              child: profileCard,
                            ),
                            const SizedBox(width: 24),
                            // Right column: menus
                            Expanded(child: menuSections),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              )
            // ── Mobile: original single-column list ───────────────────────────
            : ListView(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 14, bottom: 16),
                    child: Text(
                      'More',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.6,
                        color: AppColors.text,
                      ),
                    ),
                  ),
                  profileCard,
                  const SizedBox(height: 20),
                  menuSections,
                ],
              ),
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to sign out of your account?',
      confirmLabel: 'Logout',
      confirmColor: AppColors.outOfStockText,
    );
    if (confirmed && context.mounted) {
      await auth.logout();
      if (context.mounted) {
        context.go('/login');
      }
    }
  }
}

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: AppColors.secondaryText,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _MenuCard extends StatelessWidget {
  final List<_MenuItem> items;
  const _MenuCard({required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        border: Border.all(color: AppColors.border, width: 1),
        boxShadow: AppColors.cardShadow,
      ),
      child: Column(
        children: items.asMap().entries.map((e) {
          final isLast = e.key == items.length - 1;
          return Column(
            children: [
              e.value,
              if (!isLast)
                const Divider(
                  height: 1,
                  indent: 62,
                  endIndent: 0,
                  color: AppColors.border,
                ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color iconBgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    this.subtitle,
    required this.iconBgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: iconBgColor,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(icon, color: iconColor, size: 22),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.2,
                        color: AppColors.text,
                      ),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppColors.secondaryText,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColors.secondaryText,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
