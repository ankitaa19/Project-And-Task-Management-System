/**
 * Manager Dashboard
 * Shows projects managed by the manager and their tasks
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../auth/login_screen.dart';
import 'create_project_screen.dart';
import 'create_task_screen.dart';
import '../admin/manage_projects_screen.dart';
import '../admin/manage_tasks_screen.dart';
import '../notifications_screen.dart';

class ManagerDashboard extends StatefulWidget {
  const ManagerDashboard({super.key});

  @override
  State<ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends State<ManagerDashboard> {
  final ApiService _api = ApiService();

  int _totalProjects = 0;
  int _totalTasks = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDashboardStats();
  }

  Future<void> _loadDashboardStats() async {
    setState(() => _isLoading = true);

    try {
      // Fetch projects and tasks in parallel (backend already filters by manager)
      final results = await Future.wait([
        _api.get(ApiEndpoints.projects),
        _api.get(ApiEndpoints.tasks),
      ]);

      final projectsData = results[0];
      final tasksData = results[1];

      setState(() {
        _totalProjects = projectsData['count'] ?? 0;
        _totalTasks = tasksData['count'] ?? 0;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load stats: ${e.toString().replaceAll('Exception: ', '')}',
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
        title: const Text('Manager Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              );
            },
          ),
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadDashboardStats,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome, Manager!',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Manage your projects and tasks',
                      style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                    ),
                    const SizedBox(height: 24),

                    // Stats
                    Row(
                      children: [
                        Expanded(
                          child: _StatCard(
                            title: 'My Projects',
                            count: _totalProjects.toString(),
                            icon: Icons.folder,
                            color: AppTheme.managerColor,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ManageProjectsScreen(),
                                ),
                              );
                              _loadDashboardStats();
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _StatCard(
                            title: 'Tasks',
                            count: _totalTasks.toString(),
                            icon: Icons.task_alt,
                            color: AppTheme.secondaryColor,
                            onTap: () async {
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ManageTasksScreen(),
                                ),
                              );
                              _loadDashboardStats();
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    const Text(
                      'Quick Actions',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.managerColor,
                          child: Icon(
                            Icons.create_new_folder,
                            color: Colors.white,
                          ),
                        ),
                        title: const Text(
                          'Create Project',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Start a new project'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateProjectScreen(),
                            ),
                          );
                          _loadDashboardStats(); // Refresh stats after returning
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.secondaryColor,
                          child: Icon(Icons.add_task, color: Colors.white),
                        ),
                        title: const Text(
                          'Create Task',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('Add a new task to your project'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const CreateTaskScreen(),
                            ),
                          );
                          _loadDashboardStats(); // Refresh stats after returning
                        },
                      ),
                    ),
                    const SizedBox(height: 8),
                    Card(
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: AppTheme.primaryColor,
                          child: Icon(Icons.folder_open, color: Colors.white),
                        ),
                        title: const Text(
                          'My Projects',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: const Text('View and manage your projects'),
                        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                        onTap: () async {
                          await Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ManageProjectsScreen(),
                            ),
                          );
                          _loadDashboardStats(); // Refresh stats after returning
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

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
