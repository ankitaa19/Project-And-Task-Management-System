/**
 * Admin Dashboard
 * Shows overview of users, projects, and tasks
 * Admin has full access to all features
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../auth/login_screen.dart';
import 'create_user_screen.dart';
import 'manage_users_screen.dart';
import 'manage_projects_screen.dart';
import 'audit_logs_screen.dart';
import '../notifications_screen.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  final ApiService _api = ApiService();

  int _totalUsers = 0;
  int _totalProjects = 0;
  int _pendingTasks = 0;
  int _activeTasks = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    try {
      // Fetch all data in parallel
      final results = await Future.wait([
        _api.get(ApiEndpoints.users),
        _api.get(ApiEndpoints.projects),
        _api.get(ApiEndpoints.tasks),
      ]);

      final usersData = results[0];
      final projectsData = results[1];
      final tasksData = results[2];

      // Count pending and active tasks
      final tasks = tasksData['tasks'] as List<dynamic>;
      final pending = tasks.where((t) => t['status'] == 'pending').length;
      final active = tasks.where((t) => t['status'] == 'in_progress').length;

      setState(() {
        _totalUsers = usersData['count'] ?? 0;
        _totalProjects = projectsData['count'] ?? 0;
        _pendingTasks = pending;
        _activeTasks = active;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load dashboard stats: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadDashboardStats,
          ),
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
          // Logout button
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await AuthService().logout();
              if (context.mounted) {
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadDashboardStats,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome message
              const Text(
                'Welcome, Admin!',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'You have full access to manage users, projects, and tasks',
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              const SizedBox(height: 24),

              // Stats Overview
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Total Users',
                                count: _totalUsers.toString(),
                                icon: Icons.people,
                                color: AppTheme.primaryColor,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const ManageUsersScreen(),
                                    ),
                                  );
                                  _loadDashboardStats();
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Projects',
                                count: _totalProjects.toString(),
                                icon: Icons.folder,
                                color: AppTheme.secondaryColor,
                                onTap: () async {
                                  await Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          const ManageProjectsScreen(),
                                    ),
                                  );
                                  _loadDashboardStats();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'Pending Tasks',
                                count: _pendingTasks.toString(),
                                icon: Icons.pending_actions,
                                color: AppTheme.warningColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Active Tasks',
                                count: _activeTasks.toString(),
                                icon: Icons.task_alt,
                                color: AppTheme.inProgressColor,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
              const SizedBox(height: 24),

              // Quick Actions
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              _ActionButton(
                icon: Icons.person_add,
                title: 'Create User',
                subtitle: 'Add new user to the system',
                onTap: () async {
                  // Navigate to create user screen
                  await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CreateUserScreen()),
                  );
                  _loadDashboardStats(); // Refresh stats after returning
                },
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.folder_open,
                title: 'Manage Projects',
                subtitle: 'View and edit all projects',
                onTap: () async {
                  await Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const ManageProjectsScreen(),
                    ),
                  );
                  _loadDashboardStats(); // Refresh stats after returning
                },
              ),
              const SizedBox(height: 8),
              _ActionButton(
                icon: Icons.history,
                title: 'Audit Logs',
                subtitle: 'View all system activity',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const AuditLogsScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Stat Card Widget
class _StatCard extends StatelessWidget {
  final String title;
  final String count;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 8),
              Text(
                count,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                title,
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Action Button Widget
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryColor,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }
}
