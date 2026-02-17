/**
 * Notifications Screen
 * Shows all activity notifications (user, project, task changes).
 * Login activity is in Audit Logs; everything else appears here.
 */

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/app_theme.dart';
import '../../models/notification_model.dart';
import '../../services/notification_service.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../config/api_config.dart';
import 'manager/task_detail_screen.dart';
import 'member/task_progress_logs_screen.dart';
import 'admin/project_detail_screen.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final ApiService _api = ApiService();
  List<AppNotification> _notifications = [];
  bool _isLoading = true;
  String? _error;
  String? _userRole;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadNotifications();
  }

  Future<void> _loadUserRole() async {
    final user = await StorageService().getUser();
    setState(() => _userRole = user?.role);
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.get(ApiEndpoints.notifications);
      final List<dynamic> list = response['notifications'] ?? [];
      setState(() {
        _notifications =
            list.map((j) => AppNotification.fromJson(j)).toList();
        _isLoading = false;
      });
      final service = context.read<NotificationService>();
      service.fetchNotifications();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _markAsRead(AppNotification n) async {
    if (n.isRead) return;
    final service = context.read<NotificationService>();
    await service.markAsRead(n.id);
    _loadNotifications();
  }

  void _onNotificationTap(AppNotification n) async {
    _markAsRead(n);
    if (!mounted) return;
    final role = _userRole ?? (await StorageService().getUser())?.role;

    if (n.taskId != null && n.taskId!.isNotEmpty) {
      if (role == 'manager' || role == 'admin') {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskDetailScreen(taskId: n.taskId!),
          ),
        );
      } else {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => TaskProgressLogsScreen(taskId: n.taskId),
          ),
        );
      }
      return;
    }
    if (n.projectId != null && n.projectId!.isNotEmpty && (role == 'manager' || role == 'admin')) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => ProjectDetailScreen(projectId: n.projectId!),
        ),
      );
    }
  }

  Future<void> _markAllRead() async {
    try {
      await _api.patch(ApiEndpoints.markAllNotificationsRead);
      await context.read<NotificationService>().fetchNotifications();
      _loadNotifications();
    } catch (_) {}
  }

  IconData _iconForType(String type) {
    switch (type) {
      case 'user_created':
        return Icons.person_add;
      case 'user_deleted':
        return Icons.person_remove;
      case 'user_updated':
        return Icons.edit;
      case 'project_created':
      case 'project_assigned':
        return Icons.folder;
      case 'project_updated':
        return Icons.folder_open;
      case 'project_member_added':
      case 'member_added':
        return Icons.group_add;
      case 'member_removed':
        return Icons.group_remove;
      case 'task_created':
      case 'task_assigned':
        return Icons.assignment;
      case 'task_updated':
        return Icons.edit_note;
      case 'task_log_added':
        return Icons.history;
      case 'due_soon':
        return Icons.schedule;
      case 'status_changed':
        return Icons.published_with_changes;
      case 'deadline_near':
        return Icons.schedule;
      default:
        return Icons.notifications;
    }
  }

  Color _colorForType(String type) {
    if (type.contains('add') || type.contains('created') || type.contains('assigned')) {
      return Colors.green;
    }
    if (type.contains('remove') || type.contains('deleted')) {
      return Colors.red;
    }
    if (type.contains('update') || type.contains('changed')) {
      return AppTheme.primaryColor;
    }
    return Colors.grey;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (_notifications.any((n) => !n.isRead))
            TextButton(
              onPressed: _markAllRead,
              child: const Text('Mark all read'),
            ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
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
                      ElevatedButton.icon(
                        onPressed: _loadNotifications,
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                )
              : _notifications.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.notifications_none, size: 64, color: Colors.grey[400]),
                          const SizedBox(height: 16),
                          Text(
                            'No notifications',
                            style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadNotifications,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: _notifications.length,
                        itemBuilder: (context, index) {
                          final n = _notifications[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 12),
                            color: n.isRead ? null : AppTheme.primaryColor.withOpacity(0.06),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _colorForType(n.type).withOpacity(0.2),
                                child: Icon(_iconForType(n.type), color: _colorForType(n.type)),
                              ),
                              title: Text(
                                n.message,
                                style: TextStyle(
                                  fontWeight: n.isRead ? FontWeight.normal : FontWeight.w600,
                                ),
                              ),
                              subtitle: Text(
                                _formatDate(n.createdAt),
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                              onTap: () => _onNotificationTap(n),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${d.day}/${d.month}/${d.year}';
  }
}
