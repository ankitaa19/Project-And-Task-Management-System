/**
 * Task Model
 * Represents a task in the system
 */

class Task {
  final String id;
  final String title;
  final String? description;
  final String projectId;
  final String? projectName;
  final String? assignedToId;
  final String? assignedToName;
  final String status; // pending, in-progress, completed, blocked
  final String priority; // low, medium, high, urgent
  final DateTime? deadline;
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    this.description,
    required this.projectId,
    this.projectName,
    this.assignedToId,
    this.assignedToName,
    this.status = 'pending',
    this.priority = 'medium',
    this.deadline,
    required this.createdAt,
  });

  // Create Task from JSON (API response)
  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      projectId: json['project']?['_id'] ?? json['project'] ?? '',
      projectName: json['project']?['name'],
      assignedToId: json['assignedTo']?['_id'] ?? json['assignedTo'],
      assignedToName: json['assignedTo']?['name'],
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      deadline: json['deadline'] != null ? DateTime.parse(json['deadline']) : null,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convert Task to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'projectId': projectId,
      'projectName': projectName,
      'assignedToId': assignedToId,
      'assignedToName': assignedToName,
      'status': status,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
    };
  }

  // Check if task is overdue
  bool get isOverdue {
    if (deadline == null || status == 'completed') return false;
    return DateTime.now().isAfter(deadline!);
  }

  // Check if task is due today
  bool get isDueToday {
    if (deadline == null) return false;
    final now = DateTime.now();
    return deadline!.year == now.year &&
           deadline!.month == now.month &&
           deadline!.day == now.day;
  }
}
