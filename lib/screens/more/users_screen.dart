import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/user_profile.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/common_widgets.dart';
import 'widgets/user_card.dart';
import 'widgets/user_dialogs.dart';

/// Feature 14: User Management (ADMIN Only)
/// Supports: View, Create, Edit, Activate, Deactivate, Change Role, Search, Filter
class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String? _selectedRole; // 'ADMIN', 'WAREHOUSE_MANAGER', 'STAFF', or null
  String? _selectedStatus; // 'Active', 'Inactive', or null

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.user?.canManageUsers == true && auth.users.isEmpty) {
        auth.fetchUsers();
      }
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
    final currentUser = auth.user;
    final theme = Theme.of(context);

    // Role check guard: Staff cannot do user management (Admin only)
    if (currentUser?.canManageUsers != true) {
      return Scaffold(
        appBar: AppBar(title: const Text('User Management')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.gpp_bad_outlined, size: 64, color: AppColors.danger),
                const SizedBox(height: 16),
                Text('Access Restricted', style: theme.textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text(
                  'User Management is restricted to system administrators only. Staff accounts do not have permission to manage users.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: AppColors.secondaryText),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Go Back'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final allUsers = auth.users;

    // Filter users
    final filteredUsers = allUsers.where((u) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = u.name.toLowerCase().contains(q);
        final matchUser = u.username?.toLowerCase().contains(q) ?? false;
        final matchEmail = u.email.toLowerCase().contains(q);
        if (!matchName && !matchUser && !matchEmail) return false;
      }
      if (_selectedRole != null && u.role.toUpperCase() != _selectedRole!.toUpperCase()) {
        return false;
      }
      if (_selectedStatus != null && u.status.toLowerCase() != _selectedStatus!.toLowerCase()) {
        return false;
      }
      return true;
    }).toList();

    final adminCount = allUsers.where((u) => u.isAdmin).length;
    final managerCount = allUsers.where((u) => u.isManager).length;
    final staffCount = allUsers.where((u) => u.isStaff).length;
    final activeCount = allUsers.where((u) => u.isActive).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Management'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchField(
              controller: _searchCtrl,
              hint: 'Search by name, username, email...',
              onChanged: (q) => setState(() => _searchQuery = q),
            ),
          ),
        ),
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 840),
          child: Column(
            children: [
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _FilterChip(
                  label: 'All (${allUsers.length})',
                  selected: _selectedRole == null && _selectedStatus == null,
                  onSelected: (_) => setState(() {
                    _selectedRole = null;
                    _selectedStatus = null;
                  }),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Admin ($adminCount)',
                  selected: _selectedRole == 'ADMIN',
                  color: AppColors.primary,
                  onSelected: (val) => setState(() => _selectedRole = val ? 'ADMIN' : null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Manager ($managerCount)',
                  selected: _selectedRole == 'MANAGER',
                  color: const Color(0xFFD97706),
                  onSelected: (val) => setState(() => _selectedRole = val ? 'MANAGER' : null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Staff ($staffCount)',
                  selected: _selectedRole == 'STAFF',
                  color: const Color(0xFF0EA5E9),
                  onSelected: (val) => setState(() => _selectedRole = val ? 'STAFF' : null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active ($activeCount)',
                  selected: _selectedStatus == 'Active',
                  color: AppColors.inStock,
                  onSelected: (val) => setState(() => _selectedStatus = val ? 'Active' : null),
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Pending / Inactive (${allUsers.length - activeCount})',
                  selected: _selectedStatus == 'Inactive',
                  color: const Color(0xFFD97706),
                  onSelected: (val) => setState(() => _selectedStatus = val ? 'Inactive' : null),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // User list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => auth.fetchUsers(),
              child: filteredUsers.isEmpty
                  ? ListView(
                      children: const [
                        SizedBox(height: 80),
                        EmptyState(
                          message: 'No users found',
                          icon: Icons.people_outline,
                          subtitle: 'Try adjusting your search terms or filters',
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 88),
                      itemCount: filteredUsers.length,
                      itemBuilder: (ctx, idx) {
                        final u = filteredUsers[idx];
                        final isCurrentLoggedIn = u.id == currentUser?.id;

                        return UserCard(
                          user: u,
                          isCurrentLoggedIn: isCurrentLoggedIn,
                          onEdit: () => AddEditUserSheet.show(context, user: u),
                          onChangeRole: () => _handleRoleChange(context, auth, u),
                          onToggleStatus: () => _handleToggleStatus(context, auth, u),
                          onDelete: isCurrentLoggedIn ? null : () => _handleDeleteUser(context, auth, u),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    ),
  ),
  floatingActionButton: FloatingActionButton.extended(
        onPressed: () => AddEditUserSheet.show(context, user: null),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add User'),
      ),
    );
  }

  Future<void> _handleToggleStatus(BuildContext context, AuthProvider auth, UserProfile target) async {
    final willDeactivate = target.isActive;
    final action = willDeactivate ? 'Deactivate' : 'Approve & Activate';

    final confirmed = await ConfirmDialog.show(
      context,
      title: willDeactivate ? 'Deactivate User' : 'Approve & Activate User',
      message: willDeactivate
          ? 'Deactivate account for "${target.name}"? They will no longer be able to log in.'
          : 'Approve and activate account for "${target.name}"? They will now be allowed to log in.',
      confirmLabel: action,
      confirmColor: willDeactivate ? AppColors.danger : AppColors.inStock,
    );

    if (confirmed && context.mounted) {
      final ok = await auth.toggleUserStatus(target.id);
      if (ok && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${target.name} has been ${willDeactivate ? 'deactivated' : 'approved and activated'}'),
            backgroundColor: willDeactivate ? AppColors.danger : AppColors.inStock,
          ),
        );
      }
    }
  }

  Future<void> _handleRoleChange(BuildContext context, AuthProvider auth, UserProfile target) async {
    final newRole = await UserRoleDialog.show(context, target: target);

    if (newRole != null && newRole != target.role.toUpperCase() && context.mounted) {
      final ok = await auth.changeUserRole(target.id, newRole);
      if (context.mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${target.name}\'s role changed to $newRole'),
              backgroundColor: AppColors.primary,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(auth.error ?? 'Cannot update user role to ADMIN. Maximum limit reached.'),
              backgroundColor: AppColors.danger,
            ),
          );
        }
      }
    }
  }

  Future<void> _handleDeleteUser(BuildContext context, AuthProvider auth, UserProfile target) async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete User',
      message: 'Are you sure you want to permanently delete user "${target.name}"? This action cannot be undone.',
      confirmLabel: 'Delete',
      confirmColor: AppColors.danger,
    );
    if (confirmed && context.mounted) {
      final ok = await auth.deleteUser(target.id);
      if (context.mounted) {
        if (ok) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('User "${target.name}" deleted successfully.')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(auth.error ?? 'Failed to delete user'), backgroundColor: AppColors.danger),
          );
        }
      }
    }
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  final Color? color;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: c.withValues(alpha: 0.15),
      checkmarkColor: c,
      labelStyle: TextStyle(
        color: selected ? c : null,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
      ),
    );
  }
}
