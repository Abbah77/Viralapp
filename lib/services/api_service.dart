import 'package:dio/dio.dart';
import '../models/video_model.dart';

class ApiService {
  static const String baseUrl = 'https://tt-b577.onrender.com';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {
      'Accept-Encoding': 'gzip',
      'Content-Type': 'application/json',
    },
  ));

  static Future<FeedResponse> getFeed({int page = 1}) async {
    try {
      final res = await _dio.get('/feed', queryParameters: {'page': page});
      return FeedResponse.fromJson(res.data);
    } catch (e) {
      throw Exception('Failed to load feed: $e');
    }
  }
}
