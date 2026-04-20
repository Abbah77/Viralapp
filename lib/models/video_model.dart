class VideoModel {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String hashtags;

  VideoModel({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.hashtags,
  });

  factory VideoModel.fromJson(Map<String, dynamic> json) {
    return VideoModel(
      id: json['id'] ?? '',
      videoUrl: json['video_url'] ?? '',
      thumbnailUrl: json['thumbnail_url'] ?? '',
      caption: json['caption'] ?? '',
      hashtags: json['hashtags'] ?? '',
    );
  }
}

class FeedResponse {
  final int page;
  final int nextPage;
  final List<VideoModel> videos;
  final List<VideoModel> preloadUrls;

  FeedResponse({
    required this.page,
    required this.nextPage,
    required this.videos,
    required this.preloadUrls,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> json) {
    return FeedResponse(
      page: json['page'] ?? 1,
      nextPage: json['next_page'] ?? 2,
      videos: (json['videos'] as List<dynamic>? ?? [])
          .map((v) => VideoModel.fromJson(v))
          .toList(),
      preloadUrls: (json['preload_urls'] as List<dynamic>? ?? [])
          .map((v) => VideoModel.fromJson(v))
          .toList(),
    );
  }
}
