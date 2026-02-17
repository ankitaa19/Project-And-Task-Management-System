/**
 * Manage Tasks Screen
 * Admin and Manager can view all tasks with full details
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../config/api_config.dart';
import '../../models/task_model.dart';
import '../manager/create_task_screen.dart';
import '../manager/task_detail_screen.dart';

class ManageTasksScreen extends StatefulWidget {
  const ManageTasksScreen({super.key});

  @override
  State<ManageTasksScreen> createState() => _ManageTasksScreenState();
}

class _ManageTasksScreenState extends State<ManageTasksScreen> {
  final ApiService _api = ApiService();
  List<Task> _tasks = [];
  bool _isLoading = true;
  String? _error;
  String _filterStatus = 'all';
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadTasks();
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
   * Load all tasks from API
   */
  Future<void> _loadTasks() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiEndpoints.tasks);
      final List<dynamic> tasksJson = response['tasks'] ?? [];

      setState(() {
        _tasks = tasksJson.map((json) => Task.fromJson(json)).toList();
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
   * Get filtered tasks based on status
   */
  List<Task> get _filteredTasks {
    if (_filterStatus == 'all') return _tasks;
    return _tasks.where((task) => task.status == _filterStatus).toList();
  }

  /**
   * Get status color
   */
  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppTheme.warningColor;
      case 'in_progress':
        return AppTheme.inProgressColor;
      case 'completed':
        return AppTheme.completedColor;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  /**
   * Delete task after confirmation (manager only; backend enforces project ownership)
   */
  Future<void> _deleteTask(Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${task.title}"? This cannot be undone.'),
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
      await _api.delete(ApiEndpoints.taskById(task.id));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task deleted'), backgroundColor: Colors.green),
        );
        _loadTasks();
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
   * Get priority color
   */
  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'urgent':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.blue;
      case 'low':
        return Colors.grey;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTasks),
        ],
      ),
      floatingActionButton: _userRole == 'manager'
          ? FloatingActionButton.extended(
              onPressed: () async {
                // Navigate to create task screen
                final result = await Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const CreateTaskScreen()),
                );
                // Reload tasks if a new one was created
                if (result == true) {
                  _loadTasks();
                }
              },
              icon: const Icon(Icons.add),
              label: const Text('New Task'),
              backgroundColor: AppTheme.secondaryColor,
            )
          : null,
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'All (${_tasks.length})',
                    isSelected: _filterStatus == 'all',
                    onTap: () => setState(() => _filterStatus = 'all'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Pending',
                    isSelected: _filterStatus == 'pending',
                    onTap: () => setState(() => _filterStatus = 'pending'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'In Progress',
                    isSelected: _filterStatus == 'in_progress',
                    onTap: () => setState(() => _filterStatus = 'in_progress'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Completed',
                    isSelected: _filterStatus == 'completed',
                    onTap: () => setState(() => _filterStatus = 'completed'),
                  ),
                  const SizedBox(width: 8),
                  _FilterChip(
                    label: 'Blocked',
                    isSelected: _filterStatus == 'blocked',
                    onTap: () => setState(() => _filterStatus = 'blocked'),
                  ),
                ],
              ),
            ),
          ),

          // Tasks list
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadTasks,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  )
                : _filteredTasks.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.task_alt, size: 64, color: Colors.grey[300]),
                        const SizedBox(height: 16),
                        Text(
                          _filterStatus == 'all'
                              ? 'No tasks found'
                              : 'No $_filterStatus tasks',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Create a task to get started',
                          style: TextStyle(color: Colors.grey[500]),
                        ),
                      ],
                    ),
                  )
                : RefreshIndicator(
                    onRefresh: _loadTasks,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _filteredTasks.length,
                      itemBuilder: (context, index) {
                        final task = _filteredTasks[index];
                        return _TaskCard(
                          task: task,
                          statusColor: _getStatusColor(task.status),
                          priorityColor: _getPriorityColor(task.priority),
                          canDelete: _userRole == 'manager',
                          onTap: _userRole == 'manager'
                              ? () async {
                                  final result = await Navigator.of(context).push<bool>(
                                    MaterialPageRoute(
                                      builder: (_) => TaskDetailScreen(taskId: task.id),
                                    ),
                                  );
                                  if (result == true) _loadTasks();
                                }
                              : null,
                          onDelete: () => _deleteTask(task),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

/**
 * Filter Chip Widget
 */
class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Chip(
        label: Text(label),
        backgroundColor: isSelected ? AppTheme.primaryColor : Colors.grey[200],
        labelStyle: TextStyle(
          color: isSelected ? Colors.white : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

/**
 * Task Card Widget
 */
class _TaskCard extends StatelessWidget {
  final Task task;
  final Color statusColor;
  final Color priorityColor;
  final bool canDelete;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const _TaskCard({
    required this.task,
    required this.statusColor,
    required this.priorityColor,
    required this.canDelete,
    this.onTap,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap ?? () {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Task: ${task.title}')),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Task title, delete, and priority
              Row(
                children: [
                  Expanded(
                    child: Text(
                      task.title,
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
                      tooltip: 'Delete task',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                    ),
                  const SizedBox(width: 4),
                  // Priority badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: priorityColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.flag, size: 14, color: priorityColor),
                        const SizedBox(width: 4),
                        Text(
                          task.priority.toUpperCase(),
                          style: TextStyle(
                            color: priorityColor,
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              // Status badge
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
                  task.status.replaceAll('_', ' ').toUpperCase(),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              if (task.description != null && task.description!.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description!,
                  style: TextStyle(color: Colors.grey[700]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),
              const Divider(height: 1),
              const SizedBox(height: 12),

              // Project, Assignee, and Deadline info
              Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  // Project
                  if (task.projectName != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.folder, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            task.projectName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  // Assigned to
                  if (task.assignedToName != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.person, size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            task.assignedToName!,
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.grey[700],
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  // Deadline
                  if (task.deadline != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          task.isOverdue ? Icons.warning : Icons.calendar_today,
                          size: 16,
                          color: task.isOverdue
                              ? Colors.red
                              : task.isDueToday
                              ? Colors.orange
                              : Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${task.deadline!.month}/${task.deadline!.day}/${task.deadline!.year}',
                          style: TextStyle(
                            fontSize: 13,
                            color: task.isOverdue
                                ? Colors.red
                                : task.isDueToday
                                ? Colors.orange
                                : Colors.grey[700],
                            fontWeight: task.isOverdue || task.isDueToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                        ),
                        if (task.isOverdue)
                          Text(
                            ' (Overdue)',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                      ],
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
