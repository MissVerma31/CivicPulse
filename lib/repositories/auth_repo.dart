import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/storage/token_storage.dart';
import '../models/auth_models.dart';

class AuthRepository {
  final Dio dio;
  AuthRepository(this.dio);

  Future<void> register(RegisterRequest request) async {
    try {
      await dio.post(ApiConstants.register, data: request.toJson());
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserResponse> login(LoginRequest request) async {
    try {
      final response = await dio.post(
        ApiConstants.login,
        data: request.toJson(),
      );


      final token = response.data.toString().trim();
      if (token.isEmpty) {
        throw Exception('No token returned from login');
      }


      final looksLikeJwt = token.startsWith('eyJ') && token.split('.').length == 3;
      if (!looksLikeJwt) {
        throw Exception('Invalid email or password');
      }

      await TokenStorage.saveToken(token);
      final user = await getCurrentUser();
      await TokenStorage.saveRole(user.role);
      if (user.department != null) {
        await TokenStorage.saveDepartment(user.department!);
      }
      return user;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<UserResponse> getCurrentUser() async {
    try {
      final response = await dio.get(ApiConstants.userMe);
      return UserResponse.fromJson(response.data);
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> logout() async {
    await TokenStorage.clearToken();
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