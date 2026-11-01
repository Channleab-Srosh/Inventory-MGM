import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart' show MediaType;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../core/constants/app_constants.dart';
import 'paged_result.dart';

export 'paged_result.dart';

/// Custom API Exception with HTTP status and server error details
class ApiException implements Exception {
  final String message;
  final int statusCode;
  final List<dynamic>? errors;

  ApiException(this.message, {this.statusCode = 0, this.errors});

  @override
  String toString() => message;
}

/// Centralized API Service for communicating with the backend REST endpoints
class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  static const String _prefTokenKey = 'auth_token';
  static const String _prefUserKey = 'auth_user_data';
  static const String _prefBaseUrlKey = 'api_base_url';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  String _baseUrl = AppConstants.defaultBaseUrl;
  String? _token;

  /// Global callback when 401 Unauthorized occurs
  void Function()? onSessionExpired;

  String get baseUrl => _baseUrl;
  String? get token => _token;
  bool get hasToken => _token != null && _token!.isNotEmpty;

  static const Duration defaultTimeout = Duration(seconds: 15);
  static const Duration uploadTimeout = Duration(seconds: 60);

  /// Server origin without the API prefix, e.g. http://192.168.0.242:8080
  /// Cleans and sanitizes a URL string by trimming whitespace, stripping non-printable
  /// ASCII/control characters (e.g. \x16/SYN, newlines), invisible unicode characters,
  /// and fixing stray percent-encoded control codes before hostnames.
  static String sanitizeUrl(String? raw) {
    if (raw == null) return '';
    var clean = raw
        .replaceAll(RegExp(r'[\x00-\x1F\x7F\u200B-\u200D\uFEFF]'), '')
        .trim();
    // Strip stray percent-encoded control codes accidentally prepended to host
    clean = clean.replaceAll(RegExp(r'(https?://)%[0-9a-fA-F]{2}'), r'$1');
    return clean;
  }

  /// Checks if a string can be safely parsed as a valid HTTP or HTTPS URI
  static bool isValidBaseUrl(String? url) {
    if (url == null) return false;
    final clean = sanitizeUrl(url);
    if (clean.isEmpty) return false;
    try {
      final uri = Uri.parse(clean);
      return (uri.scheme == 'http' || uri.scheme == 'https') &&
          uri.host.isNotEmpty &&
          !uri.host.contains('%');
    } catch (_) {
      return false;
    }
  }

  String get serverOrigin {
    try {
      final clean = sanitizeUrl(_baseUrl);
      final u = Uri.parse(clean);
      return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
  
    } catch (_) {
      try {
        final u = Uri.parse(AppConstants.defaultBaseUrl);
        return '${u.scheme}://${u.host}${u.hasPort ? ':${u.port}' : ''}';
    
      } catch (_) {
        return 'http://172.20.10.10:8080';
      }
    }

  }

  /// Turns whatever the backend stored in `imageUrl` into a URL this device can load.
  ///  - relative path  (/uploads/images/x.jpg)        -> prefix with current server origin
  ///  - absolute URL pointing to localhost / old IP   -> swap its origin for the current one
  ///  - external URL (https://cdn.example.com/x.jpg)  -> unchanged
  String? resolveImageUrl(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;
    final url = raw.trim();
    if (url.startsWith('/')) return '$serverOrigin$url';
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.hasScheme) return url;
    if (uri.path.startsWith('/uploads/')) {
      final query = uri.hasQuery ? '?${uri.query}' : '';
      return '$serverOrigin${uri.path}$query';
    }
    return url;
  }

  /// Initialize service from local storage
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      try {
        _token = await _secureStorage.read(key: _prefTokenKey);
      } catch (_) {}
      if (_token == null || _token!.isEmpty) {
        _token = prefs.getString(_prefTokenKey);
      }
      final savedBaseUrl = prefs.getString(_prefBaseUrlKey);
      if (savedBaseUrl != null &&
          savedBaseUrl.trim().isNotEmpty &&
          !savedBaseUrl.contains('192.168.45.68') &&
          !savedBaseUrl.contains('10.0.2.2')) {
        _baseUrl = savedBaseUrl.trim();
      } else {
        _baseUrl = AppConstants.defaultBaseUrl;
        await prefs.setString(_prefBaseUrlKey, _baseUrl);
      }
    } catch (_) {
      _baseUrl = AppConstants.defaultBaseUrl;
    }
  }

  /// Update JWT token in secure storage & shared preferences
  Future<void> setToken(String? token) async {
    _token = token;
    try {
      if (token != null) {
        await _secureStorage.write(key: _prefTokenKey, value: token);
      } else {
        await _secureStorage.delete(key: _prefTokenKey);
      }
    } catch (_) {}
    try {
      final prefs = await SharedPreferences.getInstance();
      if (token != null) {
        await prefs.setString(_prefTokenKey, token);
      } else {
        await prefs.remove(_prefTokenKey);
      }
    } catch (_) {}
  }

  /// Persist user profile data locally
  Future<void> saveStoredUserData(String userJson) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefUserKey, userJson);
    } catch (_) {}
  }

  /// Retrieve stored user profile data locally
  Future<String?> getStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_prefUserKey);
    } catch (_) {
      return null;
    }
  }

  /// Clear stored user profile data
  Future<void> clearStoredUserData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefUserKey);
    } catch (_) {}
  }

  /// Clear token and user state on logout
  Future<void> clearToken() async {
    await setToken(null);
    await clearStoredUserData();
  }

  /// Update base URL (e.g. for switching between localhost, emulator, or production)
  Future<void> setBaseUrl(String url) async {
    final clean = url.trim();
    _baseUrl = clean.endsWith('/') ? clean.substring(0, clean.length - 1) : clean;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefBaseUrlKey, _baseUrl);
    } catch (_) {}
  }

  Map<String, String> _buildHeaders() {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (_token != null && _token!.isNotEmpty) {
      headers['Authorization'] = 'Bearer $_token';
    }
    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(utf8.decode(response.bodyBytes));
    } catch (_) {
      jsonBody = null;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (jsonBody is Map<String, dynamic> && jsonBody.containsKey('data')) {
        return jsonBody['data'];
      }
      return jsonBody;
    }

    // Global 401 Unauthorized handling matching JwtAuthEntrypoint
    if (response.statusCode == 401) {
      clearToken();
      onSessionExpired?.call();
      String unauthMsg = 'Session expired or authentication required. Please log in again.';
      if (jsonBody is Map<String, dynamic> && jsonBody['message'] != null && jsonBody['message'].toString().isNotEmpty) {
        unauthMsg = jsonBody['message'].toString();
      }
      throw ApiException(unauthMsg, statusCode: 401);
    }

    // Extract error message
    String errorMessage = 'An error occurred (HTTP ${response.statusCode})';
    List<dynamic>? errors;

    if (jsonBody is Map<String, dynamic>) {
      if (jsonBody['errors'] is List && (jsonBody['errors'] as List).isNotEmpty) {
        errors = jsonBody['errors'] as List;
        final errorDetails = errors
            .map((e) => e is Map ? (e['message'] ?? e['field'] ?? '') : e.toString())
            .where((s) => s.isNotEmpty)
            .join('; ');
        if (errorDetails.isNotEmpty) {
          errorMessage = errorDetails;
        } else if (jsonBody['message'] != null) {
          errorMessage = jsonBody['message'].toString();
        }
      } else if (jsonBody['message'] != null && jsonBody['message'].toString().isNotEmpty) {
        errorMessage = jsonBody['message'].toString();
      }
    }

    throw ApiException(errorMessage, statusCode: response.statusCode, errors: errors);
  }

  /// Check if an exception is a network unreachable / connection refused / timeout error
  bool _isConnectionError(Object e) {
    final s = e.toString().toLowerCase();
    return s.contains('socketexception') ||
        s.contains('connection refused') ||
        s.contains('clientexception') ||
        s.contains('failed host lookup') ||
        s.contains('network is unreachable') ||
        s.contains('connection reset') ||
        s.contains('timeoutexception') ||
        s.contains('timed out') ||
        s.contains('deadline exceeded') ||
        s.contains('handshakeexception') ||
        s.contains('httpexception') ||
        s.contains('os error');
  }

  /// Live connection check against candidate base URL
  Future<bool> checkConnection([String? candidateUrl]) async {
    final target = (candidateUrl ?? _baseUrl).trim();
    if (target.isEmpty) return false;
    final cleanUrl = target.endsWith('/') ? target.substring(0, target.length - 1) : target;

    try {
      // 1. Probe categories endpoint (GET /categories returns 401 Unauthorized when alive)
      final uri = Uri.parse('$cleanUrl/categories');
      final res = await http.get(uri).timeout(const Duration(milliseconds: 1500));
      return res.statusCode > 0;
    } catch (e) {
      // If the host is unreachable, connection refused, or timed out, fail fast
      if (_isConnectionError(e)) {
        return false;
      }
      try {
        // 2. Fallback probe: auth/login with empty POST
        final uri = Uri.parse('$cleanUrl/auth/login');
        final res = await http.post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: '{}',
        ).timeout(const Duration(milliseconds: 1500));
        return res.statusCode > 0;
      } catch (_) {
        return false;
      }
    }
  }

  /// Probe known candidate URLs safely and automatically switch to the reachable one
  Future<String?> findWorkingBaseUrl({List<String>? extraCandidates}) async {
    final allCandidates = [
      if (extraCandidates != null) ...extraCandidates,
      _baseUrl,
      ...AppConstants.candidateBaseUrls,
    ].where((u) => u.trim().isNotEmpty).toSet().toList();

    // If current baseUrl works, keep it
    if (await checkConnection(_baseUrl)) {
      return _baseUrl;
    }

    // Probe remaining candidates concurrently
    final remaining = allCandidates.where((u) => u != _baseUrl).toList();
    if (remaining.isEmpty) return null;

    final completer = Completer<String?>();
    int pending = remaining.length;

    for (final url in remaining) {
      checkConnection(url).then((ok) {
        if (!completer.isCompleted) {
          if (ok) {
            completer.complete(url);
          } else {
            pending--;
            if (pending <= 0) {
              completer.complete(null);
            }
          }
        }
      }).catchError((_) {
        if (!completer.isCompleted) {
          pending--;
          if (pending <= 0) {
            completer.complete(null);
          }
        }
      });
    }

    // Safety timeout: guarantee completer completes without hanging
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (!completer.isCompleted) {
        completer.complete(null);
      }
    });

    final workingUrl = await completer.future;
    if (workingUrl != null && workingUrl != _baseUrl) {
      await setBaseUrl(workingUrl);
    }
    return workingUrl;
  }

  /// Execute HTTP request with automatic fallback candidate probing on connection failure
  Future<dynamic> _executeWithFallback(
    Future<http.Response> Function(String base) requestFn,
  ) async {
    try {
      final response = await requestFn(_baseUrl);
      return _processResponse(response);
    } catch (e) {
      if (_isConnectionError(e)) {
        final working = await findWorkingBaseUrl();
        if (working != null && working != _baseUrl) {
          final retryResponse = await requestFn(working);
          return _processResponse(retryResponse);
        }
        final errStr = e.toString().toLowerCase();
        if (errStr.contains('timeout') || e is TimeoutException) {
          throw ApiException(
            'Connection timed out to $_baseUrl. The server did not respond. Check that your backend is running or change server IP.',
            statusCode: 408,
          );
        } else if (errStr.contains('refused') || errStr.contains('socketexception') || errStr.contains('failed host lookup')) {
          throw ApiException(
            'Cannot connect to backend server at $_baseUrl. Please check that the server is running.',
            statusCode: 503,
          );
        }
      }
      rethrow;
    }
  }

  // Generic HTTP helpers
  Future<dynamic> get(String endpoint, {Map<String, dynamic>? queryParams}) async {
    return _executeWithFallback((base) {
      Uri uri = Uri.parse('$base$endpoint');
      if (queryParams != null && queryParams.isNotEmpty) {
        final cleanParams = <String, String>{};
        queryParams.forEach((key, val) {
          if (val != null) {
            cleanParams[key] = val.toString();
          }
        });
        uri = uri.replace(queryParameters: cleanParams);
      }
      return http.get(uri, headers: _buildHeaders()).timeout(defaultTimeout);
    });
  }

  Future<dynamic> post(String endpoint, {dynamic body}) async {
    return _executeWithFallback((base) {
      final uri = Uri.parse('$base$endpoint');
      return http.post(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(defaultTimeout);
    });
  }

  Future<dynamic> put(String endpoint, {dynamic body}) async {
    return _executeWithFallback((base) {
      final uri = Uri.parse('$base$endpoint');
      return http.put(
        uri,
        headers: _buildHeaders(),
        body: body != null ? jsonEncode(body) : null,
      ).timeout(defaultTimeout);
    });
  }

  Future<dynamic> delete(String endpoint) async {
    return _executeWithFallback((base) {
      final uri = Uri.parse('$base$endpoint');
      return http.delete(uri, headers: _buildHeaders()).timeout(defaultTimeout);
    });
  }

  // Helper to normalize transaction type for backend enum TransactionType (STOCK_IN, STOCK_OUT)
  String? _normalizeTransactionType(dynamic type) {
    if (type == null) return null;
    final s = type.toString().toUpperCase().trim();
    if (s.isEmpty) return null;
    if (s.contains('IN')) return 'STOCK_IN';
    if (s.contains('OUT')) return 'STOCK_OUT';
    return s;
  }

  // Helper to normalize user role for backend enum Role (ADMIN, MANAGER, STAFF)
  String _normalizeRole(String role) {
    final upper = role.toUpperCase().replaceAll('ROLE_', '').trim();
    if (upper == 'ADMIN') return 'ADMIN';
    if (upper == 'MANAGER' || upper == 'WAREHOUSE_MANAGER' || upper == 'WAREHOUSE MANAGER') return 'MANAGER';
    return 'STAFF';
  }

  // Helper to parse numeric Long IDs safely for Spring Boot backend
  int? _parseNumericId(dynamic id) {
    if (id == null) return null;
    if (id is int) return id;
    return int.tryParse(id.toString().trim());
  }

  // ==========================================
  // AUTHENTICATION ENDPOINTS
  // ==========================================

  /// Login: POST /auth/login
  Future<Map<String, dynamic>> login(String username, String password) async {
    final data = await post('/auth/login', body: {
      'username': username,
      'password': password,
    });
    if (data is Map<String, dynamic> && data['token'] != null) {
      await setToken(data['token'].toString());
    }
    return data as Map<String, dynamic>;
  }

  /// Send registration OTP: POST /auth/send-registration-otp
  Future<void> sendRegistrationOtp(String email) async {
    await post('/auth/send-registration-otp', body: {'email': email});
  }

  /// Register: POST /auth/register
  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    required String otp,
  }) async {
    final data = await post('/auth/register', body: {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'otp': otp,
    });
    if (data is Map<String, dynamic> && data['token'] != null) {
      await setToken(data['token'].toString());
    }
    return data as Map<String, dynamic>;
  }

  /// Get current user profile: GET /auth/me
  Future<Map<String, dynamic>> getCurrentUser() async {
    final data = await get('/auth/me');
    return data as Map<String, dynamic>;
  }

  /// Forgot password: POST /auth/forgot-password
  Future<void> forgotPassword(String email) async {
    await post('/auth/forgot-password', body: {'email': email});
  }

  /// Reset password: POST /auth/reset-password
  Future<void> resetPassword(String email, String otp, String newPassword) async {
    await post('/auth/reset-password', body: {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  /// Change password: POST /auth/change-password
  Future<void> changePassword(String currentPassword, String newPassword) async {
    await post('/auth/change-password', body: {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  // ==========================================
  // CATEGORY ENDPOINTS
  // ==========================================

  /// Get categories: GET /categories
  Future<List<dynamic>> getCategories({String? search, int page = 0, int size = 100}) async {
    final data = await get('/categories', queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
      'sort': 'name,asc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }

  /// Get categories paged: GET /categories
  Future<PagedResult<Map<String, dynamic>>> getCategoriesPaged({
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'name,asc',
  }) async {
    final data = await get('/categories', queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
      'sort': sort,
    });
    if (data is Map<String, dynamic>) {
      return PagedResult.fromJson(data, (item) => item as Map<String, dynamic>);
    }
    return PagedResult.empty(page: page, size: size);
  }


  /// Get category by id: GET /categories/{id}
  Future<Map<String, dynamic>> getCategoryById(dynamic id) async {
    final data = await get('/categories/$id');
    return data as Map<String, dynamic>;
  }

  /// Create category: POST /categories
  Future<Map<String, dynamic>> createCategory(String name, String? description) async {
    final data = await post('/categories', body: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return data as Map<String, dynamic>;
  }

  /// Update category: PUT /categories/{id}
  Future<Map<String, dynamic>> updateCategory(dynamic id, String name, String? description) async {
    final data = await put('/categories/$id', body: {
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
    });
    return data as Map<String, dynamic>;
  }

  /// Delete category: DELETE /categories/{id}
  Future<void> deleteCategory(dynamic id) async {
    await delete('/categories/$id');
  }

  /// Bulk delete categories: DELETE /categories/1,2,3
  Future<void> deleteCategories(List<int> ids) async {
    if (ids.isEmpty) return;
    final idsStr = ids.join(',');
    await delete('/categories/$idsStr');
  }

  // ==========================================
  // SUPPLIER ENDPOINTS
  // ==========================================

  /// Get suppliers: GET /suppliers
  Future<List<dynamic>> getSuppliers({String? search, int page = 0, int size = 100}) async {
    final data = await get('/suppliers', queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
      'sort': 'name,asc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }

  /// Get suppliers paged: GET /suppliers
  Future<PagedResult<Map<String, dynamic>>> getSuppliersPaged({
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'name,asc',
  }) async {
    final data = await get('/suppliers', queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
      'sort': sort,
    });
    if (data is Map<String, dynamic>) {
      return PagedResult.fromJson(data, (item) => item as Map<String, dynamic>);
    }
    return PagedResult.empty(page: page, size: size);
  }


  /// Get supplier by id: GET /suppliers/{id}
  Future<Map<String, dynamic>> getSupplierById(dynamic id) async {
    final data = await get('/suppliers/$id');
    return data as Map<String, dynamic>;
  }

  /// Create supplier: POST /suppliers
  Future<Map<String, dynamic>> createSupplier({
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    final data = await post('/suppliers', body: {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (address != null && address.isNotEmpty) 'address': address,
    });
    return data as Map<String, dynamic>;
  }

  /// Update supplier: PUT /suppliers/{id}
  Future<Map<String, dynamic>> updateSupplier(
    dynamic id, {
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    final data = await put('/suppliers/$id', body: {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (address != null && address.isNotEmpty) 'address': address,
    });
    return data as Map<String, dynamic>;
  }

  /// Delete supplier: DELETE /suppliers/{id}
  Future<void> deleteSupplier(dynamic id) async {
    await delete('/suppliers/$id');
  }

  /// Bulk delete suppliers: DELETE /suppliers/1,2,3
  Future<void> deleteSuppliers(List<int> ids) async {
    if (ids.isEmpty) return;
    final idsStr = ids.join(',');
    await delete('/suppliers/$idsStr');
  }

  // ==========================================
  // CUSTOMER ENDPOINTS
  // ==========================================

  /// Get customers: GET /customers
  Future<List<dynamic>> getCustomers({String? search, int page = 0, int size = 100}) async {
    final data = await get('/customers', queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
      'sort': 'id,asc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }

  /// Get customers paged: GET /customers
  Future<PagedResult<Map<String, dynamic>>> getCustomersPaged({
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'id,asc',
  }) async {
    final data = await get('/customers', queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
      'sort': sort,
    });
    if (data is Map<String, dynamic>) {
      return PagedResult.fromJson(data, (item) => item as Map<String, dynamic>);
    }
    return PagedResult.empty(page: page, size: size);
  }


  /// Get customer by id: GET /customers/{id}
  Future<Map<String, dynamic>> getCustomerById(dynamic id) async {
    final data = await get('/customers/$id');
    return data as Map<String, dynamic>;
  }

  /// Create customer: POST /customers
  Future<Map<String, dynamic>> createCustomer({
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    final data = await post('/customers', body: {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (address != null && address.isNotEmpty) 'address': address,
    });
    return data as Map<String, dynamic>;
  }

  /// Update customer: PUT /customers/{id}
  Future<Map<String, dynamic>> updateCustomer(
    dynamic id, {
    required String name,
    required String phone,
    String? email,
    String? address,
  }) async {
    final data = await put('/customers/$id', body: {
      'name': name,
      'phone': phone,
      if (email != null && email.isNotEmpty) 'email': email,
      if (address != null && address.isNotEmpty) 'address': address,
    });
    return data as Map<String, dynamic>;
  }

  /// Update customer status: PUT /customers/{id}/status
  Future<Map<String, dynamic>> updateCustomerStatus(dynamic id, bool active) async {
    final data = await put('/customers/$id/status', body: {'active': active});
    return data as Map<String, dynamic>;
  }

  /// Delete customer: DELETE /customers/{id}
  Future<void> deleteCustomer(dynamic id) async {
    await delete('/customers/$id');
  }

  /// Bulk delete customers: DELETE /customers/1,2,3
  Future<void> deleteCustomers(List<int> ids) async {
    if (ids.isEmpty) return;
    final idsStr = ids.join(',');
    await delete('/customers/$idsStr');
  }

  // ==========================================
  // PRODUCT ENDPOINTS
  // ==========================================

  /// Get products: GET /products
  Future<List<dynamic>> getProducts({
    String? keyword,
    dynamic categoryId,
    dynamic supplierId,
    bool? active,
    int page = 0,
    int size = 100,
  }) async {
    final parsedCatId = _parseNumericId(categoryId);
    final parsedSupId = _parseNumericId(supplierId);

    final data = await get('/products', queryParams: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (parsedCatId != null) 'categoryId': parsedCatId,
      if (parsedSupId != null) 'supplierId': parsedSupId,
      if (active != null) 'active': active,
      'page': page,
      'size': size,
      'sort': 'id,asc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }

  /// Get products paged: GET /products
  Future<PagedResult<Map<String, dynamic>>> getProductsPaged({
    String? keyword,
    dynamic categoryId,
    dynamic supplierId,
    bool? active,
    int page = 0,
    int size = 20,
    String sort = 'id,asc',
  }) async {
    final parsedCatId = _parseNumericId(categoryId);
    final parsedSupId = _parseNumericId(supplierId);

    final data = await get('/products', queryParams: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (parsedCatId != null) 'categoryId': parsedCatId,
      if (parsedSupId != null) 'supplierId': parsedSupId,
      if (active != null) 'active': active,
      'page': page,
      'size': size,
      'sort': sort,
    });
    if (data is Map<String, dynamic>) {
      return PagedResult.fromJson(data, (item) => item as Map<String, dynamic>);
    }
    return PagedResult.empty(page: page, size: size);
  }


  /// Get product by id: GET /products/{id}
  Future<Map<String, dynamic>> getProductById(dynamic id) async {
    final data = await get('/products/$id');
    return data as Map<String, dynamic>;
  }

  /// Get product by sku: GET /products/sku/{sku}
  Future<Map<String, dynamic>> getProductBySku(String sku) async {
    final data = await get('/products/sku/$sku');
    return data as Map<String, dynamic>;
  }

  /// Create product: POST /products
  Future<Map<String, dynamic>> createProduct({
    required String sku,
    required String name,
    String? description,
    required dynamic categoryId,
    dynamic supplierId,
    required String unitOfMeasure,
    required double unitPrice,
    required int minimumStock,
    bool active = true,
  }) async {
    final parsedCatId = _parseNumericId(categoryId);
    final parsedSupId = _parseNumericId(supplierId);

    final data = await post('/products', body: {
      'sku': sku,
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'categoryId': parsedCatId,
      'supplierId': parsedSupId,
      'unitOfMeasure': unitOfMeasure.toUpperCase(),
      'unitPrice': unitPrice,
      'minimumStock': minimumStock,
      'active': active,
    });
    return data as Map<String, dynamic>;
  }

  /// Update product: PUT /products/{id}
  Future<Map<String, dynamic>> updateProduct(
    dynamic id, {
    required String sku,
    required String name,
    String? description,
    required dynamic categoryId,
    dynamic supplierId,
    required String unitOfMeasure,
    required double unitPrice,
    required int minimumStock,
    bool active = true,
    String? imageUrl, // MUST be sent, otherwise the API clears the image
  }) async {
    final parsedCatId = _parseNumericId(categoryId);
    final parsedSupId = _parseNumericId(supplierId);

    final data = await put('/products/$id', body: {
      'sku': sku,
      'name': name,
      if (description != null && description.isNotEmpty) 'description': description,
      'categoryId': parsedCatId,
      'supplierId': parsedSupId,
      'unitOfMeasure': unitOfMeasure.toUpperCase(),
      'unitPrice': unitPrice,
      'minimumStock': minimumStock,
      'active': active,
      if (imageUrl != null && imageUrl.isNotEmpty) 'imageUrl': imageUrl,
    });
    return data as Map<String, dynamic>;
  }

  /// Update product status: PUT /products/{id}/status
  Future<Map<String, dynamic>> updateProductStatus(dynamic id, bool active) async {
    final data = await put('/products/$id/status', body: {'active': active});
    return data as Map<String, dynamic>;
  }

  /// Delete product: DELETE /products/{id}
  Future<void> deleteProduct(dynamic id) async {
    await delete('/products/$id');
  }

  /// Bulk delete products: DELETE /products/1,2,3
  Future<void> deleteProducts(List<int> ids) async {
    if (ids.isEmpty) return;
    final idsStr = ids.join(',');
    await delete('/products/$idsStr');
  }

  static const int maxImageBytes = 5 * 1024 * 1024; // API limit: 5 MB

  /// Detects the real image type from the first bytes of the file.
  /// Returns (mimeType, extension) or null if it is not JPEG/PNG/GIF/WEBP.
  Future<(String, String)?> _detectImageType(File file) async {
    final raf = await file.open();
    try {
      final h = await raf.read(12);
      bool at(int i, int v) => h.length > i && h[i] == v;
      if (at(0, 0xFF) && at(1, 0xD8) && at(2, 0xFF)) return ('image/jpeg', '.jpg');
      if (at(0, 0x89) && at(1, 0x50) && at(2, 0x4E) && at(3, 0x47)) {
        return ('image/png', '.png');
      }
      if (at(0, 0x47) && at(1, 0x49) && at(2, 0x46) && at(3, 0x38)) {
        return ('image/gif', '.gif');
      }
      if (at(0, 0x52) && at(1, 0x49) && at(2, 0x46) && at(3, 0x46) &&
          at(8, 0x57) && at(9, 0x45) && at(10, 0x42) && at(11, 0x50)) {
        return ('image/webp', '.webp');
      }
      return null;
    } finally {
      await raf.close();
    }
  }

  /// Upload product image: POST /products/{id}/image (multipart/form-data, field "file")
  /// Returns the updated product JSON (contains the new `imageUrl`).
  Future<Map<String, dynamic>> uploadProductImage(dynamic id, File file) async {
    // Client-side checks (same rules as the API) so errors are clear and instant
    if (await file.length() > maxImageBytes) {
      throw ApiException('Image must not exceed 5 MB', statusCode: 400);
    }
    final type = await _detectImageType(file);
    if (type == null) {
      throw ApiException('Unsupported image type. Allowed: JPEG, PNG, GIF, WEBP, JFIF',
          statusCode: 400);
    }
    final (mime, ext) = type;
    final parts = mime.split('/');

    Future<http.Response> send(String base) async {
      final request =
          http.MultipartRequest('POST', Uri.parse('$base/products/$id/image'))
            ..headers['Accept'] = 'application/json';
      if (hasToken) request.headers['Authorization'] = 'Bearer $_token';

      request.files.add(await http.MultipartFile.fromPath(
        'file', // must match @RequestParam("file")
        file.path,
        // The API checks BOTH the content type and the file extension,
        // so set them from the real file type, not from the picker's temp name.
        filename: 'product$ext',
        contentType: MediaType(parts[0], parts[1]),
      ));
      final streamed = await request.send().timeout(uploadTimeout);
      return http.Response.fromStream(streamed);
    }

    final data = await _executeWithFallback(send);
    return data as Map<String, dynamic>;
  }

  // ==========================================
  // STOCK ENDPOINTS
  // ==========================================

  /// Stock in: POST /stock/in
  Future<Map<String, dynamic>> stockIn({
    required dynamic productId,
    required int quantity,
    String? note,
  }) async {
    final pId = _parseNumericId(productId);
    final cleanNote = note != null && note.isNotEmpty
        ? (note.length > 255 ? note.substring(0, 255) : note)
        : null;

    final data = await post('/stock/in', body: {
      'productId': pId,
      'quantity': quantity,
      if (cleanNote != null) 'note': cleanNote,
    });
    return data as Map<String, dynamic>;
  }

  /// Stock out: POST /stock/out
  Future<Map<String, dynamic>> stockOut({
    required dynamic productId,
    required int quantity,
    String? note,
  }) async {
    final pId = _parseNumericId(productId);
    final cleanNote = note != null && note.isNotEmpty
        ? (note.length > 255 ? note.substring(0, 255) : note)
        : null;

    final data = await post('/stock/out', body: {
      'productId': pId,
      'quantity': quantity,
      if (cleanNote != null) 'note': cleanNote,
    });
    return data as Map<String, dynamic>;
  }

  /// Get stock transactions history: GET /stock/history
  Future<List<dynamic>> getStockHistory({
    dynamic productId,
    dynamic type,
    dynamic userId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 100,
  }) async {
    final parsedProdId = _parseNumericId(productId);
    final parsedUserId = _parseNumericId(userId);
    final normType = _normalizeTransactionType(type);

    final data = await get('/stock/history', queryParams: {
      if (parsedProdId != null) 'productId': parsedProdId,
      if (normType != null && normType.isNotEmpty) 'type': normType,
      if (parsedUserId != null) 'userId': parsedUserId,
      if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
      if (toDate != null) 'toDate': toDate.toUtc().toIso8601String(),
      'page': page,
      'size': size,
      'sort': 'createdAt,desc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }

  /// Get stock history paged: GET /stock/history
  Future<PagedResult<Map<String, dynamic>>> getStockHistoryPaged({
    dynamic productId,
    dynamic type,
    dynamic userId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 20,
    String sort = 'createdAt,desc',
  }) async {
    final parsedProdId = _parseNumericId(productId);
    final parsedUserId = _parseNumericId(userId);
    final normType = _normalizeTransactionType(type);

    final data = await get('/stock/history', queryParams: {
      if (parsedProdId != null) 'productId': parsedProdId,
      if (normType != null && normType.isNotEmpty) 'type': normType,
      if (parsedUserId != null) 'userId': parsedUserId,
      if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
      if (toDate != null) 'toDate': toDate.toUtc().toIso8601String(),
      'page': page,
      'size': size,
      'sort': sort,
    });
    if (data is Map<String, dynamic>) {
      return PagedResult.fromJson(data, (item) => item as Map<String, dynamic>);
    }
    return PagedResult.empty(page: page, size: size);
  }

  /// Get stock transaction by id: GET /stock/history/{id}
  Future<Map<String, dynamic>> getStockHistoryById(dynamic id) async {
    final data = await get('/stock/history/$id');
    return data as Map<String, dynamic>;
  }

  // ==========================================
  // DASHBOARD ENDPOINTS
  // ==========================================

  /// Get dashboard KPI summary: GET /dashboard/summary
  Future<Map<String, dynamic>> getDashboardSummary() async {
    final data = await get('/dashboard/summary');
    return data as Map<String, dynamic>;
  }

  /// Get low stock products: GET /dashboard/low-stock
  Future<List<dynamic>> getLowStockProducts({int page = 0, int size = 100}) async {
    final data = await get('/dashboard/low-stock', queryParams: {
      'page': page,
      'size': size,
      'sort': 'stockQuantity,asc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }


  // ==========================================
  // USER MANAGEMENT ENDPOINTS (ADMIN ONLY)
  // ==========================================

  /// Get all users: GET /users
  Future<List<dynamic>> getUsers({String? search, int page = 0, int size = 100}) async {
    final data = await get('/users', queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
      'sort': 'id,asc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }

  /// Get users paged: GET /users
  Future<PagedResult<Map<String, dynamic>>> getUsersPaged({
    String? search,
    int page = 0,
    int size = 20,
    String sort = 'id,asc',
  }) async {
    final data = await get('/users', queryParams: {
      if (search != null && search.isNotEmpty) 'search': search,
      'page': page,
      'size': size,
      'sort': sort,
    });
    if (data is Map<String, dynamic>) {
      return PagedResult.fromJson(data, (item) => item as Map<String, dynamic>);
    }
    return PagedResult.empty(page: page, size: size);
  }


  /// Create user: POST /users
  Future<Map<String, dynamic>> createUser({
    required String username,
    required String email,
    required String password,
    required String fullName,
    String? phone,
    String role = 'STAFF',
  }) async {
    final data = await post('/users', body: {
      'username': username,
      'email': email,
      'password': password,
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'role': _normalizeRole(role),
    });
    return data as Map<String, dynamic>;
  }

  /// Update user: PUT /users/{id}
  Future<Map<String, dynamic>> updateUser(
    dynamic id, {
    String? username,
    required String email,
    String? password,
    required String fullName,
    String? phone,
    required String role,
  }) async {
    final data = await put('/users/$id', body: {
      if (username != null && username.isNotEmpty) 'username': username,
      'email': email,
      if (password != null && password.isNotEmpty) 'password': password,
      'fullName': fullName,
      if (phone != null && phone.isNotEmpty) 'phone': phone,
      'role': _normalizeRole(role),
    });
    return data as Map<String, dynamic>;
  }

  /// Update user status: PUT /users/{id}/status
  Future<Map<String, dynamic>> updateUserStatus(dynamic id, bool active) async {
    final data = await put('/users/$id/status', body: {'active': active});
    return data as Map<String, dynamic>;
  }

  /// Get user by id: GET /users/{id}
  Future<Map<String, dynamic>> getUserById(dynamic id) async {
    final data = await get('/users/$id');
    return data as Map<String, dynamic>;
  }

  /// Delete user: DELETE /users/{id}
  Future<void> deleteUser(dynamic id) async {
    await delete('/users/$id');
  }

  // ==========================================
  // REPORT ENDPOINTS
  // ==========================================

  /// Inventory report: GET /reports/inventory
  Future<List<dynamic>> getInventoryReport({
    String? keyword,
    dynamic categoryId,
    dynamic supplierId,
    bool? active,
    bool? lowStockOnly,
    int page = 0,
    int size = 100,
  }) async {
    final parsedCatId = _parseNumericId(categoryId);
    final parsedSupId = _parseNumericId(supplierId);

    final data = await get('/reports/inventory', queryParams: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (parsedCatId != null) 'categoryId': parsedCatId,
      if (parsedSupId != null) 'supplierId': parsedSupId,
      if (active != null) 'active': active,
      if (lowStockOnly != null) 'lowStockOnly': lowStockOnly,
      'page': page,
      'size': size,
      'sort': 'id,asc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }

  /// Inventory report paged: GET /reports/inventory
  Future<PagedResult<Map<String, dynamic>>> getInventoryReportPaged({
    String? keyword,
    dynamic categoryId,
    dynamic supplierId,
    bool? active,
    bool? lowStockOnly,
    int page = 0,
    int size = 20,
    String sort = 'id,asc',
  }) async {
    final parsedCatId = _parseNumericId(categoryId);
    final parsedSupId = _parseNumericId(supplierId);

    final data = await get('/reports/inventory', queryParams: {
      if (keyword != null && keyword.isNotEmpty) 'keyword': keyword,
      if (parsedCatId != null) 'categoryId': parsedCatId,
      if (parsedSupId != null) 'supplierId': parsedSupId,
      if (active != null) 'active': active,
      if (lowStockOnly != null) 'lowStockOnly': lowStockOnly,
      'page': page,
      'size': size,
      'sort': sort,
    });
    if (data is Map<String, dynamic>) {
      return PagedResult.fromJson(data, (item) => item as Map<String, dynamic>);
    }
    return PagedResult.empty(page: page, size: size);
  }


  /// Stock transaction report: GET /reports/stock-transactions
  Future<List<dynamic>> getStockTransactionReport({
    dynamic productId,
    dynamic type,
    dynamic userId,
    DateTime? fromDate,
    DateTime? toDate,
    int page = 0,
    int size = 100,
  }) async {
    final parsedProdId = _parseNumericId(productId);
    final parsedUserId = _parseNumericId(userId);
    final normType = _normalizeTransactionType(type);

    final data = await get('/reports/stock-transactions', queryParams: {
      if (parsedProdId != null) 'productId': parsedProdId,
      if (normType != null && normType.isNotEmpty) 'type': normType,
      if (parsedUserId != null) 'userId': parsedUserId,
      if (fromDate != null) 'fromDate': fromDate.toUtc().toIso8601String(),
      if (toDate != null) 'toDate': toDate.toUtc().toIso8601String(),
      'page': page,
      'size': size,
      'sort': 'createdAt,desc',
    });
    if (data is Map<String, dynamic> && data['content'] is List) {
      return data['content'] as List<dynamic>;
    }
    return [];
  }

}