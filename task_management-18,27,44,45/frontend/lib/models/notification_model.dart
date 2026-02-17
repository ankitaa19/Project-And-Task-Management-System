/**
 * Notification Model
 * Represents an in-app notification
 */

class AppNotification {
  final String id;
  final String message;
  final String type; // task_assigned, task_updated, deadline_near, etc.
  final String? taskId;
  final String? projectId;
  final bool isRead;
  final DateTime createdAt;

  AppNotification({
    required this.id,
    required this.message,
    required this.type,
    this.taskId,
    this.projectId,
    this.isRead = false,
    required this.createdAt,
  });

  static String? _idFromRef(dynamic ref) {
    if (ref == null) return null;
    if (ref is String) return ref.isEmpty ? null : ref;
    if (ref is Map) return (ref['_id'] ?? ref['id'])?.toString();
    return ref.toString();
  }

  // Create Notification from JSON (API response)
  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: json['_id'] ?? json['id'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? '',
      taskId: _idFromRef(json['task']),
      projectId: _idFromRef(json['project']),
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert Notification to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'type': type,
      'taskId': taskId,
      'projectId': projectId,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
