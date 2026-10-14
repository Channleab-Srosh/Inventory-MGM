import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';

/// "More" tab: list of menu items leading to full-screen pages
class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('More')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // User profile preview
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary,
                    child: Text(
                      user?.initials ?? 'AJ',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user?.name ?? 'User',
                            style: theme.textTheme.titleMedium),
                        Text(user?.email ?? '',
                            style: theme.textTheme.bodyMedium),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            user?.role ?? 'Admin',
                            style: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit_outlined),
                    onPressed: () => context.push('/more/profile'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Menu items
          _MenuSection(title: 'Inventory', items: [
            _MenuItem(
              icon: Icons.category_outlined,
              label: 'Categories',
              color: const Color(0xFF8B5CF6),
              onTap: () => context.push('/more/categories'),
            ),
            _MenuItem(
              icon: Icons.business_outlined,
              label: 'Suppliers',
              color: const Color(0xFF0EA5E9),
              onTap: () => context.push('/more/suppliers'),
            ),
          ]),
          const SizedBox(height: 12),

          _MenuSection(title: 'Reports & Analytics', items: [
            _MenuItem(
              icon: Icons.bar_chart_outlined,
              label: 'Reports',
              color: const Color(0xFF10B981),
              onTap: () => context.push('/more/reports'),
            ),
          ]),
          const SizedBox(height: 12),

          _MenuSection(title: 'Account & App', items: [
            _MenuItem(
              icon: Icons.person_outlined,
              label: 'Profile',
              color: AppColors.primary,
              onTap: () => context.push('/more/profile'),
            ),
            _MenuItem(
              icon: Icons.settings_outlined,
              label: 'Settings',
              color: AppColors.grey500,
              onTap: () => context.push('/more/settings'),
            ),
            _MenuItem(
              icon: Icons.logout,
              label: 'Logout',
              color: AppColors.outOfStock,
              onTap: () => _confirmLogout(context, auth),
            ),
          ]),
          const SizedBox(height: 32),

          Center(
            child: Text(
              'Inventory Manager v1.0.0',
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  Future<void> _confirmLogout(BuildContext context, AuthProvider auth) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      confirmColor: AppColors.outOfStock,
    );
    if (confirmed && context.mounted) {
      auth.logout();
      context.go('/login');
    }
  }
}

class _MenuSection extends StatelessWidget {
  final String title;
  final List<_MenuItem> items;
  const _MenuSection({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(title,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.grey500,
                  letterSpacing: 0.5)),
        ),
        Card(
          child: Column(
            children: items.asMap().entries.map((e) {
              final isLast = e.key == items.length - 1;
              return Column(
                children: [
                  e.value,
                  if (!isLast) const Divider(height: 1, indent: 56),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: color, size: 20),
      ),
      title: Text(label),
      trailing: const Icon(Icons.chevron_right, color: AppColors.grey500),
      onTap: onTap,
    );
  }
}
