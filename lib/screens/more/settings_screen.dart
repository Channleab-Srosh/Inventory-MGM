import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';

/// Settings screen: theme, threshold, currency, notifications
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ---- Appearance ----
          _SectionLabel(title: 'Appearance'),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  secondary: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.indigo.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.dark_mode_outlined,
                        color: Colors.indigo, size: 20),
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(
                    settings.themeMode == ThemeMode.dark
                        ? 'Dark'
                        : settings.themeMode == ThemeMode.light
                            ? 'Light'
                            : 'System default',
                  ),
                  value: settings.themeMode == ThemeMode.dark,
                  onChanged: (v) => settings.setThemeMode(
                      v ? ThemeMode.dark : ThemeMode.light),
                  activeColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Inventory ----
          _SectionLabel(title: 'Inventory'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.lowStock.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.warning_amber_outlined,
                        color: AppColors.lowStock, size: 20),
                  ),
                  title: const Text('Low Stock Threshold'),
                  subtitle: Text('${settings.lowStockThreshold} units'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: settings.lowStockThreshold > 1
                            ? () => settings.setLowStockThreshold(
                                settings.lowStockThreshold - 1)
                            : null,
                      ),
                      Text('${settings.lowStockThreshold}',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 16)),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: () => settings.setLowStockThreshold(
                            settings.lowStockThreshold + 1),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.inStock.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.attach_money,
                        color: AppColors.inStock, size: 20),
                  ),
                  title: const Text('Currency'),
                  subtitle: Text('${settings.currency} (${settings.currencySymbol})'),
                  trailing: const Icon(Icons.chevron_right, color: AppColors.grey500),
                  onTap: () => _showCurrencyPicker(context, settings),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Notifications ----
          _SectionLabel(title: 'Notifications'),
          Card(
            child: SwitchListTile(
              secondary: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: AppColors.primary, size: 20),
              ),
              title: const Text('Push Notifications'),
              subtitle: const Text('Low stock and activity alerts'),
              value: settings.notificationsEnabled,
              onChanged: settings.toggleNotifications,
              activeColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // ---- About ----
          _SectionLabel(title: 'About'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2,
                        color: AppColors.primary, size: 20),
                  ),
                  title: const Text('App Version'),
                  trailing: Text(
                    AppConstants.appVersion,
                    style: const TextStyle(
                        color: AppColors.grey500, fontWeight: FontWeight.w500),
                  ),
                ),
                const Divider(height: 1, indent: 56),
                ListTile(
                  leading: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.blue.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.privacy_tip_outlined,
                        color: Colors.blue, size: 20),
                  ),
                  title: const Text('Privacy Policy'),
                  trailing: const Icon(Icons.open_in_new, size: 16, color: AppColors.grey500),
                  onTap: () {},
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }

  void _showCurrencyPicker(BuildContext context, SettingsProvider settings) {
    final currencies = [
      {'code': 'USD', 'symbol': '\$', 'name': 'US Dollar'},
      {'code': 'EUR', 'symbol': '€', 'name': 'Euro'},
      {'code': 'GBP', 'symbol': '£', 'name': 'British Pound'},
      {'code': 'JPY', 'symbol': '¥', 'name': 'Japanese Yen'},
      {'code': 'KHR', 'symbol': '฿', 'name': 'Khmer Riel'},
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 12),
          Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppColors.grey200,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 16),
          const Text('Select Currency',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 8),
          ...currencies.map((c) => ListTile(
                title: Text('${c['name']}'),
                subtitle: Text('${c['code']} (${c['symbol']})'),
                trailing: settings.currency == c['code']
                    ? const Icon(Icons.check, color: AppColors.primary)
                    : null,
                onTap: () {
                  settings.setCurrency(c['code']!, c['symbol']!);
                  Navigator.pop(context);
                },
              )),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;
  const _SectionLabel({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: AppColors.grey500,
            letterSpacing: 0.8),
      ),
    );
  }
}
