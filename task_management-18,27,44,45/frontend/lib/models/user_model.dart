/**
 * User Model
 * Represents a user in the system
 */

class User {
  final String id;
  final String name;
  final String email;
  final String role; // admin, manager, member
  final bool isActive;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  // Create User from JSON (API response)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'] ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'member',
      isActive: json['isActive'] ?? true,
    );
  }

  // Convert User to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'isActive': isActive,
    };
  }
}
