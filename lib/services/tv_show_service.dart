import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/result.dart';
import '../models/show_model.dart';

/// Fetches TV show data (posters, summaries, metadata) from TVmaze.
///
/// TVmaze is free and requires **no API key** and no account. It is
/// rate-limited to roughly 10 requests/second, so results are cached in
/// memory for [_cacheTtl] and identical concurrent requests are de-duplicated.
class TvShowService {
  static const String _baseUrl = 'https://api.tvmaze.com';
  static const Duration _timeout = Duration(seconds: 15);
  static const Duration _cacheTtl = Duration(hours: 6);
  static const int _searchPageSize = 10;

  final http.Client? _injectedClient;
  http.Client? _lazyClient;

  /// The client is created on first use rather than in the constructor, so a
  /// service that is never called never holds an open connection pool.
  http.Client get _client => _lazyClient ??= _injectedClient ?? http.Client();

  /// Cached responses keyed by request path, e.g. "/search/shows?q=friends".
  final Map<String, _CacheEntry> _cache = {};

  /// In-flight requests, so several widgets mounting at once share one call.
  final Map<String, Future<List<TvShow>>> _inFlight = {};

  TvShowService({http.Client? client}) : _injectedClient = client;

  /// Searches shows by title. TVmaze caps a search page at 10 results, so this
  /// returns at most 10 shows ordered by relevance.
  Future<Result<List<TvShow>>> searchShows(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return Result.error('Please enter a show name');
    }

