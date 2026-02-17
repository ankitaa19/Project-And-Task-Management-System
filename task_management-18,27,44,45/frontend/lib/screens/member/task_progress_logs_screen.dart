/**
 * Task Progress Logs Screen
 * Opened when member taps a task card or from notification. Shows log chain (statement, time, status) and form to add log with optional status update.
 * Can be opened with Task (from card) or taskId (from notification); if taskId only, task is loaded first.
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../config/api_config.dart';
import '../../models/task_model.dart';
import '../../models/task_log_model.dart';

class TaskProgressLogsScreen extends StatefulWidget {
  final Task? task;
  final String? taskId;

  TaskProgressLogsScreen({super.key, this.task, this.taskId});

  @override
  State<TaskProgressLogsScreen> createState() => _TaskProgressLogsScreenState();
}

class _TaskProgressLogsScreenState extends State<TaskProgressLogsScreen> {
  final ApiService _api = ApiService();
  final _contentController = TextEditingController();
  final _progressController = TextEditingController();

  Task? _task;
  List<TaskLog> _logs = [];
  bool _loading = true;
  String? _error;
  bool _saving = false;
  String? _selectedStatus;
  String? _userRole;

  String get _taskId => _task?.id ?? widget.taskId ?? '';
  bool get _canAddLogs => _userRole == 'member';

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    if (widget.task != null) {
      _task = widget.task;
      _loadLogs();
    } else {
      _loadTaskThenLogs();
    }
  }

  Future<void> _loadUserRole() async {
    final user = await StorageService().getUser();
    setState(() => _userRole = user?.role);
  }

  Future<void> _loadTaskThenLogs() async {
    if (widget.taskId == null || widget.taskId!.isEmpty) return;
    setState(() => _loading = true);
    try {
      final res = await _api.get(ApiEndpoints.taskById(widget.taskId!));
      final task = Task.fromJson(res);
      setState(() {
        _task = task;
        _loading = false;
      });
      _loadLogs();
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadLogs() async {
    if (_taskId.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await _api.get(ApiEndpoints.taskLogs(_taskId));
      final list = (res['logs'] as List<dynamic>?)?.map((e) => TaskLog.fromJson(e)).toList() ?? [];
      setState(() {
        _logs = list;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _addLog() async {
    final content = _contentController.text.trim();
    if (content.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a progress note'), backgroundColor: Colors.orange),
      );
      return;
    }
    int? progressPercent;
    final pText = _progressController.text.trim();
    if (pText.isNotEmpty) {
      progressPercent = int.tryParse(pText);
      if (progressPercent != null && (progressPercent < 0 || progressPercent > 100)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress must be 0–100'), backgroundColor: Colors.orange),
        );
        return;
      }
    }
    setState(() => _saving = true);
    try {
      await _api.post(ApiEndpoints.taskLogs(_taskId), {
        'content': content,
        if (progressPercent != null) 'progressPercent': progressPercent,
        if (_selectedStatus != null && _selectedStatus!.isNotEmpty) 'status': _selectedStatus,
      });
      _contentController.clear();
      _progressController.clear();
      setState(() => _selectedStatus = null);
      await _loadLogs();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Progress log added'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Color _statusColor(String? status) {
    if (status == null) return Colors.grey;
    switch (status) {
      case 'pending': return AppTheme.pendingColor;
      case 'in-progress': return AppTheme.inProgressColor;
      case 'completed': return AppTheme.completedColor;
      case 'blocked': return AppTheme.blockedColor;
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_task == null && !_loading && _error == null && widget.taskId != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task logs')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    final title = _task?.title ?? 'Task logs';
    return Scaffold(
      appBar: AppBar(
        title: Text('Logs: $title', overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogs),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(_error!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center),
                            const SizedBox(height: 8),
                            TextButton(onPressed: _loadLogs, child: const Text('Retry')),
                          ],
                        ),
                      )
                    : _logs.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Text(
                                'No progress logs yet. Add a note below; you can also update the task status with each log.',
                                textAlign: TextAlign.center,
                                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
                              ),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.all(16),
                            itemCount: _logs.length,
                            itemBuilder: (context, index) {
                              final log = _logs[index];
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 14,
                                            backgroundColor: AppTheme.memberColor,
                                            child: Text(
                                              log.performedByName.isNotEmpty ? log.performedByName[0].toUpperCase() : '?',
                                              style: const TextStyle(color: Colors.white, fontSize: 12),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(log.performedByName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                          ),
                                          Text(
                                            '${log.createdAt.day}/${log.createdAt.month}/${log.createdAt.year} ${log.createdAt.hour.toString().padLeft(2, '0')}:${log.createdAt.minute.toString().padLeft(2, '0')}',
                                            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Text(log.content, style: const TextStyle(fontSize: 15)),
                                      const SizedBox(height: 6),
                                      Row(
                                        children: [
                                          if (log.progressPercent != null)
                                            Padding(
                                              padding: const EdgeInsets.only(right: 12),
                                              child: Text(
                                                '${log.progressPercent}%',
                                                style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w500),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: _statusColor(log.status).withOpacity(0.2),
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              log.statusLabel,
                                              style: TextStyle(fontSize: 12, color: _statusColor(log.status), fontWeight: FontWeight.w600),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          ),
          ),
          if (_canAddLogs) ...[
            const Divider(height: 1),
            SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text('Add progress note (updates manager)', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'e.g. What you did, how much of the task is done',
                      border: OutlineInputBorder(),
                      alignLabelWithHint: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _progressController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Progress % (0–100, optional)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    value: _selectedStatus,
                    decoration: const InputDecoration(
                      labelText: 'Update status (optional)',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: null, child: Text('No change')),
                      DropdownMenuItem(value: 'pending', child: Text('Pending')),
                      DropdownMenuItem(value: 'in-progress', child: Text('In Progress')),
                      DropdownMenuItem(value: 'completed', child: Text('Completed')),
                      DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                    ],
                    onChanged: (v) => setState(() => _selectedStatus = v),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saving ? null : _addLog,
                    icon: _saving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.add),
                    label: Text(_saving ? 'Adding...' : 'Add log'),
                  ),
                ],
              ),
            ),
          ],
          if (!_canAddLogs)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Only the assigned member can add progress logs. You can view the log history above.',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
    );
  }
}
