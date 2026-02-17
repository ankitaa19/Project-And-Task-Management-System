/**
 * Audit Logs Screen
 * Shows login-related activity only (LOGIN_SUCCESS, LOGIN_FAILED).
 * Other activity (users, projects, tasks) appears in the bell notifications.
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';

class AuditLogsScreen extends StatefulWidget {
  const AuditLogsScreen({super.key});

  @override
  State<AuditLogsScreen> createState() => _AuditLogsScreenState();
}

class _AuditLogsScreenState extends State<AuditLogsScreen> {
  final ApiService _api = ApiService();
  List<Map<String, dynamic>> _logs = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  /**
   * Load activity logs from API
   */
  Future<void> _loadLogs() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await _api.get(ApiEndpoints.activityLogs);
      final List<dynamic> logsJson = response['logs'] ?? [];

      setState(() {
        _logs = logsJson.cast<Map<String, dynamic>>();
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
   * Get icon for action type
   */
  IconData _getActionIcon(String action) {
    switch (action) {
      case 'LOGIN_SUCCESS':
        return Icons.login;
      case 'LOGIN_FAILED':
        return Icons.login;
      case 'USER_LOGIN':
        return Icons.login;
      case 'USER_CREATED':
        return Icons.person_add;
      case 'USER_UPDATED':
        return Icons.edit;
      case 'PROJECT_CREATED':
        return Icons.create_new_folder;
      case 'PROJECT_UPDATED':
        return Icons.folder_open;
      case 'MEMBER_ADDED':
        return Icons.group_add;
      case 'MEMBER_REMOVED':
        return Icons.group_remove;
      case 'TASK_CREATED':
        return Icons.add_task;
      case 'TASK_UPDATED':
        return Icons.edit_note;
      case 'TASK_ASSIGNED':
        return Icons.assignment_ind;
      case 'TASK_STATUS_CHANGED':
        return Icons.published_with_changes;
      default:
        return Icons.info;
    }
  }

  /**
   * Get color for action type
   */
  Color _getActionColor(String action) {
    if (action.contains('CREATE') || action.contains('ADD')) {
      return Colors.green;
    } else if (action.contains('UPDATE') || action.contains('CHANGE')) {
      return Colors.blue;
    } else if (action.contains('DELETE') || action.contains('REMOVE')) {
      return Colors.red;
    } else if (action.contains('LOGIN')) {
      return Colors.orange;
    }
    return Colors.grey;
  }

  /**
   * Format timestamp
   */
  String _formatTimestamp(String? timestamp) {
    if (timestamp == null) return 'Unknown';

    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inMinutes < 60) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inHours < 24) {
        return '${difference.inHours}h ago';
      } else if (difference.inDays < 7) {
        return '${difference.inDays}d ago';
      } else {
        return '${date.day}/${date.month}/${date.year}';
      }
    } catch (e) {
      return timestamp;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Audit Logs'),
            Text(
              'Login activity',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
            ),
          ],
        ),
        toolbarHeight: 72,
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
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
                  Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: _loadLogs,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            )
          : _logs.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No activity logs found',
                    style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : RefreshIndicator(
              onRefresh: _loadLogs,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _logs.length,
                itemBuilder: (context, index) {
                  final log = _logs[index];
                  final action = log['action'] ?? 'UNKNOWN';
                  final details = log['details'] ?? 'No details';
                  final timestamp =
                      log['timestamp']; // Changed from 'createdAt' to 'timestamp'
                  final performedBy = log['performedBy'];

                  return _LogItem(
                    icon: _getActionIcon(action),
                    color: _getActionColor(action),
                    action: action,
                    details: details,
                    timestamp: _formatTimestamp(timestamp),
                    performedBy: performedBy != null
                        ? (performedBy['name'] ?? 'Unknown User')
                        : 'System',
                  );
                },
              ),
            ),
    );
  }
}

/**
 * Log Item Widget
 */
class _LogItem extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String action;
  final String details;
  final String timestamp;
  final String performedBy;

  const _LogItem({
    required this.icon,
    required this.color,
    required this.action,
    required this.details,
    required this.timestamp,
    required this.performedBy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            // Icon
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 12),

            // Content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action
                  Text(
                    action.replaceAll('_', ' '),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Details
                  Text(
                    details,
                    style: TextStyle(color: Colors.grey[700], fontSize: 13),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Performed by and timestamp
                  Row(
                    children: [
                      Icon(Icons.person, size: 12, color: Colors.grey[500]),
                      const SizedBox(width: 4),
                      Text(
                        performedBy,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                      const SizedBox(width: 12),
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: Colors.grey[500],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        timestamp,
                        style: TextStyle(fontSize: 11, color: Colors.grey[600]),
                      ),
                    ],
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
