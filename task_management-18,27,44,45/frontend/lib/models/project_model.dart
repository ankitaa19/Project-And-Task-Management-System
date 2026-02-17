/**
 * Project Model
 * Represents a project in the system
 */

import 'user_model.dart';

class Project {
  final String id;
  final String name;
  final String? description;
  final User manager;
  final List<User> members;
  final String status; // active, completed, on-hold
  final DateTime createdAt;

  Project({
    required this.id,
    required this.name,
    this.description,
    required this.manager,
    required this.members,
    this.status = 'active',
    required this.createdAt,
  });

  // Create Project from JSON (API response)
  factory Project.fromJson(Map<String, dynamic> json) {
    return Project(
      id: json['_id'] ?? json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      manager: User.fromJson(json['manager'] ?? {}),
      members: (json['members'] as List<dynamic>?)
          ?.map((m) => User.fromJson(m))
          .toList() ?? [],
      status: json['status'] ?? 'active',
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert Project to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'manager': manager.toJson(),
      'members': members.map((m) => m.toJson()).toList(),
      'status': status,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
