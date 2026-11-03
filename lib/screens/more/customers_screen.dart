import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/customer_provider.dart';
import '../../providers/stock_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/customer.dart';

/// Customer Management Screen matching backend Customer module and suppliers_screen pattern
/// Operations: Create, Read, Update, Delete (Admin), Search, Active Filter
class CustomersScreen extends StatefulWidget {
  const CustomersScreen({super.key});

  @override
  State<CustomersScreen> createState() => _CustomersScreenState();
}

class _CustomersScreenState extends State<CustomersScreen> {
  final _searchCtrl = TextEditingController();
  bool? _statusFilter; // true=Active, false=Inactive, null=All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<CustomerProvider>();
      if (prov.allCustomers.isEmpty) prov.fetchCustomers();
      final stockProv = context.read<StockProvider>();
      if (stockProv.allMovements.isEmpty) stockProv.fetchMovements();
    });
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final canManageCustomers = auth.user?.canManageCustomers ?? false;
    final canDeleteCustomers = auth.user?.canDeleteCustomers ?? false;
    final prov = context.watch<CustomerProvider>();
    final stockProv = context.watch<StockProvider>();
    final allCustomers = prov.customers;

    final customers = allCustomers.where((c) {
      if (_statusFilter != null && c.isActive != _statusFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customer Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search by customer name, phone, email...',
              onChanged: prov.setSearch,
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            children: [
              // Filter Chips
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _CustomerStatusFilterChip(
                      label: 'All (${prov.allCustomers.length})',
                      selected: _statusFilter == null,
                      onSelected: () => setState(() => _statusFilter = null),
                    ),
                    const SizedBox(width: 8),
                    _CustomerStatusFilterChip(
                      label: 'Active (${prov.allCustomers.where((c) => c.isActive).length})',
                      selected: _statusFilter == true,
                      color: AppColors.inStock,
                      onSelected: () => setState(() => _statusFilter = true),
                    ),
                    const SizedBox(width: 8),
                    _CustomerStatusFilterChip(
                      label: 'Inactive (${prov.allCustomers.where((c) => !c.isActive).length})',
                      selected: _statusFilter == false,
                      color: AppColors.danger,
                      onSelected: () => setState(() => _statusFilter = false),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: prov.isLoading && prov.allCustomers.isEmpty
                    ? const Center(child: CircularProgressIndicator())
                    : prov.error != null && prov.allCustomers.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.error_outline, size: 48, color: AppColors.danger),
                                  const SizedBox(height: 12),
                                  Text(
                                    prov.error!,
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: AppColors.danger, fontSize: 14),
                                  ),
                                  const SizedBox(height: 16),
                                  FilledButton(
                                    onPressed: () => prov.fetchCustomers(),
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : RefreshIndicator(
                            onRefresh: () => prov.fetchCustomers(),
                            child: customers.isEmpty
                                ? ListView(
                                    children: [
                                      const SizedBox(height: 80),
                                      EmptyState(
                                        message: 'No customers found',
                                        subtitle: prov.search.isNotEmpty
                                            ? 'Try a different search term'
                                            : 'Tap + Add Customer to register a new customer',
                                        icon: Icons.person_search_outlined,
                                      ),
                                    ],
                                  )
                                : ListView.separated(
                                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                                    itemCount: customers.length,
                                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                                    itemBuilder: (_, i) {
                                      final c = customers[i];
                                      final txCount = stockProv.allMovements
                                          .where((m) => m.customerId == c.id)
                                          .length;
                                      final initials = c.name.trim().isNotEmpty
                                          ? (c.name.trim().split(' ').length > 1
                                              ? '${c.name.trim().split(' ')[0][0]}${c.name.trim().split(' ')[1][0]}'.toUpperCase()
                                              : c.name.trim().substring(0, c.name.trim().length >= 2 ? 2 : 1).toUpperCase())
                                          : 'C';

                                      return Card(
                                        child: Padding(
                                          padding: const EdgeInsets.all(12),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Row(
                                                crossAxisAlignment: CrossAxisAlignment.start,
                                                children: [
                                                  CircleAvatar(
                                                    radius: 22,
                                                    backgroundColor: const Color(0xFF16A34A),
                                                    child: Text(
                                                      initials,
                                                      style: const TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14,
                                                        fontWeight: FontWeight.bold,
                                                      ),
                                                    ),
                                                  ),
                                                  const SizedBox(width: 12),
                                                  Expanded(
                                                    child: Column(
                                                      crossAxisAlignment: CrossAxisAlignment.start,
                                                      children: [
                                                        Row(
                                                          children: [
                                                            Flexible(
                                                              child: Text(
                                                                c.name,
                                                                style: const TextStyle(
                                                                  fontWeight: FontWeight.w600,
                                                                  fontSize: 15,
                                                                ),
                                                                overflow: TextOverflow.ellipsis,
                                                              ),
                                                            ),
                                                            const SizedBox(width: 6),
                                                            Container(
                                                              padding: const EdgeInsets.symmetric(
                                                                  horizontal: 6, vertical: 2),
                                                              decoration: BoxDecoration(
                                                                color: (c.isActive
                                                                        ? AppColors.inStock
                                                                        : AppColors.danger)
                                                                    .withValues(alpha: 0.12),
                                                                borderRadius:
                                                                    BorderRadius.circular(4),
                                                              ),
                                                              child: Text(
                                                                c.isActive ? 'ACTIVE' : 'INACTIVE',
                                                                style: TextStyle(
                                                                  color: c.isActive
                                                                      ? AppColors.inStock
                                                                      : AppColors.danger,
                                                                  fontSize: 9,
                                                                  fontWeight: FontWeight.bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ],
                                                        ),
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.phone_outlined,
                                                                size: 13, color: AppColors.grey500),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              c.phone,
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: AppColors.secondaryText),
                                                            ),
                                                            if (c.email != null && c.email!.isNotEmpty) ...[
                                                              const SizedBox(width: 12),
                                                              const Icon(Icons.email_outlined,
                                                                  size: 13, color: AppColors.grey500),
                                                              const SizedBox(width: 4),
                                                              Flexible(
                                                                child: Text(
                                                                  c.email!,
                                                                  style: const TextStyle(
                                                                      fontSize: 12,
                                                                      color: AppColors.secondaryText),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ],
                                                        ),
                                                        if (c.address != null && c.address!.isNotEmpty) ...[
                                                          const SizedBox(height: 4),
                                                          Row(
                                                            children: [
                                                              const Icon(Icons.location_on_outlined,
                                                                  size: 13, color: AppColors.grey500),
                                                              const SizedBox(width: 4),
                                                              Flexible(
                                                                child: Text(
                                                                  c.address!,
                                                                  style: const TextStyle(
                                                                      fontSize: 11,
                                                                      color: AppColors.grey500),
                                                                  overflow: TextOverflow.ellipsis,
                                                                ),
                                                              ),
                                                            ],
                                                          ),
                                                        ],
                                                        const SizedBox(height: 4),
                                                        Row(
                                                          children: [
                                                            const Icon(Icons.receipt_long_outlined,
                                                                size: 13, color: AppColors.grey500),
                                                            const SizedBox(width: 4),
                                                            Text(
                                                              '$txCount transaction${txCount == 1 ? "" : "s"} linked',
                                                              style: const TextStyle(
                                                                  fontSize: 12,
                                                                  color: AppColors.secondaryText),
                                                            ),
                                                          ],
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                ],
                                              ),
                                              if (canManageCustomers) ...[
                                                const Divider(height: 16),
                                                Align(
                                                  alignment: Alignment.centerRight,
                                                  child: Wrap(
                                                    alignment: WrapAlignment.end,
                                                    spacing: 4,
                                                    runSpacing: 4,
                                                    children: [
                                                      TextButton.icon(
                                                        icon: const Icon(Icons.edit_outlined, size: 16),
                                                        label: const Text('Edit'),
                                                        onPressed: () => _openForm(context, c),
                                                      ),
                                                      TextButton.icon(
                                                        icon: Icon(
                                                          c.isActive ? Icons.toggle_on : Icons.toggle_off,
                                                          size: 20,
                                                          color: c.isActive ? AppColors.inStock : AppColors.grey500,
                                                        ),
                                                        label: Text(
                                                          c.isActive ? 'Active' : 'Inactive',
                                                          style: TextStyle(
                                                            color: c.isActive ? AppColors.inStock : AppColors.grey500,
                                                          ),
                                                        ),
                                                        onPressed: () async {
                                                          final ok = await prov.toggleCustomerStatus(c.id, !c.isActive);
                                                          if (ok && context.mounted) {
                                                            ScaffoldMessenger.of(context).showSnackBar(
                                                              SnackBar(
                                                                content: Text(
                                                                  '${c.name} is now ${c.isActive ? "Inactive" : "Active"}',
                                                                ),
                                                              ),
                                                            );
                                                          }
                                                        },
                                                      ),
                                                      if (canDeleteCustomers)
                                                        TextButton.icon(
                                                          icon: const Icon(Icons.delete_outline,
                                                              size: 16, color: AppColors.danger),
                                                          label: const Text('Delete',
                                                              style: TextStyle(color: AppColors.danger)),
                                                          onPressed: () =>
                                                              _handleDeleteCustomer(context, c, txCount),
                                                        ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: canManageCustomers
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context, null),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.person_add_alt_outlined),
              label: const Text('Add Customer'),
            )
          : null,
    );
  }

  /// Business Rule Implementation (matching Category and Supplier):
  /// If a customer has transactions linked, deletion is blocked
  /// and the user is guided to soft deactivation instead.
  Future<void> _handleDeleteCustomer(
      BuildContext context, Customer c, int txCount) async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canDeleteCustomers != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff accounts cannot delete customers.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    final prov = context.read<CustomerProvider>();

    if (txCount > 0) {
      // Customer has transactions -> Block deletion & recommend soft deactivation
      final result = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Customer In Use'),
          content: Text(
            'Customer "${c.name}" has $txCount transaction(s) linked to them.\n\n'
            'To maintain sales and transaction history integrity, soft deactivation is recommended instead of permanent deletion.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, 'cancel'),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.pause_circle_outline, size: 18),
              label: const Text('Soft Deactivate'),
              style:
                  ElevatedButton.styleFrom(backgroundColor: AppColors.warning),
              onPressed: () => Navigator.pop(ctx, 'deactivate'),
            ),
          ],
        ),
      );

      if (result == 'deactivate' && context.mounted) {
        final ok = await prov.deactivateCustomer(c.id);
        if (context.mounted && ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('"${c.name}" has been soft-deactivated.'),
              backgroundColor: AppColors.warning,
            ),
          );
        }
      }
    } else {
      // No local transactions found -> Confirm before calling delete API
      final confirmed = await ConfirmDialog.show(
        context,
        title: 'Delete Customer',
        message:
            'Are you sure you want to delete customer "${c.name}"? This customer has no transaction records.',
        confirmLabel: 'Delete',
        confirmColor: AppColors.danger,
      );

      if (confirmed && context.mounted) {
        final ok = await prov.deleteCustomer(c.id);
        if (context.mounted) {
          if (ok) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Customer "${c.name}" deleted.')),
            );
          } else {
            // Check if backend rejected deletion due to stock transactions (409 Conflict)
            final errorMsg = prov.error ?? 'Failed to delete customer';
            final isConflict = errorMsg.toLowerCase().contains('transaction') ||
                errorMsg.toLowerCase().contains('referenced') ||
                errorMsg.toLowerCase().contains('conflict');

            if (isConflict) {
              final action = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Customer In Use'),
                  content: Text(
                    'Cannot delete "${c.name}" because this customer is referenced by transaction records in the system.\n\n'
                    'To maintain transaction and sales integrity, soft deactivation is recommended instead of permanent deletion.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, 'cancel'),
                      child: const Text('Cancel'),
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.pause_circle_outline, size: 18),
                      label: const Text('Soft Deactivate'),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning),
                      onPressed: () => Navigator.pop(ctx, 'deactivate'),
                    ),
                  ],
                ),
              );

              if (action == 'deactivate' && context.mounted) {
                final deactivated = await prov.deactivateCustomer(c.id);
                if (context.mounted && deactivated) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('"${c.name}" has been soft-deactivated.'),
                      backgroundColor: AppColors.warning,
                    ),
                  );
                }
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(errorMsg),
                  backgroundColor: AppColors.danger,
                ),
              );
            }
          }
        }
      }
    }
  }

  void _openForm(BuildContext context, Customer? customer) {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canManageCustomers != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff accounts cannot add or edit customers.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _CustomerFormScreen(customer: customer),
    ));
  }
}

