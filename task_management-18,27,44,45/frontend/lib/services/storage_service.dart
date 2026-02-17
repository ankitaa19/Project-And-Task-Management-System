/**
 * Storage Service
 * Handles secure storage of JWT token and user data
 * Uses flutter_secure_storage for encryption
 */

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import '../models/user_model.dart';

class StorageService {
  // Singleton pattern - only one instance of StorageService
  static final StorageService _instance = StorageService._internal();
  factory StorageService() => _instance;
  StorageService._internal();

  // Secure storage instance
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  // Storage keys
  static const String _tokenKey = 'jwt_token';
  static const String _userKey = 'user_data';

  /**
   * Save JWT token securely
   */
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /**
   * Get JWT token
   */
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /**
   * Save user data
   */
  Future<void> saveUser(User user) async {
    final userJson = jsonEncode(user.toJson());
    await _storage.write(key: _userKey, value: userJson);
  }

  /**
   * Get user data
   */
  Future<User?> getUser() async {
    final userJson = await _storage.read(key: _userKey);
    if (userJson == null) return null;

    final userMap = jsonDecode(userJson);
    return User.fromJson(userMap);
  }

  /**
   * Clear all stored data (logout)
   */
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  /**
   * Check if user is logged in
   */
  Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}
