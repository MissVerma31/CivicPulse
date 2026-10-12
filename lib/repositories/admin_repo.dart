import 'package:dio/dio.dart';

import '../core/network/dio_client.dart';
import '../models/admin_models.dart';

/// Turns a Dio failure into a message an admin can act on.
String errorMessage(Object e) {
  if (e is DioException) {
    final d = e.response?.data;
    if (d is Map && d['message'] != null) return d['message'].toString();
    if (d is String && d.isNotEmpty && d.length < 200) return d;
    if (e.response?.statusCode == 403) {
      return 'This account does not have admin access.';
    }
    if (e.response?.statusCode == 401) {
      return 'Your session expired. Log in again.';
    }
    return 'Could not reach the server. Check your connection and retry.';
  }
  return e.toString();
}

class AdminRepo {
  // ADJUST if your baseUrl already ends with /api.
  static const _admin = '/api/admin';

  final Dio _dio;

  AdminRepo({Dio? dio}) : _dio = dio ?? DioClient.createDio();

  Future<AdminStats> getStats() async {
    final r = await _dio.get('$_admin/stats');
    return AdminStats.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<AdminComplaintPage> getComplaints({
    String? status,
    String? department,
    int page = 0,
    int size = 10,
  }) async {
    final r = await _dio.get('$_admin/complaints', queryParameters: {
      if (status != null) 'status': status,
      if (department != null) 'department': department,
      'page': page,
      'size': size,
    });
    return AdminComplaintPage.fromJson(Map<String, dynamic>.from(r.data));
  }

  Future<List<SlaRule>> getSlaRules() async {
    final r = await _dio.get('$_admin/sla-rules');
    return (r.data as List)
        .map((e) => SlaRule.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createSlaRule({
    required int categoryId,
    required String priority,
    required int durationHours,
  }) async {
    await _dio.post('$_admin/sla-rules', data: {
      'categoryId': categoryId,
      'priority': priority,
      'durationHours': durationHours,
    });
  }

  Future<void> updateSlaRule(int id, int durationHours) async {
    await _dio.put('$_admin/sla-rules/$id',
        data: {'durationHours': durationHours});
  }

  Future<List<CategoryOption>> getCategories() async {
    final r = await _dio.get('/api/categories');
    final raw = r.data;
    final list = raw is List ? raw : (raw['content'] as List? ?? []);
    return list
        .map((e) => CategoryOption.fromJson(Map<String, dynamic>.from(e)))
        .toList();
  }

  Future<void> createCategory({
    required String name,
    required String defaultDepartment,
  }) async {
    await _dio.post('$_admin/categories', data: {
      'name': name,
      'defaultDepartment': defaultDepartment,
    });
  }

  /// Returns the backend's confirmation string.
  Future<String> createAuthority({
    required String name,
    required String email,
    required String phoneNumber,
    required String city,
    required String ward,
    required String department,
    required String password,
  }) async {
    final r = await _dio.post('$_admin/authorities', data: {
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'city': city,
      'ward': ward,
      'department': department,
      'password': password,
    });
    return r.data?.toString() ?? 'Authority created';
  }
}