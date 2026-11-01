import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/settings_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/app_constants.dart';
import '../../data/api_service.dart';

/// Settings screen: theme, threshold, currency, notifications
class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
          // ---- Appearance ----
          const _SectionLabel(title: 'Appearance'),
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
                  activeThumbColor: AppColors.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // ---- Inventory ----
          const _SectionLabel(title: 'Inventory'),
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
          const _SectionLabel(title: 'Notifications'),
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
              activeThumbColor: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),

          // ---- Server Connection ----
          const _SectionLabel(title: 'Server Connection'),
          Card(
            child: ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.teal.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.dns_outlined, color: Colors.teal, size: 20),
              ),
              title: const Text('API Base URL'),
              subtitle: Text(ApiService().baseUrl),
              trailing: const Icon(Icons.edit_outlined, size: 18, color: AppColors.grey500),
              onTap: () => _showServerConfig(context),
            ),
          ),
          const SizedBox(height: 12),

          // ---- About ----
          const _SectionLabel(title: 'About'),
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
                  trailing: const Text(
                    AppConstants.appVersion,
                    style: TextStyle(
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
    ),
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
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SafeArea(
        child: SingleChildScrollView(
          child: Column(
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
        ),
      ),
    );
  }

  void _showServerConfig(BuildContext context) {
    final api = ApiService();
    final urlCtrl = TextEditingController(text: api.baseUrl);
    bool isTesting = false;
    bool? testSuccess;
    String? testMessage;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setDialogState) => AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.dns_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('API Base URL', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Select a preset or enter your backend server address:',
                  style: TextStyle(fontSize: 12, color: AppColors.grey500),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: urlCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Base URL',
                    hintText: AppConstants.baseUrl,
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  children: [
                    ActionChip(
                      label: const Text('Default IP (192.168.0.242)', style: TextStyle(fontSize: 11)),
                      avatar: const Icon(Icons.refresh, size: 14),
                      onPressed: () {
                        setDialogState(() {
                          urlCtrl.text = AppConstants.baseUrl;
                          testSuccess = null;
                          testMessage = null;
                        });
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    OutlinedButton.icon(
                      onPressed: isTesting
                          ? null
                          : () async {
                              setDialogState(() {
                                isTesting = true;
                                testMessage = null;
                              });
                              final ok = await api.checkConnection(urlCtrl.text.trim());
                              setDialogState(() {
                                isTesting = false;
                                testSuccess = ok;
                                testMessage = ok
                                    ? 'Connected successfully!'
                                    : 'Cannot connect to server. Check IP and port.';
                              });
                            },
                      icon: isTesting
                          ? const SizedBox(
                              width: 12,
                              height: 12,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.network_check, size: 14),
                      label: const Text('Test Connection', style: TextStyle(fontSize: 12)),
                    ),
                    TextButton.icon(
                      onPressed: isTesting
                          ? null
                          : () async {
                              setDialogState(() {
                                isTesting = true;
                                testMessage = null;
                              });
                              final found = await api.findWorkingBaseUrl();
                              setDialogState(() {
                                isTesting = false;
                                if (found != null) {
                                  urlCtrl.text = found;
                                  testSuccess = true;
                                  testMessage = 'Auto-detected working server!';
                                } else {
                                  testSuccess = false;
                                  testMessage = 'Could not find an active server automatically.';
                                }
                              });
                            },
                      icon: const Icon(Icons.auto_awesome, size: 14),
                      label: const Text('Auto-Detect', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ),
                if (testMessage != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: (testSuccess == true ? AppColors.inStock : AppColors.danger)
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          testSuccess == true ? Icons.check_circle : Icons.error,
                          size: 14,
                          color: testSuccess == true ? AppColors.inStock : AppColors.danger,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            testMessage!,
                            style: TextStyle(
                              fontSize: 11,
                              color: testSuccess == true ? AppColors.inStock : AppColors.danger,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final newUrl = urlCtrl.text.trim();
                if (newUrl.isNotEmpty) {
                  await api.setBaseUrl(newUrl);
                }
                if (ctx.mounted) Navigator.pop(ctx);
              },
              child: const Text('Save & Apply'),
            ),
          ],
        ),
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
