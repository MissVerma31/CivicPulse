import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/complaint_model.dart';
import '../models/page_response.dart';

class ComplaintRepository {
  final Dio dio;
  ComplaintRepository(this.dio);

  Future<ComplaintResponse> createComplaint(ComplaintCreateRequest request) async {
    try {
      final response = await dio.post(
        ApiConstants.complaints,
        data: request.toJson(),
      );
      return ComplaintResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<PageResponse<ComplaintResponse>> getMyComplaints({int page = 0, int size = 10}) async {
    try {
      final response = await dio.get(
        ApiConstants.myComplaints,
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data, (json) => ComplaintResponse.fromJson(json));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ComplaintResponse> getComplaintById(int id) async {
    try {
      final response = await dio.get(ApiConstants.complaintById(id));
      return ComplaintResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Old department endpoint. Authority screens now use
  /// [getAuthorityComplaints] instead (backend reads the department from
  /// the JWT, so the app no longer has to send it).
  Future<List<ComplaintResponse>> getComplaintsByDepartment(String department) async {
    try {
      final response = await dio.get(ApiConstants.complaintsByDepartment(department));
      return _parseComplaintList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------
  // Authority listings
  // ---------------------------------------------------------------

  /// GET /api/authority/complaints
  /// ALL complaints of the logged-in authority's department, including
  /// the ones nobody has verified yet.
  Future<List<ComplaintResponse>> getAuthorityComplaints({int page = 0, int size = 50}) async {
    try {
      final response = await dio.get(
        ApiConstants.authorityComplaints,
        queryParameters: {'page': page, 'size': size},
      );
      return _parseComplaintList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /api/authority/complaints/assigned-to-me
  /// Only the complaints this authority has verified / taken up.
  Future<List<ComplaintResponse>> getAssignedToMe({int page = 0, int size = 50}) async {
    try {
      final response = await dio.get(
        ApiConstants.authorityAssignedToMe,
        queryParameters: {'page': page, 'size': size},
      );
      return _parseComplaintList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // ---------------------------------------------------------------
  // Admin listing
  // ---------------------------------------------------------------

  /// GET /api/admin/complaints - every complaint in the system.
  Future<List<ComplaintResponse>> getAdminComplaints({int page = 0, int size = 50}) async {
    try {
      final response = await dio.get(
        ApiConstants.adminComplaints,
        queryParameters: {'page': page, 'size': size},
      );
      return _parseComplaintList(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  Future<PageResponse<ComplaintResponse>> getAllComplaintsPublic({
    String? status,
    String? department,
    int page = 0,
    int size = 10,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.allComplaintsPublic,
        queryParameters: {
          if (status != null) 'status': status,
          if (department != null) 'department': department,
          'page': page,
          'size': size,
        },
      );
      return PageResponse.fromJson(response.data, (json) => ComplaintResponse.fromJson(json));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  Future<void> closeComplaint(int id) async {
    try {
      await dio.patch(ApiConstants.closeComplaint(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // Authority actions

  Future<ComplaintResponse> verifyComplaint(int id, String priority) async {
    try {
      final response = await dio.patch(
        ApiConstants.verifyComplaint(id),
        data: {'priority': priority},
      );
      return ComplaintResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ComplaintResponse> startProgress(int id) async {
    try {
      final response = await dio.patch(ApiConstants.startProgress(id));
      return ComplaintResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ComplaintResponse> resolveComplaint(int id, String resolutionNote, String resolutionPhotoUrl) async {
    try {
      final response = await dio.patch(
        ApiConstants.resolveComplaint(id),
        data: {
          'resolutionNote': resolutionNote,
          'resolutionPhotoUrl': resolutionPhotoUrl,
        },
      );
      return ComplaintResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ComplaintResponse> rejectComplaint(int id, String reason) async {
    try {
      final response = await dio.patch(
        ApiConstants.rejectComplaint(id),
        data: {'reason': reason},
      );
      return ComplaintResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> upvoteComplaint(int id) async {
    try {
      await dio.patch(ApiConstants.upvoteComplaint(id));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ComplaintResponse>> checkSimilarComplaints({
    required int categoryId,
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.similarComplaints,
        queryParameters: {
          'categoryId': categoryId,
          'latitude': latitude,
          'longitude': longitude,
        },
      );
      return _parseComplaintList(response.data);
    } catch (_) {
      // Any failure (network or parsing) must never block filing a
      // complaint - proceed as if no duplicates were found.
      return [];
    }
  }

  /// Accepts either a plain JSON array or a Spring Page body
  /// ({ "content": [...], ... }), since not every endpoint's shape was
  /// confirmed in Swagger.
  List<ComplaintResponse> _parseComplaintList(dynamic data) {
    final List items = data is List
        ? data
        : (data is Map && data['content'] is List ? data['content'] as List : const []);
    return items
        .map((e) => ComplaintResponse.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Exception _handleError(DioException e) {
    if (e.response?.data is String) {
      return Exception(e.response!.data);
    }
    if (e.response?.data is Map && e.response!.data['message'] != null) {
      return Exception(e.response!.data['message']);
    }
    return Exception('Something went wrong. Please try again.');
  }
}