/**
 * App Theme Configuration
 * Defines colors, text styles, and theme for the entire app
 */

import 'package:flutter/material.dart';

class AppTheme {
  // Primary colors
  static const Color primaryColor = Color(0xFF2196F3); // Blue
  static const Color secondaryColor = Color(0xFF4CAF50); // Green
  static const Color errorColor = Color(0xFFF44336); // Red
  static const Color warningColor = Color(0xFFFF9800); // Orange

  // Role-based colors
  static const Color adminColor = Color(0xFF9C27B0); // Purple
  static const Color managerColor = Color(0xFF2196F3); // Blue
  static const Color memberColor = Color(0xFF4CAF50); // Green

  // Status colors
  static const Color pendingColor = Color(0xFFFF9800);
  static const Color inProgressColor = Color(0xFF2196F3);
  static const Color completedColor = Color(0xFF4CAF50);
  static const Color blockedColor = Color(0xFFF44336);

  // Priority colors
  static const Color lowPriority = Color(0xFF9E9E9E);
  static const Color mediumPriority = Color(0xFF2196F3);
  static const Color highPriority = Color(0xFFFF9800);
  static const Color urgentPriority = Color(0xFFF44336);

  // Light theme
  static ThemeData lightTheme = ThemeData(
    primarySwatch: Colors.blue,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: Colors.grey[100],
    appBarTheme: const AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: Colors.white,
      elevation: 2,
    ),
    cardTheme: CardThemeData(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    ),
  );

  // Get color for user role
  static Color getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return adminColor;
      case 'manager':
        return managerColor;
      case 'member':
        return memberColor;
      default:
        return Colors.grey;
    }
  }

  // Get color for task status
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return pendingColor;
      case 'in-progress':
        return inProgressColor;
      case 'completed':
        return completedColor;
      case 'blocked':
        return blockedColor;
      default:
        return Colors.grey;
    }
  }

  // Get color for task priority
  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return lowPriority;
      case 'medium':
        return mediumPriority;
      case 'high':
        return highPriority;
      case 'urgent':
        return urgentPriority;
      default:
        return Colors.grey;
    }
  }
}
