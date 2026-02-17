/**
 * Create Project Screen (Manager)
 * Managers can create new projects
 */

import 'package:flutter/material.dart';
import '../../config/app_theme.dart';
import '../../services/api_service.dart';
import '../../services/storage_service.dart';
import '../../config/api_config.dart';
import '../../models/user_model.dart';

class CreateProjectScreen extends StatefulWidget {
  const CreateProjectScreen({super.key});

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _selectedStatus = 'active';
  bool _isLoading = false;
  bool _isLoadingUsers = true;
  List<User> _availableUsers = [];
  List<User> _selectedMembers = [];

  final ApiService _api = ApiService();

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    try {
      final response = await _api.get(ApiEndpoints.users);
      final List<dynamic> usersJson = response['users'] ?? [];

      setState(() {
        _availableUsers = usersJson.map((json) => User.fromJson(json)).toList();
        _isLoadingUsers = false;
      });
    } catch (e) {
      setState(() => _isLoadingUsers = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to load users: ${e.toString().replaceAll('Exception: ', '')}',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _createProject() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Get current user to set as manager
      final currentUser = await StorageService().getUser();
      if (currentUser == null) {
        throw Exception('User not found. Please login again.');
      }

      final response = await _api.post(ApiEndpoints.projects, {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'managerId': currentUser.id,
        'status': _selectedStatus,
        if (_selectedMembers.isNotEmpty)
          'members': _selectedMembers.map((u) => u.id).toList(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              response['message'] ?? 'Project created successfully!',
            ),
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

  Future<void> _showMemberSelection() async {
    final List<User> tempSelected = List.from(_selectedMembers);

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Select Team Members'),
              content: SizedBox(
                width: double.maxFinite,
                child: _availableUsers.isEmpty
                    ? const Center(child: Text('No members available'))
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _availableUsers.length,
                        itemBuilder: (context, index) {
                          final user = _availableUsers[index];
                          final isSelected = tempSelected.any(
                            (u) => u.id == user.id,
                          );

                          return CheckboxListTile(
                            title: Text(user.name),
                            subtitle: Text('${user.email} • ${user.role}'),
                            secondary: CircleAvatar(
                              backgroundColor: user.role == 'manager'
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
                      _selectedMembers = tempSelected;
                    });
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.managerColor,
                  ),
                  child: Text('Add (${tempSelected.length})'),
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
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Project')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Project Name',
                  prefixIcon: Icon(Icons.folder),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter a project name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _descriptionController,
                maxLines: 4,
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

              // Team Members Selection
              InkWell(
                onTap: _isLoadingUsers ? null : _showMemberSelection,
                child: InputDecorator(
                  decoration: InputDecoration(
                    labelText: 'Team Members (Optional)',
                    prefixIcon: const Icon(Icons.group),
                    border: const OutlineInputBorder(),
                    suffixIcon: _isLoadingUsers
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: Padding(
                              padding: EdgeInsets.all(12.0),
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          )
                        : const Icon(Icons.arrow_drop_down),
                  ),
                  child: _selectedMembers.isEmpty
                      ? const Text(
                          'Tap to select team members',
                          style: TextStyle(color: Colors.grey),
                        )
                      : Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _selectedMembers.map((user) {
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
                              onDeleted: () {
                                setState(() {
                                  _selectedMembers.removeWhere(
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

              DropdownButtonFormField<String>(
                value: _selectedStatus,
                decoration: const InputDecoration(
                  labelText: 'Status',
                  prefixIcon: Icon(Icons.info_outline),
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'active',
                    child: Row(
                      children: [
                        Icon(
                          Icons.play_circle,
                          color: AppTheme.inProgressColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Active'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'on-hold',
                    child: Row(
                      children: [
                        Icon(
                          Icons.pause_circle,
                          color: AppTheme.warningColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('On Hold'),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: 'completed',
                    child: Row(
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: AppTheme.completedColor,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text('Completed'),
                      ],
                    ),
                  ),
                ],
                onChanged: (value) {
                  setState(() => _selectedStatus = value!);
                },
              ),
              const SizedBox(height: 24),

              ElevatedButton(
                onPressed: _isLoading ? null : _createProject,
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
                    : const Text(
                        'Create Project',
                        style: TextStyle(fontSize: 16),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
