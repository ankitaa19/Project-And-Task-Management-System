/**
 * Auth Service
 * Handles user authentication (login, logout)
 */

import '../config/api_config.dart';
import '../models/user_model.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService {
  final ApiService _api = ApiService();
  final StorageService _storage = StorageService();

  /**
   * Login user
   * @param email User email
   * @param password User password
   * @returns User object with role
   */
  Future<User> login(String email, String password) async {
    try {
      // Make login API request
      final response = await _api.post(
        ApiEndpoints.login,
        {
          'email': email,
          'password': password,
        },
      );

      // Extract token and user from response
      final String token = response['token'];
      final userJson = response['user'];
      final User user = User.fromJson(userJson);

      // Save token and user data securely
      await _storage.saveToken(token);
      await _storage.saveUser(user);

      return user;
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /**
   * Logout user
   * Clears all stored data
   */
  Future<void> logout() async {
    await _storage.clearAll();
  }

  /**
   * Get current user from storage
   */
  Future<User?> getCurrentUser() async {
    return await _storage.getUser();
  }

  /**
   * Check if user is logged in
   */
  Future<bool> isLoggedIn() async {
    return await _storage.isLoggedIn();
  }
}
