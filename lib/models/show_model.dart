/// A TV show as returned by the TVmaze API (https://api.tvmaze.com).
///
/// Only the fields the app actually uses are modelled. See
/// [TvShowService] for the fetching logic.
class TvShow {
  final int id;
  final String name;
  final String url;

  /// "Scripted", "Animation", "Game Show", ... May be null for some entries.
  final String? type;
  final String? language;
  final List<String> genres;

  /// "Running", "Ended", "To Be Determined", ... May be null.
  final String? status;
  final String? premiered;
  final String? ended;

  /// Poster sizes. Null when the show has no artwork on TVmaze, so always
  /// fall back to a placeholder rather than assuming a URL exists.
  final String? imageMedium;
  final String? imageOriginal;

  /// Raw HTML from the API. Use [summaryText] to get a plain string.
  final String? summaryHtml;

  /// IMDB id like "tt0108778". Useful for linking out to fan wikis.
  final String? imdbId;
  final String? networkName;
  final double? ratingAverage;

  TvShow({
    required this.id,
    required this.name,
    required this.url,
    this.type,
    this.language,
    this.genres = const [],
    this.status,
    this.premiered,
    this.ended,
    this.imageMedium,
    this.imageOriginal,
    this.summaryHtml,
    this.imdbId,
    this.networkName,
    this.ratingAverage,
  });

  /// True when TVmaze has no artwork for this show.
  bool get hasImage => imageMedium != null && imageMedium!.isNotEmpty;

  /// Best available poster URL, or null if the show has no artwork.
  String? get posterUrl => imageMedium ?? imageOriginal;

  /// [summaryHtml] with tags stripped, ready to render in a Text widget.
  String get summaryText {
    if (summaryHtml == null || summaryHtml!.isEmpty) return '';
    return stripHtml(summaryHtml!);
  }

  /// Year of the first episode, e.g. "1994" from "1994-09-22". Null if unknown.
  String? get premieredYear {
    if (premiered == null || premiered!.length < 4) return null;
    return premiered!.substring(0, 4);
  }

  /// Genres as a display string, e.g. "Comedy, Romance".
  String get genresText => genres.join(', ');

  factory TvShow.fromJson(Map<String, dynamic> json) {
    final image = json['image'] as Map<String, dynamic>?;

    // A show may be on a traditional network OR a web channel (streaming),
    // and exactly one of the two is populated.
    final network = json['network'] as Map<String, dynamic>?;
    final webChannel = json['webChannel'] as Map<String, dynamic>?;

    final rating = json['rating'] as Map<String, dynamic>?;
    final externals = json['externals'] as Map<String, dynamic>?;

    return TvShow(
      id: json['id'] as int? ?? 0,
      name: json['name'] as String? ?? 'Unknown',
      url: json['url'] as String? ?? '',
      type: json['type'] as String?,
      language: json['language'] as String?,
      genres: json['genres'] != null
          ? List<String>.from(json['genres'] as List)
          : const [],
      status: json['status'] as String?,
      premiered: json['premiered'] as String?,
      ended: json['ended'] as String?,
      imageMedium: image?['medium'] as String?,
      imageOriginal: image?['original'] as String?,
      summaryHtml: json['summary'] as String?,
      imdbId: externals?['imdb'] as String?,
      networkName: (network?['name'] ?? webChannel?['name']) as String?,
      ratingAverage: (rating?['average'] as num?)?.toDouble(),
    );
  }

  /// Parses one entry of `/search/shows`, which wraps the show in a score.
  factory TvShow.fromSearchEntry(Map<String, dynamic> json) {
    return TvShow.fromJson(json['show'] as Map<String, dynamic>);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'type': type,
      'language': language,
      'genres': genres,
      'status': status,
      'premiered': premiered,
      'ended': ended,
      'imageMedium': imageMedium,
      'imageOriginal': imageOriginal,
      'summaryHtml': summaryHtml,
      'imdbId': imdbId,
      'networkName': networkName,
      'ratingAverage': ratingAverage,
    };
  }

  TvShow copyWith({
    int? id,
    String? name,
    String? url,
    String? type,
    String? language,
    List<String>? genres,
    String? status,
    String? premiered,
    String? ended,
    String? imageMedium,
    String? imageOriginal,
    String? summaryHtml,
    String? imdbId,
    String? networkName,
    double? ratingAverage,
  }) {
    return TvShow(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      type: type ?? this.type,
      language: language ?? this.language,
      genres: genres ?? this.genres,
      status: status ?? this.status,
      premiered: premiered ?? this.premiered,
      ended: ended ?? this.ended,
      imageMedium: imageMedium ?? this.imageMedium,
      imageOriginal: imageOriginal ?? this.imageOriginal,
      summaryHtml: summaryHtml ?? this.summaryHtml,
      imdbId: imdbId ?? this.imdbId,
      networkName: networkName ?? this.networkName,
      ratingAverage: ratingAverage ?? this.ratingAverage,
    );
  }

  /// Strips HTML tags and decodes the handful of entities TVmaze emits.
  ///
  /// TVmaze summaries are simple `<p>`/`<b>` fragments, so a full HTML parser
  /// would be overkill here.
  static String stripHtml(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p>', caseSensitive: false), '\n\n')
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#039;', "'")
        .replaceAll('&apos;', "'")
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .replaceAll(RegExp(r'\n{3,}'), '\n\n')
        .trim();
  }
}
