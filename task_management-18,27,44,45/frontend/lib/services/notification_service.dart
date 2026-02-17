/**
 * Notification Service
 * Handles fetching and managing notifications
 * Polls backend every 15 seconds for new notifications
 */

import 'dart:async';
import '../config/api_config.dart';
import '../models/notification_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class NotificationService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  // Stream for broadcasting new notifications
  final _notificationController =
      StreamController<List<AppNotification>>.broadcast();
  Stream<List<AppNotification>> get notificationStream =>
      _notificationController.stream;

  // Polling timer
  Timer? _pollingTimer;
  List<AppNotification> _cachedNotifications = [];

  /**
   * Start polling for notifications every 15 seconds
   */
  void startPolling() {
    // Fetch immediately
    fetchNotifications();

    // Then poll every 15 seconds
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 15),
      (timer) => fetchNotifications(),
    );
  }

  /**
   * Stop polling
   */
  void stopPolling() {
    _pollingTimer?.cancel();
    _pollingTimer = null;
  }

  /**
   * Fetch notifications from backend
   */
  Future<List<AppNotification>> fetchNotifications() async {
    try {
      // Check if user is authenticated before fetching
      final token = await _storage.getToken();
      if (token == null) {
        // User not logged in, return cached notifications silently
        return _cachedNotifications;
      }

      final response = await _api.get(ApiEndpoints.notifications);

      final List<dynamic> notificationList = response['notifications'] ?? [];
      _cachedNotifications = notificationList
          .map((json) => AppNotification.fromJson(json))
          .toList();

      // Broadcast to listeners
      _notificationController.add(_cachedNotifications);

      return _cachedNotifications;
    } catch (e) {
      // Silently handle errors to avoid console spam
      return _cachedNotifications;
    }
  }

  /**
   * Mark notification as read
   */
  Future<void> markAsRead(String notificationId) async {
    try {
      await _api.patch(ApiEndpoints.markNotificationRead(notificationId));

      // Update local cache
      _cachedNotifications = _cachedNotifications.map((notif) {
        if (notif.id == notificationId) {
          return AppNotification(
            id: notif.id,
            message: notif.message,
            type: notif.type,
            taskId: notif.taskId,
            projectId: notif.projectId,
            isRead: true,
            createdAt: notif.createdAt,
          );
        }
        return notif;
      }).toList();

      _notificationController.add(_cachedNotifications);
    } catch (e) {
      print('Error marking notification as read: $e');
    }
  }

  /**
   * Get unread notification count
   */
  int get unreadCount {
    return _cachedNotifications.where((n) => !n.isRead).length;
  }

  /**
   * Dispose resources
   */
  void dispose() {
    stopPolling();
    _notificationController.close();
  }
}
