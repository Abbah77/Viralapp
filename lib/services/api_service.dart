import 'package:dio/dio.dart';
import '../models/models.dart';

class ApiService {
  static const String _base = 'https://tt-b577.onrender.com';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _base,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 10),
    headers: {'Accept-Encoding': 'gzip'},
  ));

  static Future<FeedResponse> getFeed({int page = 1}) async {
    final res = await _dio.get('/feed', queryParameters: {'page': page});
    return FeedResponse.fromJson(res.data);
  }

  static Future<List<VideoModel>> search(String query) async {
    try {
      final res = await _dio.get('/search', queryParameters: {'q': query});
      return (res.data['videos'] as List? ?? [])
          .map((v) => VideoModel.fromJson(v))
          .toList();
    } catch (_) {
      return [];
    }
  }
}
