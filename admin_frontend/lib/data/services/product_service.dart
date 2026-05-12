import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../../core/constants/api_constants.dart';

class ProductService {
  final AuthService _auth = AuthService();

  Future<List<Map<String, dynamic>>?> searchProductsRaw(String query) async {
    try {
      final token = await _auth.getToken();
      var uri = Uri.parse(ApiConstants.products);
      if (query.isNotEmpty) uri = uri.replace(queryParameters: {'search': query});
      final response = await http.get(uri, headers: {'Authorization': 'Bearer $token'});
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is List) return data.cast<Map<String, dynamic>>();
        if (data is Map && data['results'] is List) return (data['results'] as List).cast<Map<String, dynamic>>();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
