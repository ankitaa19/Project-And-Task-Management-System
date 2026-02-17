/**
 * Project Detail / Edit Screen
 * View and edit project (name, description, manager, members, status).
 * Same access as create: admin and manager (manager only for own projects).
 * Shows only this project's members; "add member" shows users not already in project.
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../config/api_config.dart';
import '../../models/project_model.dart';
import '../../models/user_model.dart';

class ProjectDetailScreen extends StatefulWidget {
  final String projectId;

  const ProjectDetailScreen({super.key, required this.projectId});

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final ApiService _api = ApiService();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  Project? _project;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;
  String? _userRole;
  String _selectedStatus = 'active';
  String? _selectedManagerId;
  List<User> _selectedMembers = [];
  List<User> _availableUsers = [];
  bool _isLoadingUsers = false;

  @override
  void initState() {
    super.initState();
    _loadUserRole();
    _loadProject();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUserRole() async {
    final user = await StorageService().getUser();
    setState(() => _userRole = user?.role);
  }

  Future<void> _loadProject() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final response = await _api.get(ApiEndpoints.projectById(widget.projectId));
      final project = Project.fromJson(response);
      setState(() {
        _project = project;
        _nameController.text = project.name;
        _descriptionController.text = project.description ?? '';
        _selectedStatus = project.status;
        _selectedManagerId = project.manager.id;
        _selectedMembers = List.from(project.members);
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _isLoading = false;
      });
    }
  }

  Future<void> _loadUsers() async {
    setState(() => _isLoadingUsers = true);
    try {
      final response = await _api.get(ApiEndpoints.users);
      final List<dynamic> usersJson = response['users'] ?? [];
      setState(() {
        _availableUsers = usersJson.map((json) => User.fromJson(json)).toList();
        _isLoadingUsers = false;
      });
    } catch (_) {
      setState(() => _isLoadingUsers = false);
    }
  }

  List<User> get _managersForDropdown {
    return _availableUsers.where((u) => u.role == 'manager' || u.role == 'admin').toList();
  }

  List<User> get _usersNotInProject {
    if (_project == null) return _availableUsers;
    final memberIds = _selectedMembers.map((m) => m.id).toSet();
    return _availableUsers.where((u) => !memberIds.contains(u.id)).toList();
  }

  Future<void> _saveProject() async {
    if (_project == null) return;
    final isManager = _userRole == 'manager';
    if (!isManager && !_formKey.currentState!.validate()) return;
    if (!isManager && _selectedManagerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a manager'), backgroundColor: Colors.red),
      );
      return;
    }
    setState(() => _isSaving = true);
    try {
      final payload = isManager
          ? {'status': _selectedStatus}
          : {
              'name': _nameController.text.trim(),
              'description': _descriptionController.text.trim(),
              'status': _selectedStatus,
              'managerId': _selectedManagerId,
              'members': _selectedMembers.map((u) => u.id).toList(),
            };
      await _api.put(ApiEndpoints.projectById(widget.projectId), payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project updated'), backgroundColor: Colors.green),
      );
      _loadProject();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', '')), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteProject() async {
    if (_project == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text(
          'Delete "${_project!.name}"? All tasks in this project will also be deleted. This cannot be undone.',
        ),
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
    if (confirmed != true || !mounted) return;
    setState(() => _isSaving = true);
    try {
      await _api.delete(ApiEndpoints.projectById(widget.projectId));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Project deleted'), backgroundColor: Colors.green),
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

  Future<void> _showAddMember() async {
    final notInProject = _usersNotInProject;
    if (notInProject.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All users are already in this project')),
      );
      return;
    }
    List<User> tempSelected = [];
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) {
          return AlertDialog(
            title: const Text('Add members'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: notInProject.length,
                itemBuilder: (context, index) {
                  final user = notInProject[index];
                  final isSelected = tempSelected.any((u) => u.id == user.id);
                  return CheckboxListTile(
                    title: Text(user.name),
                    subtitle: Text('${user.email} • ${user.role}'),
                    value: isSelected,
                    onChanged: (bool? checked) {
                      setDialogState(() {
                        if (checked == true) {
                          tempSelected.add(user);
                        } else {
                          tempSelected.removeWhere((u) => u.id == user.id);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () {
                  setState(() => _selectedMembers = [..._selectedMembers, ...tempSelected]);
                  Navigator.pop(ctx);
                },
                child: Text('Add (${tempSelected.length})'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }
    if (_error != null || _project == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Project')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_error ?? 'Project not found', style: const TextStyle(color: Colors.red)),
              const SizedBox(height: 16),
              ElevatedButton(onPressed: _loadProject, child: const Text('Retry')),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_project!.name),
        actions: [
          if (_userRole == 'admin') ...[
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _isSaving ? null : _deleteProject,
              tooltip: 'Delete project',
            ),
          ],
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
                controller: _nameController,
                readOnly: _userRole == 'manager',
                decoration: InputDecoration(
                  labelText: 'Project Name',
                  prefixIcon: const Icon(Icons.folder),
                  border: const OutlineInputBorder(),
                  filled: _userRole == 'manager',
                  fillColor: _userRole == 'manager' ? Colors.grey.shade100 : null,
                ),
                validator: _userRole == 'manager' ? null : (v) => (v == null || v.trim().isEmpty) ? 'Enter project name' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
                readOnly: _userRole == 'manager',
                decoration: InputDecoration(
                  labelText: 'Description',
                  prefixIcon: const Icon(Icons.description),
                  border: const OutlineInputBorder(),
                  alignLabelWithHint: true,
                  filled: _userRole == 'manager',
                  fillColor: _userRole == 'manager' ? Colors.grey.shade100 : null,
                ),
              ),
              const SizedBox(height: 16),
              if (_userRole == 'manager')
                InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Manager',
                    prefixIcon: const Icon(Icons.person),
                    border: const OutlineInputBorder(),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                  ),
                  child: Text(
                    _project!.manager.name.isNotEmpty ? '${_project!.manager.name} (${_project!.manager.email})' : '—',
                    style: TextStyle(color: Colors.grey[700]),
                  ),
                )
              else
                DropdownButtonFormField<String>(
                  value: _selectedManagerId,
                  decoration: const InputDecoration(
                    labelText: 'Manager',
                    prefixIcon: Icon(Icons.person),
                    border: OutlineInputBorder(),
                  ),
                  items: _managersForDropdown.map((u) {
                    return DropdownMenuItem(
                      value: u.id,
                      child: Text('${u.name} (${u.role})'),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => _selectedManagerId = value),
                ),
              const SizedBox(height: 16),
              const Text('Team members', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ..._selectedMembers.map((user) {
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: user.role == 'manager' ? AppTheme.managerColor : AppTheme.memberColor,
                        child: Text(user.name[0].toUpperCase(), style: const TextStyle(color: Colors.white, fontSize: 12)),
                      ),
                      label: Text(user.name),
                      onDeleted: _userRole == 'manager' ? null : () => setState(() => _selectedMembers.removeWhere((u) => u.id == user.id)),
                    );
                  }),
                  if (_userRole != 'manager') ...[
                    if (_isLoadingUsers)
                      const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                      )
                    else
                      ActionChip(
                        avatar: const Icon(Icons.person_add, size: 18, color: Colors.white),
                        label: const Text('Add member'),
                        onPressed: _showAddMember,
                      ),
                  ],
                ],
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: 'active', child: Text('Active')),
                  DropdownMenuItem(value: 'on-hold', child: Text('On Hold')),
                  DropdownMenuItem(value: 'completed', child: Text('Completed')),
                ],
                onChanged: (value) => setState(() => _selectedStatus = value!),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isSaving ? null : _saveProject,
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
