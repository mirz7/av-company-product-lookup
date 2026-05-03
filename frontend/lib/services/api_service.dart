import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Use the PC's local IP address so the physical Android device can connect over Wi-Fi
  static const String baseUrl = 'http://192.168.1.5:8000/api';
  final storage = const FlutterSecureStorage();

  // ── In-memory product cache ──────────────────────────────────────────────
  // Populated on first successful fetch; persists for the app session.
  static List<Map<String, dynamic>>? _allProductsCache;

  /// Call this to clear the cache (e.g. after logout).
  static void clearProductCache() => _allProductsCache = null;

  Future<bool> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/token/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'username': username, 'password': password}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await storage.write(key: 'access_token', value: data['access']);
        await storage.write(key: 'refresh_token', value: data['refresh']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Fetches all products into the cache (hits backend only once per session).
  Future<List<Map<String, dynamic>>?> _fetchAllProducts(String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/products/?query='),
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data is List) {
        _allProductsCache = List<Map<String, dynamic>>.from(data);
        return _allProductsCache;
      }
    }
    return null;
  }

  /// Search products.
  /// - Empty query  → returns the cached initial list (20 items from backend).
  /// - Non-empty    → filters cache locally; falls back to backend only if the
  ///                  cache is empty or the local search returns nothing.
  Future<List<Map<String, dynamic>>?> searchProducts(String query) async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) return null;

      // ── Empty query: just show the cached initial list ───────────────────
      if (query.isEmpty) {
        if (_allProductsCache != null) return _allProductsCache;
        return await _fetchAllProducts(token); // first load — hits backend once
      }

      // ── Non-empty query: search the cache locally first ──────────────────
      // Make sure the cache is populated
      if (_allProductsCache == null) {
        await _fetchAllProducts(token);
      }

      final q = query.toLowerCase();
      final localResults = _allProductsCache
          ?.where((p) =>
              (p['product_code']?.toString().toLowerCase().contains(q) ?? false) ||
              (p['name']?.toString().toLowerCase().contains(q) ?? false))
          .toList();

      // If we got local hits, return immediately — no backend call needed
      if (localResults != null && localResults.isNotEmpty) {
        return localResults;
      }

      // Cache miss → hit the backend for a precise search
      final response = await http.get(
        Uri.parse('$baseUrl/products/?query=$query'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) {
          final results = List<Map<String, dynamic>>.from(data);
          // Merge results into cache to avoid future backend calls
          if (results.isNotEmpty && _allProductsCache != null) {
            final existingCodes = _allProductsCache!
                .map((p) => p['product_code'])
                .toSet();
            for (final r in results) {
              if (!existingCodes.contains(r['product_code'])) {
                _allProductsCache!.add(r);
              }
            }
          }
          return results;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> register(String name, String username, String role, String password, String phone, String email) async {
    try {
      final parts = name.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      
      final response = await http.post(
        Uri.parse('$baseUrl/register/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
          'email': email,
          'first_name': firstName,
          'last_name': lastName,
          'role': role,
          'phone_number': phone,
        }),
      );
      if (response.statusCode == 201) return true;
      return false;
    } catch (e) {
      return false;
    }
  }

  // ── In-memory profile cache ──────────────────────────────────────────────
  static Map<String, dynamic>? _profileCache;

  /// Call this to clear the profile cache (e.g. on logout or update).
  static void clearProfileCache() => _profileCache = null;

  Future<Map<String, dynamic>?> getProfile({bool forceRefresh = false}) async {
    try {
      if (!forceRefresh && _profileCache != null) {
        return _profileCache;
      }

      final token = await storage.read(key: 'access_token');
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$baseUrl/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        _profileCache = jsonDecode(response.body);
        return _profileCache;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) return false;

      final response = await http.patch(
        Uri.parse('$baseUrl/profile/'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(data),
      );
      if (response.statusCode == 200) {
        clearProfileCache(); // Refresh on next fetch
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> updateProfilePhoto(String imagePath) async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) return false;

      final request = http.MultipartRequest('PATCH', Uri.parse('$baseUrl/profile/'));
      request.headers['Authorization'] = 'Bearer $token';
      request.files.add(await http.MultipartFile.fromPath('profile_photo', imagePath));

      final response = await request.send();
      if (response.statusCode == 200) {
        clearProfileCache(); // Refresh on next fetch
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> incrementSearchCount() async {
    try {
      final token = await storage.read(key: 'access_token');
      if (token == null) return;
      await http.post(
        Uri.parse('$baseUrl/profile/increment-search/'),
        headers: {'Authorization': 'Bearer $token'},
      );
      clearProfileCache(); // Ensure next visit shows updated count
    } catch (e) {
      // Ignore errors for background sync
    }
  }

  Future<void> logout() async {
    await storage.delete(key: 'access_token');
    await storage.delete(key: 'refresh_token');
    clearProfileCache();
    clearProductCache();
  }
}
