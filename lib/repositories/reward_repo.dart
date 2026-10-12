import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/reward_model.dart';
import '../models/page_response.dart';

class RewardRepository {
  final Dio dio;
  RewardRepository(this.dio);

  /// GET /api/users/me/rewards -- paginated (PageRewardHistoryResponse),
  /// same Page<> pattern as ComplaintRepository.getMyComplaints.
  Future<PageResponse<RewardHistoryItem>> getMyRewards({int page = 0, int size = 10}) async {
    try {
      final response = await dio.get(
        ApiConstants.myRewards,
        queryParameters: {'page': page, 'size': size},
      );
      return PageResponse.fromJson(response.data, (json) => RewardHistoryItem.fromJson(json));
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }


  Future<List<String>> getMyBadges() async {
    try {
      final response = await dio.get(ApiConstants.myBadges);
      return (response.data as List).map((e) => e.toString()).toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET /api/leaderboard -- plain array, NOT paginated (confirmed in Swagger).
  Future<List<LeaderboardEntry>> getLeaderboard() async {
    try {
      final response = await dio.get(ApiConstants.leaderboard);
      return (response.data as List)
          .map((e) => LeaderboardEntry.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw _handleError(e);
    }
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