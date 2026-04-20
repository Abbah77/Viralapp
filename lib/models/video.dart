class Video {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;
  final String caption;
  final String hashtags;

  const Video({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
    required this.caption,
    required this.hashtags,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['id'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
      caption: json['caption'] as String? ?? '',
      hashtags: json['hashtags'] as String? ?? '',
    );
  }

  List<String> get hashtagList => hashtags
      .split(RegExp(r'[,\s]+'))
      .where((t) => t.isNotEmpty)
      .toList();
}

class PreloadVideo {
  final String id;
  final String videoUrl;
  final String thumbnailUrl;

  const PreloadVideo({
    required this.id,
    required this.videoUrl,
    required this.thumbnailUrl,
  });

  factory PreloadVideo.fromJson(Map<String, dynamic> json) {
    return PreloadVideo(
      id: json['id'] as String,
      videoUrl: json['video_url'] as String,
      thumbnailUrl: json['thumbnail_url'] as String? ?? '',
    );
  }
}
