/**
 * Task Detail / Edit Screen (Manager)
 * View and edit task: title, description, project, assignee, priority, deadline, status.
 * Assignee list is limited to the selected project's manager and members.
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/task_model.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';
import '../member/task_progress_logs_screen.dart';

class TaskDetailScreen extends StatefulWidget {
  final String taskId;

  const TaskDetailScreen({super.key, required this.taskId});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  Task? _task;
  List<Project> _projects = [];
  Project? _selectedProject;
  String? _selectedAssigneeId;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String _selectedStatus = 'pending';
  String _selectedPriority = 'medium';
  DateTime? _selectedDeadline;

  List<User> get _assignableUsers {
    if (_selectedProject == null) return [];
    return [_selectedProject!.manager, ..._selectedProject!.members];
  }

  @override
  void initState() {
    super.initState();
    _loadTask();
    _loadProjects();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadTask() async {
    setState(() => _isLoading = true);
    try {
      final response = await _api.get(ApiEndpoints.taskById(widget.taskId));
      final task = Task.fromJson(response);
      setState(() {
        _task = task;
        _titleController.text = task.title;
        _descriptionController.text = task.description ?? '';
        _selectedStatus = task.status;
        _selectedPriority = task.priority;
        _selectedDeadline = task.deadline;
        _isLoading = false;
      });
      _loadProjectForTask(task.projectId);
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadProjectForTask(String projectId) async {
    try {
      final response = await _api.get(ApiEndpoints.projectById(projectId));
      final project = Project.fromJson(response);
      Project? fromList;
      for (final p in _projects) {
        if (p.id == project.id) {
          fromList = p;
          break;
        }
      }
      setState(() {
        _selectedProject = fromList ?? project;
        _selectedAssigneeId = _task?.assignedToId;
      });
    } catch (_) {}
  }

  Future<void> _loadProjects() async {
    try {
      final response = await _api.get(ApiEndpoints.projects);
      final list = (response['projects'] as List<dynamic>?) ?? [];
      setState(() {
        _projects = list.map((j) => Project.fromJson(j)).toList();
        if (_selectedProject == null && _task != null) {
          _selectedProject = _projects.cast<Project?>().firstWhere(
            (p) => p?.id == _task?.projectId,
            orElse: () => null,
          );
        }
      });
    } catch (_) {}
  }

  Future<void> _saveTask() async {
    if (_task == null || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _api.put(ApiEndpoints.taskById(widget.taskId), {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'projectId': _selectedProject!.id,
        'assignedTo': _selectedAssigneeId,
        'priority': _selectedPriority,
        'status': _selectedStatus,
        if (_selectedDeadline != null) 'deadline': _selectedDeadline!.toIso8601String(),
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task updated'), backgroundColor: Colors.green),
      );
      _loadTask();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteTask() async {
    if (_task == null) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Task'),
        content: Text('Delete "${_task!.title}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await _api.delete(ApiEndpoints.taskById(widget.taskId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task deleted'), backgroundColor: Colors.green),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDeadline() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _selectedDeadline ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (d != null) setState(() => _selectedDeadline = d);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null && _task == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Task')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error!, style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadTask, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }
    if (_task == null) return const SizedBox.shrink();

    return Scaffold(
      appBar: AppBar(
        title: Text(_task!.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            onPressed: _isSaving ? null : _deleteTask,
            tooltip: 'Delete task',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Task Title',
                  prefixIcon: Icon(Icons.title),
                  border: OutlineInputBorder(),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter title' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  prefixIcon: Icon(Icons.description),
                  border: OutlineInputBorder(),
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<Project>(
                value: _selectedProject == null
                    ? null
                    : () {
                        final match = _projects.where((p) => p.id == _selectedProject!.id).toList();
                        return match.isEmpty ? _selectedProject : match.first;
                      }(),
                decoration: const InputDecoration(
                  labelText: 'Project',
                  prefixIcon: Icon(Icons.folder),
                  border: OutlineInputBorder(),
                ),
                items: [
                  ..._projects.map((p) => DropdownMenuItem(value: p, child: Text(p.name))),
                  if (_selectedProject != null && !_projects.any((p) => p.id == _selectedProject!.id))
                    DropdownMenuItem(value: _selectedProject, child: Text(_selectedProject!.name)),
                ],
                onChanged: (p) {
                  setState(() {
                    _selectedProject = p;
                    _selectedAssigneeId = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String?>(
                value: _selectedAssigneeId,
                decoration: const InputDecoration(
                  labelText: 'Assign To',
                  prefixIcon: Icon(Icons.person),
                  border: OutlineInputBorder(),
                ),
                items: [
                  const DropdownMenuItem<String?>(value: null, child: Text('Unassigned')),
                  ..._assignableUsers.map((u) => DropdownMenuItem<String?>(value: u.id, child: Text('${u.name} (${u.email})'))),
                ],
                onChanged: (id) => setState(() => _selectedAssigneeId = id),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(labelText: 'Priority', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(value: 'medium', child: Text('Medium')),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(value: 'urgent', child: Text('Urgent')),
                      ],
                      onChanged: (v) => setState(() => _selectedPriority = v!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(labelText: 'Status', border: OutlineInputBorder()),
                      items: const [
                        DropdownMenuItem(value: 'pending', child: Text('Pending')),
                        DropdownMenuItem(value: 'in-progress', child: Text('In Progress')),
                        DropdownMenuItem(value: 'completed', child: Text('Completed')),
                        DropdownMenuItem(value: 'blocked', child: Text('Blocked')),
                      ],
                      onChanged: (v) => setState(() => _selectedStatus = v!),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              InkWell(
                onTap: _pickDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Deadline',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                  ),
                  child: Text(
                    _selectedDeadline == null
                        ? 'Tap to set'
                        : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                    style: TextStyle(color: _selectedDeadline == null ? Colors.grey : null),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TaskProgressLogsScreen(task: _task),
                    ),
                  );
                },
                icon: const Icon(Icons.history, size: 20),
                label: const Text('View progress logs'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.managerColor,
                ),
                child: _isSaving
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Save changes', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
