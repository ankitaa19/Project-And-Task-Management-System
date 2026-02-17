/**
 * Manage Projects Screen
 * Admin and Manager can view all projects
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/project_model.dart';
import '../../services/storage_service.dart';
import '../manager/create_project_screen.dart';
import 'project_detail_screen.dart';

class ManageProjectsScreen extends StatefulWidget {
  const ManageProjectsScreen({super.key});

  @override
  State<ManageProjectsScreen> createState() => _ManageProjectsScreenState();
}

class _ManageProjectsScreenState extends State<ManageProjectsScreen> {
  final ApiService _api = ApiService();
  List<Project> _projects = [];
  bool _isLoading = true;
  String? _error;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadProjects();
  }

  /**
   * Load current user role
   */
  Future<void> _loadUserRole() async {
    final user = await StorageService().getUser();
    setState(() {
      _userRole = user?.role;
    });
  }

  /**
   * Load all projects from API
   */
  Future<void> _loadProjects() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiEndpoints.projects);
      final List<dynamic> projectsJson = response['projects'] ?? [];

      setState(() {
        _projects = projectsJson.map((json) => Project.fromJson(json)).toList();
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
   * Delete project after confirmation (admin: any project; manager: backend restricts to own)
   */
  Future<void> _deleteProject(Project project) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Delete "${project.name}"? All tasks in this project will also be deleted. This cannot be undone.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await _api.delete(ApiEndpoints.projectById(project.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Project deleted'), backgroundColor: Colors.green),
        );
        _loadProjects();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    }
  }

  /**
   * Get status color
   */
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppTheme.inProgressColor;
      case 'completed':
        return AppTheme.completedColor;
      case 'on-hold':
        return AppTheme.warningColor;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Projects'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProjects),
        ],
      ),
      floatingActionButton: (_userRole == 'admin' || _userRole == 'manager')
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Navigate to create project screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CreateProjectScreen(),
                  ),
                );
                // Reload projects if a new one was created
                if (result == true) {
                  _loadProjects();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New Project'),
              backgroundColor: AppTheme.managerColor,
            )
          : null,
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
                    onPressed: _loadProjects,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _projects.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.folder_open, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No projects found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a project to get started',
                    style: TextStyle(color: Colors.grey[500]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadProjects,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _projects.length,
                itemBuilder: (context, index) {
                  final project = _projects[index];
                  return _ProjectCard(
                    project: project,
                    statusColor: _getStatusColor(project.status),
                    canDelete: _userRole == 'admin',
                    onTap: () async {
                      final result = await Navigator.of(context).push<bool>(
                        MaterialPageRoute(
                          builder: (_) => ProjectDetailScreen(projectId: project.id),
                        ),
                      );
                      if (result == true) _loadProjects();
                    },
                    onDelete: () => _deleteProject(project),
                  );
                },
              ),
            ),
    );
  }
}

/**
 * Project Card Widget
 */
class _ProjectCard extends StatelessWidget {
  final Project project;
  final Color statusColor;
  final bool canDelete;
  final VoidCallback onTap;
  final VoidCallback? onDelete;

  const _ProjectCard({
    required this.project,
    required this.statusColor,
    required this.canDelete,
    required this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Project name, status, and delete
              Row(
                children: [
                  Expanded(
                    child: Text(
                      project.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (canDelete && onDelete != null)
                    IconButton(
                      icon: Icon(Icons.delete_outline, color: Colors.red[400], size: 22),
                      onPressed: onDelete,
                      tooltip: 'Delete project',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  const SizedBox(width: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      project.status.toUpperCase(),
                      style: TextStyle(
                        color: statusColor,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),

              if (project.description != null &&
                  project.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  project.description!,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // Manager name and member count (from populated project data)
              Row(
                children: [
                  Icon(Icons.person, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    project.manager.name.isNotEmpty ? project.manager.name : '—',
                    style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.group, size: 16, color: Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    '${project.members.length} member${project.members.length == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
