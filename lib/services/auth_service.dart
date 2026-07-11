import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String _baseUrl = 'https://healthhive-j1xd.onrender.com/api';
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';

  /// Register. Returns error message or null on success.
  static Future<String?> register({
    required String name,
    required String email,
    required String password,
    required String phone,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 201 && data['success'] == true) {
        return null; // success
      }
      return data['message'] ?? 'Registration failed';
    } catch (e) {
      return 'Cannot connect to server. Is the backend running?';
    }
  }

  /// Login. Returns error message or null on success.
  static Future<String?> login({
    required String email,
    required String password,
  }) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_tokenKey, data['data']['token']);
        await prefs.setString(_userKey, jsonEncode(data['data']['user']));
        return null; // success
      }
      return data['message'] ?? 'Invalid credentials';
    } catch (e) {
      return 'Cannot connect to server. Is the backend running?';
    }
  }

  /// Get stored JWT token
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  /// Get logged in user info
  static Future<Map<String, dynamic>?> getLoggedInUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (userJson == null) return null;
    return Map<String, dynamic>.from(jsonDecode(userJson));
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userKey);
  }

  // ─── FORGOT PASSWORD FLOW ────────────────────────────────────────────────

  /// Send OTP. Returns error message or null on success.
  static Future<String?> sendOtp({required String email}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/send-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return null;
      return data['message'] ?? 'Failed to send OTP';
    } catch (e) {
      return 'Cannot connect to server. Is the backend running?';
    }
  }

  /// Verify OTP. Returns resetToken on success, or error string.
  static Future<Map<String, dynamic>> verifyOtp({required String email, required String otp}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'otp': otp}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) {
        return {'success': true, 'resetToken': data['resetToken']};
      }
      return {'success': false, 'message': data['message'] ?? 'Invalid OTP'};
    } catch (e) {
      return {'success': false, 'message': 'Cannot connect to server'};
    }
  }

  /// Reset password using reset token. Returns error message or null on success.
  static Future<String?> resetPassword({required String resetToken, required String newPassword}) async {
    try {
      final res = await http.post(
        Uri.parse('$_baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'resetToken': resetToken, 'newPassword': newPassword}),
      );
      final data = jsonDecode(res.body);
      if (res.statusCode == 200 && data['success'] == true) return null;
      return data['message'] ?? 'Failed to reset password';
    } catch (e) {
      return 'Cannot connect to server';
    }
  }
}
