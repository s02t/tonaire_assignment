import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String baseUrl = 'http://localhost:3000';
  // static const String baseUrl = 'http://10.0.2.2:3000'; // Android emulator
  // static const String baseUrl = 'http://localhost:3000'; // Desktop

  static const String _tokenKey = 'jwt_token';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> deleteToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await getToken();
      if (token != null) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  static Map<String, dynamic> _parseResponse(http.Response response) {
    try {
      final body = jsonDecode(response.body);
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': body};
      }
      return {'success': false, 'error': body['error'] ?? 'Unknown error'};
    } catch (_) {
      return {'success': false, 'error': 'Failed to parse response'};
    }
  }

  // ---- AUTH ----

  static Future<Map<String, dynamic>> login(String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> signup(String username, String email, String password) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/signup'),
      headers: await _headers(auth: false),
      body: jsonEncode({'username': username, 'email': email, 'password': password}),
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> forgotPassword(String email) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/forgot-password'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email}),
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> verifyOtp(String email, String otp, String newPassword) async {
    final res = await http.post(
      Uri.parse('$baseUrl/auth/verify-otp'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email, 'otp': otp, 'new_password': newPassword}),
    );
    return _parseResponse(res);
  }

  // ---- CATEGORIES ----

  static Future<Map<String, dynamic>> getCategories({String search = ''}) async {
    final uri = Uri.parse('$baseUrl/categories').replace(
      queryParameters: search.isNotEmpty ? {'search': search} : null,
    );
    final res = await http.get(uri, headers: await _headers());
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> createCategory(String name, String description) async {
    final res = await http.post(
      Uri.parse('$baseUrl/categories'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'description': description}),
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> updateCategory(int id, String name, String description) async {
    final res = await http.put(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _headers(),
      body: jsonEncode({'name': name, 'description': description}),
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> deleteCategory(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/categories/$id'),
      headers: await _headers(),
    );
    return _parseResponse(res);
  }

  // ---- PRODUCTS ----

  static Future<Map<String, dynamic>> getProducts({
    String search = '',
    int? categoryId,
    String sortBy = 'name',
    String sortOrder = 'ASC',
    int page = 1,
    int limit = 20,
    double? minPrice,
    double? maxPrice,
  }) async {
    final params = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
      'sort_by': sortBy,
      'sort_order': sortOrder,
    };
    if (search.isNotEmpty) params['search'] = search;
    if (categoryId != null) params['category_id'] = categoryId.toString();
    if (minPrice != null) params['min_price'] = minPrice.toString();
    if (maxPrice != null) params['max_price'] = maxPrice.toString();

    final uri = Uri.parse('$baseUrl/products').replace(queryParameters: params);
    final res = await http.get(uri, headers: await _headers());
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> createProduct({
    required String name,
    required int categoryId,
    required double price,
    String? description,
    String? productCode,
  }) async {
    final res = await http.post(
      Uri.parse('$baseUrl/products'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'category_id': categoryId,
        'price': price,
        'description': description,
        'product_code': productCode,
      }),
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> updateProduct(
    int id, {
    required String name,
    required int categoryId,
    required double price,
    String? description,
  }) async {
    final res = await http.put(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _headers(),
      body: jsonEncode({
        'name': name,
        'category_id': categoryId,
        'price': price,
        'description': description,
      }),
    );
    return _parseResponse(res);
  }

  static Future<Map<String, dynamic>> deleteProduct(int id) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/products/$id'),
      headers: await _headers(),
    );
    return _parseResponse(res);
  }
}