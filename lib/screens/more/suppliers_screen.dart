import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import '../../models/supplier.dart';

/// Suppliers screen with search, list, and full-screen form
class SuppliersScreen extends StatefulWidget {
  const SuppliersScreen({super.key});

  @override
  State<SuppliersScreen> createState() => _SuppliersScreenState();
}

class _SuppliersScreenState extends State<SuppliersScreen> {
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<SupplierProvider>();
    final suppliers = prov.suppliers;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Suppliers'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search suppliers...',
              onChanged: prov.setSearch,
            ),
          ),
        ),
      ),
      body: suppliers.isEmpty
          ? EmptyState(
              message: 'No suppliers found',
              icon: Icons.business_outlined,
              action: ElevatedButton.icon(
                onPressed: () => _openForm(context, null),
                icon: const Icon(Icons.add),
                label: const Text('Add Supplier'),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
              itemCount: suppliers.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (_, i) {
                final s = suppliers[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Text(s.initials,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                    title: Text(s.name),
                    subtitle: Text(s.phone ?? s.email ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (s.phone != null)
                          IconButton(
                            icon: const Icon(Icons.phone_outlined,
                                size: 20, color: AppColors.inStock),
                            onPressed: () {},
                          ),
                        if (s.email != null)
                          IconButton(
                            icon: const Icon(Icons.email_outlined,
                                size: 20, color: AppColors.primary),
                            onPressed: () {},
                          ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined,
                              size: 20, color: AppColors.grey500),
                          onPressed: () => _openForm(context, s),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline,
                              size: 20, color: AppColors.danger),
                          onPressed: () async {
                            final confirmed = await ConfirmDialog.show(
                              context,
                              title: 'Delete Supplier',
                              message:
                                  'Delete "${s.name}"? Products supplied by this vendor will remain in the catalog.',
                            );
                            if (confirmed && context.mounted) {
                              context.read<SupplierProvider>().deleteSupplier(s.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${s.name} deleted')),
                              );
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _openForm(context, null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _openForm(BuildContext context, Supplier? supplier) {
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => _SupplierFormScreen(supplier: supplier),
    ));
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

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    final prov = context.read<SupplierProvider>();
    if (_isEditing) {
      prov.updateSupplier(widget.supplier!.copyWith(
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      ));
    } else {
      prov.addSupplier(Supplier(
        id: prov.generateId(),
        name: _nameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim().isEmpty ? null : _phoneCtrl.text.trim(),
        email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
        address: _addressCtrl.text.trim().isEmpty ? null : _addressCtrl.text.trim(),
        contactPerson: _contactCtrl.text.trim().isEmpty ? null : _contactCtrl.text.trim(),
      ));
    }
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(_isEditing ? 'Supplier updated!' : 'Supplier added!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Supplier' : 'Add Supplier'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(labelText: 'Company Name *'),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Name is required' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _contactCtrl,
              decoration:
                  const InputDecoration(labelText: 'Contact Person'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _phoneCtrl,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                  labelText: 'Phone', prefixIcon: Icon(Icons.phone_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                  labelText: 'Email', prefixIcon: Icon(Icons.email_outlined)),
              validator: (v) {
                if (v == null || v.isEmpty) return null;
                if (!v.contains('@')) return 'Enter a valid email';
                return null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _addressCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Address',
                  alignLabelWithHint: true,
                  prefixIcon: Icon(Icons.location_on_outlined)),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _save,
              child: Text(_isEditing ? 'Update Supplier' : 'Add Supplier'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
