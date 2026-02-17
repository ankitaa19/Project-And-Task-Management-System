/**
 * Manage Users Screen
 * Admin can view all users with their roles and status
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/user_model.dart';
import 'create_user_screen.dart';

class ManageUsersScreen extends StatefulWidget {
  const ManageUsersScreen({super.key});

  @override
  State<ManageUsersScreen> createState() => _ManageUsersScreenState();
}

class _ManageUsersScreenState extends State<ManageUsersScreen> {
  final ApiService _api = ApiService();
  List<User> _users = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  /**
   * Load all users from API
   */
  Future<void> _loadUsers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiEndpoints.users);
      final List<dynamic> usersJson = response['users'] ?? [];

      // Parse and filter active users only
      final allUsers = usersJson.map((json) => User.fromJson(json)).toList();
      final activeUsers = allUsers.where((user) => user.isActive).toList();

      // Sort: Admin first, then Manager, then Member
      activeUsers.sort((a, b) {
        const roleOrder = {'admin': 0, 'manager': 1, 'member': 2};
        final aOrder = roleOrder[a.role.toLowerCase()] ?? 3;
        final bOrder = roleOrder[b.role.toLowerCase()] ?? 3;
        return aOrder.compareTo(bOrder);
      });

      setState(() {
        _users = activeUsers;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  /**
   * Get color for role badge
   */
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return AppTheme.primaryColor;
      case 'manager':
        return AppTheme.managerColor;
      case 'member':
        return AppTheme.memberColor;
      default:
        return Colors.grey;
    }
  }

  /**
   * Get icon for role
   */
  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Icons.admin_panel_settings;
      case 'manager':
        return Icons.manage_accounts;
      case 'member':
        return Icons.person;
      default:
        return Icons.person_outline;
    }
  }

  /**
   * Delete user after confirmation
   */
  Future<void> _deleteUser(User user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete "${user.name}" (${user.email})? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      await _api.delete(ApiEndpoints.userById(user.id));
      if (!mounted) return;
      // Update list immediately so the deleted user's card disappears
      setState(() {
        _users = _users.where((u) => u.id != user.id).toList();
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${user.name} deleted')),
      );
      // Reload from backend to stay in sync
      _loadUsers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Users'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadUsers),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          // Navigate to create user screen
          final result = await Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => const CreateUserScreen()));
          // Reload users if a new one was created
          if (result == true) {
            _loadUsers();
          }
        },
        icon: const Icon(Icons.person_add),
        label: const Text('New User'),
        backgroundColor: AppTheme.primaryColor,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadUsers,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _users.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No users found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a user to get started',
                    style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadUsers,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _users.length,
                itemBuilder: (context, index) {
                  final user = _users[index];
                  final isAdmin = user.role.toLowerCase() == 'admin';
                  return _UserCard(
                    user: user,
                    roleColor: _getRoleColor(user.role),
                    roleIcon: _getRoleIcon(user.role),
                    isAdmin: isAdmin,
                    onDelete: () => _deleteUser(user),
                  );
                },
              ),
            ),
    );
  }
}

/**
 * User Card Widget
 */
class _UserCard extends StatelessWidget {
  final User user;
  final Color roleColor;
  final IconData roleIcon;
  final bool isAdmin;
  final VoidCallback onDelete;

  const _UserCard({
    required this.user,
    required this.roleColor,
    required this.roleIcon,
    required this.onDelete,
    this.isAdmin = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: isAdmin ? 8 : 1,
      color: isAdmin ? AppTheme.primaryColor.withOpacity(0.05) : null,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isAdmin
            ? BorderSide(
                color: AppTheme.primaryColor.withOpacity(0.3),
                width: 2,
              )
            : BorderSide.none,
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Role Icon with admin badge
                Stack(
                  children: [
                    CircleAvatar(
                      backgroundColor: roleColor.withOpacity(0.2),
                      radius: 24,
                      child: Icon(roleIcon, color: roleColor, size: 24),
                    ),
                    if (isAdmin)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                          child: const Icon(
                            Icons.star,
                            size: 12,
                            color: Colors.white,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.name,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user.email,
                        style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                      ),
                    ],
                  ),
                ),

                // Role Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: roleColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    user.role.toUpperCase(),
                    style: TextStyle(
                      color: roleColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                // Delete button
                const SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
                  onPressed: onDelete,
                  tooltip: 'Delete user',
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
