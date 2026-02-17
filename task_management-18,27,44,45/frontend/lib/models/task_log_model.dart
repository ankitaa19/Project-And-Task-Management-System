/**
 * TaskLog Model
 * A single entry in the progress log chain for a task
 */

class TaskLog {
  final String id;
  final String taskId;
  final String performedById;
  final String performedByName;
  final String content;
  final int? progressPercent;
  final String? status;
  final DateTime createdAt;

  TaskLog({
    required this.id,
    required this.taskId,
    required this.performedById,
    required this.performedByName,
    required this.content,
    this.progressPercent,
    this.status,
    required this.createdAt,
  });

  factory TaskLog.fromJson(Map<String, dynamic> json) {
    final performedBy = json['performedBy'];
    final name = performedBy is Map
        ? (performedBy['name'] ?? '')
        : '';
    return TaskLog(
      id: json['_id'] ?? json['id'] ?? '',
      taskId: json['task'] is String ? json['task'] : (json['task']?['_id'] ?? ''),
      performedById: performedBy is Map ? (performedBy['_id'] ?? performedBy['id'] ?? '') : performedBy?.toString() ?? '',
      performedByName: name,
      content: json['content'] ?? '',
      progressPercent: json['progressPercent'] != null ? (json['progressPercent'] as num).toInt() : null,
      status: json['status'] as String?,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String get statusLabel {
    if (status == null || status!.isEmpty) return '—';
    switch (status!) {
      case 'pending': return 'Pending';
      case 'in-progress': return 'In Progress';
      case 'completed': return 'Completed';
      case 'blocked': return 'Blocked';
      default: return status!;
    }
  }
}
