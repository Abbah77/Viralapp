import 'package:dio/dio.dart';
import '../models/video.dart';

class ApiService {
  static const String baseUrl = 'https://tt-b577.onrender.com';
  
  final Dio _dio = Dio(BaseOptions(
    baseUrl: baseUrl,
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
    headers: {'Accept-Encoding': 'gzip'},
  ));

  Future<FeedResponse> fetchFeed({int page = 1}) async {
    try {
      final response = await _dio.get('/feed', queryParameters: {'page': page});
      final data = response.data;
      
      final videos = (data['videos'] as List)
          .map((v) => Video.fromJson(v))
          .toList();
          
      final preloadUrls = (data['preload_urls'] as List)
          .map((p) => PreloadVideo.fromJson(p))
          .toList();

      return FeedResponse(
        page: data['page'],
        videos: videos,
        preloadUrls: preloadUrls,
      );
    } on DioException catch (e) {
      throw Exception('Failed to fetch feed: ${e.message}');
    }
  }

  Future<Video> fetchSingleVideo(String videoId) async {
    try {
      final response = await _dio.get('/video/$videoId');
      return Video.fromJson(response.data);
    } on DioException catch (e) {
      throw Exception('Failed to fetch video: ${e.message}');
    }
  }

  Future<List<Video>> searchVideos({int page = 1}) async {
    try {
      final response = await _dio.get('/feed', queryParameters: {'page': page});
      final data = response.data;
      return (data['videos'] as List).map((v) => Video.fromJson(v)).toList();
    } on DioException catch (e) {
      throw Exception('Failed to search: ${e.message}');
    }
  }
}

class FeedResponse {
  final int page;
  final List<Video> videos;
  final List<PreloadVideo> preloadUrls;

  FeedResponse({
    required this.page,
    required this.videos,
    required this.preloadUrls,
  });
}
