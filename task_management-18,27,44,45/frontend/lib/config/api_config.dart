/**
 * API Configuration
 * Central place for API endpoints and base URL.
 * Base URL is read from .env (API_URL); falls back to localhost:3001/api if unset.
 */

import 'package:flutter_dotenv/flutter_dotenv.dart';

String get baseUrl =>
    dotenv.env['API_URL'] ?? 'http://localhost:3001/api';

// API Endpoints
class ApiEndpoints {
  // Auth endpoints
  static String get login => '$baseUrl/auth/login';

  // User endpoints (Admin only)
  static String get users => '$baseUrl/users';
  static String userById(String id) => '$baseUrl/users/$id';
  static String userToggleStatus(String id) =>
      '$baseUrl/users/$id/toggle-status';

  // Project endpoints
  static String get projects => '$baseUrl/projects';
  static String projectById(String id) => '$baseUrl/projects/$id';
  static String addProjectMember(String id) =>
      '$baseUrl/projects/$id/add-member';
  static String removeProjectMember(String projectId, String userId) =>
      '$baseUrl/projects/$projectId/remove-member/$userId';

  // Task endpoints
  static String get tasks => '$baseUrl/tasks';
  static String taskById(String id) => '$baseUrl/tasks/$id';
  static String taskStatus(String id) => '$baseUrl/tasks/$id/status';
  static String taskAssign(String id) => '$baseUrl/tasks/$id/assign';
  static String taskLogs(String taskId) => '$baseUrl/tasks/$taskId/logs';

  // Activity log endpoints
  static String get activityLogs => '$baseUrl/activity-logs';

  // Notification endpoints
  static String get notifications => '$baseUrl/notifications';
  static String markNotificationRead(String id) =>
      '$baseUrl/notifications/$id/read';
  static String get markAllNotificationsRead =>
      '$baseUrl/notifications/mark-all-read';
}
