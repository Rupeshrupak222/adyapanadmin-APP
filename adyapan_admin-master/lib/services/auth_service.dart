import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

/// Authentication service that connects to the real backend API.
/// Handles login, token storage, and session management.
class AuthService {
  AuthService._internal();
  static final AuthService instance = AuthService._internal();

  static const String _baseUrl = '${ApiService.baseUrl}/auth';

  String? _accessToken;
  String? _refreshToken;
  Map<String, dynamic>? _currentUser;

  String? get accessToken => _accessToken;
  Map<String, dynamic>? get currentUser => _currentUser;

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Dart/Flutter (Adyapan Admin App)',
      };

  Map<String, String> get authHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'User-Agent': 'Dart/Flutter (Adyapan Admin App)',
        if (_accessToken != null) 'Authorization': 'Bearer $_accessToken',
      };

  /// Login with email, password, and optional role/accessKey for principal.
  /// Returns a result map with success status and user data or error message.
  Future<Map<String, dynamic>> login({
    required String email,
    required String password,
    String? role,
    String? accessKey,
  }) async {
    try {
      final body = <String, dynamic>{
        'email': email.trim().toLowerCase(),
        'password': password,
        'platform': 'app',
      };

      if (role != null) body['role'] = role;
      if (accessKey != null && accessKey.isNotEmpty) {
        body['accessKey'] = accessKey;
        body['schoolKey'] = accessKey;
      }

      // First attempt — long timeout to handle Render cold start (up to 60s)
      http.Response response;
      try {
        response = await http.post(
          Uri.parse('$_baseUrl/login'),
          headers: _headers,
          body: json.encode(body),
        ).timeout(const Duration(seconds: 90));
      } catch (e) {
        // If first attempt times out, retry once (server may be waking up)
        response = await http.post(
          Uri.parse('$_baseUrl/login'),
          headers: _headers,
          body: json.encode(body),
        ).timeout(const Duration(seconds: 30));
      }

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final responseData = data['data'] ?? data;
        _accessToken = responseData['token'] ?? responseData['accessToken'];
        _refreshToken = responseData['refreshToken'];
        _currentUser = responseData['user'] != null
            ? Map<String, dynamic>.from(responseData['user'])
            : null;

        // Save session
        await _saveSession();

        return {
          'success': true,
          'user': _currentUser,
          'role': _currentUser?['role'] ?? role ?? 'admin',
          'name': _currentUser?['name'] ?? email,
          'email': _currentUser?['email'] ?? email,
          'schoolName': _currentUser?['school_name'],
          'schoolId': _currentUser?['school_id'],
        };
      }

      // Handle 409: Active session exists — auto-clear and retry
      if (response.statusCode == 409) {
        final cleared = await _clearPreviousSessions(email.trim().toLowerCase(), password);
        if (cleared) {
          // Retry login
          final retryResponse = await http.post(
            Uri.parse('$_baseUrl/login'),
            headers: _headers,
            body: json.encode(body),
          ).timeout(const Duration(seconds: 30));

          final retryData = json.decode(retryResponse.body);
          if (retryResponse.statusCode == 200 && retryData['success'] == true) {
            final responseData = retryData['data'] ?? retryData;
            _accessToken = responseData['token'] ?? responseData['accessToken'];
            _refreshToken = responseData['refreshToken'];
            _currentUser = responseData['user'] != null
                ? Map<String, dynamic>.from(responseData['user'])
                : null;
            await _saveSession();
            return {
              'success': true,
              'user': _currentUser,
              'role': _currentUser?['role'] ?? role ?? 'admin',
              'name': _currentUser?['name'] ?? email,
              'email': _currentUser?['email'] ?? email,
              'schoolName': _currentUser?['school_name'],
              'schoolId': _currentUser?['school_id'],
            };
          }
        }
        return {
          'success': false,
          'error': 'Session conflict. Please try again.',
        };
      }

      final message = data['message'] ?? data['error'] ?? 'Invalid email or password.';
      return {
        'success': false,
        'error': message,
      };
    } catch (e) {
      print('AuthService Login Error: $e');
      return {
        'success': false,
        'error': 'Server is starting up. Please wait 30 seconds and try again.',
      };
    }
  }

  /// Refresh the access token using the stored refresh token.
  Future<bool> refreshAccessToken() async {
    if (_refreshToken == null) return false;

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/refresh'),
        headers: _headers,
        body: json.encode({'refreshToken': _refreshToken}),
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        final responseData = data['data'] ?? data;
        _accessToken = responseData['token'] ?? responseData['accessToken'];
        _refreshToken = responseData['refreshToken'] ?? _refreshToken;
        await _saveSession();
        return true;
      }
    } catch (_) {}

    return false;
  }

  /// Logout — destroy server session AND clear local tokens.
  Future<void> logout() async {
    // Call backend to destroy the active session
    if (_accessToken != null) {
      try {
        await http.post(
          Uri.parse('$_baseUrl/logout'),
          headers: authHeaders,
        ).timeout(const Duration(seconds: 10));
      } catch (_) {
        // Even if server call fails, still clear local state
      }
    }

    _accessToken = null;
    _refreshToken = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
    await prefs.remove('role');
    await prefs.remove('displayName');
    await prefs.remove('email');
  }

  /// Restore session from SharedPreferences (call on app start).
  Future<bool> restoreSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _accessToken = prefs.getString('auth_token');
      _refreshToken = prefs.getString('refresh_token');

      final userData = prefs.getString('user_data');
      if (userData != null) {
        _currentUser = json.decode(userData);
      }

      return _accessToken != null && _currentUser != null;
    } catch (_) {
      return false;
    }
  }

  /// Save session to SharedPreferences.
  Future<void> _saveSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_accessToken != null) await prefs.setString('auth_token', _accessToken!);
      if (_refreshToken != null) await prefs.setString('refresh_token', _refreshToken!);
      if (_currentUser != null) await prefs.setString('user_data', json.encode(_currentUser));

      // Also save in the format MainLayout expects
      final role = _currentUser?['role'] ?? 'admin';
      final name = _currentUser?['name'] ?? 'User';
      final email = _currentUser?['email'] ?? '';
      final schoolName = _currentUser?['school_name'] ?? '';

      String displayName;
      if (role == 'principal') {
        displayName = '$name ($schoolName)';
      } else if (role == 'admin') {
        displayName = '$name (Admin)';
      } else {
        displayName = name;
      }

      await prefs.setString('role', _capitalizeRole(role));
      await prefs.setString('displayName', displayName);
      await prefs.setString('email', email);
    } catch (_) {}
  }

  String _capitalizeRole(String role) {
    if (role.isEmpty) return role;
    return role[0].toUpperCase() + role.substring(1);
  }

  /// Clear previous active sessions (handles 409 conflict)
  Future<bool> _clearPreviousSessions(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/clear-previous-sessions'),
        headers: _headers,
        body: json.encode({
          'email': email,
          'password': password,
        }),
      ).timeout(const Duration(seconds: 15));
      return response.statusCode == 200;
    } catch (e) {
      print('Clear sessions failed: $e');
      return false;
    }
  }
}
