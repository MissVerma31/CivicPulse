import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/category_model.dart';

class CategoryRepository {
  final Dio dio;
  CategoryRepository(this.dio);

  Future<List<Category>> getCategories() async {
    try {
      final response = await dio.get(ApiConstants.categories);
      return (response.data as List)
          .map((e) => Category.fromJson(e))
          .toList();
    } on DioException catch (e) {
      throw Exception('Failed to load categories: ${e.message}');
    }
  }

}