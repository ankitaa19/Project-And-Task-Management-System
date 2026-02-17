/**
 * Member Dashboard
 * Shows welcome, task stats, filters, and all assigned tasks on one page.
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/auth_service.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/task_model.dart';
import '../../models/task_log_model.dart';
import '../auth/login_screen.dart';
import '../notifications_screen.dart';
import 'task_progress_logs_screen.dart';

class MemberDashboard extends StatefulWidget {
  const MemberDashboard({super.key});

  @override
  State<MemberDashboard> createState() => _MemberDashboardState();
}

class _MemberDashboardState extends State<MemberDashboard> {
  final ApiService _api = ApiService();

  List<Task> _tasks = [];
  String? _error;
  bool _isLoading = true;

  // Filters
  String? _priorityFilter; // null = All
  String? _statusFilter;   // null = All
  String _sortBy = 'recent'; // recent, oldest, due_asc, due_desc, priority

  static const _sortOptions = {
    'recent': 'Recently added',
    'oldest': 'Oldest first',
    'due_asc': 'Due soon',
    'due_desc': 'Due later',
    'priority': 'Priority',
  };

  int get _totalTasks => _tasks.length;

  int get _dueToday {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _tasks.where((t) {
      if (t.deadline == null) return false;
      final d = t.deadline!;
      return DateTime(d.year, d.month, d.day).isAtSameMomentAs(today);
    }).length;
  }

  List<Task> get _filteredAndSortedTasks {
    var list = List<Task>.from(_tasks);
    if (_priorityFilter != null) {
      list = list.where((t) => t.priority.toLowerCase() == _priorityFilter).toList();
    }
    if (_statusFilter != null) {
      final status = _statusFilter!;
      list = list.where((t) {
        final s = t.status.toLowerCase().replaceAll('_', '-');
        return s == status;
      }).toList();
    }
    switch (_sortBy) {
      case 'recent':
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        break;
      case 'oldest':
        list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
        break;
      case 'due_asc':
        list.sort((a, b) {
          final da = a.deadline ?? DateTime(9999, 12, 31);
          final db = b.deadline ?? DateTime(9999, 12, 31);
          return da.compareTo(db);
        });
        break;
      case 'due_desc':
        list.sort((a, b) {
          final da = a.deadline ?? DateTime(9999, 12, 31);
          final db = b.deadline ?? DateTime(9999, 12, 31);
          return db.compareTo(da);
        });
        break;
      case 'priority':
        const order = ['urgent', 'high', 'medium', 'low'];
        list.sort((a, b) {
          final ia = order.indexOf(a.priority.toLowerCase());
          final ib = order.indexOf(b.priority.toLowerCase());
          final pa = ia < 0 ? order.length : ia;
          final pb = ib < 0 ? order.length : ib;
          return pa.compareTo(pb);
        });
        break;
    }
    return list;
  }

  @override
  void initState() {
    super.initState();
    _loadTasks();
  }

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
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_error!), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _updateTaskStatus(Task task, String newStatus) async {
    try {
      await _api.patch(ApiEndpoints.taskStatus(task.id), {'status': newStatus});
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Task status updated!'), backgroundColor: Colors.green),
        );
        _loadTasks();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', '')),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _addLogForTask(Task task, String content, int? progressPercent) async {
    try {
      await _api.post(ApiEndpoints.taskLogs(task.id), {
        'content': content,
        if (progressPercent != null) 'progressPercent': progressPercent,
      });
    } catch (_) {}
  }

  Future<void> _showStatusUpdateWithOptionalLog(BuildContext context, Task task, String newStatus) async {
    final statusLabel = _statusLabel(newStatus);
    final noteController = TextEditingController();
    final progressController = TextEditingController();
    final result = await showDialog<Map<String, String>?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Set status to $statusLabel'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Optionally add a progress note for your manager (e.g. how much is done, what you did):',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Progress note (optional)',
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: progressController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Progress % (0–100, optional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx, {
                'note': noteController.text.trim(),
                'progress': progressController.text.trim(),
              });
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
    noteController.dispose();
    progressController.dispose();
    if (result == null || !mounted) return;
    await _updateTaskStatus(task, newStatus);
    final note = result['note'] ?? '';
    if (note.isNotEmpty) {
      int? pct;
      final p = result['progress'] ?? '';
      if (p.isNotEmpty) pct = int.tryParse(p);
      if (pct != null && (pct < 0 || pct > 100)) pct = null;
      await _addLogForTask(task, note, pct);
      if (mounted) _loadTasks();
    }
  }

  String _statusLabel(String value) {
    switch (value) {
      case 'pending': return 'Pending';
      case 'in-progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'blocked': return 'Blocked';
      default: return value;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase().replaceAll('_', '-')) {
      case 'pending':
        return AppTheme.pendingColor;
      case 'in-progress':
        return AppTheme.inProgressColor;
      case 'completed':
        return AppTheme.completedColor;
      case 'blocked':
        return AppTheme.blockedColor;
      default:
        return Colors.grey;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return AppTheme.lowPriority;
      case 'medium':
        return AppTheme.mediumPriority;
      case 'high':
        return AppTheme.highPriority;
      case 'urgent':
        return AppTheme.urgentPriority;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Tasks'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadTasks),
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
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                      const SizedBox(height: 16),
                      Text(_error!, textAlign: TextAlign.center, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(onPressed: _loadTasks, icon: const Icon(Icons.refresh), label: const Text('Retry')),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadTasks,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Welcome, Team Member!',
                          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Your assigned tasks',
                          style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                        ),
                        const SizedBox(height: 24),

                        // Stats
                        Row(
                          children: [
                            Expanded(
                              child: _StatCard(
                                title: 'My Tasks',
                                count: _totalTasks.toString(),
                                icon: Icons.task_alt,
                                color: AppTheme.memberColor,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _StatCard(
                                title: 'Due Today',
                                count: _dueToday.toString(),
                                icon: Icons.today,
                                color: AppTheme.warningColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Filters (dropdowns in a card)
                        Card(
                          margin: EdgeInsets.zero,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(Icons.tune, size: 20, color: Colors.grey[700]),
                                    const SizedBox(width: 8),
                                    const Text('Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String?>(
                                  value: _priorityFilter,
                                  decoration: const InputDecoration(
                                    labelText: 'Priority',
                                    prefixIcon: Icon(Icons.flag_outlined, size: 20),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('All priorities')),
                                    DropdownMenuItem(value: 'low', child: Text('Low')),
                                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                    DropdownMenuItem(value: 'high', child: Text('High')),
                                    DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                                  ],
                                  onChanged: (v) => setState(() => _priorityFilter = v),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String?>(
                                  value: _statusFilter,
                                  decoration: const InputDecoration(
                                    labelText: 'Status',
                                    prefixIcon: Icon(Icons.info_outline, size: 20),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: const [
                                    DropdownMenuItem(value: null, child: Text('All statuses')),
                                    DropdownMenuItem(value: 'pending', child: Text('Pending')),
                                    DropdownMenuItem(value: 'in-progress', child: Text('In Progress')),
                                    DropdownMenuItem(value: 'completed', child: Text('Completed')),
                                    DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                                  ],
                                  onChanged: (v) => setState(() => _statusFilter = v),
                                ),
                                const SizedBox(height: 12),
                                DropdownButtonFormField<String>(
                                  value: _sortBy,
                                  decoration: const InputDecoration(
                                    labelText: 'Sort by',
                                    prefixIcon: Icon(Icons.sort, size: 20),
                                    border: OutlineInputBorder(),
                                    isDense: true,
                                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                  ),
                                  items: _sortOptions.entries
                                      .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                                      .toList(),
                                  onChanged: (v) => setState(() => _sortBy = v ?? 'recent'),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // Task list
                        Text(
                          'Tasks (${_filteredAndSortedTasks.length})',
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        if (_filteredAndSortedTasks.isEmpty)
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 32),
                            child: Center(
                              child: Column(
                                children: [
                                  Icon(Icons.task_alt, size: 48, color: Colors.grey[400]),
                                  const SizedBox(height: 12),
                                  Text(
                                    _tasks.isEmpty ? 'No tasks assigned yet' : 'No tasks match the current filters',
                                    style: TextStyle(color: Colors.grey[600]),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ..._filteredAndSortedTasks.map((task) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _TaskCard(
                                  task: task,
                                  statusColor: _getStatusColor(task.status),
                                  priorityColor: _getPriorityColor(task.priority),
                                  onTap: () async {
                                    await Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => TaskProgressLogsScreen(task: task),
                                      ),
                                    );
                                    _loadTasks();
                                  },
                                  onStatusChange: (newStatus) => _updateTaskStatus(task, newStatus),
                                  onStatusChangeWithOptionalLog: (newStatus) => _showStatusUpdateWithOptionalLog(context, task, newStatus),
                                ),
                              )),
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

  const _StatCard({
    required this.title,
    required this.count,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(count, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 14, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }
}

class _TaskCard extends StatelessWidget {
  final Task task;
  final Color statusColor;
  final Color priorityColor;
  final VoidCallback? onTap;
  final Function(String) onStatusChange;
  final Function(String)? onStatusChangeWithOptionalLog;

  const _TaskCard({
    required this.task,
    required this.statusColor,
    required this.priorityColor,
    this.onTap,
    required this.onStatusChange,
    this.onStatusChangeWithOptionalLog,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: priorityColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    task.priority.toUpperCase(),
                    style: TextStyle(color: priorityColor, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
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
            if (task.deadline != null) ...[
              Row(
                children: [
                  Icon(Icons.calendar_today, size: 16, color: task.isOverdue ? Colors.red : Colors.grey[600]),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${task.deadline!.day}/${task.deadline!.month}/${task.deadline!.year}',
                    style: TextStyle(
                      fontSize: 12,
                      color: task.isOverdue ? Colors.red : Colors.grey[600],
                      fontWeight: task.isOverdue ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  if (task.isOverdue) ...[
                    const SizedBox(width: 8),
                    const Text('⚠️ OVERDUE', style: TextStyle(fontSize: 11, color: Colors.red, fontWeight: FontWeight.bold)),
                  ],
                ],
              ),
              const SizedBox(height: 8),
            ],
            Row(
              children: [
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      task.status.toUpperCase().replaceAll('-', ' '),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (value) {
                    if (onStatusChangeWithOptionalLog != null) {
                      onStatusChangeWithOptionalLog!(value);
                    } else {
                      onStatusChange(value);
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: 'pending', child: Row(children: [Icon(Icons.pending, color: AppTheme.pendingColor, size: 20), SizedBox(width: 8), Text('Pending')])),
                    const PopupMenuItem(value: 'in-progress', child: Row(children: [Icon(Icons.play_circle, color: AppTheme.inProgressColor, size: 20), SizedBox(width: 8), Text('In Progress')])),
                    const PopupMenuItem(value: 'completed', child: Row(children: [Icon(Icons.check_circle, color: AppTheme.completedColor, size: 20), SizedBox(width: 8), Text('Completed')])),
                    const PopupMenuItem(value: 'blocked', child: Row(children: [Icon(Icons.block, color: AppTheme.blockedColor, size: 20), SizedBox(width: 8), Text('Blocked')])),
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
