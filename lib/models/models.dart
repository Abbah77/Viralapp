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

  factory VideoModel.fromJson(Map<String, dynamic> j) => VideoModel(
        id: j['id']?.toString() ?? '',
        videoUrl: j['video_url']?.toString() ?? '',
        thumbnailUrl: j['thumbnail_url']?.toString() ?? '',
        caption: j['caption']?.toString() ?? '',
        hashtags: j['hashtags']?.toString() ?? '',
      );
}

class EpisodeModel {
  final int number;
  final int startSec;
  final int endSec;

  EpisodeModel({
    required this.number,
    required this.startSec,
    required this.endSec,
  });
}

class MovieModel {
  final String id;
  final String title;
  final String thumbnailUrl;
  final String videoUrl;
  final String hashtags;
  final int durationSecs;
  final List<EpisodeModel> episodes;

  MovieModel({
    required this.id,
    required this.title,
    required this.thumbnailUrl,
    required this.videoUrl,
    required this.hashtags,
    required this.durationSecs,
    required this.episodes,
  });

  factory MovieModel.fromVideo(VideoModel v) {
    final dur = 7200; // default 2hrs fallback
    const chunkSecs = 300; // 5min episodes
    final eps = <EpisodeModel>[];
    int ep = 1;
    for (int s = 0; s < dur; s += chunkSecs) {
      eps.add(EpisodeModel(
        number: ep++,
        startSec: s,
        endSec: (s + chunkSecs).clamp(0, dur),
      ));
    }
    return MovieModel(
      id: v.id,
      title: v.caption,
      thumbnailUrl: v.thumbnailUrl,
      videoUrl: v.videoUrl,
      hashtags: v.hashtags,
      durationSecs: dur,
      episodes: eps,
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

  factory FeedResponse.fromJson(Map<String, dynamic> j) => FeedResponse(
        page: j['page'] ?? 1,
        nextPage: j['next_page'] ?? 2,
        videos: (j['videos'] as List? ?? [])
            .map((v) => VideoModel.fromJson(v))
            .toList(),
        preloadUrls: (j['preload_urls'] as List? ?? [])
            .map((v) => VideoModel.fromJson(v))
            .toList(),
      );
}
