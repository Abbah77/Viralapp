// ── Movie from /feed ──────────────────────────────────────────────────────────
class MovieCard {
  final int id;
  final String title;
  final String slug;
  final String? thumbnailUrl;
  final String? trailerUrl;

  MovieCard({
    required this.id,
    required this.title,
    required this.slug,
    this.thumbnailUrl,
    this.trailerUrl,
  });

  factory MovieCard.fromJson(Map<String, dynamic> j) => MovieCard(
    id: j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
    title: j['title']?.toString() ?? '',
    slug: j['slug']?.toString() ?? '',
    thumbnailUrl: j['thumbnail_url']?.toString(),
    trailerUrl: j['trailer_url']?.toString(),
  );

  bool get hasTrailer => trailerUrl != null && trailerUrl!.isNotEmpty;
  bool get hasThumbnail => thumbnailUrl != null && thumbnailUrl!.isNotEmpty;
}

// ── Episode from /movie/{slug} ────────────────────────────────────────────────
class EpisodeModel {
  final int id;
  final int number;
  final String url;

  EpisodeModel({
    required this.id,
    required this.number,
    required this.url,
  });

  factory EpisodeModel.fromJson(Map<String, dynamic> j) => EpisodeModel(
    id: j['id'] is int ? j['id'] : int.tryParse(j['id'].toString()) ?? 0,
    number: j['episode_number'] is int
        ? j['episode_number']
        : int.tryParse(j['episode_number'].toString()) ?? 1,
    url: j['url']?.toString() ?? '',
  );
}

// ── Full movie detail ─────────────────────────────────────────────────────────
class MovieDetail {
  final MovieCard movie;
  final List<EpisodeModel> episodes;
  final int totalEpisodes;

  MovieDetail({
    required this.movie,
    required this.episodes,
    required this.totalEpisodes,
  });

  factory MovieDetail.fromJson(Map<String, dynamic> j) => MovieDetail(
    movie: MovieCard.fromJson(j['movie'] as Map<String, dynamic>),
    episodes: (j['episodes'] as List? ?? [])
        .map((e) => EpisodeModel.fromJson(e as Map<String, dynamic>))
        .toList(),
    totalEpisodes: j['total_episodes'] as int? ?? 0,
  );
}

// ── Feed response ─────────────────────────────────────────────────────────────
class FeedResponse {
  final List<MovieCard> data;
  final int? nextCursor;
  final bool hasMore;

  FeedResponse({
    required this.data,
    this.nextCursor,
    required this.hasMore,
  });

  factory FeedResponse.fromJson(Map<String, dynamic> j) => FeedResponse(
    data: (j['data'] as List? ?? [])
        .map((m) => MovieCard.fromJson(m as Map<String, dynamic>))
        .toList(),
    nextCursor: j['next_cursor'] as int?,
    hasMore: j['has_more'] as bool? ?? false,
  );
}