class _CustomerStatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _CustomerStatusFilterChip({
    required this.label,
    required this.selected,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
      selectedColor: c.withValues(alpha: 0.15),
      labelStyle: TextStyle(
        color: selected ? c : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}

/// Full-screen customer add/edit form
class _CustomerFormScreen extends StatefulWidget {
  final Customer? customer;
  const _CustomerFormScreen({this.customer});

  @override
  State<_CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<_CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  bool _saving = false;

  bool get _isEditing => widget.customer != null;

  @override
  void initState() {
    super.initState();
    final c = widget.customer;
    _nameCtrl = TextEditingController(text: c?.name ?? '');
    _phoneCtrl = TextEditingController(text: c?.phone ?? '');
    _emailCtrl = TextEditingController(text: c?.email ?? '');
    _addressCtrl = TextEditingController(text: c?.address ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final prov = context.read<CustomerProvider>();
    final email = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim();

    try {
      if (_isEditing) {
        final updated = widget.customer!.copyWith(
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: email,
          address: address,
        );
        final res = await prov.updateCustomer(updated);
        if (mounted) {
          setState(() => _saving = false);
          if (res != null) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer updated successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(prov.error ?? 'Failed to update customer'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      } else {
        final newCustomer = Customer(
          id: '',
          name: _nameCtrl.text.trim(),
          phone: _phoneCtrl.text.trim(),
          email: email,
          address: address,
        );
        final res = await prov.addCustomer(newCustomer);
        if (mounted) {
          setState(() => _saving = false);
          if (res != null) {
            Navigator.pop(context);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Customer created successfully')),
            );
          } else {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(prov.error ?? 'Failed to create customer'),
                backgroundColor: AppColors.danger,
              ),
            );
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.danger),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Customer' : 'Add Customer'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                TextFormField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Customer Name *',
                    hintText: 'e.g. Sophea Chan',
                    prefixIcon: Icon(Icons.person_outline),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Customer name is required';
                    if (v.trim().length < 2) return 'Name must be at least 2 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone Number *',
                    hintText: 'e.g. +85512345678',
                    prefixIcon: Icon(Icons.phone_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Phone number is required';
                    if (v.trim().length < 7) return 'Enter a valid phone number';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email Address (Gmail preferred)',
                    hintText: 'e.g. sophea.chan@gmail.com',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v != null && v.trim().isNotEmpty) {
                      if (!v.contains('@') || !v.contains('.')) {
                        return 'Enter a valid email address';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _addressCtrl,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Delivery / Physical Address',
                    hintText: 'e.g. No. 128, Street 271, Phnom Penh',
                    prefixIcon: Icon(Icons.location_on_outlined),
                  ),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: _saving ? null : _save,
                  icon: _saving
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.check),
                  label: Text(_isEditing ? 'Save Changes' : 'Create Customer'),
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 50),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
