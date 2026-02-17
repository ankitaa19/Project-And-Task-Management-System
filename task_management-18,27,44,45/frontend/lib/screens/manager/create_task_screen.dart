/**
 * Create Task Screen (Manager)
 * Managers can create and assign tasks
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../config/api_config.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class CreateTaskScreen extends StatefulWidget {
  const CreateTaskScreen({super.key});

  @override
  State<CreateTaskScreen> createState() => _CreateTaskScreenState();
}

class _CreateTaskScreenState extends State<CreateTaskScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedStatus = 'pending';
  String _selectedPriority = 'medium';
  DateTime? _selectedDeadline;

  List<Project> _projects = [];
  Project? _selectedProject;
  List<User> _assignedMembers = [];

  bool _isLoading = false;
  bool _isLoadingData = true;

  final ApiService _api = ApiService();

  /// Only users who are part of the selected project (manager + members) can be assigned.
  List<User> get _assignableUsers {
    if (_selectedProject == null) return [];
    return [_selectedProject!.manager, ..._selectedProject!.members];
  }

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final projectsResponse = await _api.get(ApiEndpoints.projects);
      setState(() {
        _projects = (projectsResponse['projects'] as List<dynamic>)
            .map((json) => Project.fromJson(json))
            .toList();
        _isLoadingData = false;
      });
    } catch (e) {
      setState(() => _isLoadingData = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load data: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createTask() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedProject == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Please select a project')));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final taskData = {
        'title': _titleController.text.trim(),
        'description': _descriptionController.text.trim(),
        'projectId': _selectedProject!.id,
        'status': _selectedStatus,
        'priority': _selectedPriority,
        if (_assignedMembers.isNotEmpty)
          'assignedTo': _assignedMembers.map((u) => u.id).toList(),
        if (_selectedDeadline != null)
          'deadline': _selectedDeadline!.toIso8601String(),
      };

      final response = await _api.post(ApiEndpoints.tasks, taskData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message'] ?? 'Task created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true);
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _selectDeadline() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (date != null) {
      setState(() => _selectedDeadline = date);
    }
  }

  /**
   * Show multi-select dialog: only project manager and project members.
   */
  Future<void> _showMemberSelection() async {
    if (_selectedProject == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a project first')),
      );
      return;
    }
    final assignable = _assignableUsers;
    if (assignable.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('This project has no members to assign')),
      );
      return;
    }
    final List<User> tempSelected = List.from(_assignedMembers);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Assign Task To'),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: assignable.length,
                  itemBuilder: (context, index) {
                    final user = assignable[index];
                          final isSelected = tempSelected.any(
                            (u) => u.id == user.id,
                          );

                          return CheckboxListTile(
                            title: Text(user.name),
                            subtitle: Text('${user.email} • ${user.role}'),
                            secondary: CircleAvatar(
                              backgroundColor: user.role == 'manager' || user.role == 'admin'
                                  ? AppTheme.managerColor
                                  : AppTheme.memberColor,
                              child: Text(
                                user.name[0].toUpperCase(),
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            value: isSelected,
                            onChanged: (bool? checked) {
                              setDialogState(() {
                                if (checked == true) {
                                  tempSelected.add(user);
                                } else {
                                  tempSelected.removeWhere(
                                    (u) => u.id == user.id,
                                  );
                                }
                              });
                            },
                          );
                        },
                      ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _assignedMembers = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.secondaryColor,
                  ),
                  child: Text('Assign (${tempSelected.length})'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingData) {
      return Scaffold(
        appBar: AppBar(title: const Text('Create Task')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create New Task')),
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a task title';
                  }
                  return null;
                },
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
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<Project>(
                value: _selectedProject,
                decoration: const InputDecoration(
                  labelText: 'Project',
                  prefixIcon: Icon(Icons.folder),
                  border: OutlineInputBorder(),
                ),
                items: _projects.map((project) {
                  return DropdownMenuItem(
                    value: project,
                    child: Text(project.name),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedProject = value;
                    // Keep only assignees who are still in the new project
                    if (value != null) {
                      final ids = {value.manager.id, ...value.members.map((m) => m.id)};
                      _assignedMembers = _assignedMembers.where((u) => ids.contains(u.id)).toList();
                    } else {
                      _assignedMembers = [];
                    }
                  });
                },
                validator: (value) {
                  if (value == null) {
                    return 'Please select a project';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Multi-select members with enhanced visual design
              InkWell(
                onTap: () => _showMemberSelection(),
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Assign To (Optional)',
                    prefixIcon: const Icon(Icons.people),
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.arrow_drop_down),
                    helperText: _assignedMembers.isEmpty
                        ? null
                        : '${_assignedMembers.length} member(s) selected',
                  ),
                  child: _assignedMembers.isEmpty
                      ? const Text(
                          'Tap to assign members',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _assignedMembers.map((user) {
                            return Chip(
                              avatar: CircleAvatar(
                                backgroundColor: user.role == 'manager'
                                    ? AppTheme.managerColor
                                    : AppTheme.memberColor,
                                child: Text(
                                  user.name[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                              label: Text(user.name),
                              deleteIcon: const Icon(Icons.close, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _assignedMembers.removeWhere(
                                    (u) => u.id == user.id,
                                  );
                                });
                              },
                            );
                          }).toList(),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedPriority,
                      decoration: const InputDecoration(
                        labelText: 'Priority',
                        prefixIcon: Icon(Icons.flag),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'low', child: Text('Low')),
                        DropdownMenuItem(
                          value: 'medium',
                          child: Text('Medium'),
                        ),
                        DropdownMenuItem(value: 'high', child: Text('High')),
                        DropdownMenuItem(
                          value: 'urgent',
                          child: Text('Urgent'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedPriority = value!);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedStatus,
                      decoration: const InputDecoration(
                        labelText: 'Status',
                        prefixIcon: Icon(Icons.info_outline),
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'pending',
                          child: Text('Pending'),
                        ),
                        DropdownMenuItem(
                          value: 'in-progress',
                          child: Text('In Progress'),
                        ),
                        DropdownMenuItem(
                          value: 'completed',
                          child: Text('Completed'),
                        ),
                        DropdownMenuItem(
                          value: 'blocked',
                          child: Text('Blocked'),
                        ),
                      ],
                      onChanged: (value) {
                        setState(() => _selectedStatus = value!);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Deadline picker with better visual design
              InkWell(
                onTap: _selectDeadline,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Deadline (Optional)',
                    prefixIcon: Icon(Icons.calendar_today),
                    border: OutlineInputBorder(),
                    suffixIcon: Icon(Icons.arrow_drop_down),
                  ),
                  child: Text(
                    _selectedDeadline == null
                        ? 'Tap to set deadline'
                        : '${_selectedDeadline!.day}/${_selectedDeadline!.month}/${_selectedDeadline!.year}',
                    style: TextStyle(
                      color: _selectedDeadline == null
                          ? Colors.grey
                          : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _createTask,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppTheme.managerColor,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Create Task', style: TextStyle(fontSize: 16)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
