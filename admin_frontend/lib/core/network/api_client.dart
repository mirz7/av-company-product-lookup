import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/constants/api_constants.dart';

class ApiClient {
  static Future<String?> getValidToken() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('access_token');
    if (accessToken == null) return null;

    // Check if token is expired locally if we have a decoder.
    // Or we can just try to use it and if 401, refresh.
    // Since we just want to avoid rewriting all services, we'll just return it.
    // However, if we do a proactive check or let the services call this...
    // Actually, it's better if ApiClient wraps the http calls to catch 401.
    return accessToken;
  }

  static Future<bool> refreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    final refreshToken = prefs.getString('refresh_token');
    if (refreshToken == null || refreshToken.isEmpty) return false;

    try {
      final response = await http.post(
        Uri.parse('${ApiConstants.baseUrl}/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccess = data['access'];
        if (newAccess != null) {
          await prefs.setString('access_token', newAccess);
          // Some backends also return a new refresh token (ROTATE_REFRESH_TOKENS)
          if (data['refresh'] != null) {
            await prefs.setString('refresh_token', data['refresh']);
          }
          return true;
        }
      } else {
        // Refresh token is invalid/expired
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
      }
    } catch (_) {
      // Network error, maybe don't log out yet
    }
    return false;
  }

  // Wrapper for GET
  static Future<http.Response> get(Uri url, {Map<String, String>? headers}) async {
    http.Response res = await http.get(url, headers: await _addToken(headers));
    if (res.statusCode == 401) {
      if (await refreshToken()) {
        res = await http.get(url, headers: await _addToken(headers));
      }
    }
    return res;
  }

  // Wrapper for POST
  static Future<http.Response> post(Uri url, {Map<String, String>? headers, Object? body}) async {
    http.Response res = await http.post(url, headers: await _addToken(headers), body: body);
    if (res.statusCode == 401) {
      if (await refreshToken()) {
        res = await http.post(url, headers: await _addToken(headers), body: body);
      }
    }
    return res;
  }

  // Wrapper for PUT
  static Future<http.Response> put(Uri url, {Map<String, String>? headers, Object? body}) async {
    http.Response res = await http.put(url, headers: await _addToken(headers), body: body);
    if (res.statusCode == 401) {
      if (await refreshToken()) {
        res = await http.put(url, headers: await _addToken(headers), body: body);
      }
    }
    return res;
  }

  // Wrapper for PATCH
  static Future<http.Response> patch(Uri url, {Map<String, String>? headers, Object? body}) async {
    http.Response res = await http.patch(url, headers: await _addToken(headers), body: body);
    if (res.statusCode == 401) {
      if (await refreshToken()) {
        res = await http.patch(url, headers: await _addToken(headers), body: body);
      }
    }
    return res;
  }

  // Wrapper for DELETE
  static Future<http.Response> delete(Uri url, {Map<String, String>? headers, Object? body}) async {
    http.Response res = await http.delete(url, headers: await _addToken(headers), body: body);
    if (res.statusCode == 401) {
      if (await refreshToken()) {
        res = await http.delete(url, headers: await _addToken(headers), body: body);
      }
    }
    return res;
  }

  // Utility to handle multipart refresh generically. 
  // For ProductService multipart upload we can just get token proactively or wrap it.
  static Future<String?> getFreshTokenProactively() async {
     final prefs = await SharedPreferences.getInstance();
     // We can just rely on getValidToken, but if it fails, refreshToken(). 
     // We'll expose a robust method for MultipartRequest which can't be deep cloned easily.
     return prefs.getString('access_token');
  }

  static Future<Map<String, String>> _addToken(Map<String, String>? headers) async {
    final Map<String, String> updated = headers != null ? Map.from(headers) : {};
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    
    // Only inject if it's meant to be an authenticated call or if we just globally attach it
    if (token != null && !updated.containsKey('Authorization')) {
        updated['Authorization'] = 'Bearer $token';
    } else if (updated.containsKey('Authorization')) {
        // Update the existing auth header if it has bearer
        if (updated['Authorization']!.startsWith('Bearer ')) {
            updated['Authorization'] = 'Bearer $token';
        }
    }
    return updated;
  }
}
