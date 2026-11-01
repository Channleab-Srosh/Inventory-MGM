import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/supplier_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/supplier.dart';

/// Features 7 & 8: Supplier Management Screen
/// Fields: ID, Name, Phone, Email, Address, Status, Created Date, Updated Date
/// Operations: Create, Read, Update, Delete, Search (by Name, Phone)
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchCtrl = TextEditingController();
  bool? _statusFilter; // true=Active, false=Inactive, null=All

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prov = context.read<SupplierProvider>();
      if (prov.allSuppliers.isEmpty) prov.fetchSuppliers();
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
    final canManageSuppliers = auth.user?.canManageSuppliers ?? true;
    final prov = context.watch<SupplierProvider>();
    final allSuppliers = prov.suppliers;

    final suppliers = allSuppliers.where((s) {
      if (_statusFilter != null && s.isActive != _statusFilter) {
        return false;
      }
      return true;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Supplier Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search by supplier name, phone, email...',
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
                _StatusFilterChip(
                  label: 'All (${prov.allSuppliers.length})',
                  selected: _statusFilter == null,
                  onSelected: () => setState(() => _statusFilter = null),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: 'Active (${prov.allSuppliers.where((s) => s.isActive).length})',
                  selected: _statusFilter == true,
                  color: AppColors.inStock,
                  onSelected: () => setState(() => _statusFilter = true),
                ),
                const SizedBox(width: 8),
                _StatusFilterChip(
                  label: 'Inactive (${prov.allSuppliers.where((s) => !s.isActive).length})',
                  selected: _statusFilter == false,
                  color: AppColors.danger,
                  onSelected: () => setState(() => _statusFilter = false),
                ),
              ],
            ),
          ),

          Expanded(
            child: prov.isLoading && prov.allSuppliers.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : prov.error != null && prov.allSuppliers.isEmpty
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
                                onPressed: () => prov.fetchSuppliers(),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () => prov.fetchSuppliers(),
                        child: suppliers.isEmpty
                            ? ListView(
                                children: [
                                  const SizedBox(height: 80),
                                  EmptyState(
                                    message: 'No suppliers found',
                                    subtitle: prov.search.isNotEmpty
                                        ? 'Try a different search term'
                                        : 'Tap + Add Supplier to register a new vendor',
                                    icon: Icons.business_outlined,
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                                itemCount: suppliers.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 6),
                                itemBuilder: (_, i) {
                      final s = suppliers[i];
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
                                    backgroundColor: const Color(0xFF0EA5E9),
                                    child: Text(
                                      s.initials,
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
                                                s.name,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
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
                                                color: (s.isActive
                                                        ? AppColors.inStock
                                                        : AppColors.danger)
                                                    .withValues(alpha: 0.12),
                                                borderRadius:
                                                    BorderRadius.circular(4),
                                              ),
                                              child: Text(
                                                s.status.toUpperCase(),
                                                style: TextStyle(
                                                  color: s.isActive
                                                      ? AppColors.inStock
                                                      : AppColors.danger,
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        if (s.contactPerson != null &&
                                            s.contactPerson!.isNotEmpty) ...[
                                          const SizedBox(height: 2),
                                          Text(
                                            'Contact: ${s.contactPerson!}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.secondaryText,
                                            ),
                                          ),
                                        ],
                                        const SizedBox(height: 4),
                                        Row(
                                          children: [
                                            if (s.phone != null && s.phone!.isNotEmpty) ...[
                                              const Icon(Icons.phone_outlined,
                                                  size: 13, color: AppColors.grey500),
                                              const SizedBox(width: 4),
                                              Text(
                                                s.phone!,
                                                style: const TextStyle(
                                                    fontSize: 12,
                                                    color: AppColors.secondaryText),
                                              ),
                                              const SizedBox(width: 12),
                                            ],
                                            if (s.email != null && s.email!.isNotEmpty) ...[
                                              const Icon(Icons.email_outlined,
                                                  size: 13, color: AppColors.grey500),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  s.email!,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color: AppColors.secondaryText),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                        if (s.address != null && s.address!.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.location_on_outlined,
                                                  size: 13, color: AppColors.grey500),
                                              const SizedBox(width: 4),
                                              Flexible(
                                                child: Text(
                                                  s.address!,
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color: AppColors.grey500),
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              if (canManageSuppliers) ...[
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
                                        onPressed: () => _openForm(context, s),
                                      ),
                                      TextButton.icon(
                                        icon: Icon(
                                          s.isActive ? Icons.toggle_on : Icons.toggle_off,
                                          size: 20,
                                          color: s.isActive ? AppColors.inStock : AppColors.grey500,
                                        ),
                                        label: Text(
                                          s.isActive ? 'Active' : 'Inactive',
                                          style: TextStyle(
                                            color: s.isActive ? AppColors.inStock : AppColors.grey500,
                                          ),
                                        ),
                                        onPressed: () {
                                          prov.toggleSupplierStatus(s.id);
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                '${s.name} is now ${s.isActive ? "Inactive" : "Active"}',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                      TextButton.icon(
                                        icon: const Icon(Icons.delete_outline,
                                            size: 16, color: AppColors.danger),
                                        label: const Text('Delete',
                                            style: TextStyle(color: AppColors.danger)),
                                        onPressed: () async {
                                          final confirmed = await ConfirmDialog.show(
                                            context,
                                            title: 'Delete Supplier',
                                            message:
                                                'Delete "${s.name}"? Products supplied by this vendor will remain in the catalog.',
                                            confirmLabel: 'Delete',
                                            confirmColor: AppColors.danger,
                                          );
                                          if (confirmed && context.mounted) {
                                            await prov.deleteSupplier(s.id);
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('${s.name} deleted')),
                                              );
                                            }
                                          }
                                        },
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
  floatingActionButton: canManageSuppliers
          ? FloatingActionButton.extended(
              onPressed: () => _openForm(context, null),
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Add Supplier'),
            )
          : null,
    );
  }

  void _openForm(BuildContext context, Supplier? supplier) {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canManageSuppliers != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff accounts cannot add or edit suppliers.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _SupplierFormScreen(supplier: supplier),
    ));
  }
}

class _StatusFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final VoidCallback onSelected;

  const _StatusFilterChip({
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

/// Full-screen supplier add/edit form
class _SupplierFormScreen extends StatefulWidget {
  final Supplier? supplier;
  const _SupplierFormScreen({this.supplier});

  @override
  State<_SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<_SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _contactCtrl;
  String _status = 'Active';

  bool get _isEditing => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    final s = widget.supplier;
    _nameCtrl = TextEditingController(text: s?.name ?? '');
    _phoneCtrl = TextEditingController(text: s?.phone ?? '');
    _emailCtrl = TextEditingController(text: s?.email ?? '');
    _addressCtrl = TextEditingController(text: s?.address ?? '');
    _contactCtrl = TextEditingController(text: s?.contactPerson ?? '');
    _status = s?.status ?? 'Active';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _addressCtrl.dispose();
    _contactCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final auth = context.read<AuthProvider>();
    if (auth.user?.canManageSuppliers != true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Staff accounts cannot add or edit suppliers.'),
          backgroundColor: AppColors.danger,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<SupplierProvider>();
    final name = _nameCtrl.text.trim();
    final phone = _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim();
    final email = _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim();
    final address = _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim();
    final contact = _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim();

    if (_isEditing) {
      await prov.updateSupplier(widget.supplier!.copyWith(
        name: name,
        phone: phone,
        email: email,
        address: address,
        contactPerson: contact,
        status: _status,
      ));
    } else {
      await prov.addSupplier(Supplier(
        id: prov.generateId(),
        name: name,
        phone: phone,
        email: email,
        address: address,
        contactPerson: contact,
        status: _status,
      ));
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(_isEditing ? 'Supplier updated!' : 'Supplier added!')));
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (auth.user?.canManageSuppliers != true) {
      return Scaffold(
        appBar: AppBar(title: Text(_isEditing ? 'Edit Supplier' : 'Add Supplier')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.lock_outline, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Access Restricted', style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'Staff accounts cannot add or edit suppliers.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Supplier' : 'Add Supplier'),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Supplier Name *',
                hintText: 'e.g. ABC Distribution',
                prefixIcon: Icon(Icons.business_outlined),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _contactCtrl,
              decoration: const InputDecoration(
                labelText: 'Contact Person',
                hintText: 'e.g. Mr. Seng',
                prefixIcon: Icon(Icons.person_outline),
              ),
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                labelText: 'Phone *',
                hintText: 'e.g. 012 345 678',
                prefixIcon: Icon(Icons.phone_outlined),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return 'Phone number is required';
                }
                final clean = v.trim();
                final phoneReg = RegExp(r'^[0-9+()\-\s]{7,20}$');
                if (!phoneReg.hasMatch(clean)) {
                  return 'Invalid phone format (7-20 digits)';
                }
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'abc@gmail.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Address',
                hintText: 'e.g. Phnom Penh',
                alignLabelWithHint: true,
                prefixIcon: Icon(Icons.location_on_outlined),
              ),
            ),
            const SizedBox(height: 14),
            DropdownButtonFormField<String>(
              isExpanded: true,
              initialValue: _status,
              decoration: const InputDecoration(
                labelText: 'Status',
                prefixIcon: Icon(Icons.toggle_on_outlined),
              ),
              items: const [
                DropdownMenuItem(value: 'Active', child: Text('Active')),
                DropdownMenuItem(value: 'Inactive', child: Text('Inactive')),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _status = val);
              },
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.check),
              label: Text(_isEditing ? 'Save Changes' : 'Create Supplier'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    ),
  ),
);
  }
}
