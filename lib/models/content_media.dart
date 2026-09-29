/// One item in a post's slideshow.
///
/// Posts used to carry a single `imageUrl` / `videoUrl` / `audioUrl`. Those
/// fields still exist and are still written, because older documents (and
/// several screens) read them. [ContentMedia] is the ordered list that makes a
/// slideshow possible: slide order is the array order, so the author controls
/// the sequence rather than the viewer.
class ContentMedia {
  const ContentMedia({
    required this.type,
    required this.url,
    this.thumbnailUrl,
    this.durationMs,
    this.width,
    this.height,
  });

  /// One of `image`, `video`, `audio`.
  final String type;

  /// The Cloudinary delivery URL.
  final String url;

  /// Optional poster frame, for videos that should not autoplay inline.
  final String? thumbnailUrl;

  /// Known duration in milliseconds, when it was recorded at upload time.
  final int? durationMs;

  /// Intrinsic pixel size, taken from the Cloudinary upload response. Stored so
  /// the viewer can show media at its real proportions without having to
  /// download and decode it first.
  final int? width;
  final int? height;

  bool get isImage => type == 'image';
  bool get isVideo => type == 'video';
  bool get isAudio => type == 'audio';

  /// True when the intrinsic size is known and sane.
  bool get hasDimensions => (width ?? 0) > 0 && (height ?? 0) > 0;

  /// The media's own aspect ratio, or null when unknown.
  ///
  /// A portrait phone photo is 9:16 and a widescreen video is 16:9; forcing
  /// both into one box is what makes a preview crop or letterbox badly.
  double? get aspectRatio =>
      hasDimensions ? width! / height! : null;

  /// Reads one entry of a Firestore `media` array, tolerating the shapes the
  /// array has taken over time.
  static ContentMedia? tryParse(Object? raw) {
    if (raw is! Map) return null;

    final url = (raw['url'] ?? raw['secure_url'])?.toString().trim() ?? '';
    if (url.isEmpty) return null;

    final declared = raw['type']?.toString().trim().toLowerCase() ?? '';
    final thumbnail = raw['thumbnailUrl']?.toString().trim();

    return ContentMedia(
      // The type is authoritative when present, but can be recovered from the
      // URL when an older document omitted it.
      type: declared.isNotEmpty ? declared : inferTypeFromUrl(url),
      url: url,
      thumbnailUrl: (thumbnail == null || thumbnail.isEmpty) ? null : thumbnail,
      durationMs: (raw['durationMs'] as num?)?.toInt(),
      width: (raw['width'] as num?)?.toInt(),
      height: (raw['height'] as num?)?.toInt(),
    );
  }

  /// Best-effort type recovery from a Cloudinary delivery URL.
  ///
  /// Cloudinary puts the resource type in the path, so `/image/upload/...`
  /// is an image and `/video/upload/...` is a video (audio is served by the
  /// video pipeline, so a file extension is needed to tell it apart).
  static String inferTypeFromUrl(String url) {
    final lower = url.toLowerCase();
    if (lower.contains('/audio/')) return 'audio';
    if (lower.contains('/video/') || lower.contains('/raw/')) return 'video';
    if (lower.contains('/image/')) return 'image';

    if (_hasExtension(lower, const ['.mp3', '.m4a', '.wav', '.aac', '.ogg', '.flac'])) {
      return 'audio';
    }
    if (_hasExtension(lower, const ['.mp4', '.mov', '.webm', '.m4v', '.avi', '.mkv'])) {
      return 'video';
    }
    if (_hasExtension(lower, const ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.avif', '.bmp'])) {
      return 'image';
    }
    return 'image';
  }

  static bool _hasExtension(String lowerUrl, List<String> extensions) {
    final path = Uri.tryParse(lowerUrl)?.path ?? lowerUrl;
    return extensions.any(path.endsWith);
  }

  /// Firestore representation.
  Map<String, dynamic> toJson() => {
        'type': type,
        'url': url,
        if (thumbnailUrl != null) 'thumbnailUrl': thumbnailUrl,
        if (durationMs != null) 'durationMs': durationMs,
        if (width != null) 'width': width,
        if (height != null) 'height': height,
      };

  /// Returns a copy with the given fields replaced.
  ContentMedia copyWith({String? url, int? width, int? height}) => ContentMedia(
        type: type,
        url: url ?? this.url,
        thumbnailUrl: thumbnailUrl,
        durationMs: durationMs,
        width: width ?? this.width,
        height: height ?? this.height,
      );

  @override
  bool operator ==(Object other) =>
      other is ContentMedia && other.type == type && other.url == url;

  @override
  int get hashCode => Object.hash(type, url);
}
