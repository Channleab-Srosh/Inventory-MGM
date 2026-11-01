import 'package:flutter/material.dart';
import '../../../models/user_profile.dart';
import '../../../core/theme/app_theme.dart';

/// Reusable User Card for displaying and managing users in UserManagementScreen
class UserCard extends StatelessWidget {
  final UserProfile user;
  final bool isCurrentLoggedIn;
  final VoidCallback onEdit;
  final VoidCallback onChangeRole;
  final VoidCallback onToggleStatus;
  final VoidCallback? onDelete;

  const UserCard({
    super.key,
    required this.user,
    required this.isCurrentLoggedIn,
    required this.onEdit,
    required this.onChangeRole,
    required this.onToggleStatus,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final u = user;

    final Color roleColor = u.isAdmin
        ? AppColors.primary
        : (u.isWarehouseManager
            ? const Color(0xFFD97706)
            : const Color(0xFF0EA5E9));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: roleColor,
                  child: Text(
                    u.initials,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
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
                              u.name,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isCurrentLoggedIn) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'YOU',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '@${u.username ?? u.email.split('@').first}',
                        style: const TextStyle(
                          color: AppColors.grey500,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        u.email,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 13),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (u.phone != null && u.phone!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.phone_outlined, size: 13, color: AppColors.grey500),
                            const SizedBox(width: 4),
                            Text(
                              u.phone!,
                              style: const TextStyle(fontSize: 12, color: AppColors.secondaryText),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Role badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        u.roleBadgeLabel,
                        style: TextStyle(
                          color: roleColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: u.isActive
                            ? AppColors.inStock.withValues(alpha: 0.15)
                            : const Color(0xFFD97706).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3,
                            backgroundColor: u.isActive ? AppColors.inStock : const Color(0xFFD97706),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            u.isActive ? 'ACTIVE' : 'PENDING APPROVAL',
                            style: TextStyle(
                              color: u.isActive ? AppColors.inStock : const Color(0xFFD97706),
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const Divider(height: 18),
            // Actions Wrap
            Align(
              alignment: Alignment.centerRight,
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: [
                  // Edit User
                  TextButton.icon(
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Edit'),
                    onPressed: onEdit,
                  ),

                  // Change Role
                  TextButton.icon(
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: const Text('Role'),
                    onPressed: isCurrentLoggedIn
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('You cannot change your own role.')),
                            );
                          }
                        : onChangeRole,
                  ),

                  // Toggle Status (Activate / Deactivate / Approve)
                  TextButton.icon(
                    icon: Icon(
                      u.isActive ? Icons.block_outlined : Icons.verified_user_outlined,
                      size: 16,
                      color: u.isActive ? AppColors.danger : AppColors.inStock,
                    ),
                    label: Text(
                      u.isActive ? 'Deactivate' : 'Approve',
                      style: TextStyle(
                        color: u.isActive ? AppColors.danger : AppColors.inStock,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    onPressed: isCurrentLoggedIn
                        ? () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('You cannot deactivate your own account.')),
                            );
                          }
                        : onToggleStatus,
                  ),

                  // Delete User
                  if (!isCurrentLoggedIn && onDelete != null)
                    TextButton.icon(
                      icon: const Icon(Icons.delete_outline, size: 16, color: AppColors.danger),
                      label: const Text('Delete', style: TextStyle(color: AppColors.danger)),
                      onPressed: onDelete,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