    final path = '/search/shows?q=${Uri.encodeQueryComponent(trimmed)}';
    try {
      final shows = await _fetchList(path);
      return Result.success(shows);
    } catch (e) {
      return Result.error(_friendlyError(e, 'Could not search shows'));
    }
  }

  /// Searches across the shows with the highest ratings. Useful as a
  /// "popular shows" source when the user has not typed anything yet.
  Future<Result<List<TvShow>>> topRatedShows({int page = 0}) async {
    try {
      final shows = await _fetchList('/shows?page=$page');
      return Result.success(shows);
    } catch (e) {
      return Result.error(_friendlyError(e, 'Could not load popular shows'));
    }
  }

  /// Fetches a single show by its TVmaze id.
  Future<Result<TvShow>> getShow(int id) async {
    final cached = _readCache('/shows/$id');
    if (cached != null) {
      return Result.success(cached);
    }

    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/shows/$id'))
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return Result.error('Show not found');
      }
      if (response.statusCode != 200) {
        return Result.error('Server error (${response.statusCode})');
      }

      final show = TvShow.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      _writeCache('/shows/$id', show);
      return Result.success(show);
    } catch (e) {
      return Result.error(_friendlyError(e, 'Could not load show'));
    }
  }

  /// Fetches a single show by its TVmaze id with cast and artwork embedded.
  ///
  /// Use this instead of [getShow] when you need a character avatar or a
  /// higher-resolution poster, since the cast is not on the plain show object.
  Future<Result<TvShowDetail>> getShowDetail(int id) async {
    try {
      final response = await _client
          .get(Uri.parse('$_baseUrl/shows/$id?embed[]=cast&embed[]=images'))
          .timeout(_timeout);

      if (response.statusCode == 404) {
        return Result.error('Show not found');
      }
      if (response.statusCode != 200) {
        return Result.error('Server error (${response.statusCode})');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final embedded = json['_embedded'] as Map<String, dynamic>?;

      final cast = (embedded?['cast'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .map(
                (e) => CastMember(
                  id: e['person']?['id'] as int? ?? 0,
                  name: e['person']?['name'] as String? ?? 'Unknown',
                  characterName: e['character']?['name'] as String?,
                  imageUrl: e['person']?['image']?['medium'] as String?,
                ),
              )
              .where((m) => m.name != 'Unknown')
              .toList() ??
          const <CastMember>[];

      // TVmaze returns every artwork variant per show, each with a `type`
      // ("poster" or "background") and nested `resolutions`.
      final images = (embedded?['images'] as List<dynamic>?)
              ?.map((e) => ShowImage.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <ShowImage>[];

      return Result.success(
        TvShowDetail(
          show: TvShow.fromJson(json),
          cast: cast,
          images: images,
        ),
      );
    } catch (e) {
      return Result.error(_friendlyError(e, 'Could not load show details'));
    }
  }

  /// GETs a list endpoint, returning cached data when it is still fresh.
  Future<List<TvShow>> _fetchList(String path) async {
    final cached = _readCacheList(path);
    if (cached != null) {
      return cached;
    }

    // Reuse an identical request that is already running.
    return _inFlight.putIfAbsent(path, () async {
      try {
        final response =
            await _client.get(Uri.parse('$_baseUrl$path')).timeout(_timeout);

        if (response.statusCode == 404) {
          return <TvShow>[];
        }
        if (response.statusCode != 200) {
          throw TvShowApiException('Server error (${response.statusCode})');
        }

        final decoded = jsonDecode(response.body) as List<dynamic>;
        final shows = decoded
            .take(_searchPageSize)
            .map((e) => TvShow.fromSearchEntry(e as Map<String, dynamic>))
            .toList();

        _writeCacheList(path, shows);
        return shows;
      } finally {
        _inFlight.remove(path);
      }
    });
  }

  // --- Cache helpers -------------------------------------------------------

  List<TvShow>? _readCacheList(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.list;
  }

  void _writeCacheList(String key, List<TvShow> value) {
    _cache[key] = _CacheEntry.list(value);
  }

  TvShow? _readCache(String key) {
    final entry = _cache[key];
    if (entry == null) return null;
    if (DateTime.now().difference(entry.timestamp) > _cacheTtl) {
      _cache.remove(key);
      return null;
    }
    return entry.single;
  }

  void _writeCache(String key, TvShow value) {
    _cache[key] = _CacheEntry.single(value);
  }

  /// Empties the in-memory cache, e.g. when the user pulls to refresh.
  void clearCache() {
    _cache.clear();
  }

  void dispose() {
    clearCache();
    _lazyClient?.close();
    _lazyClient = null;
  }

  /// Turns raw exceptions into a message that is safe to show a user.
  String _friendlyError(Object e, String fallback) {
    if (e is TvShowApiException) return e.message;
    if (e is http.ClientException) {
      return 'No internet connection. Check your network and try again.';
    }
    return '$fallback: $e';
  }
}

/// Raised for non-success responses that are not a "not found" case.
class TvShowApiException implements Exception {
  final String message;
  TvShowApiException(this.message);
  @override
  String toString() => message;
}

/// One cached response. TVmaze returns either a show or a list of search
/// results, so the entry holds whichever the endpoint produced.
class _CacheEntry {
  final DateTime timestamp = DateTime.now();
  final List<TvShow>? list;
  final TvShow? single;

  _CacheEntry.list(this.list) : single = null;
  _CacheEntry.single(this.single) : list = null;
}

/// A show plus its embedded cast and artwork.
class TvShowDetail {
  final TvShow show;

  /// Entries of `_embedded.cast`, each with a person photo.
  final List<CastMember> cast;

  /// All artwork TVmaze holds, beyond the single poster on [TvShow].
  final List<ShowImage> images;

  TvShowDetail({
    required this.show,
    this.cast = const [],
    this.images = const [],
  });

  /// Posters, excluding background art.
  List<ShowImage> get posters => images.where((i) => i.isPoster).toList();

  /// The largest landscape image, good as a story or profile banner.
  String? get backgroundUrl {
    final backgrounds = images.where((i) => i.isBackground);
    if (backgrounds.isEmpty) return null;

    ShowImage best = backgrounds.first;
    for (final image in backgrounds) {
      if ((image.width ?? 0) > (best.width ?? 0)) {
        best = image;
      }
    }
    return best.originalUrl;
  }
}

/// One artwork variant from `_embedded.images`.
class ShowImage {
  final int id;

  /// "poster" for portrait key art, "background" for landscape art.
  final String type;
  final bool isMain;
  final String? originalUrl;
  final String? mediumUrl;
  final int? width;
  final int? height;

  const ShowImage({
    required this.id,
    required this.type,
    this.isMain = false,
    this.originalUrl,
    this.mediumUrl,
    this.width,
    this.height,
  });

  bool get isPoster => type == 'poster';
  bool get isBackground => type == 'background';

  String? get url => mediumUrl ?? originalUrl;

  /// The default key art for this show, if TVmaze flags one as main.
  String? get mainPosterUrl {
    if (!isPoster) return null;
    final main = isMain ? this : null;
    return (main ?? this).url;
  }

  factory ShowImage.fromJson(Map<String, dynamic> json) {
    final resolutions = json['resolutions'] as Map<String, dynamic>?;
    final original = resolutions?['original'] as Map<String, dynamic>?;
    final medium = resolutions?['medium'] as Map<String, dynamic>?;

    // Prefer the original entry for dimensions since backgrounds have no
    // medium variant at all.
    final sized = original ?? medium;

    return ShowImage(
      id: json['id'] as int? ?? 0,
      type: json['type'] as String? ?? 'poster',
      isMain: json['main'] as bool? ?? false,
      originalUrl: original?['url'] as String?,
      mediumUrl: medium?['url'] as String?,
      width: sized?['width'] as int?,
      height: sized?['height'] as int?,
    );
  }
}

/// A cast member with their photo, for character avatars.
class CastMember {
  final int id;
  final String name;
  final String? characterName;
  final String? imageUrl;

  const CastMember({
    required this.id,
    required this.name,
    this.characterName,
    this.imageUrl,
  });
}
