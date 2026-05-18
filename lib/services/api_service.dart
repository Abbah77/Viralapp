import 'package:dio/dio.dart';
import '../models/models.dart';

class ApiService {
  static const String _base = 'https://tt-b577.onrender.com';

  // Longer timeouts to handle Render free-tier cold starts (up to 60s)
  static final Dio _dio = Dio(BaseOptions(
    baseUrl: _base,
    connectTimeout: const Duration(seconds: 70),
    receiveTimeout: const Duration(seconds: 70),
    headers: {'Accept-Encoding': 'gzip'},
  ));

  /// Retry helper — retries up to [maxAttempts] times with exponential backoff.
  /// Ideal for Render cold-starts that need a few seconds to wake up.
  static Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxAttempts = 3,
  }) async {
    int attempt = 0;
    while (true) {
      try {
        return await fn();
      } catch (e) {
        attempt++;
        if (attempt >= maxAttempts) rethrow;
        // Wait 4s, 8s before retrying
        await Future.delayed(Duration(seconds: 4 * attempt));
      }
    }
  }

  // GET /feed?cursor=&limit=10
  static Future<FeedResponse> getFeed({int? cursor, int limit = 10}) =>
      _withRetry(() async {
        final params = <String, dynamic>{'limit': limit};
        if (cursor != null) params['cursor'] = cursor;
        final res = await _dio.get('/feed', queryParameters: params);
        return FeedResponse.fromJson(res.data as Map<String, dynamic>);
      });

  // GET /movie/{slug}
  static Future<MovieDetail> getMovie(String slug) =>
      _withRetry(() async {
        final res = await _dio.get('/movie/$slug');
        return MovieDetail.fromJson(res.data as Map<String, dynamic>);
      });

  // GET /search?q=
  static Future<List<MovieCard>> search(String q, {int limit = 20}) =>
      _withRetry(() async {
        final res = await _dio.get('/search', queryParameters: {'q': q, 'limit': limit});
        return (res.data['data'] as List? ?? [])
            .map((m) => MovieCard.fromJson(m as Map<String, dynamic>))
            .toList();
      });
}
