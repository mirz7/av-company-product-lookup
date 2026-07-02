import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import '../../core/constants/api_constants.dart';
import '../../core/network/api_client.dart';

class ProductService {

  Future<List<Map<String, dynamic>>?> searchProductsRaw(String query) async {
    try {
      var uri = Uri.parse(ApiConstants.products);
      if (query.isNotEmpty) uri = uri.replace(queryParameters: {'query': query});
      final response = await ApiClient.get(uri);
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

  Future<Map<String, dynamic>> uploadCSV(PlatformFile file) async {
    return uploadInventory(file, mode: 'replace');
  }

  Future<Map<String, dynamic>> uploadInventory(PlatformFile file, {String mode = 'upsert'}) async {
    try {
      // Small proactive call to ensure token is refreshed if expired
      await ApiClient.get(Uri.parse(ApiConstants.health));
      final token = await ApiClient.getFreshTokenProactively();
      
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConstants.baseUrl}/admin/products/upload-inventory/'),
      );
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['mode'] = mode;

      if (kIsWeb) {
        if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ));
        } else {
          return {'success': false, 'error': 'No file bytes available for web upload'};
        }
      } else {
        if (file.path != null) {
          request.files.add(await http.MultipartFile.fromPath(
            'file',
            file.path!,
            filename: file.name,
          ));
        } else if (file.bytes != null) {
          request.files.add(http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ));
        } else {
          return {'success': false, 'error': 'No file data available'};
        }
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final resData = jsonDecode(response.body);
        // Parse created/updated counts from message if present
        final msg = resData['message'] ?? 'Upload completed successfully';
        int created = resData['created'] ?? 0;
        int updated = resData['updated'] ?? 0;
        // Try parsing from message string: "Created: X, Updated: Y"
        final createdMatch = RegExp(r'Created[:\s]+([\d]+)').firstMatch(msg);
        final updatedMatch = RegExp(r'Updated[:\s]+([\d]+)').firstMatch(msg);
        if (createdMatch != null) created = int.tryParse(createdMatch.group(1) ?? '0') ?? 0;
        if (updatedMatch != null) updated = int.tryParse(updatedMatch.group(1) ?? '0') ?? 0;
        return {
          'success': true,
          'message': msg,
          'created': created,
          'updated': updated,
        };
      } else {
        try {
          final resData = jsonDecode(response.body);
          return {'success': false, 'error': resData['error'] ?? 'Server error ${response.statusCode}'};
        } catch (_) {
          return {'success': false, 'error': 'Server error: ${response.statusCode}'};
        }
      }
    } catch (e) {
      return {'success': false, 'error': 'Connection error: $e'};
    }
  }
}
