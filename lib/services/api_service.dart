import 'package:dio/dio.dart';
import '../models/models.dart';

class ApiService {
  static const String _base = 'https://tt-b577.onrender.com';

  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _base,
    connectTimeout: const Duration(seconds: 12),
    receiveTimeout: const Duration(seconds: 12),
    headers: {'Accept-Encoding': 'gzip'},
  ));

  // GET /feed?cursor=&limit=10
  static Future<FeedResponse> getFeed({int? cursor, int limit = 10}) async {
    final params = <String, dynamic>{'limit': limit};
    if (cursor != null) params['cursor'] = cursor;
    final res = await _dio.get('/feed', queryParameters: params);
    return FeedResponse.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /movie/{slug}
  static Future<MovieDetail> getMovie(String slug) async {
    final res = await _dio.get('/movie/$slug');
    return MovieDetail.fromJson(res.data as Map<String, dynamic>);
  }

  // GET /search?q=
  static Future<List<MovieCard>> search(String q, {int limit = 20}) async {
    final res = await _dio.get('/search', queryParameters: {'q': q, 'limit': limit});
    return (res.data['data'] as List? ?? [])
        .map((m) => MovieCard.fromJson(m as Map<String, dynamic>))
        .toList();
  }
}
